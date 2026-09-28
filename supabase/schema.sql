-- Fitly Studio starter schema for Supabase
-- Run in Supabase SQL Editor. Never expose the service_role key in browser code.
create extension if not exists pgcrypto;

create table if not exists public.profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  display_name text,
  role text not null default 'user' check (role in ('user','admin')),
  created_at timestamptz not null default now()
);
create table if not exists public.products (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  category text not null,
  description text not null default '',
  image_url text,
  price numeric(10,2),
  color text,
  active boolean not null default true,
  created_at timestamptz not null default now()
);
create table if not exists public.tryon_sessions (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  product_id uuid references public.products(id) on delete set null,
  status text not null default 'queued' check (status in ('queued','processing','completed','failed')),
  input_image_path text,
  result_image_path text,
  created_at timestamptz not null default now()
);
create table if not exists public.reports (
  id uuid primary key default gen_random_uuid(),
  user_id uuid references auth.users(id) on delete set null,
  session_id uuid references public.tryon_sessions(id) on delete set null,
  message text not null,
  status text not null default 'open' check (status in ('open','reviewing','resolved')),
  created_at timestamptz not null default now()
);

create or replace function public.is_admin()
returns boolean language sql stable security definer
set search_path = public
as $$ select exists (select 1 from public.profiles p where p.id = auth.uid() and p.role = 'admin') $$;

alter table public.profiles enable row level security;
alter table public.products enable row level security;
alter table public.tryon_sessions enable row level security;
alter table public.reports enable row level security;

create policy "profiles read own or admin" on public.profiles for select to authenticated
using (id = auth.uid() or public.is_admin());
create policy "users update own profile" on public.profiles for update to authenticated
using (id = auth.uid()) with check (id = auth.uid() and role = 'user');
create policy "admins manage profiles" on public.profiles for all to authenticated
using (public.is_admin()) with check (public.is_admin());

create policy "public read active products" on public.products for select
using (active = true or public.is_admin());
create policy "admins manage products" on public.products for all to authenticated
using (public.is_admin()) with check (public.is_admin());

create policy "users read own sessions or admin" on public.tryon_sessions for select to authenticated
using (user_id = auth.uid() or public.is_admin());
create policy "users create own sessions" on public.tryon_sessions for insert to authenticated
with check (user_id = auth.uid());
create policy "admins manage sessions" on public.tryon_sessions for all to authenticated
using (public.is_admin()) with check (public.is_admin());

create policy "users read own reports or admin" on public.reports for select to authenticated
using (user_id = auth.uid() or public.is_admin());
create policy "users create reports" on public.reports for insert to authenticated
with check (user_id = auth.uid());
create policy "admins manage reports" on public.reports for all to authenticated
using (public.is_admin()) with check (public.is_admin());

-- Create a profile automatically when someone registers.
create or replace function public.handle_new_user()
returns trigger language plpgsql security definer set search_path = public
as $$ begin
  insert into public.profiles (id, display_name)
  values (new.id, coalesce(new.raw_user_meta_data->>'display_name',''));
  return new;
end; $$;
drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created after insert on auth.users
for each row execute procedure public.handle_new_user();

-- Promote the intended administrator manually from the Supabase SQL editor:
-- update public.profiles set role = 'admin'
-- where id = (select id from auth.users where email = 'YOUR_ADMIN_EMAIL');
