-- MoodyToy — SQL миграции для Supabase

-- Таблица пользователей
CREATE TABLE IF NOT EXISTS users (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name TEXT NOT NULL DEFAULT 'Гость',
  email TEXT UNIQUE,
  phone TEXT,
  age INTEGER,
  birth_date DATE,
  gender TEXT CHECK (gender IN ('male','female','other')),
  looking_for TEXT CHECK (looking_for IN ('male','female','all')),
  bio TEXT,
  city TEXT,
  height INTEGER,
  tags TEXT[] DEFAULT '{}',
  photos TEXT[] DEFAULT '{}',
  avatar_url TEXT,
  avatar_emoji TEXT DEFAULT '😊',
  face_verified BOOLEAN DEFAULT false,
  keyfob_mac TEXT,
  mood TEXT CHECK (mood IN ('coffee','gamer','dating','walk','sport')),
  location_enabled BOOLEAN DEFAULT true,
  lat DOUBLE PRECISION,
  lng DOUBLE PRECISION,
  location_updated_at TIMESTAMPTZ,
  push_token TEXT,
  profile_private BOOLEAN DEFAULT false,
  battery_level INTEGER DEFAULT 100,
  device_id TEXT,
  created_at TIMESTAMPTZ DEFAULT now(),
  last_seen_at TIMESTAMPTZ DEFAULT now()
);

-- Таблица дружбы
CREATE TABLE IF NOT EXISTS friendships (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  requester_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  receiver_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  status TEXT NOT NULL DEFAULT 'pending' CHECK (status IN ('pending','accepted','declined')),
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now(),
  UNIQUE(requester_id, receiver_id)
);

-- Таблица сообщений
CREATE TABLE IF NOT EXISTS messages (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  chat_id TEXT NOT NULL,
  sender_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  text TEXT,
  image_url TEXT,
  created_at TIMESTAMPTZ DEFAULT now()
);

-- Коллекции (магазин)
CREATE TABLE IF NOT EXISTS collections (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name TEXT NOT NULL,
  series TEXT,
  image_url TEXT,
  emoji TEXT,
  price_cny NUMERIC,
  sale_price_cny NUMERIC,
  is_new BOOLEAN DEFAULT false,
  in_stock BOOLEAN DEFAULT true,
  description TEXT
);

-- Игрушки пользователей
CREATE TABLE IF NOT EXISTS user_toys (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  collection_id UUID REFERENCES collections(id),
  name TEXT NOT NULL,
  emoji TEXT,
  series TEXT,
  serial_number TEXT,
  keyfob_mac TEXT,
  created_at TIMESTAMPTZ DEFAULT now()
);

-- Индексы
CREATE INDEX IF NOT EXISTS idx_users_location ON users(lat, lng) WHERE location_enabled = true;
CREATE INDEX IF NOT EXISTS idx_users_mood ON users(mood);
CREATE INDEX IF NOT EXISTS idx_users_device ON users(device_id);
CREATE INDEX IF NOT EXISTS idx_friendships_req ON friendships(requester_id);
CREATE INDEX IF NOT EXISTS idx_friendships_rec ON friendships(receiver_id);
CREATE INDEX IF NOT EXISTS idx_messages_chat ON messages(chat_id, created_at);

-- RLS
ALTER TABLE users ENABLE ROW LEVEL SECURITY;
ALTER TABLE friendships ENABLE ROW LEVEL SECURITY;
ALTER TABLE messages ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_toys ENABLE ROW LEVEL SECURITY;

-- Политики (DROP + CREATE — PostgreSQL не поддерживает IF NOT EXISTS для POLICY)
DROP POLICY IF EXISTS "allow_all_select" ON users;
DROP POLICY IF EXISTS "allow_all_insert" ON users;
DROP POLICY IF EXISTS "allow_all_update" ON users;
CREATE POLICY "allow_all_select" ON users FOR SELECT USING (true);
CREATE POLICY "allow_all_insert" ON users FOR INSERT WITH CHECK (true);
CREATE POLICY "allow_all_update" ON users FOR UPDATE USING (true);

DROP POLICY IF EXISTS "allow_all_select" ON friendships;
DROP POLICY IF EXISTS "allow_all_insert" ON friendships;
DROP POLICY IF EXISTS "allow_all_update" ON friendships;
DROP POLICY IF EXISTS "allow_all_delete" ON friendships;
CREATE POLICY "allow_all_select" ON friendships FOR SELECT USING (true);
CREATE POLICY "allow_all_insert" ON friendships FOR INSERT WITH CHECK (true);
CREATE POLICY "allow_all_update" ON friendships FOR UPDATE USING (true);
CREATE POLICY "allow_all_delete" ON friendships FOR DELETE USING (true);

DROP POLICY IF EXISTS "allow_all_select" ON messages;
DROP POLICY IF EXISTS "allow_all_insert" ON messages;
CREATE POLICY "allow_all_select" ON messages FOR SELECT USING (true);
CREATE POLICY "allow_all_insert" ON messages FOR INSERT WITH CHECK (true);

DROP POLICY IF EXISTS "allow_all_select" ON user_toys;
DROP POLICY IF EXISTS "allow_all_insert" ON user_toys;
DROP POLICY IF EXISTS "allow_all_delete" ON user_toys;
CREATE POLICY "allow_all_select" ON user_toys FOR SELECT USING (true);
CREATE POLICY "allow_all_insert" ON user_toys FOR INSERT WITH CHECK (true);
CREATE POLICY "allow_all_delete" ON user_toys FOR DELETE USING (true);

-- Realtime
ALTER PUBLICATION supabase_realtime ADD TABLE users;
ALTER PUBLICATION supabase_realtime ADD TABLE friendships;
ALTER PUBLICATION supabase_realtime ADD TABLE messages;
