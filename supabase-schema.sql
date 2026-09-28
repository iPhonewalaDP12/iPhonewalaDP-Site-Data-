create extension if not exists pgcrypto;

create table if not exists public.content_items (
  id uuid primary key default gen_random_uuid(),
  title text not null,
  url text not null,
  type text not null check (type in ('reel','tutorial')),
  published boolean not null default true,
  sort_order integer not null default 0,
  created_at timestamptz not null default now()
);

create table if not exists public.admin_users (
  user_id uuid primary key references auth.users(id) on delete cascade,
  created_at timestamptz not null default now()
);

create or replace function public.is_admin()
returns boolean
language sql
security definer
set search_path = public
as $$
  select exists (
    select 1
    from public.admin_users
    where user_id = auth.uid()
  );
$$;

alter table public.content_items enable row level security;
alter table public.admin_users enable row level security;

drop policy if exists "Public can read published content"
on public.content_items;

create policy "Public can read published content"
on public.content_items
for select
to anon, authenticated
using (published = true or public.is_admin());

drop policy if exists "Admins can insert content"
on public.content_items;

create policy "Admins can insert content"
on public.content_items
for insert
to authenticated
with check (public.is_admin());

drop policy if exists "Admins can update content"
on public.content_items;

create policy "Admins can update content"
on public.content_items
for update
to authenticated
using (public.is_admin())
with check (public.is_admin());

drop policy if exists "Admins can delete content"
on public.content_items;

create policy "Admins can delete content"
on public.content_items
for delete
to authenticated
using (public.is_admin());

drop policy if exists "Admins can read own admin row"
on public.admin_users;

create policy "Admins can read own admin row"
on public.admin_users
for select
to authenticated
using (user_id = auth.uid());
