create table public.user_data (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  data_type text not null check (
    data_type in ('pantry', 'groceries', 'recipes', 'saved_recipes', 'meal_plans')
  ),
  payload jsonb not null default '[]'::jsonb,
  amount text,
  unit text,
  updated_at timestamptz not null default now(),
  deleted_at timestamptz,
  unique (user_id, data_type)
);

alter table public.user_data enable row level security;

create policy "Users can read their own data"
on public.user_data for select to authenticated
using (auth.uid() = user_id);

create policy "Users can create their own data"
on public.user_data for insert to authenticated
with check (auth.uid() = user_id);

create policy "Users can update their own data"
on public.user_data for update to authenticated
using (auth.uid() = user_id)
with check (auth.uid() = user_id);

create policy "Users can delete their own data"
on public.user_data for delete to authenticated
using (auth.uid() = user_id);

insert into storage.buckets (id, name, public)
values ('profile-photos', 'profile-photos', false)
on conflict (id) do nothing;

create policy "Users can read their own profile photo"
on storage.objects for select to authenticated
using (bucket_id = 'profile-photos' and (storage.foldername(name))[1] = auth.uid()::text);

create policy "Users can upload their own profile photo"
on storage.objects for insert to authenticated
with check (bucket_id = 'profile-photos' and (storage.foldername(name))[1] = auth.uid()::text);

create policy "Users can update their own profile photo"
on storage.objects for update to authenticated
using (bucket_id = 'profile-photos' and (storage.foldername(name))[1] = auth.uid()::text)
with check (bucket_id = 'profile-photos' and (storage.foldername(name))[1] = auth.uid()::text);

create policy "Users can delete their own profile photo"
on storage.objects for delete to authenticated
using (bucket_id = 'profile-photos' and (storage.foldername(name))[1] = auth.uid()::text);
