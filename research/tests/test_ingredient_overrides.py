from __future__ import annotations

import sqlite3
import sys
import unittest
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT / "scripts"))

from calculate_meal_energy import calculate_meal  # noqa: E402


DATABASE = ROOT / "data" / "arcane_odyssey_cooking.sqlite"


class IngredientOverrideTests(unittest.TestCase):
    def test_tuna_uses_verified_contribution_curve(self) -> None:
        cases = [
            (["Tuna"], 40),
            (["Tuna", "Banana"], 43),
            (["Tuna", "Banana", "Brown Mushroom"], 45),
            (["Tuna", "Banana", "Brown Mushroom", "Raw Bird Meat"], 48),
        ]
        for ingredients, expected_tuna_contribution in cases:
            with self.subTest(unique_count=len(ingredients)):
                result = calculate_meal(DATABASE, ingredients, "Balanced Meal", 1)
                tuna = result["contributions"][0]
                self.assertEqual(expected_tuna_contribution, tuna["contribution"])
                self.assertEqual(
                    "verified",
                    tuna["interpolation_override"]["verification_status"],
                )

    def test_massive_colossal_squid_is_warning_not_exclusion(self) -> None:
        connection = sqlite3.connect(DATABASE)
        connection.row_factory = sqlite3.Row
        try:
            warning = connection.execute(
                """
                SELECT w.historical_base_cooked_energy,
                       w.current_verification_status,
                       r.energy_multiplier
                FROM ingredient_modifier_warnings AS w
                JOIN ingredients AS i USING (ingredient_id)
                JOIN ingredient_modifier_rules AS r
                  ON r.ingredient_kind = i.ingredient_kind
                 AND r.modifier_name = w.modifier_name
                WHERE i.name = 'Colossal Squid'
                  AND w.modifier_name = 'Massive'
                """
            ).fetchone()
            self.assertIsNotNone(warning)
            self.assertEqual(560, warning["historical_base_cooked_energy"])
            self.assertEqual("unverified_current", warning["current_verification_status"])
            self.assertEqual(3.0, warning["energy_multiplier"])

            exclusion_count = connection.execute(
                """
                SELECT COUNT(*)
                FROM ingredient_modifier_exclusions AS e
                JOIN ingredients AS i USING (ingredient_id)
                WHERE i.name = 'Colossal Squid'
                  AND e.modifier_name = 'Massive'
                """
            ).fetchone()[0]
            self.assertEqual(0, exclusion_count)
        finally:
            connection.close()

    def test_tuna_override_does_not_replace_full_potential(self) -> None:
        result = calculate_meal(
            DATABASE,
            ["Tuna", "Banana"],
            "Burger",
            1,
        )
        tuna = result["contributions"][0]
        self.assertEqual(48, tuna["contribution"])
        self.assertIsNone(tuna["interpolation_override"])


if __name__ == "__main__":
    unittest.main()
