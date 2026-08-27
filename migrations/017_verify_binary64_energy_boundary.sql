-- Level-1 boundary test: four individually floored contributions sum to 100,
-- exact variety arithmetic predicts 115, and the game displays 114.
PRAGMA foreign_keys = ON;

BEGIN IMMEDIATE;

UPDATE meal_energy_formula_models
SET numeric_boundary_status = 'verified',
    notes = 'U is the number of unique ingredient identities in slots 1-4. For M>=1, alpha=(U-1)/3 and C=floor(E*(1+alpha*(M-1))). For M<1, C=floor(E*M) regardless of U. Sum all per-item contributions, including slot 5; V=1+0.05*(U-1); then floor(S*V*recipe_multiplier*cooking_quality) once at the end. Arithmetic follows IEEE-754 binary64/Luau number behavior: a verified level-1 U=4 test with S=100 displayed 114 because binary 100*1.15 is slightly below 115.'
WHERE code = 'standard';

INSERT INTO recipe_resolution_observations (
    batch_name,
    test_number,
    input_description,
    result_display_name,
    resolved_recipe_id,
    final_energy,
    effects_json,
    notes
)
VALUES (
    'numeric-boundary-1',
    1,
    'Brown Mushroom + Green Apple + Raw Bear Meat + Raw Bird Meat',
    'Not recorded',
    NULL,
    114,
    NULL,
    'Cooking level 1. Per-item contributions are 12, 13, 60, and 15 (S=100); U=4 gives V=1.15 and Q=1. Exact decimal arithmetic predicts 115, while IEEE-754 binary64 evaluates the product just below 115 and the game displays 114.'
)
ON CONFLICT(batch_name, test_number) DO UPDATE SET
    input_description = excluded.input_description,
    result_display_name = excluded.result_display_name,
    resolved_recipe_id = excluded.resolved_recipe_id,
    final_energy = excluded.final_energy,
    effects_json = excluded.effects_json,
    notes = excluded.notes;

COMMIT;
