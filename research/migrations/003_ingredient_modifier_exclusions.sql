-- Confirmed ingredient-specific restrictions on otherwise available modifiers.
PRAGMA foreign_keys = ON;

BEGIN;

CREATE TABLE ingredient_modifier_exclusions (
    ingredient_id  INTEGER NOT NULL,
    modifier_name  TEXT NOT NULL,
    reason         TEXT,

    PRIMARY KEY (ingredient_id, modifier_name),
    CHECK (
        modifier_name IN ('Small', 'Giant', 'Massive', 'Arcane')
    ),

    FOREIGN KEY (ingredient_id)
        REFERENCES ingredients (ingredient_id)
        ON UPDATE CASCADE
        ON DELETE CASCADE
) STRICT;

-- Scalar subqueries plus the NOT NULL constraint make a missing canonical name
-- abort the migration instead of silently omitting a restriction.
INSERT INTO ingredient_modifier_exclusions (
    ingredient_id,
    modifier_name,
    reason
)
VALUES
    ((SELECT ingredient_id FROM ingredients WHERE name = 'Raw Kraken meat'),
     'Arcane', 'Confirmed in-game restriction'),
    ((SELECT ingredient_id FROM ingredients WHERE name = 'Raw Omen meat'),
     'Arcane', 'Confirmed in-game restriction'),
    ((SELECT ingredient_id FROM ingredients WHERE name = 'Raw bird meat'),
     'Arcane', 'Confirmed in-game restriction'),
    ((SELECT ingredient_id FROM ingredients WHERE name = 'Raw rabbit meat'),
     'Arcane', 'Confirmed in-game restriction'),
    ((SELECT ingredient_id FROM ingredients WHERE name = 'Red apple'),
     'Arcane', 'Confirmed in-game restriction'),
    ((SELECT ingredient_id FROM ingredients WHERE name = 'Green apple'),
     'Arcane', 'Confirmed in-game restriction'),
    ((SELECT ingredient_id FROM ingredients WHERE name = 'Festive Cookie Dough'),
     'Arcane', 'Confirmed in-game restriction');

COMMIT;
