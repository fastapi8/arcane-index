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

## Private visit analytics

The deployed site can send invisible page-visit events to
[GoatCounter](https://www.goatcounter.com/). There is no visitor badge or stats
page in the site; analytics are viewed in GoatCounter's authenticated dashboard.
The integration is disabled unless a site code is configured, and GoatCounter
ignores localhost by default.

To enable it:

1. Create a GoatCounter site and set **Dashboard viewable by** to
   **Logged-in users only** in its settings.
2. In the GitHub repository, open **Settings → Secrets and variables → Actions →
   Variables** and add `GOATCOUNTER_CODE`. Set it to the subdomain portion of
   the GoatCounter URL (for `https://arcane-index.goatcounter.com`, use
   `arcane-index`).
3. Run the Pages workflow again, or push to `main`.

For a local production build, pass the same value as
`VITE_GOATCOUNTER_CODE`, for example:

```sh
VITE_GOATCOUNTER_CODE=arcane-index npm run build
```

The site code and collection endpoint are necessarily visible in the browser,
but the counts and dashboard remain private. Do not enable GoatCounter's public
visitor-counter setting.
