-- Run after importing data/ingredients.csv into _ingredient_csv_load.
-- Modifier rows are omitted because the CSV contains bases only.
PRAGMA foreign_keys = ON;

BEGIN;

INSERT INTO ingredient_import (
    import_batch,
    source_row,
    ingredient,
    dish_type,
    energy,
    status_effects,
    rarity
)
SELECT
    'initial-transcription',
    rowid,
    ingredient,
    dish_type,
    energy,
    status_effects,
    rarity
FROM _ingredient_csv_load;

WITH source_rows AS (
    SELECT
        ingredient,
        dish_type,
        energy,
        rarity,
        CASE
            WHEN ingredient = 'Samerian Ice' THEN 'ice'
            WHEN ingredient IN (
                'Basil herb', 'Cardamom spice', 'Clove spice', 'Garlic spice',
                'Marjoram herb', 'Horizon rosemary', 'Lemongrass herb',
                'Molten latana', 'Moly', 'Pepper spice', 'Rock salt',
                'Sea kale', 'Sun caraway', 'Vanilla herb'
            ) THEN 'seasoning'
            WHEN dish_type IN (
                'Fish Patty', 'Grilled Fish', 'Grilled Salmon',
                'Grilled Giant Fish', 'Grilled Giant Salmon',
                'Grilled Giant Anglerfish', 'Grilled Jellyfish',
                'Grilled Giant Stingray', 'Grilled Giant Shark',
                'Grilled Giant Squid', 'Grilled Giant Eel',
                'Grilled Giant Tuna', 'Grilled Turtle'
            ) THEN 'fish'
            ELSE 'normal'
        END AS ingredient_kind
    FROM _ingredient_csv_load
)
INSERT INTO ingredients (
    name,
    variety_identity,
    ingredient_kind,
    solo_energy,
    solo_dish_type,
    base_rarity
)
SELECT
    ingredient,
    ingredient_kind || ':' || lower(replace(ingredient, ' ', '-')),
    ingredient_kind,
    energy,
    nullif(dish_type, ''),
    rarity
FROM source_rows;

WITH RECURSIVE status_parts (
    ingredient_import_id,
    effect,
    remaining,
    display_order
) AS (
    SELECT
        ingredient_import_id,
        trim(CASE
            WHEN instr(status_effects, ',') = 0 THEN status_effects
            ELSE substr(status_effects, 1, instr(status_effects, ',') - 1)
        END),
        ltrim(CASE
            WHEN instr(status_effects, ',') = 0 THEN ''
            ELSE substr(status_effects, instr(status_effects, ',') + 1)
        END),
        1
    FROM ingredient_import
    WHERE import_batch = 'initial-transcription'
      AND status_effects IS NOT NULL
      AND trim(status_effects) <> ''

    UNION ALL

    SELECT
        ingredient_import_id,
        trim(CASE
            WHEN instr(remaining, ',') = 0 THEN remaining
            ELSE substr(remaining, 1, instr(remaining, ',') - 1)
        END),
        ltrim(CASE
            WHEN instr(remaining, ',') = 0 THEN ''
            ELSE substr(remaining, instr(remaining, ',') + 1)
        END),
        display_order + 1
    FROM status_parts
    WHERE remaining <> ''
), parsed_statuses AS (
    SELECT
        ingredient_import_id,
        CASE
            WHEN effect LIKE '% III' THEN substr(effect, 1, length(effect) - 4)
            WHEN effect LIKE '% II' THEN substr(effect, 1, length(effect) - 3)
            WHEN effect LIKE '% IV' THEN substr(effect, 1, length(effect) - 3)
            WHEN effect LIKE '% V' THEN substr(effect, 1, length(effect) - 2)
            WHEN effect LIKE '% I' THEN substr(effect, 1, length(effect) - 2)
        END AS status_name,
        CASE
            WHEN effect LIKE '% III' THEN 3
            WHEN effect LIKE '% II' THEN 2
            WHEN effect LIKE '% IV' THEN 4
            WHEN effect LIKE '% V' THEN 5
            WHEN effect LIKE '% I' THEN 1
        END AS tier,
        display_order
    FROM status_parts
)
INSERT OR IGNORE INTO statuses (name)
SELECT DISTINCT status_name
FROM parsed_statuses;

WITH RECURSIVE status_parts (
    ingredient_import_id,
    effect,
    remaining,
    display_order
) AS (
    SELECT
        ingredient_import_id,
        trim(CASE
            WHEN instr(status_effects, ',') = 0 THEN status_effects
            ELSE substr(status_effects, 1, instr(status_effects, ',') - 1)
        END),
        ltrim(CASE
            WHEN instr(status_effects, ',') = 0 THEN ''
            ELSE substr(status_effects, instr(status_effects, ',') + 1)
        END),
        1
    FROM ingredient_import
    WHERE import_batch = 'initial-transcription'
      AND status_effects IS NOT NULL
      AND trim(status_effects) <> ''

    UNION ALL

    SELECT
        ingredient_import_id,
        trim(CASE
            WHEN instr(remaining, ',') = 0 THEN remaining
            ELSE substr(remaining, 1, instr(remaining, ',') - 1)
        END),
        ltrim(CASE
            WHEN instr(remaining, ',') = 0 THEN ''
            ELSE substr(remaining, instr(remaining, ',') + 1)
        END),
        display_order + 1
    FROM status_parts
    WHERE remaining <> ''
), parsed_statuses AS (
    SELECT
        ingredient_import_id,
        CASE
            WHEN effect LIKE '% III' THEN substr(effect, 1, length(effect) - 4)
            WHEN effect LIKE '% II' THEN substr(effect, 1, length(effect) - 3)
            WHEN effect LIKE '% IV' THEN substr(effect, 1, length(effect) - 3)
            WHEN effect LIKE '% V' THEN substr(effect, 1, length(effect) - 2)
            WHEN effect LIKE '% I' THEN substr(effect, 1, length(effect) - 2)
        END AS status_name,
        CASE
            WHEN effect LIKE '% III' THEN 3
            WHEN effect LIKE '% II' THEN 2
            WHEN effect LIKE '% IV' THEN 4
            WHEN effect LIKE '% V' THEN 5
            WHEN effect LIKE '% I' THEN 1
        END AS tier,
        display_order
    FROM status_parts
)
INSERT INTO ingredient_statuses (
    ingredient_id,
    status_id,
    tier,
    display_order
)
SELECT
    ingredients.ingredient_id,
    statuses.status_id,
    parsed_statuses.tier,
    parsed_statuses.display_order
FROM parsed_statuses
JOIN ingredient_import
    ON ingredient_import.ingredient_import_id = parsed_statuses.ingredient_import_id
JOIN ingredients
    ON ingredients.name = ingredient_import.ingredient
JOIN statuses
    ON statuses.name = parsed_statuses.status_name;

UPDATE ingredient_import
SET normalized_ingredient_id = (
    SELECT ingredients.ingredient_id
    FROM ingredients
    WHERE ingredients.name = ingredient_import.ingredient
)
WHERE import_batch = 'initial-transcription';

DROP TABLE _ingredient_csv_load;

COMMIT;
