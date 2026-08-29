PRAGMA foreign_keys = ON;

BEGIN IMMEDIATE;

ALTER TABLE ingredients
ADD COLUMN imported_solo_energy INTEGER
CHECK (imported_solo_energy IS NULL OR imported_solo_energy >= 0);

UPDATE ingredients
SET imported_solo_energy = solo_energy;

CREATE TEMP TABLE solo_energy_resolution (
    ingredient_id         INTEGER PRIMARY KEY,
    imported_solo_energy  INTEGER NOT NULL,
    corrected_solo_energy INTEGER NOT NULL,
    candidate_count       INTEGER NOT NULL CHECK (candidate_count = 1)
) STRICT;

-- Search integer candidates rather than dividing. These source rows were
-- measured as recognized one-ingredient meals at perfect/max cooking quality:
-- imported = floor(base_solo * 1.5).
WITH RECURSIVE
    candidates(value) AS (
        VALUES (0)
        UNION ALL
        SELECT value + 1
        FROM candidates
        WHERE value < (SELECT MAX(solo_energy) + 1 FROM ingredients)
    ),
    affected AS (
        SELECT ingredient_id, solo_energy
        FROM ingredients
        WHERE ingredient_kind = 'fish'
           OR lower(name) IN (
               'pumpkin', 'sky pumpkin', 'stratos pumpkin', 'wheat',
               'festive cookie dough'
           )
    )
INSERT INTO solo_energy_resolution (
    ingredient_id, imported_solo_energy, corrected_solo_energy, candidate_count
)
SELECT
    affected.ingredient_id,
    affected.solo_energy,
    MIN(candidates.value),
    COUNT(candidates.value)
FROM affected
LEFT JOIN candidates
  ON (candidates.value * 3) / 2 = affected.solo_energy
GROUP BY affected.ingredient_id;

-- Independently require the reversed value to match the already verified raw
-- mechanics before changing the public solo-energy value.
CREATE TEMP TABLE solo_energy_mechanics_guard (
    ingredient_id INTEGER PRIMARY KEY,
    matches_raw_mechanics INTEGER NOT NULL CHECK (matches_raw_mechanics = 1)
) STRICT;

INSERT INTO solo_energy_mechanics_guard (ingredient_id, matches_raw_mechanics)
SELECT
    ingredients.ingredient_id,
    CAST(
        solo_energy_resolution.corrected_solo_energy
        = CAST(ingredients.raw_energy * ingredients.cook_multiplier AS INTEGER)
        AS INTEGER
    )
FROM solo_energy_resolution
JOIN ingredients USING (ingredient_id);

UPDATE ingredients
SET solo_energy = (
    SELECT corrected_solo_energy
    FROM solo_energy_resolution
    WHERE solo_energy_resolution.ingredient_id = ingredients.ingredient_id
)
WHERE ingredient_id IN (SELECT ingredient_id FROM solo_energy_resolution);

DROP TABLE solo_energy_mechanics_guard;
DROP TABLE solo_energy_resolution;

UPDATE ingredients
SET name = 'Colossal Squid',
    variety_identity = 'fish:colossal-squid'
WHERE name = 'Squid'
  AND ingredient_kind = 'fish';

UPDATE ingredient_import
SET ingredient = 'Colossal Squid'
WHERE ingredient = 'Squid'
  AND normalized_ingredient_id = (
      SELECT ingredient_id FROM ingredients WHERE name = 'Colossal Squid'
  );

-- Old schemas allowed the word in modifier-name CHECK constraints. No such
-- rows exist, and these guards make the live model reject future use.
DELETE FROM ingredient_modifier_rules WHERE modifier_name = 'Colossal';
DELETE FROM ingredient_modifier_exclusions WHERE modifier_name = 'Colossal';
DELETE FROM ingredient_modifiers WHERE modifier_name = 'Colossal';

CREATE TRIGGER ingredient_modifiers_reject_colossal_insert
BEFORE INSERT ON ingredient_modifiers
FOR EACH ROW
WHEN NEW.modifier_name = 'Colossal'
BEGIN
    SELECT RAISE(ABORT, 'Colossal is a fish name, not an ingredient modifier');
END;

CREATE TRIGGER ingredient_modifiers_reject_colossal_update
BEFORE UPDATE OF modifier_name ON ingredient_modifiers
FOR EACH ROW
WHEN NEW.modifier_name = 'Colossal'
BEGIN
    SELECT RAISE(ABORT, 'Colossal is a fish name, not an ingredient modifier');
END;

CREATE TRIGGER ingredient_modifier_rules_reject_colossal_insert
BEFORE INSERT ON ingredient_modifier_rules
FOR EACH ROW
WHEN NEW.modifier_name = 'Colossal'
BEGIN
    SELECT RAISE(ABORT, 'Colossal is a fish name, not an ingredient modifier');
END;

CREATE TRIGGER ingredient_modifier_exclusions_reject_colossal_insert
BEFORE INSERT ON ingredient_modifier_exclusions
FOR EACH ROW
WHEN NEW.modifier_name = 'Colossal'
BEGIN
    SELECT RAISE(ABORT, 'Colossal is a fish name, not an ingredient modifier');
END;

COMMIT;
