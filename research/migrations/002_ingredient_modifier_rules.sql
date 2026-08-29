-- Modifier variants remain derived values and are not ingredient identities.
PRAGMA foreign_keys = ON;

BEGIN;

CREATE TABLE ingredient_modifier_rules (
    ingredient_kind    TEXT NOT NULL,
    modifier_name      TEXT NOT NULL,
    energy_multiplier  REAL NOT NULL,

    PRIMARY KEY (ingredient_kind, modifier_name),
    CHECK (ingredient_kind IN ('normal', 'fish', 'seasoning', 'ice')),
    CHECK (
        modifier_name IN ('Small', 'Giant', 'Massive', 'Arcane')
    ),
    CHECK (energy_multiplier > 0)
) STRICT;

-- These rules apply to fish only. Colossal is part of the canonical species
-- name Colossal Squid and is not a modifier.
INSERT INTO ingredient_modifier_rules (
    ingredient_kind,
    modifier_name,
    energy_multiplier
)
VALUES
    ('fish', 'Small',   0.5),
    ('fish', 'Giant',   2.0),
    ('fish', 'Massive', 3.0),
    ('fish', 'Arcane',  1.5);

COMMIT;
