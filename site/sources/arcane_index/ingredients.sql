with ordered_statuses as (
    select
        ingredient_statuses.ingredient_id,
        ingredient_statuses.display_order,
        statuses.name || ' ' || case ingredient_statuses.tier
            when 1 then 'I'
            when 2 then 'II'
            when 3 then 'III'
            when 4 then 'IV'
            when 5 then 'V'
            else cast(ingredient_statuses.tier as text)
        end as status_label
    from ingredient_statuses
    join statuses
      on statuses.status_id = ingredient_statuses.status_id
), status_summary as (
    select ingredient_id, group_concat(status_label, ', ') as statuses
    from (
        select ingredient_id, status_label
        from ordered_statuses
        order by ingredient_id, display_order
    )
    group by ingredient_id
)
select
    ingredients.ingredient_id,
    ingredients.name,
    ingredients.base_rarity as rarity,
    ingredients.solo_energy,
    ingredients.imported_solo_energy,
    coalesce(ingredients.solo_dish_type, '—') as dish_type,
    ingredients.ingredient_kind,
    coalesce(status_summary.statuses, '—') as statuses
from ingredients
left join status_summary
  on status_summary.ingredient_id = ingredients.ingredient_id
order by ingredients.name
