from __future__ import annotations

import sys
import unittest
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT / "scripts"))

from calculate_meal_energy import calculate_meal  # noqa: E402


DATABASE = ROOT / "data" / "arcane_odyssey_cooking.sqlite"


class MealEnergyFormulaTests(unittest.TestCase):
    def test_all_balanced_meal_measurements(self) -> None:
        measured = [
            (["Banana", "Brown Mushroom", "Raw Bird Meat"], 57),
            (["Lime", "Blue Mushroom", "Raw Bird Meat"], 61),
            (["Banana", "Brown Mushroom", "Oscar"], 66),
            (["Lime", "Blue Mushroom", "Oscar"], 69),
            (["Sky Grapefruit", "Omprela Mushroom", "Chain Pickerel"], 108),
            (["Banana", "Brown Mushroom", "Raw Bird Meat", "Banana"], 77),
            (["Banana", "Brown Mushroom", "Raw Bird Meat", "Green Apple"], 89),
        ]
        for ingredients, expected in measured:
            with self.subTest(ingredients=ingredients):
                result = calculate_meal(DATABASE, ingredients, "Balanced Meal", 8)
                self.assertEqual(expected, result["final_energy"])

    def test_slot_five_contributes_but_does_not_increase_variety(self) -> None:
        result = calculate_meal(
            DATABASE,
            ["Banana", "Brown Mushroom", "Raw Bird Meat", "Banana", "Green Apple"],
            "Balanced Meal",
            9,
        )
        self.assertEqual(3, result["unique_ingredient_count_slots_1_to_4"])
        self.assertEqual("11/10", result["variety_multiplier"])
        self.assertFalse(result["contributions"][4]["counts_toward_unique_count"])

    def test_verified_binary64_boundary_floors_to_114(self) -> None:
        result = calculate_meal(
            DATABASE,
            ["Brown Mushroom", "Green Apple", "Raw Bear Meat", "Raw Bird Meat"],
            "Balanced Meal",
            1,
        )
        self.assertEqual(100, result["contribution_sum"])
        self.assertEqual("115", result["pre_floor_final_exact"])
        self.assertLess(result["pre_floor_final_binary64"], 115)
        self.assertEqual(114, result["final_energy"])


if __name__ == "__main__":
    unittest.main()
