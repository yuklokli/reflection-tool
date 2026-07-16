-- ============================================================================
-- Field Notes — Reflection : Supabase schema + Row-Level Security
-- Run this in your Supabase project's SQL Editor (once).
-- Every row is scoped to the signed-in user, so only you can see your data.
-- ============================================================================

-- FIELD NOTES ---------------------------------------------------------------
create table if not exists public.field_notes (
  id          uuid primary key,
  user_id     uuid not null default auth.uid() references auth.users(id) on delete cascade,
  title       text not null,
  content     text,
  category    text not null,
  tags        text[] not null default '{}',
  created_at  timestamptz not null default now()
);

-- OUTPUTS (weekly reflection) ----------------------------------------------
create table if not exists public.outputs (
  id          uuid primary key,
  user_id     uuid not null default auth.uid() references auth.users(id) on delete cascade,
  title       text not null,
  content     text,
  categories  text[] not null default '{}',
  created_at  timestamptz not null default now()
);

-- OUTPUT ⇄ NOTE links (many-to-many) ---------------------------------------
create table if not exists public.output_note_links (
  id            uuid primary key,
  output_id     uuid not null references public.outputs(id) on delete cascade,
  field_note_id uuid not null references public.field_notes(id) on delete cascade
);

-- NEXT STEPS ----------------------------------------------------------------
create table if not exists public.next_steps (
  id          uuid primary key,
  user_id     uuid not null default auth.uid() references auth.users(id) on delete cascade,
  output_id   uuid not null references public.outputs(id) on delete cascade,
  text        text not null,
  created_at  timestamptz not null default now()
);

-- FOLLOW-UP NOTES on a next step -------------------------------------------
create table if not exists public.next_step_followups (
  id           uuid primary key,
  next_step_id uuid not null references public.next_steps(id) on delete cascade,
  text         text not null,
  created_at   timestamptz not null default now()
);

-- Helpful indexes
create index if not exists idx_notes_user   on public.field_notes(user_id, created_at desc);
create index if not exists idx_outputs_user on public.outputs(user_id, created_at desc);
create index if not exists idx_steps_output on public.next_steps(output_id);
create index if not exists idx_links_output on public.output_note_links(output_id);
create index if not exists idx_fu_step      on public.next_step_followups(next_step_id);

-- ============================================================================
-- Row-Level Security
-- ============================================================================
alter table public.field_notes         enable row level security;
alter table public.outputs             enable row level security;
alter table public.output_note_links   enable row level security;
alter table public.next_steps          enable row level security;
alter table public.next_step_followups enable row level security;

-- Direct-owner tables: owner = auth.uid()
create policy "own field_notes" on public.field_notes
  for all using (auth.uid() = user_id) with check (auth.uid() = user_id);
create policy "own outputs" on public.outputs
  for all using (auth.uid() = user_id) with check (auth.uid() = user_id);
create policy "own next_steps" on public.next_steps
  for all using (auth.uid() = user_id) with check (auth.uid() = user_id);

-- Child tables: ownership inferred through the parent row
create policy "own output_note_links" on public.output_note_links
  for all using (
    exists (select 1 from public.outputs o where o.id = output_id and o.user_id = auth.uid())
  ) with check (
    exists (select 1 from public.outputs o where o.id = output_id and o.user_id = auth.uid())
  );

create policy "own next_step_followups" on public.next_step_followups
  for all using (
    exists (select 1 from public.next_steps s where s.id = next_step_id and s.user_id = auth.uid())
  ) with check (
    exists (select 1 from public.next_steps s where s.id = next_step_id and s.user_id = auth.uid())
  );
