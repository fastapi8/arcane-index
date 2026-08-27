-- Controlled recipe-resolution observations: batch 5.
PRAGMA foreign_keys = ON;

BEGIN;

INSERT INTO recipe_aliases (recipe_id, alias, alias_kind, notes)
VALUES (
    (SELECT recipe_id FROM recipes WHERE name = 'Fish and Mushroom Stew'),
    'Salmon and Mushroom Stew', 'observed_dynamic_name',
    'Observed when Salmon supplies the fish slot.'
);

UPDATE recipes
SET ingredient_rule_text =
        'Fruit + mushroom (normal or Giant) + fish or meat; exact count limits pending',
    notes = coalesce(notes || ' ', '') ||
        'Observed without an additional normal mushroom using both fish and meat.'
WHERE name = 'Balanced Meal';

UPDATE recipes
SET notes = coalesce(notes || ' ', '') ||
        'Small Shiner and import-derived Big Haddock used the generic display name; Salmon used Salmon and Mushroom Stew. In the tested four-slot combination this stew wins even when Pumpkin is present.'
WHERE name = 'Fish and Mushroom Stew';

UPDATE recipes
SET notes = coalesce(notes || ' ', '') ||
        'In the tested four-slot combination this stew wins even when Pumpkin is present.'
WHERE name = 'Meat and Mushroom Stew';

INSERT INTO recipe_resolution_observations (
    batch_name, test_number, input_description, slot_order_description,
    result_display_name, resolved_recipe_id, notes
)
VALUES
    ('resolution-5', 1,
     'Giant Greencap + Brown Mushroom + Shiner', NULL,
     'Fish and Mushroom Stew',
     (SELECT recipe_id FROM recipes WHERE name = 'Fish and Mushroom Stew'),
     'Small-fish test.'),
    ('resolution-5', 2,
     'Giant Greencap + Brown Mushroom + Salmon', NULL,
     'Salmon and Mushroom Stew',
     (SELECT recipe_id FROM recipes WHERE name = 'Fish and Mushroom Stew'),
     'Species-specific display name for Salmon.'),
    ('resolution-5', 3,
     'Giant Greencap + Brown Mushroom + Haddock', NULL,
     'Fish and Mushroom Stew',
     (SELECT recipe_id FROM recipes WHERE name = 'Fish and Mushroom Stew'),
     'Import-derived Big fish still uses the generic stew display name.'),
    ('resolution-5', 4,
     'Giant Greencap + Shiner + Banana', NULL,
     'Balanced Meal',
     (SELECT recipe_id FROM recipes WHERE name = 'Balanced Meal'),
     'Balanced Meal does not require an additional normal mushroom.'),
    ('resolution-5', 5,
     'Giant Greencap + Raw Bear Meat + Banana', NULL,
     'Balanced Meal',
     (SELECT recipe_id FROM recipes WHERE name = 'Balanced Meal'),
     'Balanced Meal does not require an additional normal mushroom.'),
    ('resolution-5', 6,
     'Giant Greencap + Brown Mushroom + Pumpkin + Shiner', NULL,
     'Fish and Mushroom Stew',
     (SELECT recipe_id FROM recipes WHERE name = 'Fish and Mushroom Stew'),
     'Stew wins over pumpkin-based pie resolution in this overlap.'),
    ('resolution-5', 7,
     'Giant Greencap + Brown Mushroom + Pumpkin + Raw Bear Meat', NULL,
     'Bear and Mushroom Stew',
     (SELECT recipe_id FROM recipes WHERE name = 'Meat and Mushroom Stew'),
     'Meat stew wins over pumpkin-based pie resolution in this overlap.');

COMMIT;
