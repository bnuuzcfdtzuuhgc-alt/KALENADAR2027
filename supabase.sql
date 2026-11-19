-- =========================================================
--  Настенный календарь: база и хранилище в Supabase
--  Запуск: Supabase → SQL Editor → New query → вставить всё → Run
--  Скрипт можно запускать повторно.
-- =========================================================

-- 1) Публичное хранилище для картинок
insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values ('calendar', 'calendar', true, 10485760, array['image/jpeg','image/png','image/webp'])
on conflict (id) do update
  set public = true,
      file_size_limit = excluded.file_size_limit,
      allowed_mime_types = excluded.allowed_mime_types;

-- 2) Список админов (по email). Через API таблицу не прочитать и не изменить.
create table if not exists public.admins (
  email text primary key
);
alter table public.admins enable row level security;

-- 3) Проверка «текущий пользователь — админ?»
create or replace function public.is_admin()
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select exists (
    select 1 from public.admins
    where lower(email) = lower(coalesce(auth.jwt() ->> 'email', ''))
  );
$$;
revoke all on function public.is_admin() from public;
grant execute on function public.is_admin() to anon, authenticated;

-- 4) Листы календаря: год + номер листа (0 = обложка, 1..12 = месяцы)
create table if not exists public.calendar_pages (
  year       int         not null,
  slot       int         not null check (slot between 0 and 12),
  path       text        not null,
  updated_at timestamptz not null default now(),
  primary key (year, slot)
);
alter table public.calendar_pages enable row level security;

drop policy if exists "pages: read all"       on public.calendar_pages;
drop policy if exists "pages: admin insert"   on public.calendar_pages;
drop policy if exists "pages: admin update"   on public.calendar_pages;
drop policy if exists "pages: admin delete"   on public.calendar_pages;

create policy "pages: read all"     on public.calendar_pages for select using (true);
create policy "pages: admin insert" on public.calendar_pages for insert to authenticated with check (public.is_admin());
create policy "pages: admin update" on public.calendar_pages for update to authenticated using (public.is_admin()) with check (public.is_admin());
create policy "pages: admin delete" on public.calendar_pages for delete to authenticated using (public.is_admin());

-- 5) Права на файлы: смотреть может любой (бакет публичный), менять — только админ
drop policy if exists "calendar: admin select" on storage.objects;
drop policy if exists "calendar: admin insert" on storage.objects;
drop policy if exists "calendar: admin update" on storage.objects;
drop policy if exists "calendar: admin delete" on storage.objects;

create policy "calendar: admin select" on storage.objects for select to authenticated
  using (bucket_id = 'calendar' and public.is_admin());
create policy "calendar: admin insert" on storage.objects for insert to authenticated
  with check (bucket_id = 'calendar' and public.is_admin());
create policy "calendar: admin update" on storage.objects for update to authenticated
  using (bucket_id = 'calendar' and public.is_admin())
  with check (bucket_id = 'calendar' and public.is_admin());
create policy "calendar: admin delete" on storage.objects for delete to authenticated
  using (bucket_id = 'calendar' and public.is_admin());

-- 6) ВПИШИ СВОЙ EMAIL (тот же, что у пользователя в Authentication → Users)
insert into public.admins (email) values ('admin@example.com')
on conflict do nothing;
