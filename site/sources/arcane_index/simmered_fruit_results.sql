select
    general_ingredient_count,
    10 * cast(raw_energy_sum / 10 as integer) as raw_energy_bin,
    10 * cast(final_energy / 10 as integer) as final_energy_bin,
    sum(represented_meal_count) as represented_meal_count,
    count(*) as mechanical_classes,
    min(final_energy) as minimum_final_energy,
    max(final_energy) as maximum_final_energy
from simmered_fruit_results
group by general_ingredient_count, raw_energy_bin, final_energy_bin
order by general_ingredient_count, raw_energy_bin, final_energy_bin
