---
title: Ingredients
---

Search Arcane Odyssey's ingredients. Special modifiers are excluded by default
to make searching easier.

```sql ingredient_catalog
select
    name,
    rarity,
    solo_energy,
    dish_type,
    statuses
from arcane_index.ingredients
order by name
```

<div class="ingredient-catalog">
    <DataTable data={ingredient_catalog} search=true rows=25>
        <Column id=name title="Ingredient" width="24%" />
        <Column id=rarity title="Rarity" width="13%" />
        <Column id=solo_energy title="Solo Energy" fmt=num0 width="13%" />
        <Column id=dish_type title="Dish Type" width="25%" />
        <Column id=statuses title="Statuses" width="25%" />
    </DataTable>
</div>

## Modifiers

Modifiers are derived variants that do not count as unique identities. Their
energy multipliers apply to an ingredient's base contribution.

```sql modifier_rules
select
    modifier_name,
    applies_to,
    energy_multiplier
from arcane_index.modifier_rules
```

<DataTable data={modifier_rules} rows=10>
    <Column id=modifier_name title="Modifier" />
    <Column id=applies_to title="Applies To" />
    <Column id=energy_multiplier title="Energy Multiplier" />
</DataTable>

### Ingredient-specific rulings

Ingredient-specific exceptions that do not follow the general rules above.

```sql special_rulings
select
    ingredient as "Ingredient",
    ruling as "Ruling",
    applies_to as "Applies To",
    detail as "Details"
from arcane_index.ingredient_special_rulings
```

<DataTable data={special_rulings} rows=10 />

### Arcane exclusions

These ingredients cannot receive the Arcane modifier.

```sql modifier_exclusions
select
    ingredient,
    reason
from arcane_index.modifier_exclusions
```

<DataTable data={modifier_exclusions} rows=10>
    <Column id=ingredient title="Ingredient" />
    <Column id=reason title="Reason" />
</DataTable>
