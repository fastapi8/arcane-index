PRAGMA foreign_keys = ON;

BEGIN;

CREATE TABLE cooking_slot_status_rules (
    cooking_slot_index    INTEGER PRIMARY KEY,
    primary_status_mode   TEXT NOT NULL,
    secondary_status_mode TEXT NOT NULL,
    verification_status   TEXT NOT NULL,
    evidence_summary      TEXT NOT NULL,

    CHECK (cooking_slot_index BETWEEN 1 AND 5),
    CHECK (primary_status_mode IN ('normal', 'suppressed')),
    CHECK (secondary_status_mode IN ('normal', 'suppressed')),
    CHECK (verification_status IN ('partially_verified', 'verified'))
) STRICT;

INSERT INTO cooking_slot_status_rules (
    cooking_slot_index, primary_status_mode, secondary_status_mode,
    verification_status, evidence_summary
)
VALUES (
    5, 'suppressed', 'normal', 'verified',
    'Orange Swiftcap, Cursed Mushroom, and Raw Krystoros Meat each lost their primary Energizing or Recovery tier contribution in slot five while retaining Featherfall III, Insanity III, or Poisoned IV. Moving the same ingredient to slot four restored its primary tier contribution.'
);

INSERT INTO recipe_resolution_observations (
    batch_name, test_number, input_description, slot_order_description,
    result_display_name, resolved_recipe_id, final_energy, effects_json, notes
)
VALUES
    ('fifth-slot-status-1', 1,
     'Banana + Brown Mushroom + Raw Bird Meat + Banana + Orange Swiftcap',
     'Orange Swiftcap in slot 5', 'Not recorded', NULL, NULL,
     '[{"name":"Recovery","tier":1},{"name":"Energizing","tier":1},{"name":"Invigorating","tier":1},{"name":"Featherfall","tier":3}]',
     'Slot-five Orange Swiftcap retained Featherfall III but did not raise Energizing.'),
    ('fifth-slot-status-1', 2,
     'Banana + Brown Mushroom + Raw Bird Meat + Orange Swiftcap + Banana',
     'Orange Swiftcap in slot 4; Banana in slot 5', 'Not recorded', NULL, NULL,
     '[{"name":"Recovery","tier":1},{"name":"Energizing","tier":3},{"name":"Invigorating","tier":1},{"name":"Featherfall","tier":3}]',
     'Slot-four Orange Swiftcap supplied both Energizing III and Featherfall III.'),
    ('fifth-slot-status-1', 3,
     'Banana + Brown Mushroom + Raw Bird Meat + Banana + Cursed Mushroom',
     'Cursed Mushroom in slot 5', 'Not recorded', NULL, NULL,
     '[{"name":"Recovery","tier":1},{"name":"Energizing","tier":1},{"name":"Invigorating","tier":1},{"name":"Insanity","tier":3}]',
     'Slot-five Cursed Mushroom retained Insanity III but did not raise Energizing.'),
    ('fifth-slot-status-1', 4,
     'Banana + Brown Mushroom + Raw Bird Meat + Cursed Mushroom + Banana',
     'Cursed Mushroom in slot 4; Banana in slot 5', 'Not recorded', NULL, NULL,
     '[{"name":"Recovery","tier":1},{"name":"Energizing","tier":3},{"name":"Invigorating","tier":1},{"name":"Insanity","tier":3}]',
     'Slot-four Cursed Mushroom supplied both Energizing III and Insanity III.'),
    ('fifth-slot-status-1', 5,
     'Banana + Brown Mushroom + Raw Bird Meat + Banana + Raw Krystoros Meat',
     'Raw Krystoros Meat in slot 5', 'Not recorded', NULL, NULL,
     '[{"name":"Recovery","tier":1},{"name":"Energizing","tier":1},{"name":"Invigorating","tier":1},{"name":"Poisoned","tier":4}]',
     'Slot-five Raw Krystoros Meat retained Poisoned IV but did not raise Recovery.'),
    ('fifth-slot-status-1', 6,
     'Banana + Brown Mushroom + Raw Bird Meat + Raw Krystoros Meat + Banana',
     'Raw Krystoros Meat in slot 4; Banana in slot 5', 'Not recorded', NULL, NULL,
     '[{"name":"Recovery","tier":4},{"name":"Energizing","tier":1},{"name":"Invigorating","tier":1},{"name":"Poisoned","tier":4}]',
     'Slot-four Raw Krystoros Meat supplied both Recovery IV and Poisoned IV.'),

    ('arcane-invigorating-1', 1, 'Arcane Stormfruit', NULL,
     'Not recorded', NULL, 112,
     '[{"name":"Invigorating","tier":4}]',
     'Arcane Stormfruit alone did not exceed its base Invigorating IV tier.'),
    ('arcane-invigorating-1', 2, 'Arcane Stratos Pumpkin', NULL,
     'Not recorded', NULL, 280,
     '[{"name":"Invigorating","tier":5}]',
     'Arcane Stratos Pumpkin alone displayed Invigorating V.'),
    ('arcane-invigorating-1', 3,
     'Arcane Stratos Pumpkin + Arcane Stormfruit', NULL,
     'Not recorded', NULL, NULL,
     '[{"name":"Invigorating","tier":6}]', NULL),
    ('arcane-invigorating-1', 4,
     'Arcane Stratos Pumpkin + Stormfruit', NULL,
     'Not recorded', NULL, NULL,
     '[{"name":"Invigorating","tier":6}]',
     'Stormfruit did not need Arcane for the combination to reach tier VI.'),
    ('arcane-invigorating-1', 5,
     'Stratos Pumpkin + Arcane Stormfruit', NULL,
     'Not recorded', NULL, NULL,
     '[{"name":"Invigorating","tier":5}]',
     'Arcane Stormfruit did not raise normal Stratos Pumpkin above tier V.');

WITH effect_data (batch_name, test_number, effect_name, tier) AS (
    VALUES
        ('fifth-slot-status-1', 1, 'Recovery', 1),
        ('fifth-slot-status-1', 1, 'Energizing', 1),
        ('fifth-slot-status-1', 1, 'Invigorating', 1),
        ('fifth-slot-status-1', 1, 'Featherfall', 3),
        ('fifth-slot-status-1', 2, 'Recovery', 1),
        ('fifth-slot-status-1', 2, 'Energizing', 3),
        ('fifth-slot-status-1', 2, 'Invigorating', 1),
        ('fifth-slot-status-1', 2, 'Featherfall', 3),
        ('fifth-slot-status-1', 3, 'Recovery', 1),
        ('fifth-slot-status-1', 3, 'Energizing', 1),
        ('fifth-slot-status-1', 3, 'Invigorating', 1),
        ('fifth-slot-status-1', 3, 'Insanity', 3),
        ('fifth-slot-status-1', 4, 'Recovery', 1),
        ('fifth-slot-status-1', 4, 'Energizing', 3),
        ('fifth-slot-status-1', 4, 'Invigorating', 1),
        ('fifth-slot-status-1', 4, 'Insanity', 3),
        ('fifth-slot-status-1', 5, 'Recovery', 1),
        ('fifth-slot-status-1', 5, 'Energizing', 1),
        ('fifth-slot-status-1', 5, 'Invigorating', 1),
        ('fifth-slot-status-1', 5, 'Poisoned', 4),
        ('fifth-slot-status-1', 6, 'Recovery', 4),
        ('fifth-slot-status-1', 6, 'Energizing', 1),
        ('fifth-slot-status-1', 6, 'Invigorating', 1),
        ('fifth-slot-status-1', 6, 'Poisoned', 4),
        ('arcane-invigorating-1', 1, 'Invigorating', 4),
        ('arcane-invigorating-1', 2, 'Invigorating', 5),
        ('arcane-invigorating-1', 3, 'Invigorating', 6),
        ('arcane-invigorating-1', 4, 'Invigorating', 6),
        ('arcane-invigorating-1', 5, 'Invigorating', 5)
)
INSERT INTO recipe_observation_effects (
    recipe_resolution_observation_id, effect_name, tier,
    duration_seconds, displayed_duration_seconds
)
SELECT observations.recipe_resolution_observation_id,
       effect_data.effect_name, effect_data.tier, NULL, NULL
FROM effect_data
JOIN recipe_resolution_observations AS observations
  ON observations.batch_name = effect_data.batch_name
 AND observations.test_number = effect_data.test_number;

COMMIT;
