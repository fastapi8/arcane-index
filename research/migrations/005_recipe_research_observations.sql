PRAGMA foreign_keys = ON;

BEGIN;

CREATE TABLE recipe_aliases (
    recipe_alias_id  INTEGER PRIMARY KEY,
    recipe_id        INTEGER NOT NULL,
    alias            TEXT NOT NULL COLLATE NOCASE,
    alias_kind       TEXT NOT NULL,
    notes            TEXT,

    UNIQUE (alias),
    CHECK (alias_kind IN ('reference_name', 'observed_dynamic_name', 'display_variant')),

    FOREIGN KEY (recipe_id)
        REFERENCES recipes (recipe_id)
        ON UPDATE CASCADE
        ON DELETE CASCADE
) STRICT;

CREATE TABLE recipe_resolution_observations (
    recipe_resolution_observation_id  INTEGER PRIMARY KEY,
    batch_name                        TEXT NOT NULL,
    test_number                       INTEGER NOT NULL,
    input_description                 TEXT NOT NULL,
    slot_order_description            TEXT,
    result_display_name               TEXT NOT NULL,
    resolved_recipe_id                INTEGER,
    final_energy                      INTEGER,
    effects_json                     TEXT,
    notes                            TEXT,
    observed_at                      TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,

    UNIQUE (batch_name, test_number),
    CHECK (test_number >= 1),
    CHECK (final_energy IS NULL OR final_energy >= 0),
    CHECK (effects_json IS NULL OR json_valid(effects_json)),

    FOREIGN KEY (resolved_recipe_id)
        REFERENCES recipes (recipe_id)
        ON UPDATE CASCADE
        ON DELETE SET NULL
) STRICT;

-- Recipe-facing classifications derived from imported single-fish dish names.
-- They are evidence tags, not new canonical ingredient identities.
CREATE TABLE ingredient_recipe_tags (
    ingredient_id       INTEGER NOT NULL,
    tag                  TEXT NOT NULL,
    verification_status TEXT NOT NULL,
    evidence             TEXT NOT NULL,

    PRIMARY KEY (ingredient_id, tag),
    CHECK (verification_status IN ('import_derived', 'experiment_verified')),

    FOREIGN KEY (ingredient_id)
        REFERENCES ingredients (ingredient_id)
        ON UPDATE CASCADE
        ON DELETE CASCADE
) STRICT;

-- The reference called this recipe Bread and Fruit Meal; the controlled result
-- displayed Baguette and Fruit Meal.
UPDATE recipes
SET name = 'Baguette and Fruit Meal',
    resolution_status = 'partially_verified',
    notes = 'Observed display name supersedes the screenshot reference name.'
WHERE name = 'Bread and Fruit Meal';

INSERT INTO recipe_aliases (recipe_id, alias, alias_kind, notes)
VALUES
    ((SELECT recipe_id FROM recipes WHERE name = 'Baguette and Fruit Meal'),
     'Bread and Fruit Meal', 'reference_name',
     'Name shown in the supplied reference screenshot.'),
    ((SELECT recipe_id FROM recipes WHERE name = 'Burgers'),
     'Meat Burgers', 'observed_dynamic_name',
     'Observed with two wheat, one fish, and one meat.');

INSERT INTO recipes (
    name, ingredient_rule_text, energy_model_code, effects_mode,
    resolution_status, source_note, notes
)
VALUES
    ('Meat and Mushroom Pie', '1 pumpkin + 1 meat + 1 mushroom', 'standard',
     'unknown', 'partially_verified', 'Controlled recipe tests, batch 1',
     'Observed display name substitutes the meat species, e.g. Bear and Mushroom Pie.'),
    ('Balanced Meal', 'Fruit + mushroom + fish or meat; exact count limits pending',
     'standard', 'listed', 'partially_verified',
     'Controlled recipe tests plus supplied research notes, batch 1',
     'Known to provide Energizing, Recovery, and Invigorating. No one identity is believed to exceed three slots.' );

INSERT INTO recipe_aliases (recipe_id, alias, alias_kind, notes)
VALUES
    ((SELECT recipe_id FROM recipes WHERE name = 'Meat and Mushroom Pie'),
     'Bear and Mushroom Pie', 'observed_dynamic_name',
     'Observed using Raw Bear Meat.' );

UPDATE recipes
SET ingredient_rule_text =
        'Pumpkin + fruit + mushroom + meat; exact count limits pending',
    effects_mode = 'listed',
    resolution_status = 'partially_verified',
    source_note = 'Controlled recipe tests plus supplied research notes, batch 1',
    notes =
        'Pumpkin distinguishes the pie form. Known to provide Energizing, Recovery, and Invigorating. No one identity is believed to exceed three slots.'
WHERE name = 'Balanced Pie';

WITH balanced_effects (recipe_name, effect_name, display_order) AS (
    VALUES
        ('Balanced Meal', 'Energizing', 1),
        ('Balanced Meal', 'Recovery', 2),
        ('Balanced Meal', 'Invigorating', 3),
        ('Balanced Pie', 'Energizing', 1),
        ('Balanced Pie', 'Recovery', 2),
        ('Balanced Pie', 'Invigorating', 3)
)
INSERT INTO recipe_effects (recipe_id, effect_name, display_order, condition_text)
SELECT recipes.recipe_id, balanced_effects.effect_name,
       balanced_effects.display_order, NULL
FROM balanced_effects
JOIN recipes ON recipes.name = balanced_effects.recipe_name;

INSERT INTO recipe_resolution_observations (
    batch_name, test_number, input_description, slot_order_description,
    result_display_name, resolved_recipe_id, notes
)
VALUES
    ('balanced-and-priority-1', 1,
     'Pumpkin + Brown Mushroom + Raw Bear Meat',
     'Pumpkin, Brown Mushroom, Raw Bear Meat', 'Bear and Mushroom Pie',
     (SELECT recipe_id FROM recipes WHERE name = 'Meat and Mushroom Pie'), NULL),
    ('balanced-and-priority-1', 2,
     'Pumpkin + Brown Mushroom + Raw Bear Meat',
     'Raw Bear Meat, Pumpkin, Brown Mushroom', 'Bear and Mushroom Pie',
     (SELECT recipe_id FROM recipes WHERE name = 'Meat and Mushroom Pie'),
     'Same result under the tested slot-order permutation.'),
    ('balanced-and-priority-1', 3,
     'Pumpkin + Brown Mushroom + Raw Bear Meat + Banana', NULL,
     'Balanced Pie',
     (SELECT recipe_id FROM recipes WHERE name = 'Balanced Pie'), NULL),
    ('balanced-and-priority-1', 4,
     'Banana + Brown Mushroom + Raw Bear Meat + Banana', NULL,
     'Balanced Meal',
     (SELECT recipe_id FROM recipes WHERE name = 'Balanced Meal'), NULL),
    ('balanced-and-priority-1', 5,
     'Banana + Brown Mushroom + Raw Bear Meat + Green Apple', NULL,
     'Balanced Meal',
     (SELECT recipe_id FROM recipes WHERE name = 'Balanced Meal'), NULL),
    ('balanced-and-priority-1', 6,
     'Banana + Brown Mushroom + any fish (specific species not recorded)', NULL,
     'Balanced Meal',
     (SELECT recipe_id FROM recipes WHERE name = 'Balanced Meal'), NULL),
    ('balanced-and-priority-1', 8,
     '2 Pumpkins + 2 Brown Mushrooms', NULL,
     'Giant Mushroom Pie',
     (SELECT recipe_id FROM recipes WHERE name = 'Giant Mushroom Pie'),
     'Giant Mushroom Pie wins over Giant Pumpkin Pie for this overlap.'),
    ('balanced-and-priority-1', 9,
     'Wheat + Banana + Green Apple + Mango', NULL,
     'Baguette and Fruit Meal',
     (SELECT recipe_id FROM recipes WHERE name = 'Baguette and Fruit Meal'),
     'Baguette and Fruit Meal wins over Hoagie for this overlap.'),
    ('balanced-and-priority-1', 10,
     '2 Wheat + any fish (specific species not recorded) + Raw Bear Meat', NULL,
     'Meat Burgers',
     (SELECT recipe_id FROM recipes WHERE name = 'Burgers'),
     'Species-specific display variant of the Burgers family.');

INSERT INTO ingredient_recipe_tags (
    ingredient_id, tag, verification_status, evidence
)
SELECT ingredient_id, 'small_fish', 'import_derived',
       'Imported solo dish type is Fish Patty.'
FROM ingredients
WHERE ingredient_kind = 'fish'
  AND solo_dish_type = 'Fish Patty';

INSERT INTO ingredient_recipe_tags (
    ingredient_id, tag, verification_status, evidence
)
SELECT ingredient_id, 'big_fish', 'import_derived',
       'Imported solo dish type begins with Grilled Giant.'
FROM ingredients
WHERE ingredient_kind = 'fish'
  AND solo_dish_type LIKE 'Grilled Giant%';

COMMIT;
