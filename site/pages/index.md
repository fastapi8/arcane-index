---
title: Arcane Index
---

```sql catalog_summary
select
    count(distinct rarity) as rarity_count,
    count(*) filter (where statuses <> '—') as ingredients_with_statuses
from arcane_index.ingredients
```

A data-backed reference for Arcane Odyssey cooking research.

The research SQLite database is the canonical source. This static Evidence site
is built from a generated snapshot of that database and does not require Python,
an API, or a database server at runtime.

<BigValue data={catalog_summary} value=rarity_count title="Rarity tiers" />
<BigValue data={catalog_summary} value=ingredients_with_statuses title="With statuses" />

## Browse the index

- [Ingredients](/ingredients) — searchable ingredient data
- [Recipes](/recipes) — catalog view coming later
- [Mechanics](/mechanics) — research notes coming later
- [Analytics](/analytics) — analysis views coming later
