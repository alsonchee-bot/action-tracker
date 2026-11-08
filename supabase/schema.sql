-- Schema for the Action Tracker (already applied to the Supabase project).
create table public.actions (
  id uuid primary key default gen_random_uuid(),
  text text not null check (char_length(btrim(text)) between 1 and 200),
  owner text not null check (char_length(btrim(owner)) between 1 and 60),
  due date not null,
  done boolean not null default false,
  created_at timestamptz not null default now()
);

create index actions_owner_idx on public.actions (lower(owner));

alter table public.actions enable row level security;

-- Open access by design: anyone with the site link can read and change actions.
create policy "Anyone can read actions" on public.actions
  for select to anon, authenticated using (true);
create policy "Anyone can add actions" on public.actions
  for insert to anon, authenticated with check (true);
create policy "Anyone can update actions" on public.actions
  for update to anon, authenticated using (true) with check (true);
create policy "Anyone can delete actions" on public.actions
  for delete to anon, authenticated using (true);

alter publication supabase_realtime add table public.actions;
