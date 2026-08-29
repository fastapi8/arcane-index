PRAGMA foreign_keys = ON;

BEGIN;

-- Later tests show that mixed Giant/normal mushrooms can cook when another
-- category supplies a valid recipe. The invalidity is therefore scoped to the
-- exact two-slot mushroom-only case.
UPDATE cooking_invalidity_rules
SET condition_json =
        '{"exact_total_slots":2,"all":[{"tag":"giant_mushroom","min_count":1},{"category":"mushroom","count":2}]}',
    verification_status = 'verified',
    notes =
        'Verified for two mushrooms when at least one is a canonical Giant mushroom. Tested with Giant Greencap + Brown Mushroom, Giant Greencap + Giant Redcap, Giant Purplecap + Brown Mushroom, and Giant Seacap + White Mushroom. Additional fruit or balanced-meal ingredients can produce a valid recipe.'
WHERE rule_code = 'multiple_mushrooms_with_giant_mushroom';

INSERT INTO recipes (
    name, ingredient_rule_text, energy_model_code, effects_mode,
    resolution_status, source_note, notes
)
VALUES (
    'Giant Fruit and Mushroom Meal',
    'Giant mushroom + normal mushroom + fruit; exact count variants pending',
    'standard', 'unknown', 'partially_verified',
    'Controlled recipe tests, batch 3',
    'Observed with Giant Greencap, Brown Mushroom, and Banana.'
);

INSERT INTO recipe_resolution_observations (
    batch_name, test_number, input_description, slot_order_description,
    result_display_name, resolved_recipe_id, notes
)
VALUES
    ('resolution-3', 1,
     'Giant Greencap + Brown Mushroom + Banana', NULL,
     'Giant Fruit and Mushroom Meal',
     (SELECT recipe_id FROM recipes WHERE name = 'Giant Fruit and Mushroom Meal'),
     'Shows that mixed Giant and normal mushrooms are not universally invalid.'),
    ('resolution-3', 2,
     'Giant Greencap + Brown Mushroom + Banana + Raw Bear Meat', NULL,
     'Balanced Meal',
     (SELECT recipe_id FROM recipes WHERE name = 'Balanced Meal'),
     'Balanced Meal wins when fruit, mushroom, and recovery categories are present.'),
    ('resolution-3', 3,
     'Giant Purplecap + Brown Mushroom', NULL,
     'Invalid', NULL,
     'Confirms the two-slot Giant-plus-normal mushroom invalidity across another Giant identity.'),
    ('resolution-3', 4,
     'Giant Seacap + White Mushroom', NULL,
     'Invalid', NULL,
     'Confirms the two-slot Giant-plus-normal mushroom invalidity across another Giant identity.'),
    ('resolution-3', 5,
     'Pumpkin + Pumpkin + Raw Bear Meat + Raw Deer Meat', NULL,
     'Giant Meat Pie',
     (SELECT recipe_id FROM recipes WHERE name = 'Giant Meat Pie'),
     'Giant Meat Pie wins over Giant Pumpkin Pie.'),
    ('resolution-3', 6,
     'Pumpkin + Pumpkin + Pumpkin + Brown Mushroom', NULL,
     'Giant Mushroom Pie',
     (SELECT recipe_id FROM recipes WHERE name = 'Giant Mushroom Pie'),
     'Giant Mushroom Pie wins over Giant Pumpkin Pie with three pumpkins and one mushroom.'),
    ('resolution-3', 7,
     'Pumpkin + Pumpkin + Pumpkin + Banana', NULL,
     'Giant Fruit Pie',
     (SELECT recipe_id FROM recipes WHERE name = 'Giant Fruit Pie'),
     'Giant Fruit Pie wins over Giant Pumpkin Pie with three pumpkins and one fruit.');

UPDATE recipes
SET resolution_status = 'partially_verified',
    notes = coalesce(notes || ' ', '') ||
        'Observed to win over Giant Pumpkin Pie in controlled batch 3.'
WHERE name IN ('Giant Meat Pie', 'Giant Mushroom Pie', 'Giant Fruit Pie');

COMMIT;
