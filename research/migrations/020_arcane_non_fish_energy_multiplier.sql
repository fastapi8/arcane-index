-- Arcane triples the energy contribution of canonical non-fish ingredients.
-- Seasonings and ice are separate mechanics and are not covered by this rule.
PRAGMA foreign_keys = ON;

BEGIN IMMEDIATE;

INSERT INTO ingredient_modifier_rules (
    ingredient_kind,
    modifier_name,
    energy_multiplier
)
VALUES ('normal', 'Arcane', 3.0);

COMMIT;
