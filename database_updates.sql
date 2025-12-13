-- Run this in your Supabase SQL Editor

create table public.app_versions (
  id uuid default gen_random_uuid() primary key,
  created_at timestamp with time zone default timezone('utc'::text, now()) not null,
  version text not null,
  build_number int not null,
  download_url text not null,
  force_update boolean default false,
  description text,
  platform text not null check (platform in ('android', 'ios'))
);

-- Enable RLS
alter table public.app_versions enable row level security;

-- Policy: Everyone can read
create policy "Allow public read access"
on public.app_versions
for select
to public
using (true);

-- Policy: Only admins can insert/update (assuming you have an admin role or similar, adapting to your system)
-- For now, allowing authenticated users with admin role, or you can insert directly via Supabase Dashboard
create policy "Allow admin insert"
on public.app_versions
for insert
to authenticated
with check (
  exists (
    select 1 from public.users 
    where users.id = auth.uid() and users.role = 'admin'
  )
);
