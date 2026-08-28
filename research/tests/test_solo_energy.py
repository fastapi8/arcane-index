from __future__ import annotations

import math
import sqlite3
import unittest
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
DATABASE = ROOT / "data" / "arcane_odyssey_cooking.sqlite"
MAX_LEVEL_NON_FISH = {
    "Pumpkin",
    "Sky pumpkin",
    "Stratos pumpkin",
    "Wheat",
    "Festive Cookie Dough",
}


class SoloEnergyTests(unittest.TestCase):
    def setUp(self) -> None:
        self.connection = sqlite3.connect(DATABASE)
        self.connection.row_factory = sqlite3.Row

    def tearDown(self) -> None:
        self.connection.close()

    def test_recognized_solo_meals_reverse_max_quality_uniquely(self) -> None:
        rows = self.connection.execute(
            """
            SELECT name, ingredient_kind, solo_energy, imported_solo_energy,
                   raw_energy, cook_multiplier
            FROM ingredients
            WHERE ingredient_kind = 'fish'
               OR name IN (?, ?, ?, ?, ?)
            ORDER BY name
            """,
            tuple(sorted(MAX_LEVEL_NON_FISH)),
        ).fetchall()
        self.assertEqual(91, len(rows))

        for row in rows:
            with self.subTest(ingredient=row["name"]):
                candidates = [
                    value
                    for value in range(row["imported_solo_energy"] + 1)
                    if (value * 3) // 2 == row["imported_solo_energy"]
                ]
                self.assertEqual([row["solo_energy"]], candidates)
                self.assertEqual(
                    math.floor(row["raw_energy"] * row["cook_multiplier"]),
                    row["solo_energy"],
                )

    def test_colossal_squid_is_a_canonical_fish_not_a_modifier(self) -> None:
        canonical = self.connection.execute(
            "SELECT ingredient_kind FROM ingredients WHERE name = 'Colossal Squid'"
        ).fetchone()
        self.assertIsNotNone(canonical)
        self.assertEqual("fish", canonical["ingredient_kind"])
        self.assertIsNone(
            self.connection.execute(
                "SELECT ingredient_id FROM ingredients WHERE name = 'Squid'"
            ).fetchone()
        )
        self.assertEqual(
            0,
            self.connection.execute(
                "SELECT COUNT(*) FROM ingredient_modifier_rules "
                "WHERE modifier_name = 'Colossal'"
            ).fetchone()[0],
        )
        ingredient_id = self.connection.execute(
            "SELECT ingredient_id FROM ingredients WHERE name = 'Colossal Squid'"
        ).fetchone()[0]
        with self.assertRaises(sqlite3.IntegrityError):
            self.connection.execute(
                """
                INSERT INTO ingredient_modifiers (
                    ingredient_id, modifier_name, rarity_delta
                ) VALUES (?, 'Colossal', NULL)
                """,
                (ingredient_id,),
            )
        self.connection.rollback()

    def test_arcane_energy_multiplier_differs_for_fish_and_non_fish(self) -> None:
        rows = self.connection.execute(
            """
            SELECT ingredient_kind, energy_multiplier
            FROM ingredient_modifier_rules
            WHERE modifier_name = 'Arcane'
            ORDER BY ingredient_kind
            """
        ).fetchall()
        self.assertEqual(
            [("fish", 1.5), ("normal", 3.0)],
            [
                (row["ingredient_kind"], row["energy_multiplier"])
                for row in rows
            ],
        )


if __name__ == "__main__":
    unittest.main()
