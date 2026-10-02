-- 모아보드 데이터베이스
-- Supabase 대시보드 → SQL Editor → New query 에 통째로 붙여 넣고 Run 을 누릅니다.
-- 여러 번 실행해도 오류 없이 같은 결과가 나옵니다.

-- 1. 보드 -------------------------------------------------------------
create table if not exists public.boards (
  id          uuid primary key default gen_random_uuid(),
  owner       uuid not null default auth.uid() references auth.users (id) on delete cascade,
  title       text not null check (char_length(title) between 1 and 60),
  description text check (char_length(description) <= 200),
  created_at  timestamptz not null default now()
);
create index if not exists boards_owner_idx on public.boards (owner);

-- 2. 카드 -------------------------------------------------------------
create table if not exists public.cards (
  id          uuid primary key default gen_random_uuid(),
  board_id    uuid not null references public.boards (id) on delete cascade,
  author_name text not null check (char_length(author_name) between 1 and 20 and btrim(author_name) <> ''),
  content     text not null check (char_length(content) between 1 and 1000 and btrim(content) <> ''),
  color       text,
  -- 사진 경로는 "<보드 id>/<파일 id>.jpg" 모양만 받는다
  image_path  text check (image_path is null or image_path ~ '^[0-9a-f-]{36}/[0-9a-z-]+\.jpg$'),
  created_at  timestamptz not null default now()
);
create index if not exists cards_board_idx on public.cards (board_id, created_at desc);

-- 3. 접근 권한 ----------------------------------------------------------
-- anon = 로그인하지 않은 방문자, authenticated = 로그인한 사람
grant select on public.boards to anon;
grant select, insert, update, delete on public.boards to authenticated;
grant select, insert on public.cards to anon;
grant select, insert, delete on public.cards to authenticated;

alter table public.boards enable row level security;
alter table public.cards  enable row level security;

-- 보드: 링크를 아는 사람은 누구나 본다. 만들기·고치기·지우기는 주인만.
drop policy if exists boards_select_all on public.boards;
create policy boards_select_all on public.boards
  for select to anon, authenticated using (true);

drop policy if exists boards_insert_owner on public.boards;
create policy boards_insert_owner on public.boards
  for insert to authenticated with check (owner = (select auth.uid()));

drop policy if exists boards_update_owner on public.boards;
create policy boards_update_owner on public.boards
  for update to authenticated
  using (owner = (select auth.uid())) with check (owner = (select auth.uid()));

drop policy if exists boards_delete_owner on public.boards;
create policy boards_delete_owner on public.boards
  for delete to authenticated using (owner = (select auth.uid()));

-- 카드: 누구나 보고 누구나 붙인다(길이는 위 check 제약이 막는다). 지우기는 보드 주인만.
drop policy if exists cards_select_all on public.cards;
create policy cards_select_all on public.cards
  for select to anon, authenticated using (true);

drop policy if exists cards_insert_all on public.cards;
create policy cards_insert_all on public.cards
  for insert to anon, authenticated with check (true);

drop policy if exists cards_delete_board_owner on public.cards;
create policy cards_delete_board_owner on public.cards
  for delete to authenticated
  using (exists (
    select 1 from public.boards b
    where b.id = cards.board_id and b.owner = (select auth.uid())
  ));

-- 4. 사진 저장소 --------------------------------------------------------
insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values ('card-images', 'card-images', true, 5242880, array['image/jpeg', 'image/png', 'image/webp'])
on conflict (id) do nothing;

-- ponytail: 로그인 없이 누구나 사진을 올릴 수 있고 횟수 제한이 없다. 수업에서는 괜찮지만,
--           실제로 공개하기 전에 보드별 업로드 횟수 제한(rate limit)을 붙인다.
drop policy if exists card_images_insert_all on storage.objects;
create policy card_images_insert_all on storage.objects
  for insert to anon, authenticated with check (bucket_id = 'card-images');

drop policy if exists card_images_select_all on storage.objects;
create policy card_images_select_all on storage.objects
  for select to anon, authenticated using (bucket_id = 'card-images');

-- 보드 주인은 카드를 지울 때 그 카드의 사진도 지운다 (폴더 이름 = 보드 id)
drop policy if exists card_images_delete_board_owner on storage.objects;
create policy card_images_delete_board_owner on storage.objects
  for delete to authenticated
  using (
    bucket_id = 'card-images'
    and exists (
      select 1 from public.boards b
      where b.id::text = (storage.foldername(name))[1] and b.owner = (select auth.uid())
    )
  );

-- 5. 실시간 ------------------------------------------------------------
-- 카드가 붙거나 지워지면 보드를 보고 있는 모두에게 알린다.
-- 한 번만 추가되도록 이미 들어 있는지 먼저 확인한다.
do $$
begin
  if not exists (
    select 1 from pg_publication_tables
    where pubname = 'supabase_realtime' and schemaname = 'public' and tablename = 'cards'
  ) then
    alter publication supabase_realtime add table public.cards;
  end if;
end $$;
