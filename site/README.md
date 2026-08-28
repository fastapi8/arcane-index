# Arcane Index site

This is a static [Evidence](https://evidence.dev/) project. Its source database
is generated from `../research/data/arcane_odyssey_cooking.sqlite`; do not edit
the generated copy under `sources/arcane_index/`.

From this directory:

```sh
npm install
npm run sources
npm run dev
```

Run `npm run data` whenever only the SQLite snapshot needs to be refreshed.
`npm run build` creates the deployable static site in `build/`. The configured
base path is `/arcane-index`, matching a GitHub project-pages deployment.
