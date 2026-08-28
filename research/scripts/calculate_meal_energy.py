#!/usr/bin/env python3
"""Reference implementation of the verified Arcane Odyssey meal-energy model.

Game results use Luau-number/IEEE-754 binary64 arithmetic. Exact rational values
are also reported to make floating-point boundary losses visible.
"""

from __future__ import annotations

import argparse
import json
import math
import sqlite3
import sys
import unicodedata
from fractions import Fraction
from pathlib import Path
from typing import Any, Iterable


ROOT = Path(__file__).resolve().parents[1]
DEFAULT_DATABASE = ROOT / "data" / "arcane_odyssey_cooking.sqlite"


class CalculationError(RuntimeError):
    pass


def normalize_name(value: str) -> str:
    return " ".join(unicodedata.normalize("NFKC", value).casefold().split())


def exact_decimal(value: Any) -> Fraction:
    # SQLite stores these as REAL. Limiting the denominator recovers the intended
    # mechanics fractions (for example 1.66666666666667 -> 5/3).
    return Fraction(str(value)).limit_denominator(10_000)


def _unique_match(rows: Iterable[sqlite3.Row], requested: str, label: str) -> sqlite3.Row:
    wanted = normalize_name(requested)
    matches = [row for row in rows if normalize_name(row["match_name"]) == wanted]
    if not matches:
        raise CalculationError(f"Unknown {label}: {requested!r}")
    identities = {row["id"] for row in matches}
    if len(identities) != 1:
        names = ", ".join(sorted({row["canonical_name"] for row in matches}))
        raise CalculationError(f"Ambiguous {label} {requested!r}; matched: {names}")
    return matches[0]


def _resolve_ingredients(connection: sqlite3.Connection, names: list[str]) -> list[sqlite3.Row]:
    rows = connection.execute(
        """
        SELECT ingredient_id AS id, name AS match_name, name AS canonical_name, raw_energy,
               cook_multiplier, counts_in_first_four_diversity
        FROM ingredients
        """
    ).fetchall()
    resolved = []
    for name in names:
        row = _unique_match(rows, name, "ingredient")
        if row["raw_energy"] is None:
            raise CalculationError(f"Ingredient {row['canonical_name']!r} has no raw energy")
        if row["cook_multiplier"] is None and row["raw_energy"] != 0:
            raise CalculationError(
                f"Ingredient {row['canonical_name']!r} has no cooking multiplier"
            )
        resolved.append(row)
    return resolved


def _resolve_recipe(connection: sqlite3.Connection, name: str) -> sqlite3.Row:
    rows = connection.execute(
        """
        SELECT r.recipe_id AS id, r.name AS match_name, r.name AS canonical_name,
               em.calculation_mode, em.recipe_multiplier, em.minimum_energy,
               em.fixed_energy
        FROM recipes AS r
        JOIN recipe_energy_models AS em
          ON em.energy_model_code = r.energy_model_code
        UNION ALL
        SELECT r.recipe_id AS id, a.alias AS match_name, r.name AS canonical_name,
               em.calculation_mode, em.recipe_multiplier, em.minimum_energy,
               em.fixed_energy
        FROM recipe_aliases AS a
        JOIN recipes AS r ON r.recipe_id = a.recipe_id
        JOIN recipe_energy_models AS em
          ON em.energy_model_code = r.energy_model_code
        """
    ).fetchall()
    return _unique_match(rows, name, "recipe")


def calculate_meal(
    database: Path | str,
    ingredient_names: list[str],
    recipe_name: str,
    cooking_level: int = 8,
) -> dict[str, Any]:
    if not 1 <= len(ingredient_names) <= 5:
        raise CalculationError("A meal must contain between one and five ingredients")

    connection = sqlite3.connect(str(database))
    connection.row_factory = sqlite3.Row
    try:
        ingredients = _resolve_ingredients(connection, ingredient_names)
        recipe = _resolve_recipe(connection, recipe_name)
        level = connection.execute(
            """
            SELECT cooking_level AS level,
                   cooking_multiplier AS energy_quality_multiplier,
                   general_ingredient_slot_count AS ingredient_slots
            FROM cooking_level_mechanics WHERE cooking_level = ?
            """,
            (cooking_level,),
        ).fetchone()
        if level is None:
            raise CalculationError(f"Unknown cooking level: {cooking_level}")
        if len(ingredients) > level["ingredient_slots"]:
            raise CalculationError(
                f"Cooking level {cooking_level} supports {level['ingredient_slots']} ingredient "
                f"slots, not {len(ingredients)}"
            )

        formula = connection.execute(
            "SELECT * FROM meal_energy_formula_models WHERE code = 'standard'"
        ).fetchone()
        if formula is None:
            raise CalculationError("The standard meal-energy formula has not been installed")

        unique_limit = formula["unique_slots"]
        unique_ids = {
            row["id"]
            for row in ingredients[:unique_limit]
            if row["counts_in_first_four_diversity"]
        }
        unique_count = len(unique_ids)
        if unique_count < 1:
            raise CalculationError("The first four slots contain no diversity-counting ingredient")

        mode = recipe["calculation_mode"]
        if mode == "fixed":
            final = int(recipe["fixed_energy"])
            return {
                "recipe": recipe["canonical_name"],
                "cooking_level": cooking_level,
                "calculation_mode": mode,
                "final_energy": final,
                "numeric_model": "fixed value",
            }
        if mode not in {"standard_interpolation_variety", "full_potential"}:
            raise CalculationError(f"Unsupported calculation mode: {mode!r}")

        alpha_exact = (
            Fraction(1)
            if mode == "full_potential"
            else Fraction(unique_count - 1, formula["interpolation_denominator"])
        )
        alpha_binary64 = float(alpha_exact)
        interpolation_overrides = {
            (row["ingredient_id"], row["unique_count"]): row
            for row in connection.execute(
                """
                SELECT ingredient_id, unique_count, contribution_energy,
                       verification_status, notes
                FROM ingredient_interpolation_overrides
                """
            ).fetchall()
        }
        contributions = []
        contribution_sum = 0
        for slot, row in enumerate(ingredients, start=1):
            raw = int(row["raw_energy"])
            multiplier_exact = (
                exact_decimal(row["cook_multiplier"])
                if row["cook_multiplier"] is not None
                else Fraction(1)
            )
            multiplier_binary64 = (
                float(row["cook_multiplier"])
                if row["cook_multiplier"] is not None
                else 1.0
            )
            if multiplier_binary64 < 1.0:
                pre_floor_binary64 = raw * multiplier_binary64
                pre_floor_exact = raw * multiplier_exact
            else:
                pre_floor_binary64 = raw * (
                    1.0 + alpha_binary64 * (multiplier_binary64 - 1.0)
                )
                pre_floor_exact = raw * (
                    1 + alpha_exact * (multiplier_exact - 1)
                )
            contribution = math.floor(pre_floor_binary64)
            contribution_override = (
                interpolation_overrides.get((row["id"], unique_count))
                if mode == "standard_interpolation_variety"
                else None
            )
            if contribution_override is not None:
                contribution = int(contribution_override["contribution_energy"])
            contribution_sum += contribution
            contributions.append(
                {
                    "slot": slot,
                    "ingredient": row["canonical_name"],
                    "raw_energy": raw,
                    "cook_multiplier": str(multiplier_exact),
                    "pre_floor_exact": str(pre_floor_exact),
                    "pre_floor_binary64": pre_floor_binary64,
                    "contribution": contribution,
                    "interpolation_override": (
                        {
                            "verification_status": contribution_override[
                                "verification_status"
                            ],
                            "notes": contribution_override["notes"],
                        }
                        if contribution_override is not None
                        else None
                    ),
                    "counts_toward_unique_count": bool(
                        slot <= unique_limit and row["counts_in_first_four_diversity"]
                    ),
                }
            )

        variety_exact = 1 + exact_decimal(formula["variety_increment"]) * (unique_count - 1)
        recipe_multiplier_exact = exact_decimal(recipe["recipe_multiplier"])
        quality_exact = exact_decimal(level["energy_quality_multiplier"])
        pre_floor_final_exact = (
            contribution_sum * variety_exact * recipe_multiplier_exact * quality_exact
        )

        variety_binary64 = 1.0 + float(formula["variety_increment"]) * (unique_count - 1)
        recipe_multiplier_binary64 = float(recipe["recipe_multiplier"])
        quality_binary64 = float(level["energy_quality_multiplier"])
        pre_floor_final_binary64 = (
            contribution_sum
            * variety_binary64
            * recipe_multiplier_binary64
            * quality_binary64
        )
        final = math.floor(pre_floor_final_binary64)
        if recipe["minimum_energy"] is not None:
            final = max(final, int(recipe["minimum_energy"]))

        return {
            "recipe": recipe["canonical_name"],
            "cooking_level": cooking_level,
            "calculation_mode": mode,
            "unique_ingredient_count_slots_1_to_4": unique_count,
            "alpha": str(alpha_exact),
            "contributions": contributions,
            "contribution_sum": contribution_sum,
            "variety_multiplier": str(variety_exact),
            "recipe_multiplier": str(recipe_multiplier_exact),
            "quality_multiplier": str(quality_exact),
            "pre_floor_final_exact": str(pre_floor_final_exact),
            "pre_floor_final_binary64": pre_floor_final_binary64,
            "final_energy": final,
            "numeric_model": "IEEE-754 binary64 (Luau number behavior)",
            "numeric_boundary_status": formula["numeric_boundary_status"],
        }
    finally:
        connection.close()


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("ingredients", nargs="+", help="Ingredient names in slot order")
    parser.add_argument("--recipe", required=True, help="Resolved recipe name or alias")
    parser.add_argument("--level", type=int, default=8, help="Cooking level (default: 8)")
    parser.add_argument("--database", type=Path, default=DEFAULT_DATABASE)
    return parser.parse_args()


def main() -> int:
    args = parse_args()
    try:
        result = calculate_meal(args.database, args.ingredients, args.recipe, args.level)
    except (CalculationError, sqlite3.Error) as error:
        print(f"error: {error}", file=sys.stderr)
        return 1
    print(json.dumps(result, indent=2))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
