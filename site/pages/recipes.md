---
title: Recipes
---

<script>
    let activeSimmeredFruitIngredientCount = 2;

    const ingredientCountName = (ingredientCount) =>
        ({ 2: 'Two', 3: 'Three', 4: 'Four', 5: 'Five' })[ingredientCount];

    const compactCount = new Intl.NumberFormat('en', {
        notation: 'compact',
        maximumFractionDigits: 1
    });

    const exactCount = new Intl.NumberFormat('en');
    const simmeredFruitHeatmapDataCache = new Map();

    const getSimmeredFruitHeatmapData = (source, ingredientCount) => {
        if (!simmeredFruitHeatmapDataCache.has(ingredientCount)) {
            simmeredFruitHeatmapDataCache.set(
                ingredientCount,
                source.where(`general_ingredient_count = ${ingredientCount}`)
            );
        }

        return simmeredFruitHeatmapDataCache.get(ingredientCount);
    };

    const simmeredFruitHeatmapOptions = (data) => {
        let rowsByBin;

        const getRowsByBin = () => {
            const rows = Array.from(data ?? []);

            if (!rowsByBin || rowsByBin.size !== rows.length) {
                rowsByBin = new Map(
                    rows.map((row) => [
                        `${row.raw_energy_bin}:${row.final_energy_bin}`,
                        row
                    ])
                );
            }

            return rowsByBin;
        };

        return {
            xAxis: {
                axisTick: {
                    show: false
                },
                axisLabel: {
                    show: false
                }
            },
            yAxis: {
                axisLabel: {
                    interval: (_index, value) => Number(value) % 40 === 0,
                    hideOverlap: false
                }
            },
            tooltip: {
                trigger: 'item',
                confine: true,
                formatter: (params) => {
                    const rawEnergy = Number(params.value[0]);
                    const finalEnergy = Number(params.value[1]);
                    const row = getRowsByBin().get(`${rawEnergy}:${finalEnergy}`);
                    const representedMeals = Number(row?.represented_meal_count ?? 0);
                    const density = Number(params.value[2] ?? row?.log_meal_count ?? 0);

                    return [
                        `<strong>Raw Energy:</strong> ${rawEnergy}–${rawEnergy + 9}`,
                        `<strong>Final Energy:</strong> ${finalEnergy}–${finalEnergy + 9}`,
                        `<strong>Represented meals:</strong> ${exactCount.format(representedMeals)}`,
                        `<strong>Log₁₀ count:</strong> ${density.toFixed(3)}`
                    ].join('<br/>');
                }
            }
        };
    };

    const distributionAxisOptions = {
        xAxis: {
            axisLabel: {
                formatter: (value) => Number(value) % 20 === 0 ? value : ''
            }
        },
        yAxis: {
            axisLabel: {
                formatter: (value) => compactCount.format(value)
            }
        }
    };
</script>

## Simmered Fruit

Simmered Fruit uses at least two fruits and never includes Pumpkin, Sky
Pumpkin, or Stratos Pumpkin. Any remaining general ingredient slots may contain
fruit or seasoning. At maximum cooking level, the dedicated seasoning slot is
optional and may contain one additional seasoning.

Slots 1–4 are interchangeable for the known energy formula. Slot 5 contributes
energy but cannot increase ingredient diversity. The dedicated seasoning slot is
separate from all five general slots.

The results below cover base ingredients at cooking level 10. Arcane variants
are not included. Mechanically equivalent seasoning selections are aggregated
and retained as weighted counts.

```sql simmered_fruit_summary
select
    sum(represented_meal_count) as represented_meals,
    min(minimum_final_energy) as minimum_energy,
    max(maximum_final_energy) as maximum_energy
from arcane_index.simmered_fruit_results
```

<BigValue
    data={simmered_fruit_summary}
    value=represented_meals
    title="Represented Meals"
    fmt=num0
/>

<BigValue
    data={simmered_fruit_summary}
    value=minimum_energy
    title="Minimum Energy"
    fmt=num0
/>

<BigValue
    data={simmered_fruit_summary}
    value=maximum_energy
    title="Maximum Energy"
    fmt=num0
/>

```sql simmered_fruit_heatmap
with slot_counts (general_ingredient_count) as (
    values (2), (3), (4), (5)
), raw_bins as (
    select range as raw_energy_bin from range(10, 331, 10)
), final_bins as (
    select range as final_energy_bin from range(0, 511, 10)
), shared_grid as (
    select
        slot_counts.general_ingredient_count,
        raw_bins.raw_energy_bin,
        final_bins.final_energy_bin
    from slot_counts
    cross join raw_bins
    cross join final_bins
)
select
    shared_grid.general_ingredient_count,
    shared_grid.raw_energy_bin,
    shared_grid.final_energy_bin,
    coalesce(results.represented_meal_count, 0) as represented_meal_count,
    round(log10(coalesce(results.represented_meal_count, 0) + 1), 3)
        as log_meal_count
from shared_grid
left join arcane_index.simmered_fruit_results as results
  on results.general_ingredient_count = shared_grid.general_ingredient_count
 and results.raw_energy_bin = shared_grid.raw_energy_bin
 and results.final_energy_bin = shared_grid.final_energy_bin
order by
    shared_grid.general_ingredient_count,
    shared_grid.raw_energy_bin,
    shared_grid.final_energy_bin
```

The heatmaps group raw and final energy into ten-energy bands, with final-energy
labels every forty points. All four views share the same domains so their shapes
can be compared directly. Darker cells represent more named meals on a
logarithmic scale, which prevents common seasoning permutations from drowning
out less common results. Hover over a cell for more details.

<div class="simmered-fruit-analysis">
    <div class="simmered-fruit-tabs" role="tablist" aria-label="General ingredient count">
        {#each [2, 3, 4, 5] as ingredientCount}
            <button
                type="button"
                role="tab"
                aria-selected={activeSimmeredFruitIngredientCount === ingredientCount}
                class:active={activeSimmeredFruitIngredientCount === ingredientCount}
                on:click={() => activeSimmeredFruitIngredientCount = ingredientCount}
            >
                {ingredientCount} ingredients
            </button>
        {/each}
    </div>

    <div class="simmered-fruit-heatmaps">
        {#each [2, 3, 4, 5] as ingredientCount}
            <div
                class="simmered-fruit-heatmap"
                class:active={activeSimmeredFruitIngredientCount === ingredientCount}
                aria-hidden={activeSimmeredFruitIngredientCount !== ingredientCount}
            >
                <Heatmap
                    data={getSimmeredFruitHeatmapData(simmered_fruit_heatmap, ingredientCount)}
                    x=raw_energy_bin
                    y=final_energy_bin
                    value=log_meal_count
                    xSort=raw_energy_bin
                    ySort=final_energy_bin
                    xAxisPosition="top"
                    valueLabels=false
                    mobileValueLabels=false
                    min=0
                    max=6.6
                    colorScale=blue
                    valueFmt="0.0"
                    title={`${ingredientCountName(ingredientCount)} General Ingredients`}
                    subtitle="Color: log₁₀ represented meals"
                    chartAreaHeight=400
                    echartsOptions={simmeredFruitHeatmapOptions(
                        getSimmeredFruitHeatmapData(simmered_fruit_heatmap, ingredientCount)
                    )}
                    downloadableData=true
                />
            </div>
        {/each}
    </div>
</div>

## Final-energy distribution

```sql simmered_fruit_energy_distribution
with slot_counts (general_ingredient_count) as (
    values (2), (3), (4), (5)
), final_bins as (
    select range as final_energy_bin from range(0, 511, 10)
), represented_meals as (
    select
        general_ingredient_count,
        final_energy_bin,
        sum(represented_meal_count) as represented_meal_count
    from arcane_index.simmered_fruit_results
    group by general_ingredient_count, final_energy_bin
)
select
    slot_counts.general_ingredient_count,
    final_bins.final_energy_bin,
    represented_meals.represented_meal_count
from slot_counts
cross join final_bins
left join represented_meals
  on represented_meals.general_ingredient_count = slot_counts.general_ingredient_count
 and represented_meals.final_energy_bin = final_bins.final_energy_bin
order by slot_counts.general_ingredient_count, final_bins.final_energy_bin
```

Ten-energy final-meal bands for the selected ingredient count. Counts use a
logarithmic scale so both common and uncommon outcomes remain visible.

<div class="simmered-fruit-distribution">
    {#each [2, 3, 4, 5] as ingredientCount}
        <div
            class="simmered-fruit-distribution-chart"
            class:active={activeSimmeredFruitIngredientCount === ingredientCount}
            aria-hidden={activeSimmeredFruitIngredientCount !== ingredientCount}
        >
            <BarChart
                data={simmered_fruit_energy_distribution.where(`general_ingredient_count = ${ingredientCount}`)}
                x=final_energy_bin
                y=represented_meal_count
                yLog=true
                yFmt=num0
                labels=false
                xAxisLabels=true
                xAxisTitle="Final Meal Energy"
                yAxisTitle="Represented Meal Count"
                echartsOptions={distributionAxisOptions}
                chartAreaHeight=300
                downloadableData=true
            />
        </div>
    {/each}
</div>

WIP

<style>
    .simmered-fruit-analysis {
        margin: 1.5rem 0 1rem;
    }

    .simmered-fruit-tabs {
        display: grid;
        grid-template-columns: repeat(4, minmax(0, 1fr));
        margin: 0 0 0.5rem;
        border-bottom: 1px solid var(--color-base-300, #d1d5db);
    }

    .simmered-fruit-tabs button {
        padding: 0.65rem 0.5rem;
        border-bottom: 2px solid transparent;
        color: inherit;
        opacity: 0.65;
    }

    .simmered-fruit-tabs button.active {
        border-bottom-color: currentColor;
        font-weight: 600;
        opacity: 1;
    }

    .simmered-fruit-heatmaps {
        position: relative;
    }

    .simmered-fruit-heatmap {
        position: absolute;
        inset: 0;
        visibility: hidden;
        pointer-events: none;
    }

    .simmered-fruit-heatmap.active {
        position: relative;
        visibility: visible;
        pointer-events: auto;
    }

    .simmered-fruit-distribution {
        position: relative;
        margin: 0.75rem 0 2.5rem;
    }

    .simmered-fruit-distribution-chart {
        position: absolute;
        inset: 0;
        visibility: hidden;
        pointer-events: none;
    }

    .simmered-fruit-distribution-chart.active {
        position: relative;
        visibility: visible;
        pointer-events: auto;
    }
</style>
