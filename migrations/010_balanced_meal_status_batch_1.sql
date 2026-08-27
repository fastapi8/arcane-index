-- Controlled Balanced Meal energy and status-tier observations: status batch 1.
PRAGMA foreign_keys = ON;

BEGIN;

CREATE TABLE recipe_observation_effects (
    recipe_resolution_observation_id  INTEGER NOT NULL,
    effect_name                       TEXT NOT NULL COLLATE NOCASE,
    tier                              INTEGER NOT NULL,
    duration_seconds                  REAL,

    PRIMARY KEY (recipe_resolution_observation_id, effect_name),
    CHECK (tier >= 1),
    CHECK (duration_seconds IS NULL OR duration_seconds >= 0),

    FOREIGN KEY (recipe_resolution_observation_id)
        REFERENCES recipe_resolution_observations
            (recipe_resolution_observation_id)
        ON UPDATE CASCADE
        ON DELETE CASCADE
) STRICT;

INSERT INTO recipe_resolution_observations (
    batch_name, test_number, input_description, slot_order_description,
    result_display_name, resolved_recipe_id, final_energy, effects_json, notes
)
VALUES
    ('status-1', 1, 'Banana + Brown Mushroom + Raw Bird Meat', NULL,
     'Balanced Meal', (SELECT recipe_id FROM recipes WHERE name = 'Balanced Meal'),
     57, '[{"name":"Recovery","tier":1},{"name":"Energizing","tier":1},{"name":"Invigorating","tier":1}]', NULL),
    ('status-1', 2, 'Lime + Blue Mushroom + Raw Bird Meat', NULL,
     'Balanced Meal', (SELECT recipe_id FROM recipes WHERE name = 'Balanced Meal'),
     61, '[{"name":"Recovery","tier":1},{"name":"Energizing","tier":2},{"name":"Invigorating","tier":2}]', NULL),
    ('status-1', 3, 'Banana + Brown Mushroom + Oscar', NULL,
     'Balanced Meal', (SELECT recipe_id FROM recipes WHERE name = 'Balanced Meal'),
     66, '[{"name":"Recovery","tier":2},{"name":"Energizing","tier":1},{"name":"Invigorating","tier":1}]', NULL),
    ('status-1', 4, 'Lime + Blue Mushroom + Oscar', NULL,
     'Balanced Meal', (SELECT recipe_id FROM recipes WHERE name = 'Balanced Meal'),
     69, '[{"name":"Recovery","tier":2},{"name":"Energizing","tier":2},{"name":"Invigorating","tier":2}]', NULL),
    ('status-1', 5, 'Sky Grapefruit + Omprela Mushroom + Chain Pickerel', NULL,
     'Balanced Meal', (SELECT recipe_id FROM recipes WHERE name = 'Balanced Meal'),
     108, '[{"name":"Recovery","tier":3},{"name":"Energizing","tier":3},{"name":"Invigorating","tier":3}]', NULL),
    ('status-1', 6, 'Banana + Brown Mushroom + Raw Bird Meat + Banana', NULL,
     'Balanced Meal', (SELECT recipe_id FROM recipes WHERE name = 'Balanced Meal'),
     77, '[{"name":"Recovery","tier":1},{"name":"Energizing","tier":1},{"name":"Invigorating","tier":1}]',
     'Duplicate Banana did not increase Invigorating tier.'),
    ('status-1', 7, 'Banana + Brown Mushroom + Raw Bird Meat + Green Apple', NULL,
     'Balanced Meal', (SELECT recipe_id FROM recipes WHERE name = 'Balanced Meal'),
     89, '[{"name":"Recovery","tier":1},{"name":"Energizing","tier":1},{"name":"Invigorating","tier":1}]',
     'A distinct common fruit identity did not increase Invigorating tier.');

WITH effect_data (test_number, effect_name, tier) AS (
    VALUES
        (1, 'Recovery', 1), (1, 'Energizing', 1), (1, 'Invigorating', 1),
        (2, 'Recovery', 1), (2, 'Energizing', 2), (2, 'Invigorating', 2),
        (3, 'Recovery', 2), (3, 'Energizing', 1), (3, 'Invigorating', 1),
        (4, 'Recovery', 2), (4, 'Energizing', 2), (4, 'Invigorating', 2),
        (5, 'Recovery', 3), (5, 'Energizing', 3), (5, 'Invigorating', 3),
        (6, 'Recovery', 1), (6, 'Energizing', 1), (6, 'Invigorating', 1),
        (7, 'Recovery', 1), (7, 'Energizing', 1), (7, 'Invigorating', 1)
)
INSERT INTO recipe_observation_effects (
    recipe_resolution_observation_id, effect_name, tier, duration_seconds
)
SELECT observations.recipe_resolution_observation_id,
       effect_data.effect_name, effect_data.tier, NULL
FROM effect_data
JOIN recipe_resolution_observations AS observations
  ON observations.batch_name = 'status-1'
 AND observations.test_number = effect_data.test_number;

UPDATE recipes
SET notes = coalesce(notes || ' ', '') ||
        'Status batch 1 matched each contributing ingredient tier independently from tiers I through III. Duplicate and distinct common fruit additions did not raise Invigorating above I.'
WHERE name = 'Balanced Meal';

COMMIT;
