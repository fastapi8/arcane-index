select
    10 * cast(final_energy / 10 as integer) as final_energy_bin,
    sum(represented_meal_count) as represented_meal_count
from simmered_fruit_results
group by final_energy_bin
order by final_energy_bin
