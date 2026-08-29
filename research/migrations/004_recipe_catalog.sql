-- Recipe catalog transcribed from the supplied in-game research reference.
-- Resolution text is preserved verbatim; precedence remains unverified and is
-- intentionally not inferred from the order of the reference table.
PRAGMA foreign_keys = ON;

BEGIN;

CREATE TABLE recipe_energy_models (
    energy_model_code  TEXT PRIMARY KEY,
    calculation_mode   TEXT NOT NULL,
    recipe_multiplier  REAL NOT NULL DEFAULT 1.0,
    minimum_energy     INTEGER,
    fixed_energy       INTEGER,
    description        TEXT NOT NULL,

    CHECK (
        calculation_mode IN
            ('standard_interpolation_variety', 'full_potential', 'fixed')
    ),
    CHECK (recipe_multiplier > 0),
    CHECK (minimum_energy IS NULL OR minimum_energy >= 0),
    CHECK (fixed_energy IS NULL OR fixed_energy >= 0),
    CHECK (
        (calculation_mode = 'fixed' AND fixed_energy IS NOT NULL)
        OR (calculation_mode <> 'fixed' AND fixed_energy IS NULL)
    )
) STRICT;

CREATE TABLE recipes (
    recipe_id              INTEGER PRIMARY KEY,
    name                   TEXT NOT NULL COLLATE NOCASE,
    ingredient_rule_text   TEXT,
    energy_model_code      TEXT NOT NULL,
    effects_mode           TEXT NOT NULL DEFAULT 'listed',
    resolution_status      TEXT NOT NULL DEFAULT 'reference',
    source_note            TEXT NOT NULL,
    notes                  TEXT,

    UNIQUE (name),
    CHECK (effects_mode IN ('listed', 'conditional', 'none', 'unknown')),
    CHECK (
        resolution_status IN
            ('reference', 'partially_verified', 'verified', 'unverified')
    ),

    FOREIGN KEY (energy_model_code)
        REFERENCES recipe_energy_models (energy_model_code)
        ON UPDATE CASCADE
        ON DELETE RESTRICT
) STRICT;

CREATE TABLE recipe_effects (
    recipe_id       INTEGER NOT NULL,
    effect_name     TEXT NOT NULL COLLATE NOCASE,
    display_order   INTEGER NOT NULL,
    condition_text  TEXT,

    PRIMARY KEY (recipe_id, effect_name),
    UNIQUE (recipe_id, display_order),
    CHECK (display_order >= 1),

    FOREIGN KEY (recipe_id)
        REFERENCES recipes (recipe_id)
        ON UPDATE CASCADE
        ON DELETE CASCADE
) STRICT;

CREATE TABLE recipe_resolution_exceptions (
    recipe_resolution_exception_id  INTEGER PRIMARY KEY,
    recipe_id                       INTEGER NOT NULL,
    condition_type                  TEXT NOT NULL,
    condition_json                  TEXT NOT NULL,
    verification_status             TEXT NOT NULL,
    notes                           TEXT,

    CHECK (json_valid(condition_json)),
    CHECK (verification_status IN ('reported', 'verified', 'unverified')),

    FOREIGN KEY (recipe_id)
        REFERENCES recipes (recipe_id)
        ON UPDATE CASCADE
        ON DELETE CASCADE
) STRICT;

INSERT INTO recipe_energy_models (
    energy_model_code,
    calculation_mode,
    recipe_multiplier,
    minimum_energy,
    fixed_energy,
    description
)
VALUES
    ('standard', 'standard_interpolation_variety', 1.0, NULL, NULL,
     'Standard interpolation plus ingredient-variety formula.'),
    ('full_potential', 'full_potential', 1.0, NULL, NULL,
     'Forces every ingredient to contribute its full potential.'),
    ('full_potential_2_25x', 'full_potential', 2.25, NULL, NULL,
     'Forces full potential, then applies a 2.25x recipe multiplier.'),
    ('smoothie', 'standard_interpolation_variety', 1.5, 5, NULL,
     'Uses the standard formula, then a 1.5x recipe multiplier; minimum 5.'),
    ('fixed_5', 'fixed', 1.0, NULL, 5,
     'Always resolves to exactly 5 energy.');

INSERT INTO recipes (
    name, ingredient_rule_text, energy_model_code, effects_mode,
    resolution_status, source_note, notes
)
VALUES
    ('Mushroom Meal', 'Mushroom(s) + fish or fruit + herbs', 'standard',
     'listed', 'reference', 'Supplied recipe-table screenshot, 2026-08-27', NULL),
    ('Mushroom Pie', '1 pumpkin + 3 of any mushroom', 'standard',
     'listed', 'reference', 'Supplied recipe-table screenshot, 2026-08-27', NULL),
    ('Giant Mushroom Pie', '2-3 pumpkins + 1-2 of any mushroom', 'standard',
     'listed', 'reference', 'Supplied recipe-table screenshot, 2026-08-27', NULL),
    ('Mushroom Stew', 'At least 2 mushrooms', 'standard',
     'listed', 'reference', 'Supplied recipe-table screenshot, 2026-08-27', NULL),
    ('Fruit Pie', '1 pumpkin + 3 of any fruit', 'standard',
     'listed', 'reference', 'Supplied recipe-table screenshot, 2026-08-27', NULL),
    ('Giant Fruit Pie', '2-3 pumpkins + 1-2 of any fruit', 'standard',
     'listed', 'reference', 'Supplied recipe-table screenshot, 2026-08-27', NULL),
    ('Steamed Mushroom', 'Only 1 mushroom', 'standard',
     'listed', 'reference', 'Supplied recipe-table screenshot, 2026-08-27', NULL),
    ('Fish Patty', '1 any small fish (example: Anchovy)', 'standard',
     'listed', 'reference', 'Supplied recipe-table screenshot, 2026-08-27', NULL),
    ('Grilled Fish', '1 any fish', 'standard',
     'listed', 'reference', 'Supplied recipe-table screenshot, 2026-08-27', NULL),
    ('Grilled Meat', '1 of any meat (example: Raw deer meat)', 'standard',
     'listed', 'reference', 'Supplied recipe-table screenshot, 2026-08-27', NULL),
    ('Fish Combo', 'Any 2 fish', 'standard',
     'listed', 'reference', 'Supplied recipe-table screenshot, 2026-08-27', NULL),
    ('Meat Combo', 'Any 2 meat', 'standard',
     'listed', 'reference', 'Supplied recipe-table screenshot, 2026-08-27', NULL),
    ('Fish Dinner', 'Any 3 fish', 'standard',
     'listed', 'reference', 'Supplied recipe-table screenshot, 2026-08-27', NULL),
    ('Meat Dinner', 'Any 3 meat', 'standard',
     'listed', 'reference', 'Supplied recipe-table screenshot, 2026-08-27', NULL),
    ('Fish Buffet', '4 fish', 'standard',
     'listed', 'reference', 'Supplied recipe-table screenshot, 2026-08-27', NULL),
    ('Meat Buffet', '4 meat', 'standard',
     'listed', 'reference', 'Supplied recipe-table screenshot, 2026-08-27', NULL),
    ('Fish Pie', '1 pumpkin + 1 of any fish', 'standard',
     'listed', 'reference', 'Supplied recipe-table screenshot, 2026-08-27', NULL),
    ('Meat Pie', '1 pumpkin + 1 of any meat', 'standard',
     'listed', 'reference', 'Supplied recipe-table screenshot, 2026-08-27', NULL),
    ('Giant Fish Pie',
     '2-3 pumpkins + 1-2 of any fish, or 1 pumpkin + 2-3 of any fish',
     'standard', 'listed', 'reference',
     'Supplied recipe-table screenshot, 2026-08-27', NULL),
    ('Giant Meat Pie',
     '2-3 pumpkins + 1-2 of any meat, or 1 pumpkin + 2-3 of any meat',
     'standard', 'listed', 'reference',
     'Supplied recipe-table screenshot, 2026-08-27', NULL),
    ('Pumpkin Pie', 'At least 1 pumpkin (appearance differs by pumpkin type)',
     'standard', 'listed', 'reference',
     'Supplied recipe-table screenshot, 2026-08-27',
     'Resolution precedence versus Giant Pumpkin Pie is not yet encoded.'),
    ('Giant Pumpkin Pie', '2-4 pumpkins (appearance differs by pumpkin type)',
     'standard', 'listed', 'reference',
     'Supplied recipe-table screenshot, 2026-08-27', NULL),
    ('Bread and Fruit Meal', '1 wheat + 3 of any fruit', 'standard',
     'listed', 'reference', 'Supplied recipe-table screenshot, 2026-08-27', NULL),
    ('Hoagie', '1 wheat + any 3 fruits, fish, meat, or mushrooms', 'standard',
     'listed', 'reference', 'Supplied recipe-table screenshot, 2026-08-27', NULL),
    ('Sandwich', '1 wheat + any 1-2 mushrooms', 'standard',
     'listed', 'reference', 'Supplied recipe-table screenshot, 2026-08-27', NULL),
    ('Bread', '1-2 wheat', 'full_potential',
     'listed', 'partially_verified', 'Screenshot plus supplied mechanics notes, 2026-08-27', NULL),
    ('Baguette', '3 wheat', 'full_potential',
     'listed', 'partially_verified', 'Screenshot plus supplied mechanics notes, 2026-08-27', NULL),
    ('Spaghetti', '1 wheat + 3 tomatoes, 2 wheat + 2 tomatoes, or 4 wheat',
     'full_potential', 'listed', 'partially_verified',
     'Screenshot plus supplied mechanics notes, 2026-08-27', NULL),
    ('Burger', '1 wheat + 1 fish or meat', 'full_potential_2_25x',
     'listed', 'partially_verified', 'Screenshot plus supplied mechanics notes, 2026-08-27', NULL),
    ('Burgers', '2 wheat + 1 fish + 1 meat', 'full_potential_2_25x',
     'listed', 'partially_verified', 'Screenshot plus supplied mechanics notes, 2026-08-27', NULL),
    ('Burger Buffet', '2 wheat + 2 fish or meat', 'full_potential_2_25x',
     'listed', 'partially_verified', 'Screenshot plus supplied mechanics notes, 2026-08-27', NULL),
    ('Breadsticks with Sauce', '3 wheat + tomato', 'full_potential',
     'listed', 'partially_verified', 'Screenshot plus supplied mechanics notes, 2026-08-27', NULL),
    ('Fish and Mushroom Pie', '1 pumpkin + 1 any fish + 1 any mushroom',
     'standard', 'listed', 'reference', 'Supplied recipe-table screenshot, 2026-08-27', NULL),
    ('Smoothie', 'Samerian Ice + any 1-3 fruits or mushrooms', 'smoothie',
     'conditional', 'partially_verified', 'Screenshot plus supplied mechanics notes, 2026-08-27', NULL),
    ('Mistake', 'Only herbs, seasonings, or certain fruits', 'fixed_5',
     'none', 'partially_verified', 'Screenshot plus supplied mechanics notes, 2026-08-27',
     'Additional confirmed condition is stored in recipe_resolution_exceptions.'),
    ('Disgusting Smoothie', 'Samerian Ice + any 1-3 fish or meat', 'fixed_5',
     'none', 'partially_verified', 'Screenshot plus supplied mechanics notes, 2026-08-27', NULL),

    -- Known full-potential family members whose exact resolution conditions were
    -- not present in the supplied screenshot.
    ('Spaghetti and Fruit', NULL, 'full_potential', 'unknown', 'unverified',
     'Supplied mechanics notes, 2026-08-27', 'Exact ingredient condition pending.'),
    ('Mushroom Spaghetti', NULL, 'full_potential', 'unknown', 'unverified',
     'Supplied mechanics notes, 2026-08-27', 'Exact ingredient condition pending.'),
    ('Bird Spaghetti', NULL, 'full_potential', 'unknown', 'unverified',
     'Supplied mechanics notes, 2026-08-27', 'Exact ingredient condition pending.'),
    ('Bird and Mushroom Spaghetti', NULL, 'full_potential', 'unknown', 'unverified',
     'Supplied mechanics notes, 2026-08-27', 'Exact ingredient condition pending.'),
    ('Balanced Pie', NULL, 'standard', 'unknown', 'unverified',
     'User hypothesis, 2026-08-27',
     'Suspected meat + fruit + mushroom; requires in-game verification.');

WITH effect_data (recipe_name, effect_name, display_order, condition_text) AS (
    VALUES
        ('Mushroom Meal', 'Energizing', 1, NULL),
        ('Mushroom Pie', 'Invigorating', 1, NULL),
        ('Mushroom Pie', 'Energizing', 2, NULL),
        ('Giant Mushroom Pie', 'Invigorating', 1, NULL),
        ('Giant Mushroom Pie', 'Energizing', 2, NULL),
        ('Mushroom Stew', 'Energizing', 1, NULL),
        ('Fruit Pie', 'Invigorating', 1, NULL),
        ('Giant Fruit Pie', 'Invigorating', 1, NULL),
        ('Steamed Mushroom', 'Energizing', 1, NULL),
        ('Fish Patty', 'Recovery', 1, NULL),
        ('Grilled Fish', 'Recovery', 1, NULL),
        ('Grilled Meat', 'Recovery', 1, NULL),
        ('Fish Combo', 'Recovery', 1, NULL),
        ('Meat Combo', 'Recovery', 1, NULL),
        ('Fish Dinner', 'Recovery', 1, NULL),
        ('Meat Dinner', 'Recovery', 1, NULL),
        ('Fish Buffet', 'Recovery', 1, NULL),
        ('Meat Buffet', 'Recovery', 1, NULL),
        ('Fish Pie', 'Invigorating', 1, NULL),
        ('Fish Pie', 'Recovery', 2, NULL),
        ('Meat Pie', 'Invigorating', 1, NULL),
        ('Meat Pie', 'Recovery', 2, NULL),
        ('Giant Fish Pie', 'Invigorating', 1, NULL),
        ('Giant Fish Pie', 'Recovery', 2, NULL),
        ('Giant Meat Pie', 'Invigorating', 1, NULL),
        ('Giant Meat Pie', 'Recovery', 2, NULL),
        ('Pumpkin Pie', 'Invigorating', 1, NULL),
        ('Giant Pumpkin Pie', 'Invigorating', 1, NULL),
        ('Bread and Fruit Meal', 'Recovery', 1, NULL),
        ('Bread and Fruit Meal', 'Invigorating', 2, NULL),
        ('Hoagie', 'Recovery', 1, NULL),
        ('Hoagie', 'Invigorating', 2, NULL),
        ('Hoagie', 'Energizing', 3, NULL),
        ('Sandwich', 'Recovery', 1, NULL),
        ('Sandwich', 'Energizing', 2, NULL),
        ('Bread', 'Recovery', 1, NULL),
        ('Baguette', 'Recovery', 1, NULL),
        ('Spaghetti', 'Recovery', 1, NULL),
        ('Spaghetti', 'Invigorating', 2, NULL),
        ('Burger', 'Recovery', 1, NULL),
        ('Burgers', 'Recovery', 1, NULL),
        ('Burger Buffet', 'Recovery', 1, NULL),
        ('Breadsticks with Sauce', 'Recovery', 1, NULL),
        ('Breadsticks with Sauce', 'Invigorating', 2, NULL),
        ('Fish and Mushroom Pie', 'Recovery', 1, NULL),
        ('Fish and Mushroom Pie', 'Invigorating', 2, NULL),
        ('Fish and Mushroom Pie', 'Energizing', 3, NULL),
        ('Smoothie', 'Sun Protection', 1, 'Always supplied by Samerian Ice.'),
        ('Smoothie', 'Invigorating', 2, 'When the smoothie contains fruit.'),
        ('Smoothie', 'Energizing', 3, 'When the smoothie contains mushrooms.')
)
INSERT INTO recipe_effects (
    recipe_id, effect_name, display_order, condition_text
)
SELECT recipes.recipe_id, effect_data.effect_name,
       effect_data.display_order, effect_data.condition_text
FROM effect_data
JOIN recipes ON recipes.name = effect_data.recipe_name;

INSERT INTO recipe_resolution_exceptions (
    recipe_id,
    condition_type,
    condition_json,
    verification_status,
    notes
)
VALUES (
    (SELECT recipe_id FROM recipes WHERE name = 'Mistake'),
    'status_combination',
    '{"all":["Poisoned"],"any":["Fortitude","Energy Efficiency"]}',
    'verified',
    'Poison plus either Fortitude or Energy Efficiency resolves as Mistake.'
);

COMMIT;
