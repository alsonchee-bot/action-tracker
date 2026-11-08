-- Schema for the Action Tracker. This is already applied to the Supabase project.
-- It does not create any users: sample users are seeded separately, and admins add
-- more from the Users tab (which calls admin_create_user below).

-- Profiles: one row per Supabase Auth user (auth.users), with username, name and role.
create table public.profiles (
  id uuid primary key references auth.users (id) on delete cascade,
  username text not null unique check (username ~ '^[a-z0-9._-]{2,30}$'),
  display_name text not null check (char_length(btrim(display_name)) between 1 and 60),
  role text not null default 'member' check (role in ('admin', 'member')),
  created_at timestamptz not null default now()
);

alter table public.profiles enable row level security;
revoke all on public.profiles from anon;

-- Signed-in users can read profiles (for the Owner list). Nobody can write directly;
-- changes go through the admin functions below.
create policy "Signed-in users can read profiles" on public.profiles
  for select to authenticated using (true);

-- Actions, each owned by a user.
create table public.actions (
  id uuid primary key default gen_random_uuid(),
  text text not null check (char_length(btrim(text)) between 1 and 200),
  owner_id uuid not null references public.profiles (id) on delete restrict,
  due date not null,
  done boolean not null default false,
  created_at timestamptz not null default now()
);

create index actions_owner_id_idx on public.actions (owner_id);

alter table public.actions enable row level security;
revoke all on public.actions from anon;

create policy "Signed-in users can read actions" on public.actions
  for select to authenticated using (true);
create policy "Signed-in users can add actions" on public.actions
  for insert to authenticated with check (true);
create policy "Signed-in users can update actions" on public.actions
  for update to authenticated using (true) with check (true);
create policy "Signed-in users can delete actions" on public.actions
  for delete to authenticated using (true);

-- Admin check, used only inside the admin functions below.
create or replace function public.is_admin()
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select exists (
    select 1 from public.profiles
    where id = (select auth.uid()) and role = 'admin'
  );
$$;

-- Admin only: add a user with an initial password. Usernames map to an internal
-- address (username@actiontracker.example) because Supabase Auth needs an email.
create or replace function public.admin_create_user(
  p_username text,
  p_display_name text,
  p_password text,
  p_role text default 'member'
)
returns public.profiles
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_username text := lower(btrim(p_username));
  v_name text := btrim(p_display_name);
  v_email text;
  v_id uuid := gen_random_uuid();
  v_profile public.profiles;
begin
  if not public.is_admin() then
    raise exception 'Only admins can add users.' using errcode = '42501';
  end if;
  if v_username is null or v_username !~ '^[a-z0-9._-]{2,30}$' then
    raise exception 'Username must be 2 to 30 characters: letters, numbers, dots, dashes or underscores.' using errcode = '22023';
  end if;
  if v_name is null or char_length(v_name) not between 1 and 60 then
    raise exception 'Enter a display name of up to 60 characters.' using errcode = '22023';
  end if;
  if p_role is null or p_role not in ('admin', 'member') then
    raise exception 'Role must be admin or member.' using errcode = '22023';
  end if;
  if p_password is null or char_length(p_password) < 6 then
    raise exception 'Password must be at least 6 characters.' using errcode = '22023';
  end if;

  v_email := v_username || '@actiontracker.example';
  if exists (select 1 from public.profiles where username = v_username)
     or exists (select 1 from auth.users where lower(email) = v_email) then
    raise exception 'That username is already taken.' using errcode = '23505';
  end if;

  insert into auth.users (
    instance_id, id, aud, role, email, encrypted_password, email_confirmed_at,
    raw_app_meta_data, raw_user_meta_data, created_at, updated_at,
    confirmation_token, recovery_token, email_change_token_new, email_change
  ) values (
    '00000000-0000-0000-0000-000000000000', v_id, 'authenticated', 'authenticated', v_email,
    extensions.crypt(p_password, extensions.gen_salt('bf', 10)), now(),
    '{"provider":"email","providers":["email"]}'::jsonb,
    jsonb_build_object('username', v_username, 'display_name', v_name),
    now(), now(), '', '', '', ''
  );

  insert into auth.identities (id, user_id, provider_id, identity_data, provider, last_sign_in_at, created_at, updated_at)
  values (
    gen_random_uuid(), v_id, v_id::text,
    jsonb_build_object('sub', v_id::text, 'email', v_email, 'email_verified', true, 'phone_verified', false),
    'email', now(), now(), now()
  );

  insert into public.profiles (id, username, display_name, role)
  values (v_id, v_username, v_name, p_role)
  returning * into v_profile;

  return v_profile;
end;
$$;

-- Admin only: set a new password for a user and sign them out everywhere.
create or replace function public.admin_reset_password(p_user_id uuid, p_password text)
returns void
language plpgsql
security definer
set search_path = ''
as $$
begin
  if not public.is_admin() then
    raise exception 'Only admins can reset passwords.' using errcode = '42501';
  end if;
  if p_password is null or char_length(p_password) < 6 then
    raise exception 'Password must be at least 6 characters.' using errcode = '22023';
  end if;

  update auth.users
  set encrypted_password = extensions.crypt(p_password, extensions.gen_salt('bf', 10)),
      updated_at = now()
  where id = p_user_id;

  if not found then
    raise exception 'User not found.' using errcode = 'P0002';
  end if;

  delete from auth.sessions where user_id = p_user_id;
end;
$$;

revoke execute on function public.is_admin() from public, anon, authenticated;
revoke execute on function public.admin_create_user(text, text, text, text) from public, anon;
revoke execute on function public.admin_reset_password(uuid, text) from public, anon;
grant execute on function public.admin_create_user(text, text, text, text) to authenticated;
grant execute on function public.admin_reset_password(uuid, text) to authenticated;

-- Live updates
alter publication supabase_realtime add table public.actions;
alter publication supabase_realtime add table public.profiles;
