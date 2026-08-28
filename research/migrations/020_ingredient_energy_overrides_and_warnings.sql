-- Verified ingredient-specific interpolation overrides and non-blocking warnings
-- for historical modifier anomalies.
PRAGMA foreign_keys = ON;

BEGIN IMMEDIATE;

CREATE TABLE ingredient_interpolation_overrides (
    ingredient_id       INTEGER NOT NULL,
    unique_count        INTEGER NOT NULL,
    contribution_energy INTEGER NOT NULL,
    verification_status TEXT NOT NULL,
    notes               TEXT NOT NULL,

    PRIMARY KEY (ingredient_id, unique_count),
    CHECK (unique_count BETWEEN 1 AND 4),
    CHECK (contribution_energy >= 0),
    CHECK (verification_status IN ('verified', 'historical', 'unverified')),

    FOREIGN KEY (ingredient_id)
        REFERENCES ingredients (ingredient_id)
        ON UPDATE CASCADE
        ON DELETE CASCADE
) STRICT;

WITH tuna_curve (unique_count, contribution_energy) AS (
    VALUES (1, 40), (2, 43), (3, 45), (4, 48)
)
INSERT INTO ingredient_interpolation_overrides (
    ingredient_id,
    unique_count,
    contribution_energy,
    verification_status,
    notes
)
SELECT
    (SELECT ingredient_id FROM ingredients WHERE name = 'Tuna'),
    tuna_curve.unique_count,
    tuna_curve.contribution_energy,
    'verified',
    'Verified Tuna contribution curve. Use this value instead of the standard cooking-multiplier interpolation for the corresponding number of unique identities in slots 1-4.'
FROM tuna_curve;

CREATE TABLE ingredient_modifier_warnings (
    ingredient_id                    INTEGER NOT NULL,
    modifier_name                    TEXT NOT NULL,
    warning_code                     TEXT NOT NULL,
    severity                         TEXT NOT NULL,
    historical_base_cooked_energy    INTEGER,
    current_verification_status      TEXT NOT NULL,
    warning_text                     TEXT NOT NULL,

    PRIMARY KEY (ingredient_id, modifier_name, warning_code),
    CHECK (modifier_name IN ('Small', 'Giant', 'Massive', 'Arcane')),
    CHECK (severity IN ('info', 'warning')),
    CHECK (
        historical_base_cooked_energy IS NULL
        OR historical_base_cooked_energy >= 0
    ),
    CHECK (
        current_verification_status IN
            ('verified_current', 'historical_bug', 'unverified_current')
    ),

    FOREIGN KEY (ingredient_id)
        REFERENCES ingredients (ingredient_id)
        ON UPDATE CASCADE
        ON DELETE CASCADE
) STRICT;

INSERT INTO ingredient_modifier_warnings (
    ingredient_id,
    modifier_name,
    warning_code,
    severity,
    historical_base_cooked_energy,
    current_verification_status,
    warning_text
)
VALUES (
    (SELECT ingredient_id FROM ingredients WHERE name = 'Colossal Squid'),
    'Massive',
    'historical-massive-colossal-squid-anomaly',
    'warning',
    560,
    'unverified_current',
    'Historical Massive Colossal Squid data reported exactly 560 base cooked energy, which is incompatible with the generic 3x Massive model. The item was known to be bugged at that time and current behavior is unverified because the variant is exceptionally rare. Massive remains allowed; do not treat this warning as an exclusion or active override.'
);

COMMIT;
