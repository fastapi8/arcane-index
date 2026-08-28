select
    modifier_name,
    case ingredient_kind
        when 'fish' then 'Fish'
        when 'normal' then 'Non-fish ingredients'
        else ingredient_kind
    end as applies_to,
    '×' || printf('%g', energy_multiplier) as energy_multiplier
from ingredient_modifier_rules
order by
    case modifier_name
        when 'Small' then 1
        when 'Giant' then 2
        when 'Massive' then 3
        when 'Arcane' then 4
        else 5
    end,
    ingredient_kind
