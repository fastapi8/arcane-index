-- The Arcane status tests reported effects, not resolved recipe display names.
-- Remove the earlier inferred Balanced Meal label rather than treating it as evidence.
PRAGMA foreign_keys = ON;

BEGIN IMMEDIATE;

UPDATE recipe_resolution_observations
SET result_display_name = 'Not recorded',
    resolved_recipe_id = NULL
WHERE batch_name = 'arcane-status-threshold-2';

COMMIT;
