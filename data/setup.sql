-- Circle Free Fire — jalankan seluruh SQL ini di Supabase SQL Editor.
-- PENTING: kebijakan public read di profiles sengaja membatasi kolom sensitif dari tampilan UI saja,
-- tetapi RLS SELECT di bawah membuat semua kolom profil dapat dibaca publik. Untuk produksi,
-- pisahkan data publik ke view/table khusus agar email/field privat tidak terekspos.
create extension if not exists pgcrypto;

create table if not exists public.profiles (
  id uuid references auth.users on delete cascade primary key,
  username text unique,
  role text not null default 'member' check (role in ('member','admin')),
  avatar text, bio text, nickname_epep text, id_epep text,
  id_epep_public boolean not null default false,
  created_at timestamptz default now()
);
create or replace function public.handle_new_user()
returns trigger language plpgsql security definer set search_path = public as $$
begin
 insert into public.profiles(id,username,role)
 values(new.id,coalesce(new.raw_user_meta_data->>'username',split_part(new.email,'@',1)),'member');
 return new;
end; $$;
drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created after insert on auth.users
for each row execute procedure public.handle_new_user();

create table if not exists public.banners (
 id uuid primary key default gen_random_uuid(), media_url text not null, type text not null default 'image' check(type in ('image','video')),
 title text, urutan int not null default 0, is_active boolean not null default true
);
create table if not exists public.circle_profile (
 id int primary key default 1 check(id=1), description text, founded_year int default 2021, logo text, tagline text
);
insert into public.circle_profile(id,description,founded_year,tagline) values(1,'Komunitas Free Fire yang solid dan aktif.',2021,'Unity in Fire') on conflict(id) do nothing;

create table if not exists public.team_members (
 id uuid primary key default gen_random_uuid(), name text not null, position text, photo text, bio text, urutan int default 0, type text default 'founder' check(type in ('founder','admin'))
);
create table if not exists public.events (
 id uuid primary key default gen_random_uuid(), title text not null, date date, poster text, description text
);
create table if not exists public.gallery (
 id uuid primary key default gen_random_uuid(), media_url text not null, type text default 'image' check(type in ('image','video')), caption text, taken_at date default current_date
);
create table if not exists public.socials (
 id uuid primary key default gen_random_uuid(), platform text not null, url text not null, urutan int default 0
);
insert into public.socials(platform,url,urutan) values
('Discord','https://discord.com',1),('WhatsApp','https://whatsapp.com',2)
on conflict do nothing;

alter table public.profiles enable row level security;
alter table public.banners enable row level security;
alter table public.circle_profile enable row level security;
alter table public.team_members enable row level security;
alter table public.events enable row level security;
alter table public.gallery enable row level security;
alter table public.socials enable row level security;

-- Helper admin: cek role pada profiles. Jangan izinkan user mengubah role sendiri.
create or replace function public.is_circle_admin()
returns boolean language sql stable security definer set search_path=public as $$
 select exists(select 1 from public.profiles p where p.id=auth.uid() and p.role='admin');
$$;

drop policy if exists "profiles public read" on public.profiles;
drop policy if exists "profile own read" on public.profiles;
drop policy if exists "profile own update" on public.profiles;
drop policy if exists "admin manage profiles" on public.profiles;
create policy "profile own read" on public.profiles for select to authenticated using(id=auth.uid() or public.is_circle_admin());
create policy "profile own update" on public.profiles for update to authenticated using(id=auth.uid()) with check(id=auth.uid() and role='member');
create policy "admin manage profiles" on public.profiles for all to authenticated using(public.is_circle_admin()) with check(public.is_circle_admin());
-- Public member showcase: read profiles limited via view below; app should query this view for public list.
create or replace view public.public_member_showcase as
 select id, username, avatar, bio, nickname_epep, id_epep, id_epep_public, created_at
 from public.profiles where role='member';

-- Public read for public content; admin write
do $$ declare t text; begin
 foreach t in array array['banners','circle_profile','team_members','events','gallery','socials'] loop
  execute format('drop policy if exists %I on public.%I',t||'_public_read',t);
  execute format('create policy %I on public.%I for select to anon, authenticated using (true)',t||'_public_read',t);
  execute format('drop policy if exists %I on public.%I',t||'_admin_all',t);
  execute format('create policy %I on public.%I for all to authenticated using (public.is_circle_admin()) with check (public.is_circle_admin())',t||'_admin_all',t);
 end loop;
end $$;

-- Storage: bucket public agar avatar/poster dapat ditampilkan dengan URL publik.
insert into storage.buckets(id,name,public,file_size_limit,allowed_mime_types)
values('uploads','uploads',true,20971520,array['image/jpeg','image/png','image/webp','image/gif','video/mp4','video/webm'])
on conflict(id) do update set public=true;
drop policy if exists "uploads public read" on storage.objects;
create policy "uploads public read" on storage.objects for select using(bucket_id='uploads');
drop policy if exists "uploads authenticated insert" on storage.objects;
create policy "uploads authenticated insert" on storage.objects for insert to authenticated with check(bucket_id='uploads');
drop policy if exists "uploads admin delete" on storage.objects;
create policy "uploads admin delete" on storage.objects for delete to authenticated using(bucket_id='uploads' and public.is_circle_admin());

-- ADMIN PERTAMA:
-- 1) Daftar akun normal melalui register.html dan verifikasi email.
-- 2) Di SQL Editor, jalankan query berikut dengan email akun tersebut:
-- update public.profiles set role='admin' where id=(select id from auth.users where email='EMAIL_ADMIN_KAMU');
-- Jangan menyediakan admin signup publik atau mempercayai role dari user metadata.
