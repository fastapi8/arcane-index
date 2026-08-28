select
    ingredients.name as ingredient,
    'Fractional energy override' as ruling,
    'Cooking interpolation' as applies_to,
    '40.3125 ≤ R < 40.5555' as detail
from ingredients
where exists (
    select 1
    from ingredient_interpolation_overrides
    where ingredient_interpolation_overrides.ingredient_id = ingredients.ingredient_id
)

union all

select
    ingredients.name as ingredient,
    'Historical modifier warning' as ruling,
    ingredient_modifier_warnings.modifier_name as applies_to,
    'Historical: '
        || ingredient_modifier_warnings.historical_base_cooked_energy
        || ' energy' as detail
from ingredient_modifier_warnings
join ingredients using (ingredient_id)

order by ingredient
