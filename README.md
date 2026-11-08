# Action Tracker

A single-page meeting action tracker. Add an action with an owner and a due date, tick actions off, and see open, done and overdue counts at a glance. Overdue actions are highlighted in red.

Data lives in Supabase and updates appear on every signed-in page in real time.

## Sign-in and users

- People sign in with a username and password. Passwords are stored by Supabase Auth in `auth.users`.
- Supabase Auth needs an email, so each username maps to an internal address (`username@actiontracker.example`) that never receives mail.
- Each user has a row in `public.profiles` (username, display name, role).
- **Admins** get a **Users** tab to add users with an initial password and to reset passwords. **Members** can use actions and change their own password from the **Account** tab.
- Actions can only be read or changed by signed-in users, and each action's Owner is one of the users.

## Run locally

Open `index.html` in a browser. There is no build step. The page loads `supabase-js` from a CDN.

## Deploy to Vercel

1. In Vercel, choose **Add New… > Project** and import this repository.
2. Set **Framework Preset** to **Other**.
3. Leave the build command and output directory empty. Vercel serves `index.html` from the repository root.
4. Select **Deploy**.

`vercel.json` adds basic security headers and clean URLs.

## Database

`supabase/schema.sql` holds the tables, row-level security policies, admin functions and realtime setup. It has already been applied to the project used by `index.html`. It creates no users; the first admin has to be created in Supabase directly, and admins add everyone else from the app.

The publishable key in `index.html` is meant to be public. Access is controlled by the row-level security policies and the admin checks in the database functions.
