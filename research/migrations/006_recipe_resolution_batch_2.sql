-- Controlled recipe-resolution observations: batch 2.
PRAGMA foreign_keys = ON;

BEGIN;

CREATE TABLE cooking_invalidity_rules (
    cooking_invalidity_rule_id  INTEGER PRIMARY KEY,
    rule_code                   TEXT NOT NULL,
    condition_json              TEXT NOT NULL,
    verification_status         TEXT NOT NULL,
    notes                       TEXT NOT NULL,

    UNIQUE (rule_code),
    CHECK (json_valid(condition_json)),
    CHECK (verification_status IN ('hypothesis', 'partially_verified', 'verified'))
) STRICT;

INSERT INTO ingredient_recipe_tags (
    ingredient_id, tag, verification_status, evidence
)
VALUES
    ((SELECT ingredient_id FROM ingredients WHERE name = 'Giant greencap'),
     'giant_mushroom', 'experiment_verified',
     'Used in controlled invalid mushroom combinations.'),
    ((SELECT ingredient_id FROM ingredients WHERE name = 'Giant purplecap'),
     'giant_mushroom', 'import_derived',
     'Canonical Giant mushroom identity; family behavior inferred from tested peers.'),
    ((SELECT ingredient_id FROM ingredients WHERE name = 'Giant redcap'),
     'giant_mushroom', 'experiment_verified',
     'Used in controlled invalid mushroom combinations.'),
    ((SELECT ingredient_id FROM ingredients WHERE name = 'Giant seacap'),
     'giant_mushroom', 'import_derived',
     'Canonical Giant mushroom identity; family behavior inferred from tested peers.');

INSERT INTO cooking_invalidity_rules (
    rule_code, condition_json, verification_status, notes
)
VALUES (
    'multiple_mushrooms_with_giant_mushroom',
    '{"all":[{"tag":"giant_mushroom","min_count":1},{"category":"mushroom","min_count":2}],"tested_total_slot_counts":[2]}',
    'partially_verified',
    'A Giant Greencap plus Brown Mushroom and a Giant Greencap plus Giant Redcap were both invalid. Three- and four-slot scope remains untested.'
);

INSERT INTO recipe_resolution_observations (
    batch_name, test_number, input_description, slot_order_description,
    result_display_name, resolved_recipe_id, notes
)
VALUES
    ('resolution-2', 1, 'Giant Greencap + Brown Mushroom', NULL,
     'Invalid', NULL, 'Mixed Giant and normal mushroom pair did not cook.'),
    ('resolution-2', 2, 'Giant Greencap + Giant Redcap', NULL,
     'Invalid', NULL, 'Two different Giant mushroom identities did not cook.'),
    ('resolution-2', 3, 'Brown Mushroom + White Mushroom', NULL,
     'Mushroom Stew',
     (SELECT recipe_id FROM recipes WHERE name = 'Mushroom Stew'),
     'Normal-mushroom control cooked successfully.'),
    ('resolution-2', 4, 'Pumpkin + Brown Mushroom + Neon Tetra', NULL,
     'Fish and Mushroom Pie',
     (SELECT recipe_id FROM recipes WHERE name = 'Fish and Mushroom Pie'), NULL),
    ('resolution-2', 5, 'Pumpkin + Pumpkin + Banana + Green Apple', NULL,
     'Giant Fruit Pie',
     (SELECT recipe_id FROM recipes WHERE name = 'Giant Fruit Pie'),
     'Giant Fruit Pie wins over Giant Pumpkin Pie for this overlap.'),
    ('resolution-2', 6, 'Pumpkin + Pumpkin + Neon Tetra + Shiner', NULL,
     'Giant Fish Pie',
     (SELECT recipe_id FROM recipes WHERE name = 'Giant Fish Pie'),
     'Giant Fish Pie wins over Giant Pumpkin Pie for this overlap.'),
    ('resolution-2', 7, 'Banana + Green Apple + Mango + Wheat',
     'Banana, Green Apple, Mango, Wheat',
     'Baguette and Fruit Meal',
     (SELECT recipe_id FROM recipes WHERE name = 'Baguette and Fruit Meal'),
     'Matches the prior result with Wheat moved from first to last.');

UPDATE recipes
SET resolution_status = 'partially_verified',
    notes = coalesce(notes || ' ', '') ||
        'Observed to win over Giant Pumpkin Pie with two pumpkins and two matching-category ingredients.'
WHERE name IN ('Giant Fruit Pie', 'Giant Fish Pie');

UPDATE recipes
SET resolution_status = 'partially_verified'
WHERE name IN ('Mushroom Stew', 'Fish and Mushroom Pie');

UPDATE recipes
SET notes = coalesce(notes || ' ', '') ||
        'A second test with Wheat moved from first to last produced the same recipe.'
WHERE name = 'Baguette and Fruit Meal';

COMMIT;
