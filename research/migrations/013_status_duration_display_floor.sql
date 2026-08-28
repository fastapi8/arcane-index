-- Confirmed status-duration presentation: fractional seconds are floored.
PRAGMA foreign_keys = ON;

BEGIN;

ALTER TABLE status_duration_models
ADD COLUMN display_rounding_mode TEXT NOT NULL DEFAULT 'floor'
CHECK (display_rounding_mode IN ('floor', 'nearest', 'ceiling'));

ALTER TABLE recipe_observation_effects
ADD COLUMN displayed_duration_seconds INTEGER
CHECK (displayed_duration_seconds IS NULL OR displayed_duration_seconds >= 0);

UPDATE status_duration_models
SET display_rounding_mode = 'floor',
    notes =
        'Seasoning does not affect duration. Per-status fractional seconds are floored for display. Fifth-slot status-type behavior remains uncertain.'
WHERE status_duration_model_code = 'standard';

-- Status batch 1, test 3: 66 * 6.5 * 1.5 / 3 = 214.5 exact seconds,
-- observed in game as 3m34s (214 displayed seconds) for each status.
UPDATE recipe_observation_effects
SET duration_seconds = 214.5,
    displayed_duration_seconds = 214
WHERE recipe_resolution_observation_id = (
    SELECT recipe_resolution_observation_id
    FROM recipe_resolution_observations
    WHERE batch_name = 'status-1' AND test_number = 3
);

COMMIT;
