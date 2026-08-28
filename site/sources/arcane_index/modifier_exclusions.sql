select
    ingredients.name as ingredient,
    ingredient_modifier_exclusions.modifier_name as modifier,
    ingredient_modifier_exclusions.reason
from ingredient_modifier_exclusions
join ingredients using (ingredient_id)
order by modifier, ingredient
