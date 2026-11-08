# Action Tracker

A single-page meeting action tracker. Add an action with an owner and a due date, tick actions off, and see open, done and overdue counts at a glance. Overdue actions are highlighted in red.

Data is saved in the browser's local storage, so each person sees their own list on their own device.

## Run locally

Open `index.html` in a browser. There is no build step and no dependencies.

## Deploy to Vercel

1. In Vercel, choose **Add New… > Project** and import this repository.
2. Set **Framework Preset** to **Other**.
3. Leave the build command and output directory empty. Vercel serves `index.html` from the repository root.
4. Select **Deploy**.

`vercel.json` adds basic security headers and clean URLs.
