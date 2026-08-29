from __future__ import annotations

import sqlite3
import unittest
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
DATABASE = ROOT / "data" / "arcane_odyssey_cooking.sqlite"


class SimmeredFruitResultTests(unittest.TestCase):
    def setUp(self) -> None:
        self.connection = sqlite3.connect(DATABASE)
        self.connection.row_factory = sqlite3.Row

    def tearDown(self) -> None:
        self.connection.close()

    def test_exact_fruit_catalog_excludes_pumpkins(self) -> None:
        fruits = self.connection.execute(
            """
            SELECT i.name
            FROM ingredients AS i
            JOIN ingredient_recipe_tags AS tags USING (ingredient_id)
            WHERE tags.tag = 'fruit'
            ORDER BY i.name
            """
        ).fetchall()
        self.assertEqual(31, len(fruits))
        self.assertFalse(any("pumpkin" in row["name"].casefold() for row in fruits))
        self.assertEqual(
            ["Pumpkin", "Sky pumpkin", "Stratos pumpkin"],
            [
                row["name"]
                for row in self.connection.execute(
                    """
                    SELECT i.name
                    FROM ingredients AS i
                    JOIN ingredient_recipe_tags AS tags USING (ingredient_id)
                    WHERE tags.tag = 'pumpkin'
                    ORDER BY i.ingredient_id
                    """
                )
            ],
        )

    def test_distribution_represents_every_allowed_named_loadout(self) -> None:
        summary = self.connection.execute(
            """
            SELECT count(*) AS aggregate_rows,
                   sum(represented_meal_count) AS represented_meals,
                   min(final_energy) AS minimum_energy,
                   max(final_energy) AS maximum_energy
            FROM simmered_fruit_results
            """
        ).fetchone()
        self.assertEqual(183_250, summary["aggregate_rows"])
        self.assertEqual(128_905_440, summary["represented_meals"])
        self.assertEqual(9, summary["minimum_energy"])
        self.assertEqual(516, summary["maximum_energy"])

    def test_only_multi_fruit_max_level_results_are_stored(self) -> None:
        invalid = self.connection.execute(
            """
            SELECT count(*)
            FROM simmered_fruit_results
            WHERE cooking_level <> 10
               OR fruit_count < 2
               OR general_ingredient_count < 2
               OR general_ingredient_count > 5
               OR fruit_count + general_seasoning_count <> general_ingredient_count
            """
        ).fetchone()[0]
        self.assertEqual(0, invalid)

    def test_dedicated_seasoning_slot_multiplies_named_loadouts_by_fourteen(self) -> None:
        counts = {
            row["dedicated_seasoning_present"]: row["meal_count"]
            for row in self.connection.execute(
                """
                SELECT dedicated_seasoning_present,
                       sum(represented_meal_count) AS meal_count
                FROM simmered_fruit_results
                GROUP BY dedicated_seasoning_present
                """
            )
        }
        self.assertEqual(counts[0] * 14, counts[1])

    def test_fifth_slot_is_kept_mechanically_distinct(self) -> None:
        rows = self.connection.execute(
            """
            SELECT slot_five_kind, sum(represented_meal_count) AS meal_count
            FROM simmered_fruit_results
            GROUP BY slot_five_kind
            """
        ).fetchall()
        self.assertEqual({"empty", "fruit", "seasoning"}, {row[0] for row in rows})
        self.assertTrue(all(row["meal_count"] > 0 for row in rows))


if __name__ == "__main__":
    unittest.main()
