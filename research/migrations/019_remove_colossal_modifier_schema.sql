-- Rebuild modifier tables so Colossal is absent from the allowed modifier enum,
-- not merely rejected by migration-018 compatibility triggers.
PRAGMA foreign_keys = OFF;

BEGIN IMMEDIATE;

CREATE TABLE ingredient_modifiers_new (
    ingredient_modifier_id INTEGER PRIMARY KEY,
    ingredient_id          INTEGER NOT NULL,
    modifier_name          TEXT NOT NULL,
    rarity_delta           INTEGER,

    CHECK (modifier_name IN ('Small', 'Giant', 'Massive', 'Arcane')),
    CHECK (rarity_delta IS NULL OR rarity_delta BETWEEN -4 AND 4),
    UNIQUE (ingredient_id, modifier_name),

    FOREIGN KEY (ingredient_id)
        REFERENCES ingredients (ingredient_id)
        ON UPDATE CASCADE
        ON DELETE CASCADE
) STRICT;

INSERT INTO ingredient_modifiers_new
SELECT *
FROM ingredient_modifiers
WHERE modifier_name <> 'Colossal';

DROP TABLE ingredient_modifiers;
ALTER TABLE ingredient_modifiers_new RENAME TO ingredient_modifiers;

CREATE INDEX idx_ingredient_modifiers_ingredient
ON ingredient_modifiers (ingredient_id);

CREATE TRIGGER ingredient_modifiers_size_requires_fish_insert
BEFORE INSERT ON ingredient_modifiers
FOR EACH ROW
WHEN NEW.modifier_name IN ('Small', 'Giant', 'Massive')
BEGIN
    SELECT CASE
        WHEN (
            SELECT ingredient_kind
            FROM ingredients
            WHERE ingredient_id = NEW.ingredient_id
        ) IS NOT 'fish'
        THEN RAISE(ABORT, 'size modifiers may only be attached to fish bases')
    END;
END;

CREATE TRIGGER ingredient_modifiers_size_requires_fish_update
BEFORE UPDATE OF ingredient_id, modifier_name ON ingredient_modifiers
FOR EACH ROW
WHEN NEW.modifier_name IN ('Small', 'Giant', 'Massive')
BEGIN
    SELECT CASE
        WHEN (
            SELECT ingredient_kind
            FROM ingredients
            WHERE ingredient_id = NEW.ingredient_id
        ) IS NOT 'fish'
        THEN RAISE(ABORT, 'size modifiers may only be attached to fish bases')
    END;
END;

CREATE TABLE ingredient_modifier_rules_new (
    ingredient_kind   TEXT NOT NULL,
    modifier_name     TEXT NOT NULL,
    energy_multiplier REAL NOT NULL,

    PRIMARY KEY (ingredient_kind, modifier_name),
    CHECK (ingredient_kind IN ('normal', 'fish', 'seasoning', 'ice')),
    CHECK (modifier_name IN ('Small', 'Giant', 'Massive', 'Arcane')),
    CHECK (energy_multiplier > 0)
) STRICT;

INSERT INTO ingredient_modifier_rules_new
SELECT *
FROM ingredient_modifier_rules
WHERE modifier_name <> 'Colossal';

DROP TABLE ingredient_modifier_rules;
ALTER TABLE ingredient_modifier_rules_new RENAME TO ingredient_modifier_rules;

CREATE TABLE ingredient_modifier_exclusions_new (
    ingredient_id INTEGER NOT NULL,
    modifier_name TEXT NOT NULL,
    reason        TEXT,

    PRIMARY KEY (ingredient_id, modifier_name),
    CHECK (modifier_name IN ('Small', 'Giant', 'Massive', 'Arcane')),

    FOREIGN KEY (ingredient_id)
        REFERENCES ingredients (ingredient_id)
        ON UPDATE CASCADE
        ON DELETE CASCADE
) STRICT;

INSERT INTO ingredient_modifier_exclusions_new
SELECT *
FROM ingredient_modifier_exclusions
WHERE modifier_name <> 'Colossal';

DROP TABLE ingredient_modifier_exclusions;
ALTER TABLE ingredient_modifier_exclusions_new
RENAME TO ingredient_modifier_exclusions;

COMMIT;

PRAGMA foreign_keys = ON;
