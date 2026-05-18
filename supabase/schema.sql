-- Run this in your Supabase SQL editor

-- Helper function to get the effective family_id for the current user
-- (own user_id, or family_owner from user metadata)
create or replace function auth.family_id() returns uuid as $$
  select coalesce(
    (auth.jwt() -> 'user_metadata' ->> 'family_owner')::uuid,
    auth.uid()
  );
$$ language sql stable;

-- Families table (for sharing between caregivers)
create table if not exists public.families (
  id uuid default gen_random_uuid() primary key,
  owner_id uuid not null references auth.users(id) on delete cascade,
  invite_code text not null unique,
  created_at timestamptz default now(),
  unique(owner_id)
);
alter table public.families enable row level security;
create policy "owner can manage family" on public.families
  for all using (owner_id = auth.uid());
create policy "anyone can look up by invite_code" on public.families
  for select using (true);

-- Child profiles
create table if not exists public.child_profiles (
  id bigserial primary key,
  family_id uuid not null,
  profile_uuid text not null,
  name text not null,
  date_of_birth text not null,
  created_at text not null,
  updated_at text not null,
  unique(family_id, profile_uuid)
);
alter table public.child_profiles enable row level security;
create policy "family members can view profiles" on public.child_profiles for select using (family_id = auth.family_id());
create policy "family members can insert profiles" on public.child_profiles for insert with check (family_id = auth.family_id());
create policy "family members can update profiles" on public.child_profiles for update using (family_id = auth.family_id());
create policy "family members can delete profiles" on public.child_profiles for delete using (family_id = auth.family_id());

-- Activity completions
create table if not exists public.activity_completions (
  id bigserial primary key,
  family_id uuid not null,
  profile_uuid text not null,
  activity_id text not null,
  date_key text not null,
  completed_at text not null,
  updated_at text not null,
  unique(family_id, profile_uuid, date_key)
);
alter table public.activity_completions enable row level security;
create policy "family members can view completions" on public.activity_completions for select using (family_id = auth.family_id());
create policy "family members can insert completions" on public.activity_completions for insert with check (family_id = auth.family_id());
create policy "family members can update completions" on public.activity_completions for update using (family_id = auth.family_id());
create policy "family members can delete completions" on public.activity_completions for delete using (family_id = auth.family_id());

-- Milestone achievements
create table if not exists public.milestone_achievements (
  id bigserial primary key,
  family_id uuid not null,
  profile_uuid text not null,
  milestone_id text not null,
  achieved_date text not null,
  notes text,
  updated_at text not null,
  unique(family_id, profile_uuid, milestone_id)
);
alter table public.milestone_achievements enable row level security;
create policy "family members can view milestones" on public.milestone_achievements for select using (family_id = auth.family_id());
create policy "family members can insert milestones" on public.milestone_achievements for insert with check (family_id = auth.family_id());
create policy "family members can update milestones" on public.milestone_achievements for update using (family_id = auth.family_id());
create policy "family members can delete milestones" on public.milestone_achievements for delete using (family_id = auth.family_id());

-- Unlocked badges
create table if not exists public.unlocked_badges (
  id bigserial primary key,
  family_id uuid not null,
  profile_uuid text not null,
  badge_id text not null,
  unlocked_at text not null,
  updated_at text not null,
  unique(family_id, profile_uuid, badge_id)
);
alter table public.unlocked_badges enable row level security;
create policy "family members can view badges" on public.unlocked_badges for select using (family_id = auth.family_id());
create policy "family members can insert badges" on public.unlocked_badges for insert with check (family_id = auth.family_id());
create policy "family members can update badges" on public.unlocked_badges for update using (family_id = auth.family_id());
create policy "family members can delete badges" on public.unlocked_badges for delete using (family_id = auth.family_id());

-- Growth measurements
create table if not exists public.growth_measurements (
  id bigserial primary key,
  family_id uuid not null,
  profile_uuid text not null,
  local_id integer not null,
  metric text not null,
  value real not null,
  measured_on text not null,
  notes text,
  updated_at text not null,
  unique(family_id, profile_uuid, local_id)
);
alter table public.growth_measurements enable row level security;
create policy "family members can view growth" on public.growth_measurements for select using (family_id = auth.family_id());
create policy "family members can insert growth" on public.growth_measurements for insert with check (family_id = auth.family_id());
create policy "family members can update growth" on public.growth_measurements for update using (family_id = auth.family_id());
create policy "family members can delete growth" on public.growth_measurements for delete using (family_id = auth.family_id());

-- Photo memories (metadata only — image files are device-local)
create table if not exists public.photo_memories (
  id bigserial primary key,
  family_id uuid not null,
  profile_uuid text not null,
  local_id integer not null,
  reference_type text not null,
  reference_id text not null,
  image_path text not null,
  caption text,
  captured_at text not null,
  updated_at text not null,
  unique(family_id, profile_uuid, local_id)
);
alter table public.photo_memories enable row level security;
create policy "family members can view photos" on public.photo_memories for select using (family_id = auth.family_id());
create policy "family members can insert photos" on public.photo_memories for insert with check (family_id = auth.family_id());
create policy "family members can update photos" on public.photo_memories for update using (family_id = auth.family_id());
create policy "family members can delete photos" on public.photo_memories for delete using (family_id = auth.family_id());
