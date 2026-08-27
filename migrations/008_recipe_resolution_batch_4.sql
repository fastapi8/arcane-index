-- Controlled recipe-resolution observations: batch 4.
PRAGMA foreign_keys = ON;

BEGIN;

UPDATE recipes
SET ingredient_rule_text =
        'Giant mushroom + fruit; may include an additional normal mushroom',
    notes = coalesce(notes || ' ', '') ||
        'Observed both with and without an additional normal mushroom.'
WHERE name = 'Giant Fruit and Mushroom Meal';

INSERT INTO recipes (
    name, ingredient_rule_text, energy_model_code, effects_mode,
    resolution_status, source_note, notes
)
VALUES
    ('Fish and Mushroom Stew',
     'Giant mushroom + normal mushroom + fish; exact variants pending',
     'standard', 'unknown', 'partially_verified',
     'Controlled recipe tests, batch 4',
     'Still resolved when fruit was added in the tested four-slot combination.'),
    ('Meat and Mushroom Stew',
     'Giant mushroom + normal mushroom + meat; exact variants pending',
     'standard', 'unknown', 'partially_verified',
     'Controlled recipe tests, batch 4',
     'Observed display name substitutes the meat species.'),
    ('Giant Fruit and Mushroom Pie',
     'Pumpkin + Giant mushroom + normal mushroom + fruit',
     'standard', 'unknown', 'partially_verified',
     'Controlled recipe tests, batch 4', NULL);

INSERT INTO recipe_aliases (recipe_id, alias, alias_kind, notes)
VALUES (
    (SELECT recipe_id FROM recipes WHERE name = 'Meat and Mushroom Stew'),
    'Bear and Mushroom Stew', 'observed_dynamic_name',
    'Observed using Raw Bear Meat.'
);

INSERT INTO recipe_resolution_observations (
    batch_name, test_number, input_description, slot_order_description,
    result_display_name, resolved_recipe_id, notes
)
VALUES
    ('resolution-4', 1,
     'Giant Greencap + Banana', NULL,
     'Giant Fruit and Mushroom Meal',
     (SELECT recipe_id FROM recipes WHERE name = 'Giant Fruit and Mushroom Meal'),
     'Shows that an additional normal mushroom is not required.'),
    ('resolution-4', 2,
     'Giant Greencap + Brown Mushroom + Green Apple', NULL,
     'Giant Fruit and Mushroom Meal',
     (SELECT recipe_id FROM recipes WHERE name = 'Giant Fruit and Mushroom Meal'), NULL),
    ('resolution-4', 3,
     'Giant Greencap + Brown Mushroom + fish (specific species not recorded)', NULL,
     'Fish and Mushroom Stew',
     (SELECT recipe_id FROM recipes WHERE name = 'Fish and Mushroom Stew'), NULL),
    ('resolution-4', 4,
     'Giant Greencap + Brown Mushroom + Raw Bear Meat', NULL,
     'Bear and Mushroom Stew',
     (SELECT recipe_id FROM recipes WHERE name = 'Meat and Mushroom Stew'), NULL),
    ('resolution-4', 5,
     'Giant Greencap + Brown Mushroom + Pumpkin', NULL,
     'Giant Mushroom Pie',
     (SELECT recipe_id FROM recipes WHERE name = 'Giant Mushroom Pie'),
     'Giant Mushroom Pie wins over the Giant fruit/mushroom meal family when pumpkin is used.'),
    ('resolution-4', 6,
     'Giant Greencap + Brown Mushroom + fish (specific species not recorded) + Banana', NULL,
     'Fish and Mushroom Stew',
     (SELECT recipe_id FROM recipes WHERE name = 'Fish and Mushroom Stew'),
     'Fish and Mushroom Stew wins over Balanced Meal in this four-slot overlap.'),
    ('resolution-4', 7,
     'Giant Greencap + Brown Mushroom + Pumpkin + Banana', NULL,
     'Giant Fruit and Mushroom Pie',
     (SELECT recipe_id FROM recipes WHERE name = 'Giant Fruit and Mushroom Pie'), NULL);

COMMIT;
