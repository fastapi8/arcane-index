PRAGMA foreign_keys = ON;

BEGIN;

UPDATE status_duration_models
SET energy_coefficient = 6.5,
    formula_expression =
        'per_status_seconds = (final_energy * 6.5 * cooking_multiplier) / distinct_status_type_count',
    verification_status = 'verified',
    notes =
        'Seasoning does not affect duration. Fifth-slot status-type behavior remains uncertain.'
WHERE status_duration_model_code = 'standard';

COMMIT;
