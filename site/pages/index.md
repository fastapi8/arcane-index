---
title: Arcane Index
---

```sql catalog_summary
select
    count(distinct rarity) as rarity_count,
    count(*) filter (where statuses <> '—') as ingredients_with_statuses
from arcane_index.ingredients
```

## License

Except where otherwise noted, Arcane Index’s original data compilation, research, analysis, and written documentation are licensed under the [Creative Commons Attribution 4.0 International License](https://creativecommons.org/licenses/by/4.0/). You may share and adapt this material, including commercially, provided you give appropriate credit to Arcane Index and indicate any changes made.

Third-party material, including Arcane Odyssey game assets, screenshots, trademarks, and other content owned by their respective rights holders, is not covered by this license.

Suggested attribution: “Data and analysis from Arcane Index by fastapi8, ReakToppom, and KozyAtmosphere — CC BY 4.0.”

<!-- <BigValue data={catalog_summary} value=rarity_count title="Rarity tiers" />
<BigValue data={catalog_summary} value=ingredients_with_statuses title="With statuses" />

## Important links

- [Ingredients](/ingredients)
- [Recipes](/recipes)
- [Mechanics](/mechanics)
- [Analytics](/analytics) -->
