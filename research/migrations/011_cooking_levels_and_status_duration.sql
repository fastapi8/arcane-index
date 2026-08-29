PRAGMA foreign_keys = ON;

BEGIN;

CREATE TABLE cooking_level_mechanics (
    cooking_level                  INTEGER PRIMARY KEY,
    cooking_multiplier             REAL NOT NULL,
    general_ingredient_slot_count  INTEGER NOT NULL,
    has_dedicated_seasoning_slot   INTEGER NOT NULL,
    unlock_note                    TEXT,

    CHECK (cooking_level BETWEEN 1 AND 10),
    CHECK (cooking_multiplier > 0),
    CHECK (general_ingredient_slot_count BETWEEN 1 AND 5),
    CHECK (has_dedicated_seasoning_slot IN (0, 1))
) STRICT;

CREATE TABLE status_duration_models (
    status_duration_model_code  TEXT PRIMARY KEY,
    energy_coefficient          REAL NOT NULL,
    uses_cooking_multiplier     INTEGER NOT NULL,
    divide_by_status_type_count INTEGER NOT NULL,
    seasoning_affects_duration  INTEGER NOT NULL,
    formula_expression          TEXT NOT NULL,
    verification_status         TEXT NOT NULL,
    notes                       TEXT,

    CHECK (energy_coefficient > 0),
    CHECK (uses_cooking_multiplier IN (0, 1)),
    CHECK (divide_by_status_type_count IN (0, 1)),
    CHECK (seasoning_affects_duration IN (0, 1)),
    CHECK (verification_status IN ('pending_confirmation', 'verified'))
) STRICT;

INSERT INTO cooking_level_mechanics (
    cooking_level,
    cooking_multiplier,
    general_ingredient_slot_count,
    has_dedicated_seasoning_slot,
    unlock_note
)
VALUES
    (1,  1.0, 4, 0, 'Base cooking level.'),
    (2,  1.1, 4, 0, 'Cooking multiplier increases to 1.1x.'),
    (3,  1.2, 4, 0, 'Cooking multiplier increases to 1.2x.'),
    (4,  1.3, 4, 0, 'Cooking multiplier increases to 1.3x.'),
    (5,  1.3, 4, 0, 'No relevant calculation or slot change.'),
    (6,  1.4, 4, 0, 'Cooking multiplier increases to 1.4x.'),
    (7,  1.4, 4, 1, 'Unlocks a dedicated seasoning slot.'),
    (8,  1.5, 4, 1, 'Cooking multiplier increases to 1.5x.'),
    (9,  1.5, 5, 1, 'Unlocks the fifth general cooking slot.'),
    (10, 1.5, 5, 1, 'No relevant calculation or slot change.');

INSERT INTO status_duration_models (
    status_duration_model_code,
    energy_coefficient,
    uses_cooking_multiplier,
    divide_by_status_type_count,
    seasoning_affects_duration,
    formula_expression,
    verification_status,
    notes
)
VALUES (
    'standard',
    6.5,
    1,
    1,
    0,
    'per_status_seconds = (final_energy * 6.5 * cooking_multiplier) / distinct_status_type_count',
    'verified',
    'Seasoning does not affect duration. Fifth-slot status-type behavior remains uncertain.'
);

COMMIT;
