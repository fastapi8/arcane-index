#!/usr/bin/env python3
"""Generate the exact aggregated distribution of max-level Simmered Fruit meals."""

from __future__ import annotations

import argparse
import math
import sqlite3
from collections import defaultdict
from fractions import Fraction
from itertools import combinations_with_replacement
from pathlib import Path

from calculate_meal_energy import exact_decimal


ROOT = Path(__file__).resolve().parents[1]
DEFAULT_DATABASE = ROOT / "data" / "arcane_odyssey_cooking.sqlite"
COOKING_LEVEL = 10
SEASONING_COUNT = 14


def seasoning_multiset_count(slot_count: int, distinct_count: int) -> int:
    """Named seasoning multisets with the requested size and distinct count."""
    if slot_count == 0:
        return 1 if distinct_count == 0 else 0
    return math.comb(SEASONING_COUNT, distinct_count) * math.comb(
        slot_count - 1, distinct_count - 1
    )


def contribution(row: sqlite3.Row, unique_count: int, overrides: dict[tuple[int, int], int]) -> int:
    override = overrides.get((row["ingredient_id"], unique_count))
    if override is not None:
        return override
    raw = int(row["raw_energy"])
    multiplier = float(row["cook_multiplier"] or 1.0)
    if multiplier < 1.0:
        return math.floor(raw * multiplier)
    alpha = (unique_count - 1) / 3.0
    return math.floor(raw * (1.0 + alpha * (multiplier - 1.0)))


def final_energy(contribution_sum: int, unique_count: int) -> int:
    variety = 1.0 + 0.05 * (unique_count - 1)
    return math.floor(contribution_sum * variety * 1.5)


def generate(database: Path | str = DEFAULT_DATABASE) -> tuple[int, int]:
    connection = sqlite3.connect(str(database))
    connection.row_factory = sqlite3.Row
    connection.execute("PRAGMA foreign_keys = ON")
    try:
        fruits = connection.execute(
            """
            SELECT i.ingredient_id, i.name, i.raw_energy, i.cook_multiplier
            FROM ingredients AS i
            JOIN ingredient_recipe_tags AS tags
              ON tags.ingredient_id = i.ingredient_id
             AND tags.tag = 'fruit'
            ORDER BY i.ingredient_id
            """
        ).fetchall()
        if len(fruits) != 31:
            raise RuntimeError(f"expected 31 base fruits, found {len(fruits)}")
        if any(row["raw_energy"] is None for row in fruits):
            raise RuntimeError("all fruits must have raw energy before generation")

        actual_seasoning_count = connection.execute(
            "SELECT count(*) FROM ingredients WHERE ingredient_kind = 'seasoning'"
        ).fetchone()[0]
        if actual_seasoning_count != SEASONING_COUNT:
            raise RuntimeError(
                f"expected {SEASONING_COUNT} seasonings, found {actual_seasoning_count}"
            )

        recipe_id = connection.execute(
            "SELECT recipe_id FROM recipes WHERE name = 'Simmered Fruit'"
        ).fetchone()
        if recipe_id is None:
            raise RuntimeError("Simmered Fruit recipe is not installed")
        recipe_id = int(recipe_id[0])

        quality = connection.execute(
            "SELECT cooking_multiplier FROM cooking_level_mechanics WHERE cooking_level = ?",
            (COOKING_LEVEL,),
        ).fetchone()
        if quality is None or float(quality[0]) != 1.5:
            raise RuntimeError("level 10 must use the verified 1.5 cooking multiplier")

        formula = connection.execute(
            "SELECT variety_increment, interpolation_denominator FROM meal_energy_formula_models WHERE code = 'standard'"
        ).fetchone()
        if formula is None or exact_decimal(formula["variety_increment"]) != Fraction(1, 20):
            raise RuntimeError("unexpected standard meal formula")
        if int(formula["interpolation_denominator"]) != 3:
            raise RuntimeError("unexpected interpolation denominator")

        overrides = {
            (int(row["ingredient_id"]), int(row["unique_count"])): int(
                row["contribution_energy"]
            )
            for row in connection.execute(
                "SELECT ingredient_id, unique_count, contribution_energy FROM ingredient_interpolation_overrides"
            )
        }

        # Aggregate by every field exposed to the recipes-page plot. Ingredient
        # identities remain fully represented in represented_meal_count even when
        # they land on the same plotted result.
        outcomes: dict[tuple[object, ...], int] = defaultdict(int)

        def record(
            first_four_fruits: tuple[sqlite3.Row, ...],
            first_four_seasoning_count: int,
            distinct_seasoning_count: int,
            fifth: sqlite3.Row | str | None,
            dedicated_present: int,
        ) -> None:
            unique_fruits = len({row["ingredient_id"] for row in first_four_fruits})
            unique_count = unique_fruits + distinct_seasoning_count
            first_sum = sum(
                contribution(row, unique_count, overrides) for row in first_four_fruits
            )
            raw_sum = sum(int(row["raw_energy"]) for row in first_four_fruits)
            fruit_count = len(first_four_fruits)
            general_seasoning_count = first_four_seasoning_count
            slot_five_kind = "empty"
            multiplier = seasoning_multiset_count(
                first_four_seasoning_count, distinct_seasoning_count
            )

            if isinstance(fifth, sqlite3.Row):
                slot_five_kind = "fruit"
                fruit_count += 1
                first_sum += contribution(fifth, unique_count, overrides)
                raw_sum += int(fifth["raw_energy"])
            elif fifth == "seasoning":
                slot_five_kind = "seasoning"
                general_seasoning_count += 1
                multiplier *= SEASONING_COUNT

            if dedicated_present:
                multiplier *= SEASONING_COUNT

            general_count = fruit_count + general_seasoning_count
            energy = final_energy(first_sum, unique_count)
            key = (
                general_count,
                fruit_count,
                general_seasoning_count,
                unique_count,
                slot_five_kind,
                dedicated_present,
                raw_sum,
                first_sum,
                energy,
            )
            outcomes[key] += multiplier

        # Two to four occupied general slots. All are within the diversity region.
        for general_count in range(2, 5):
            for fruit_count in range(2, general_count + 1):
                seasoning_slots = general_count - fruit_count
                distinct_values = range(1, seasoning_slots + 1) if seasoning_slots else (0,)
                for fruit_rows in combinations_with_replacement(fruits, fruit_count):
                    for distinct_seasonings in distinct_values:
                        for dedicated in (0, 1):
                            record(
                                fruit_rows,
                                seasoning_slots,
                                distinct_seasonings,
                                None,
                                dedicated,
                            )

        # Five occupied general slots. The first four are unordered, while slot 5
        # is retained separately because it contributes energy without diversity.
        for first_four_fruit_count in range(1, 5):
            seasoning_slots = 4 - first_four_fruit_count
            distinct_values = range(1, seasoning_slots + 1) if seasoning_slots else (0,)
            for fruit_rows in combinations_with_replacement(
                fruits, first_four_fruit_count
            ):
                for distinct_seasonings in distinct_values:
                    for fifth in fruits:
                        for dedicated in (0, 1):
                            record(
                                fruit_rows,
                                seasoning_slots,
                                distinct_seasonings,
                                fifth,
                                dedicated,
                            )
                    if first_four_fruit_count >= 2:
                        for dedicated in (0, 1):
                            record(
                                fruit_rows,
                                seasoning_slots,
                                distinct_seasonings,
                                "seasoning",
                                dedicated,
                            )

        rows = [
            (recipe_id, COOKING_LEVEL, *key, represented_count)
            for key, represented_count in outcomes.items()
        ]
        with connection:
            connection.execute("DELETE FROM simmered_fruit_results")
            connection.executemany(
                """
                INSERT INTO simmered_fruit_results (
                    recipe_id, cooking_level, general_ingredient_count,
                    fruit_count, general_seasoning_count,
                    first_four_unique_count, slot_five_kind,
                    dedicated_seasoning_present, raw_energy_sum,
                    contribution_sum, final_energy, represented_meal_count
                ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
                """,
                rows,
            )

        represented = sum(outcomes.values())
        return len(rows), represented
    finally:
        connection.close()


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--database", type=Path, default=DEFAULT_DATABASE)
    args = parser.parse_args()
    rows, represented = generate(args.database)
    print(f"Stored {rows:,} aggregate rows representing {represented:,} meals")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
