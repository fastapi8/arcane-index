---
title: Mechanics
---

Solo Energy is the level-1/base cooked contribution. The imported source table
measured fish, pumpkins, Wheat, and Festive Cookie Dough as perfect/max-level
one-ingredient meals, so those source values include the `1.5×` cooking-quality
bonus. Arcane Index reverses the floored quality stage by searching for the
unique integer satisfying `floor(base solo energy × 1.5) = imported energy`.

The original measurement remains available as `imported_solo_energy` in SQLite.
The Python calculator in `research/scripts/` remains the reference implementation
and regression oracle.
