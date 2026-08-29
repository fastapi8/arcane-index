#!/usr/bin/env python3
"""Populate confirmed cooking multipliers and safely inferred raw energies.

Raw energy is inferred only when exactly one non-negative integer satisfies
the appropriate floored cooking equation. Recognized one-ingredient meals,
including fish, reverse the max-level cooking multiplier as a separate stage.
"""

from __future__ import annotations

import argparse
import json
import math
import re
import sqlite3
import sys
import unicodedata
from collections import defaultdict
from fractions import Fraction
from pathlib import Path
from typing import Any


REPOSITORY_ROOT = Path(__file__).resolve().parents[1]
DEFAULT_DATABASE = REPOSITORY_ROOT / "data" / "arcane_odyssey_cooking.sqlite"


def names(multiplier: Fraction, value: str) -> dict[str, Fraction]:
    return {name.strip(): multiplier for name in value.split(",")}


NON_FISH_MULTIPLIERS: dict[str, Fraction] = {}
NON_FISH_MULTIPLIERS.update(names(Fraction(3, 2), """
    Raw Krystoros Meat, Raw Kynatos Meat, Raw Pnevma Meat,
    Raw Terasavros Meat, Raw Thymos Meat, Raw Bear Meat, Raw Bird Meat,
    Raw Boar Meat, Raw Crocodile Meat, Raw Deer Meat, Raw Rabbit Meat,
    Raw Tiger Meat, Raw Wolf Meat
"""))
NON_FISH_MULTIPLIERS.update(names(Fraction(6, 5), """
    Green Apple, Marula, Prickly Pear, Red Apple, Sky Apple, Sky Pear,
    Sourcap, Stratos Apple, Stratos Pear, Stratos Sourcap, Tomato
"""))
NON_FISH_MULTIPLIERS.update(names(Fraction(1, 1), """
    Banana, Lime, Mango, Sky Grapefruit, Sky Lemon, Stratos Grapefruit,
    Stratos Lemon, Giant Banana, Giant Lemon
"""))
NON_FISH_MULTIPLIERS.update(names(Fraction(8, 5), """
    Blue Mushroom, Giant Seacap, Satura Mushroom, Seacap Mushroom,
    Raw Kraken Meat, Raw Omen Meat
"""))
NON_FISH_MULTIPLIERS.update(names(Fraction(5, 4), """
    Giant Greencap, Giant Purplecap, Giant Redcap, Omprela Mushroom,
    Stormfruit, Pumpkin, Sky Pumpkin, Stratos Pumpkin
"""))
NON_FISH_MULTIPLIERS.update(names(Fraction(1, 2), """
    Coconut, Grapes, Orange, Peach, Sky Grapes, Giant Orange
"""))
NON_FISH_MULTIPLIERS.update(names(Fraction(1, 4), """
    Sky Watermelon, Stratos Watermelon, Watermelon
"""))
NON_FISH_MULTIPLIERS.update(names(Fraction(2, 1), "Brown Mushroom, White Mushroom"))
NON_FISH_MULTIPLIERS.update(names(Fraction(7, 2), "Wheat"))
NON_FISH_MULTIPLIERS.update(names(Fraction(5, 3), "Cloudcap Mushroom, Orange Swiftcap"))
NON_FISH_MULTIPLIERS.update(names(Fraction(23, 10), "Cursed Mushroom"))
NON_FISH_MULTIPLIERS.update(names(Fraction(5, 2), "Festive Cookie Dough"))
NON_FISH_MULTIPLIERS.update(names(Fraction(6, 5), """
    Giant Red Apple, Giant Sky Apple, Giant Stratos Apple
"""))

FISH_OVERRIDES = {
    "Jellyfish": Fraction(1, 2),
    "Tuna": Fraction(6, 5),
    "Salmon": Fraction(6, 5),
}
FISH_SIZE_PREFIX = re.compile(r"^(?:giant|small|massive)\s+", re.IGNORECASE)
MAX_COOKING_LEVEL_MULTIPLIER = Fraction(3, 2)
MAX_LEVEL_MEAL_NAMES = {
    "Pumpkin",
    "Sky Pumpkin",
    "Stratos Pumpkin",
    "Wheat",
    "Festive Cookie Dough",
}
CONFIRMED_RAW_ENERGIES = {
    "Coconut": 7,
    "Grapes": 10,
    "Orange": 9,
    "Peach": 12,
    "Sky Grapes": 13,
    "Sky Watermelon": 37,
    "Stratos Watermelon": 55,
    "Watermelon": 25,
    # Non-fish Giant variants have three times their normal counterpart's raw
    # energy. Giant Orange therefore resolves the former 26/27 ambiguity to 27.
    "Giant Orange": 27,
    # A max-level Giant Jellyfish restores 27: 18 * 0.5 * 2 * 1.5 = 27.
    # Candidate 19 would instead display 28, so the canonical value is 18.
    "Jellyfish": 18,
}


def normalized_name(value: str) -> str:
    """Normalize harmless display differences without fuzzy matching."""
    return " ".join(unicodedata.normalize("NFKC", value).split()).casefold()


def ceil_fraction(numerator: int, denominator: int) -> int:
    return -(-numerator // denominator)


def integer_candidates(solo_energy: int, multiplier: Fraction) -> tuple[list[int], tuple[int, int]]:
    """Return all x where floor(x * multiplier) is the imported solo value."""
    p, q = multiplier.numerator, multiplier.denominator
    lower = max(0, ceil_fraction(solo_energy * q, p))
    upper = ceil_fraction((solo_energy + 1) * q, p) - 1
    candidates = [
        value for value in range(lower, upper + 1)
        if (value * p) // q == solo_energy
    ]
    return candidates, (lower, upper)


def raw_energy_candidates(
    solo_energy: int,
    cook_multiplier: Fraction,
    meal_level_multiplier: Fraction | None,
) -> tuple[list[int], tuple[int, int], list[int]]:
    """Reverse each floored stage and return safe integer raw candidates.

    Recognized one-ingredient meals were measured at max cooking level. Their
    displayed solo value is floor(floor(raw * cook) * 1.5), so the level stage
    must be reversed before the ingredient cooking stage.
    """
    if meal_level_multiplier is None:
        candidates, candidate_range = integer_candidates(solo_energy, cook_multiplier)
        return candidates, candidate_range, [solo_energy]

    pre_level_candidates, _ = integer_candidates(solo_energy, meal_level_multiplier)
    raw_candidates: set[int] = set()
    for pre_level_energy in pre_level_candidates:
        candidates, _ = integer_candidates(pre_level_energy, cook_multiplier)
        raw_candidates.update(candidates)
    ordered = sorted(raw_candidates)
    candidate_range = (ordered[0], ordered[-1]) if ordered else (0, -1)
    return ordered, candidate_range, pre_level_candidates


def displayed_solo_energy(
    raw_energy: int,
    cook_multiplier: Fraction,
    meal_level_multiplier: Fraction | None,
) -> int:
    cooked = (raw_energy * cook_multiplier.numerator) // cook_multiplier.denominator
    if meal_level_multiplier is None:
        return cooked
    return (cooked * meal_level_multiplier.numerator) // meal_level_multiplier.denominator


def multiplier_text(value: Fraction) -> str:
    decimal = float(value)
    if value.denominator == 1:
        return f"{decimal:.1f}"
    return f"{value.numerator}/{value.denominator} ({decimal:g})"


def multiplier_matches(existing: float, expected: Fraction) -> bool:
    return math.isclose(existing, float(expected), rel_tol=0.0, abs_tol=1e-12)


def build_targets(rows: list[sqlite3.Row]) -> tuple[list[tuple[sqlite3.Row, Fraction]], list[str]]:
    by_key: dict[str, list[sqlite3.Row]] = defaultdict(list)
    for row in rows:
        by_key[normalized_name(row["name"])].append(row)

    errors: list[str] = []
    targets: list[tuple[sqlite3.Row, Fraction]] = []

    for confirmed_name, multiplier in NON_FISH_MULTIPLIERS.items():
        matches = by_key.get(normalized_name(confirmed_name), [])
        if not matches:
            errors.append(f"missing confirmed non-fish ingredient: {confirmed_name}")
            continue
        if len(matches) != 1:
            ids = [row["ingredient_id"] for row in matches]
            errors.append(f"duplicate normalized matches for {confirmed_name}: ids {ids}")
            continue
        row = matches[0]
        if row["ingredient_kind"] != "normal":
            errors.append(
                f"kind mismatch for {confirmed_name}: expected normal, found {row['ingredient_kind']}"
            )
            continue
        targets.append((row, multiplier))

    fish_rows = [row for row in rows if row["ingredient_kind"] == "fish"]
    canonical_fish: list[sqlite3.Row] = []
    for row in fish_rows:
        if FISH_SIZE_PREFIX.match(row["name"].strip()):
            errors.append(
                f"fish size variant is not canonical and will not be updated: "
                f"{row['name']} (id {row['ingredient_id']})"
            )
        else:
            canonical_fish.append(row)

    fish_by_key: dict[str, list[sqlite3.Row]] = defaultdict(list)
    for row in canonical_fish:
        fish_by_key[normalized_name(row["name"])].append(row)

    for override_name in FISH_OVERRIDES:
        matches = fish_by_key.get(normalized_name(override_name), [])
        if not matches:
            errors.append(f"missing confirmed fish override ingredient: {override_name}")
        elif len(matches) != 1:
            ids = [row["ingredient_id"] for row in matches]
            errors.append(f"duplicate normalized fish matches for {override_name}: ids {ids}")

    for row in canonical_fish:
        multiplier = FISH_OVERRIDES.get(row["name"], Fraction(1, 1))
        if row["name"] not in FISH_OVERRIDES:
            multiplier = next(
                (value for name, value in FISH_OVERRIDES.items()
                 if normalized_name(name) == normalized_name(row["name"])),
                Fraction(1, 1),
            )
        targets.append((row, multiplier))

    return targets, errors


def populate(database: Path) -> dict[str, Any]:
    report: dict[str, Any] = {
        "database": str(database),
        "multipliers_written": 0,
        "multipliers_already_matching": 0,
        "raw_energies_written": 0,
        "raw_energies_corrected_from_legacy_model": 0,
        "raw_energies_already_matching": 0,
        "solo_energies_corrected_from_max_level": 0,
        "solo_energies_already_base": 0,
        "confirmed_raw_energies_written": 0,
        "confirmed_raw_energies_already_matching": 0,
        "zero_contribution_raw_energies_written": 0,
        "zero_contribution_raw_energies_already_zero": 0,
        "fish_raw_energies_written": 0,
        "manual_review": [],
        "conflicts": [],
        "errors": [],
    }

    connection = sqlite3.connect(database)
    connection.row_factory = sqlite3.Row
    try:
        connection.execute("PRAGMA foreign_keys = ON")
        connection.execute("BEGIN IMMEDIATE")
        rows = connection.execute(
            """SELECT ingredient_id, name, ingredient_kind, solo_energy,
                      imported_solo_energy,
                      raw_energy, cook_multiplier
               FROM ingredients
               ORDER BY ingredient_id"""
        ).fetchall()
        targets, errors = build_targets(rows)
        if errors:
            report["errors"].extend(errors)
            raise RuntimeError("name validation failed; no changes were committed")

        # Seasonings and Samerian Ice always contribute zero energy. Their
        # cooking multipliers are intentionally left null because zero raw
        # contribution is sufficient. Both retain their canonical identities.
        for row in rows:
            if row["ingredient_kind"] not in {"seasoning", "ice"}:
                continue
            if row["raw_energy"] is None:
                connection.execute(
                    "UPDATE ingredients SET raw_energy = 0 WHERE ingredient_id = ?",
                    (row["ingredient_id"],),
                )
                report["zero_contribution_raw_energies_written"] += 1
            elif row["raw_energy"] == 0:
                report["zero_contribution_raw_energies_already_zero"] += 1
            else:
                report["conflicts"].append({
                    "ingredient": row["name"],
                    "field": "raw_energy",
                    "existing": row["raw_energy"],
                    "confirmed": 0,
                })

        for row, multiplier in targets:
            current_multiplier = row["cook_multiplier"]
            multiplier_conflict = False
            if current_multiplier is None:
                connection.execute(
                    "UPDATE ingredients SET cook_multiplier = ? WHERE ingredient_id = ?",
                    (float(multiplier), row["ingredient_id"]),
                )
                report["multipliers_written"] += 1
            elif multiplier_matches(current_multiplier, multiplier):
                report["multipliers_already_matching"] += 1
            else:
                report["conflicts"].append({
                    "ingredient": row["name"],
                    "field": "cook_multiplier",
                    "existing": current_multiplier,
                    "confirmed": float(multiplier),
                })
                # Still evaluate raw data so every existing mechanics conflict is
                # reported, but do not add a raw value while the stored multiplier
                # contradicts the confirmed one.
                multiplier_conflict = True

            is_corrected_non_fish_meal = normalized_name(row["name"]) in {
                normalized_name(name) for name in MAX_LEVEL_MEAL_NAMES
            }
            is_max_level_meal = (
                row["ingredient_kind"] == "fish" or is_corrected_non_fish_meal
            )
            meal_level_multiplier = (
                MAX_COOKING_LEVEL_MULTIPLIER if is_max_level_meal else None
            )
            source_solo_energy = row["imported_solo_energy"]
            if source_solo_energy is None:
                raise RuntimeError(
                    f"missing imported solo-energy provenance for {row['name']}"
                )
            candidates, candidate_range, pre_level_candidates = raw_energy_candidates(
                source_solo_energy, multiplier, meal_level_multiplier
            )

            if is_max_level_meal:
                if len(pre_level_candidates) != 1:
                    report["manual_review"].append({
                        "ingredient": row["name"],
                        "field": "solo_energy",
                        "imported_solo_energy": source_solo_energy,
                        "candidate_values": pre_level_candidates,
                        "max_cooking_level_multiplier": multiplier_text(
                            MAX_COOKING_LEVEL_MULTIPLIER
                        ),
                    })
                else:
                    corrected_solo = pre_level_candidates[0]
                    if row["solo_energy"] == corrected_solo:
                        report["solo_energies_already_base"] += 1
                    elif row["solo_energy"] == source_solo_energy:
                        connection.execute(
                            "UPDATE ingredients SET solo_energy = ? WHERE ingredient_id = ?",
                            (corrected_solo, row["ingredient_id"]),
                        )
                        report["solo_energies_corrected_from_max_level"] += 1
                    else:
                        report["conflicts"].append({
                            "ingredient": row["name"],
                            "field": "solo_energy",
                            "existing": row["solo_energy"],
                            "imported": source_solo_energy,
                            "corrected": corrected_solo,
                        })
            confirmed_raw = next(
                (value for name, value in CONFIRMED_RAW_ENERGIES.items()
                 if normalized_name(name) == normalized_name(row["name"])),
                None,
            )
            if confirmed_raw is not None:
                if confirmed_raw not in candidates:
                    raise AssertionError(
                        f"confirmed raw energy for {row['name']} ({confirmed_raw}) "
                        f"is outside calculated candidates {candidates}"
                    )
                candidates = [confirmed_raw]
            if len(candidates) != 1:
                report["manual_review"].append({
                    "ingredient": row["name"],
                    "multiplier": multiplier_text(multiplier),
                    "solo_energy": row["solo_energy"],
                    "imported_solo_energy": source_solo_energy,
                    "candidate_values": candidates,
                    "candidate_range": list(candidate_range),
                    "max_cooking_level_multiplier": (
                        multiplier_text(meal_level_multiplier)
                        if meal_level_multiplier is not None else None
                    ),
                    "pre_level_energy_candidates": pre_level_candidates,
                    "existing_raw_energy": row["raw_energy"],
                })
                continue

            inferred = candidates[0]
            recomputed_solo = displayed_solo_energy(
                inferred, multiplier, meal_level_multiplier
            )
            if recomputed_solo != source_solo_energy:
                raise AssertionError(
                    f"verification failed for {row['name']}: "
                    f"{recomputed_solo} != {source_solo_energy}"
                )

            current_raw = row["raw_energy"]
            if current_raw is None:
                if not multiplier_conflict:
                    connection.execute(
                        "UPDATE ingredients SET raw_energy = ? WHERE ingredient_id = ?",
                        (inferred, row["ingredient_id"]),
                    )
                    report["raw_energies_written"] += 1
                    if row["ingredient_kind"] == "fish":
                        report["fish_raw_energies_written"] += 1
                    if confirmed_raw is not None:
                        report["confirmed_raw_energies_written"] += 1
            elif current_raw == inferred:
                report["raw_energies_already_matching"] += 1
                if confirmed_raw is not None:
                    report["confirmed_raw_energies_already_matching"] += 1
            elif is_corrected_non_fish_meal:
                # Correct only the exact value generated by this script's former
                # one-stage model. Any other existing value remains a conflict.
                legacy_candidates, _ = integer_candidates(source_solo_energy, multiplier)
                if len(legacy_candidates) == 1 and current_raw == legacy_candidates[0]:
                    connection.execute(
                        "UPDATE ingredients SET raw_energy = ? WHERE ingredient_id = ?",
                        (inferred, row["ingredient_id"]),
                    )
                    report["raw_energies_corrected_from_legacy_model"] += 1
                else:
                    report["conflicts"].append({
                        "ingredient": row["name"],
                        "field": "raw_energy",
                        "existing": current_raw,
                        "inferred": inferred,
                    })
            else:
                report["conflicts"].append({
                    "ingredient": row["name"],
                    "field": "raw_energy",
                    "existing": current_raw,
                    "inferred": inferred,
                })

        connection.commit()
        return report
    except Exception as error:
        connection.rollback()
        report["fatal_error"] = str(error)
        raise PopulationError(report) from error
    finally:
        connection.close()


class PopulationError(RuntimeError):
    def __init__(self, report: dict[str, Any]):
        self.report = report
        super().__init__(report.get("fatal_error", "population failed"))


def print_report(report: dict[str, Any]) -> None:
    print(json.dumps(report, indent=2, sort_keys=True))


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument(
        "database",
        nargs="?",
        type=Path,
        default=DEFAULT_DATABASE,
        help=f"SQLite database (default: {DEFAULT_DATABASE})",
    )
    return parser.parse_args()


def main() -> int:
    args = parse_args()
    if not args.database.is_file():
        print(f"error: database does not exist: {args.database}", file=sys.stderr)
        return 2
    try:
        report = populate(args.database.resolve())
    except PopulationError as error:
        print_report(error.report)
        return 1
    print_report(report)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
