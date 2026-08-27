PRAGMA foreign_keys = ON;

BEGIN IMMEDIATE;

CREATE TABLE IF NOT EXISTS meal_energy_formula_models (
    code TEXT PRIMARY KEY,
    unique_slots INTEGER NOT NULL CHECK (unique_slots > 0),
    interpolation_denominator INTEGER NOT NULL CHECK (interpolation_denominator > 0),
    variety_increment REAL NOT NULL CHECK (variety_increment >= 0),
    low_multiplier_interpolates INTEGER NOT NULL CHECK (low_multiplier_interpolates IN (0, 1)),
    per_item_floor INTEGER NOT NULL CHECK (per_item_floor IN (0, 1)),
    intermediate_floor INTEGER NOT NULL CHECK (intermediate_floor IN (0, 1)),
    final_floor INTEGER NOT NULL CHECK (final_floor IN (0, 1)),
    slot_after_unique_limit_contributes_energy INTEGER NOT NULL CHECK (slot_after_unique_limit_contributes_energy IN (0, 1)),
    numeric_boundary_status TEXT NOT NULL CHECK (numeric_boundary_status IN ('verified', 'unverified')),
    notes TEXT NOT NULL
);

INSERT INTO meal_energy_formula_models (
    code,
    unique_slots,
    interpolation_denominator,
    variety_increment,
    low_multiplier_interpolates,
    per_item_floor,
    intermediate_floor,
    final_floor,
    slot_after_unique_limit_contributes_energy,
    numeric_boundary_status,
    notes
) VALUES (
    'standard',
    4,
    3,
    0.05,
    0,
    1,
    0,
    1,
    1,
    'unverified',
    'U is the number of unique ingredient identities in slots 1-4. For M>=1, alpha=(U-1)/3 and C=floor(E*(1+alpha*(M-1))). For M<1, C=floor(E*M) regardless of U. Sum all per-item contributions, including slot 5; V=1+0.05*(U-1); then floor(S*V*recipe_multiplier*cooking_quality) once at the end. Exact Roblox/Luau floating-point behavior at integer boundaries remains unverified.'
)
ON CONFLICT(code) DO UPDATE SET
    unique_slots = excluded.unique_slots,
    interpolation_denominator = excluded.interpolation_denominator,
    variety_increment = excluded.variety_increment,
    low_multiplier_interpolates = excluded.low_multiplier_interpolates,
    per_item_floor = excluded.per_item_floor,
    intermediate_floor = excluded.intermediate_floor,
    final_floor = excluded.final_floor,
    slot_after_unique_limit_contributes_energy = excluded.slot_after_unique_limit_contributes_energy,
    numeric_boundary_status = excluded.numeric_boundary_status,
    notes = excluded.notes;

CREATE TABLE IF NOT EXISTS status_tier_rules (
    id INTEGER PRIMARY KEY,
    rule_code TEXT NOT NULL UNIQUE,
    effect_status_id INTEGER NOT NULL REFERENCES statuses(status_id),
    resulting_tier INTEGER NOT NULL CHECK (resulting_tier > 0),
    condition_json TEXT NOT NULL CHECK (json_valid(condition_json)),
    verification_status TEXT NOT NULL CHECK (verification_status IN ('hypothesis', 'verified', 'rejected')),
    notes TEXT
);

INSERT INTO status_tier_rules (
    rule_code,
    effect_status_id,
    resulting_tier,
    condition_json,
    verification_status,
    notes
)
SELECT
    'arcane-stratos-pumpkin-with-any-second-ingredient',
    s.status_id,
    6,
    json_object(
        'ingredient', 'Stratos Pumpkin',
        'required_modifier', 'Arcane',
        'minimum_total_ingredients', 2,
        'effect', 'Invigorating'
    ),
    'verified',
    'Arcane Stratos Pumpkin is Invigorating V alone and Invigorating VI with each tested second ingredient: Banana, Brown Mushroom, and Coconut.'
FROM statuses AS s
WHERE lower(s.name) = 'invigorating'
ON CONFLICT(rule_code) DO UPDATE SET
    effect_status_id = excluded.effect_status_id,
    resulting_tier = excluded.resulting_tier,
    condition_json = excluded.condition_json,
    verification_status = excluded.verification_status,
    notes = excluded.notes;

INSERT INTO recipe_resolution_observations (
    batch_name,
    test_number,
    input_description,
    result_display_name,
    resolved_recipe_id,
    effects_json,
    notes
)
SELECT
    'arcane-status-threshold-2',
    v.test_number,
    v.input_description,
    'Not recorded',
    NULL,
    v.effects_json,
    v.notes
FROM (
    SELECT 1 AS test_number,
           'Arcane Stratos Pumpkin + Banana' AS input_description,
           '[{"name":"Invigorating","tier":6}]' AS effects_json,
           'Observed Invigorating VI.' AS notes
    UNION ALL
    SELECT 2, 'Arcane Stratos Pumpkin + Brown Mushroom',
           '[{"name":"Invigorating","tier":6},{"name":"Energizing","tier":1}]',
           'Observed Invigorating VI and Energizing I.'
    UNION ALL
    SELECT 3, 'Arcane Stratos Pumpkin + Coconut',
           '[{"name":"Invigorating","tier":6}]',
           'Observed Invigorating VI.'
    UNION ALL
    SELECT 4, 'Stratos Pumpkin + Stormfruit',
           '[{"name":"Invigorating","tier":5}]',
           'Observed Invigorating V.'
) AS v
ON CONFLICT(batch_name, test_number) DO UPDATE SET
    input_description = excluded.input_description,
    result_display_name = excluded.result_display_name,
    resolved_recipe_id = excluded.resolved_recipe_id,
    effects_json = excluded.effects_json,
    notes = excluded.notes;

INSERT INTO recipe_observation_effects (
    recipe_resolution_observation_id,
    effect_name,
    tier,
    duration_seconds,
    displayed_duration_seconds
)
SELECT o.recipe_resolution_observation_id, v.effect_name, v.tier, NULL, NULL
FROM (
    SELECT 1 AS test_number, 'Invigorating' AS effect_name, 6 AS tier
    UNION ALL SELECT 2, 'Invigorating', 6
    UNION ALL SELECT 2, 'Energizing', 1
    UNION ALL SELECT 3, 'Invigorating', 6
    UNION ALL SELECT 4, 'Invigorating', 5
) AS v
JOIN recipe_resolution_observations AS o
  ON o.batch_name = 'arcane-status-threshold-2'
 AND o.test_number = v.test_number
ON CONFLICT(recipe_resolution_observation_id, effect_name) DO UPDATE SET
    tier = excluded.tier;

COMMIT;
