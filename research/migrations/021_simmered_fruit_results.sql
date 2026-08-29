-- Machine-readable Simmered Fruit resolution and materialized max-level results.
PRAGMA foreign_keys = ON;

BEGIN;

INSERT INTO recipes (
    name, ingredient_rule_text, energy_model_code, effects_mode,
    resolution_status, source_note, notes
)
VALUES (
    'Simmered Fruit',
    'At least 2 fruits; excludes pumpkins. Remaining general slots and the optional dedicated seasoning slot may contain seasonings.',
    'standard',
    'conditional',
    'partially_verified',
    'User-supplied resolution rule, 2026-08-29',
    'Generated results use base ingredients without Arcane variants at cooking level 10. Slots 1-4 are mechanically interchangeable; slot 5 and the dedicated seasoning slot remain distinct.'
);

CREATE TABLE recipe_resolution_rules (
    recipe_id            INTEGER PRIMARY KEY,
    condition_json       TEXT NOT NULL,
    verification_status  TEXT NOT NULL,
    notes                TEXT,

    CHECK (json_valid(condition_json)),
    CHECK (verification_status IN ('reported', 'partially_verified', 'verified')),

    FOREIGN KEY (recipe_id)
        REFERENCES recipes (recipe_id)
        ON UPDATE CASCADE
        ON DELETE CASCADE
) STRICT;

INSERT INTO recipe_resolution_rules (
    recipe_id, condition_json, verification_status, notes
)
VALUES (
    (SELECT recipe_id FROM recipes WHERE name = 'Simmered Fruit'),
    '{"allowed_categories":["fruit","seasoning"],"fruit":{"min_count":2},"excluded_tags":["pumpkin"],"max_general_slots":5,"dedicated_seasoning_slot":{"optional":true,"max_count":1}}',
    'reported',
    'A fifth general ingredient is mechanically distinct from the first four. The dedicated seasoning slot is outside the five general slots.'
);

-- Fruit membership is explicit so later generators do not depend on display-name
-- conventions. Pumpkin identities are deliberately absent.
INSERT INTO ingredient_recipe_tags (
    ingredient_id, tag, verification_status, evidence
)
SELECT ingredient_id, 'fruit', 'import_derived',
       'Imported solo dish type begins with Cooked; explicitly reviewed for Simmered Fruit generation.'
FROM ingredients
WHERE name IN (
    'Banana', 'Coconut', 'Giant banana', 'Giant lemon', 'Giant orange',
    'Giant red apple', 'Giant sky apple', 'Giant stratos apple', 'Grapes',
    'Green apple', 'Lime', 'Mango', 'Marula', 'Orange', 'Peach',
    'Prickly pear', 'Red apple', 'Sky apple', 'Sky grapefruit', 'Sky grapes',
    'Sky lemon', 'Sky pear', 'Sky watermelon', 'Stormfruit', 'Stratos apple',
    'Stratos grapefruit', 'Stratos lemon', 'Stratos pear',
    'Stratos watermelon', 'Tomato', 'Watermelon'
);

INSERT INTO ingredient_recipe_tags (
    ingredient_id, tag, verification_status, evidence
)
SELECT ingredient_id, 'pumpkin', 'import_derived',
       'Imported solo dish type is Pumpkin Pie; excluded from Simmered Fruit.'
FROM ingredients
WHERE name IN ('Pumpkin', 'Sky pumpkin', 'Stratos pumpkin');

-- One row is an aggregate of mechanically equivalent named loadouts. The
-- represented count retains the exact number of concrete ingredient choices.
CREATE TABLE simmered_fruit_results (
    simmered_fruit_result_id       INTEGER PRIMARY KEY,
    recipe_id                       INTEGER NOT NULL,
    cooking_level                   INTEGER NOT NULL,
    general_ingredient_count        INTEGER NOT NULL,
    fruit_count                     INTEGER NOT NULL,
    general_seasoning_count         INTEGER NOT NULL,
    first_four_unique_count         INTEGER NOT NULL,
    slot_five_kind                  TEXT NOT NULL,
    dedicated_seasoning_present     INTEGER NOT NULL,
    raw_energy_sum                  INTEGER NOT NULL,
    contribution_sum                INTEGER NOT NULL,
    final_energy                    INTEGER NOT NULL,
    represented_meal_count          INTEGER NOT NULL,

    CHECK (cooking_level = 10),
    CHECK (general_ingredient_count BETWEEN 2 AND 5),
    CHECK (fruit_count BETWEEN 2 AND 5),
    CHECK (general_seasoning_count BETWEEN 0 AND 3),
    CHECK (fruit_count + general_seasoning_count = general_ingredient_count),
    CHECK (first_four_unique_count BETWEEN 1 AND 4),
    CHECK (slot_five_kind IN ('empty', 'fruit', 'seasoning')),
    CHECK (
        (general_ingredient_count < 5 AND slot_five_kind = 'empty')
        OR (general_ingredient_count = 5 AND slot_five_kind <> 'empty')
    ),
    CHECK (dedicated_seasoning_present IN (0, 1)),
    CHECK (raw_energy_sum >= 0),
    CHECK (contribution_sum >= 0),
    CHECK (final_energy >= 0),
    CHECK (represented_meal_count > 0),

    UNIQUE (
        recipe_id, cooking_level, general_ingredient_count, fruit_count,
        general_seasoning_count, first_four_unique_count, slot_five_kind,
        dedicated_seasoning_present, raw_energy_sum, contribution_sum,
        final_energy
    ),

    FOREIGN KEY (recipe_id)
        REFERENCES recipes (recipe_id)
        ON UPDATE CASCADE
        ON DELETE CASCADE,
    FOREIGN KEY (cooking_level)
        REFERENCES cooking_level_mechanics (cooking_level)
        ON UPDATE CASCADE
        ON DELETE RESTRICT
) STRICT;

CREATE INDEX idx_simmered_fruit_results_plot
    ON simmered_fruit_results (general_ingredient_count, raw_energy_sum, final_energy);

COMMIT;
