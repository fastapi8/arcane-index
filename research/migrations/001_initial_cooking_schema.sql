-- SQLite foreign-key enforcement is connection-local, so enable it for every
-- connection that reads or writes this database as well as when applying this
-- migration.
PRAGMA foreign_keys = ON;

BEGIN;

-- Faithful CSV staging area. Keep rows here even when they normalize to a
-- canonical base ingredient plus one or more modifiers.
CREATE TABLE ingredient_import (
    ingredient_import_id     INTEGER PRIMARY KEY,
    import_batch             TEXT NOT NULL,
    source_row               INTEGER,
    ingredient               TEXT NOT NULL,
    dish_type                TEXT,
    energy                   INTEGER,
    status_effects           TEXT,
    rarity                   TEXT,

    normalized_ingredient_id INTEGER,
    normalized_modifier_id   INTEGER,
    imported_at              TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CHECK (energy IS NULL OR energy >= 0),
    CHECK (
        rarity IS NULL OR rarity IN
            ('common', 'uncommon', 'rare', 'mystic', 'legendary')
    ),
    CHECK (
        normalized_modifier_id IS NULL OR normalized_ingredient_id IS NOT NULL
    ),
    UNIQUE (import_batch, source_row),

    FOREIGN KEY (normalized_ingredient_id)
        REFERENCES ingredients (ingredient_id)
        ON UPDATE CASCADE
        ON DELETE SET NULL,
    FOREIGN KEY (normalized_modifier_id)
        REFERENCES ingredient_modifiers (ingredient_modifier_id)
        ON UPDATE CASCADE
        ON DELETE SET NULL
) STRICT;

-- One row per canonical base ingredient identity. A named non-fish item such
-- as "Giant Seacap" is a base ingredient, while fish size variants are not.
CREATE TABLE ingredients (
    ingredient_id                    INTEGER PRIMARY KEY,
    name                             TEXT NOT NULL COLLATE NOCASE,
    variety_identity                 TEXT NOT NULL COLLATE NOCASE,
    ingredient_kind                  TEXT NOT NULL,

    -- Initially loaded from the source display value. Migration 018 preserves
    -- that measurement and corrects recognized max-level meals to their
    -- level-1/base solo value.
    solo_energy                      INTEGER NOT NULL,
    solo_dish_type                   TEXT,

    raw_energy                       INTEGER,
    cook_multiplier                  REAL,
    base_rarity                      TEXT NOT NULL,

    -- Ice and seasonings have identities and count in the first four slots.
    counts_in_first_four_diversity   INTEGER NOT NULL DEFAULT 1,
    created_at                       TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CHECK (ingredient_kind IN ('normal', 'fish', 'seasoning', 'ice')),
    CHECK (solo_energy >= 0),
    CHECK (raw_energy IS NULL OR raw_energy >= 0),
    CHECK (cook_multiplier IS NULL OR cook_multiplier > 0),
    CHECK (
        base_rarity IN
            ('common', 'uncommon', 'rare', 'mystic', 'legendary')
    ),
    CHECK (counts_in_first_four_diversity IN (0, 1)),
    UNIQUE (name),
    UNIQUE (variety_identity)
) STRICT;

CREATE TABLE statuses (
    status_id       INTEGER PRIMARY KEY,
    name            TEXT NOT NULL COLLATE NOCASE,
    UNIQUE (name)
) STRICT;

-- Example source value "Energizing III, Insanity III" becomes two rows here.
CREATE TABLE ingredient_statuses (
    ingredient_id   INTEGER NOT NULL,
    status_id       INTEGER NOT NULL,
    tier            INTEGER NOT NULL,
    display_order   INTEGER NOT NULL DEFAULT 1,

    PRIMARY KEY (ingredient_id, status_id),
    UNIQUE (ingredient_id, display_order),
    CHECK (tier >= 1),
    CHECK (display_order >= 1),

    FOREIGN KEY (ingredient_id)
        REFERENCES ingredients (ingredient_id)
        ON UPDATE CASCADE
        ON DELETE CASCADE,
    FOREIGN KEY (status_id)
        REFERENCES statuses (status_id)
        ON UPDATE CASCADE
        ON DELETE RESTRICT
) STRICT;

-- Each row applies one modifier to one base identity. Modifier combinations
-- are represented by multiple rows for the same ingredient, never by a new
-- ingredient row. rarity_delta is nullable until verified.
CREATE TABLE ingredient_modifiers (
    ingredient_modifier_id   INTEGER PRIMARY KEY,
    ingredient_id            INTEGER NOT NULL,
    modifier_name            TEXT NOT NULL,
    rarity_delta             INTEGER,

    CHECK (
        modifier_name IN ('Small', 'Giant', 'Massive', 'Arcane')
    ),
    CHECK (rarity_delta IS NULL OR rarity_delta BETWEEN -4 AND 4),
    UNIQUE (ingredient_id, modifier_name),

    FOREIGN KEY (ingredient_id)
        REFERENCES ingredients (ingredient_id)
        ON UPDATE CASCADE
        ON DELETE CASCADE
) STRICT;

-- Size modifiers are only valid for fish. Arcane may apply to any base;
-- non-fish Giant items are represented as independent ingredient bases.
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

CREATE INDEX idx_ingredient_import_normalized_ingredient
    ON ingredient_import (normalized_ingredient_id);

CREATE INDEX idx_ingredient_import_batch_source_row
    ON ingredient_import (import_batch, source_row);

CREATE INDEX idx_ingredients_kind_rarity
    ON ingredients (ingredient_kind, base_rarity);

CREATE INDEX idx_ingredient_statuses_status_tier
    ON ingredient_statuses (status_id, tier);

CREATE INDEX idx_ingredient_modifiers_ingredient
    ON ingredient_modifiers (ingredient_id);

COMMIT;
