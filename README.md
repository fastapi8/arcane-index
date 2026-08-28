# Arcane Index

Arcane Index separates verified cooking research from its static Evidence
website.

## Repository layout

- `research/data/` — canonical SQLite database and ingredient CSV
- `research/migrations/` — database migrations
- `research/scripts/` — normalization and cooking-mechanics reference scripts
- `research/tests/` — regression tests for the mechanics implementation
- `site/` — Evidence pages, source queries, and static-site configuration

The research database is the single source of truth. Evidence reads a generated
snapshot created by `research/scripts/export_site_data.py`; the generated file
is ignored by Git and must not be edited by hand.

## Research commands

Run the regression suite from the repository root:

```sh
python3 -m unittest discover -s research/tests
```

Run the reference calculator with, for example:

```sh
python3 research/scripts/calculate_meal_energy.py \
  Banana "Brown Mushroom" "Raw Bird Meat" \
  --recipe "Balanced Meal"
```

## Site commands

Install the Evidence dependencies once:

```sh
cd site
npm install
```

Then use:

```sh
npm run data       # refresh the generated SQLite snapshot only
npm run sources    # refresh the snapshot and compile Evidence source queries
npm run dev        # refresh data and start local development
npm run build      # refresh data and build the static site into site/build/
```

The contents of `site/build/` can be published to GitHub Pages. The Evidence
base path is set to `/arcane-index` in `site/evidence.config.yaml` for project
pages at `https://<owner>.github.io/arcane-index/`; change or remove it when
using a custom domain. The deployed site has no runtime backend, authentication
layer, or server-side database.
