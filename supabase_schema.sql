-- ====================================================================
-- Схема базы данных Supabase для проекта "Город рядом — Кишинёв"
-- Проект: https://ypnjuaqrjharewvtfkrg.supabase.co
-- ====================================================================

-- 1. Таблица отзывов (reviews)
create table if not exists public.reviews (
    id uuid default gen_random_uuid() primary key,
    place text not null,
    author_id uuid references auth.users(id) on delete cascade not null,
    author_name text not null,
    text text not null,
    stars integer not null check (stars >= 1 and stars <= 5),
    pros text,
    cons text,
    photo_url text,
    created_at timestamp with time zone default timezone('utc'::text, now()) not null
);

-- Индексы для быстрого поиска отзывов по месту
create index if not exists idx_reviews_place on public.reviews(place);
create index if not exists idx_reviews_created_at on public.reviews(created_at desc);

-- Включаем Row Level Security (RLS)
alter table public.reviews enable row level security;

-- Политики RLS для reviews:
-- Все могут читать отзывы
create policy "reviews_select_all" on public.reviews
    for select using (true);

-- Авторизованные пользователи могут добавлять отзывы
create policy "reviews_insert_authenticated" on public.reviews
    for insert to authenticated
    with check (auth.uid() = author_id);

-- Авторы и админ могут удалять отзывы
create policy "reviews_delete_author" on public.reviews
    for delete to authenticated
    using (auth.uid() = author_id);

create policy "reviews_delete_admin" on public.reviews
    for delete to authenticated
    using (auth.uid() = 'abcd0d01-0308-49f9-a475-e5d8c1a9feb7'::uuid);


-- 2. Таблица голосов за отзывы (review_votes)
create table if not exists public.review_votes (
    id uuid default gen_random_uuid() primary key,
    review_id uuid references public.reviews(id) on delete cascade not null,
    user_id uuid references auth.users(id) on delete cascade not null,
    value integer not null check (value in (-1, 1)),
    created_at timestamp with time zone default timezone('utc'::text, now()) not null,
    unique(review_id, user_id)
);

create index if not exists idx_review_votes_review on public.review_votes(review_id);

alter table public.review_votes enable row level security;

-- Политики RLS для review_votes:
create policy "review_votes_select_all" on public.review_votes
    for select using (true);

create policy "review_votes_insert_authenticated" on public.review_votes
    for insert to authenticated
    with check (auth.uid() = user_id);

create policy "review_votes_update_authenticated" on public.review_votes
    for update to authenticated
    using (auth.uid() = user_id);

create policy "review_votes_delete_authenticated" on public.review_votes
    for delete to authenticated
    using (auth.uid() = user_id);


-- 3. Storage bucket для фотографий отзывов (review-photos)
-- Создайте bucket 'review-photos' в Supabase Dashboard -> Storage (публичный)
-- Политика для удаления фото админом:
-- create policy review_photos_delete_admin on storage.objects for delete to authenticated
--     using (bucket_id = 'review-photos' and auth.uid()::text = 'abcd0d01-0308-49f9-a475-e5d8c1a9feb7');
