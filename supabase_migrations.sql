-- ============================================================
-- MoodyToy — SQL Migrations для Supabase
-- Выполнить в Supabase Dashboard → SQL Editor
-- ============================================================

-- ── 1. Расширения ────────────────────────────────────────────
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "postgis"; -- для геозапросов (опционально)

-- ── 2. Таблица пользователей ─────────────────────────────────
CREATE TABLE IF NOT EXISTS public.users (
  id            UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  email         TEXT UNIQUE NOT NULL,
  phone         TEXT UNIQUE,
  name          TEXT NOT NULL DEFAULT '',
  age           INTEGER CHECK (age >= 18),
  gender        TEXT CHECK (gender IN ('male', 'female', 'other')),
  looking_for   TEXT CHECK (looking_for IN ('male', 'female', 'all')),
  bio           TEXT CHECK (char_length(bio) <= 300),
  city          TEXT,
  height        INTEGER CHECK (height BETWEEN 140 AND 220),
  tags          TEXT[] DEFAULT '{}',
  photos        TEXT[] DEFAULT '{}',
  face_verified BOOLEAN DEFAULT FALSE,
  keyfob_mac    TEXT,
  mood          TEXT CHECK (mood IN ('ready', 'waiting', 'sad', 'extra')),
  location_enabled BOOLEAN DEFAULT FALSE,
  lat           DOUBLE PRECISION,
  lng           DOUBLE PRECISION,
  location_updated_at TIMESTAMP WITH TIME ZONE,
  push_token    TEXT,
  profile_private BOOLEAN DEFAULT FALSE,
  battery_level INTEGER CHECK (battery_level BETWEEN 0 AND 100),
  created_at    TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  last_seen_at  TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- ── 3. Таблица дружбы ─────────────────────────────────────────
CREATE TABLE IF NOT EXISTS public.friendships (
  id           UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  requester_id UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
  receiver_id  UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
  status       TEXT NOT NULL DEFAULT 'pending'
               CHECK (status IN ('pending', 'accepted', 'declined')),
  created_at   TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at   TIMESTAMP WITH TIME ZONE,
  UNIQUE(requester_id, receiver_id)
);

-- ── 4. Таблица брелоков ───────────────────────────────────────
CREATE TABLE IF NOT EXISTS public.keyfobs (
  id               UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  mac_address      TEXT UNIQUE NOT NULL,
  user_id          UUID REFERENCES public.users(id) ON DELETE SET NULL,
  firmware_version TEXT DEFAULT '1.0.0',
  battery_level    INTEGER CHECK (battery_level BETWEEN 0 AND 100),
  registered_at    TIMESTAMP WITH TIME ZONE,
  last_ping_at     TIMESTAMP WITH TIME ZONE
);

-- ── 5. Таблица коллекций (магазин) ───────────────────────────
CREATE TABLE IF NOT EXISTS public.collections (
  id            UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  name          TEXT NOT NULL,
  series        TEXT NOT NULL DEFAULT 'Серия 1',
  image_url     TEXT,
  price_cny     NUMERIC(10,2) NOT NULL,
  sale_price_cny NUMERIC(10,2),
  is_new        BOOLEAN DEFAULT FALSE,
  in_stock      BOOLEAN DEFAULT TRUE,
  description   TEXT,
  created_at    TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- ── 6. Таблица купленных игрушек ──────────────────────────────
CREATE TABLE IF NOT EXISTS public.user_collections (
  id            UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id       UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
  collection_id UUID NOT NULL REFERENCES public.collections(id),
  keyfob_mac    TEXT,
  serial_number TEXT NOT NULL DEFAULT '#0000',
  purchased_at  TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- ── 7. Индексы ───────────────────────────────────────────────
CREATE INDEX IF NOT EXISTS idx_users_location
  ON public.users(lat, lng)
  WHERE location_enabled = TRUE;

CREATE INDEX IF NOT EXISTS idx_users_keyfob_mac
  ON public.users(keyfob_mac)
  WHERE keyfob_mac IS NOT NULL;

CREATE INDEX IF NOT EXISTS idx_friendships_requester
  ON public.friendships(requester_id);

CREATE INDEX IF NOT EXISTS idx_friendships_receiver
  ON public.friendships(receiver_id);

CREATE INDEX IF NOT EXISTS idx_users_location_updated
  ON public.users(location_enabled, location_updated_at);

-- ── 8. Row Level Security (RLS) ──────────────────────────────
ALTER TABLE public.users ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.friendships ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.keyfobs ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.collections ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.user_collections ENABLE ROW LEVEL SECURITY;

-- Пользователи могут читать видимых пользователей
CREATE POLICY "users_select_public" ON public.users
  FOR SELECT USING (TRUE);

-- Пользователь может обновлять только свой профиль
CREATE POLICY "users_update_own" ON public.users
  FOR UPDATE USING (auth.uid() = id);

-- Пользователь может создать свой профиль
CREATE POLICY "users_insert_own" ON public.users
  FOR INSERT WITH CHECK (auth.uid() = id);

-- Friendships — пользователь видит свои
CREATE POLICY "friendships_select" ON public.friendships
  FOR SELECT USING (
    auth.uid() = requester_id OR auth.uid() = receiver_id
  );

CREATE POLICY "friendships_insert" ON public.friendships
  FOR INSERT WITH CHECK (auth.uid() = requester_id);

CREATE POLICY "friendships_update" ON public.friendships
  FOR UPDATE USING (
    auth.uid() = requester_id OR auth.uid() = receiver_id
  );

-- Collections — все могут читать
CREATE POLICY "collections_select_all" ON public.collections
  FOR SELECT USING (TRUE);

-- User collections — только своё
CREATE POLICY "user_collections_select" ON public.user_collections
  FOR SELECT USING (auth.uid() = user_id);

-- ── 9. Realtime — включить для нужных таблиц ─────────────────
-- Выполнить в Supabase Dashboard → Database → Replication:
-- Включить Realtime для таблицы users (поля: location_enabled, lat, lng, mood)
-- Включить Realtime для таблицы friendships

-- ── 10. Тестовые данные (опционально) ────────────────────────
-- INSERT INTO public.collections (name, series, price_cny, is_new) VALUES
-- ('Котик Мяу', 'Серия 1', 299, TRUE),
-- ('Пандочка', 'Серия 1', 349, TRUE),
-- ('Лисёнок', 'Серия 2', 399, FALSE);
