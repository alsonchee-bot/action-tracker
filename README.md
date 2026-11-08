# Action Tracker

A single-page meeting action tracker. Add an action with an owner and a due date, tick actions off, and see open, done and overdue counts at a glance. Overdue actions are highlighted in red.

Data is stored in a Supabase table (`public.actions`) and updates appear on every open page in real time.

## Access

The table is open by design: anyone with the site link can read, add, tick and delete actions. The publishable key in `index.html` is meant to be public, so access is controlled by the row-level security policies in `supabase/schema.sql`. If the link needs to be private, switch to Supabase Auth and tighten those policies.

## Run locally

Open `index.html` in a browser. There is no build step. The page loads `supabase-js` from a CDN.

## Deploy to Vercel

1. In Vercel, choose **Add New… > Project** and import this repository.
2. Set **Framework Preset** to **Other**.
3. Leave the build command and output directory empty. Vercel serves `index.html` from the repository root.
4. Select **Deploy**.

`vercel.json` adds basic security headers and clean URLs.

## Database

`supabase/schema.sql` holds the table, row-level security policies and realtime setting. It has already been applied to the project used by `index.html`.
