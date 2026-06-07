-- Добавить колонку user_id (уникальный логин)
ALTER TABLE users ADD COLUMN IF NOT EXISTS user_id TEXT UNIQUE;

-- Индекс для быстрого поиска по user_id
CREATE INDEX IF NOT EXISTS idx_users_user_id ON users(user_id);

-- Функция проверки уникальности user_id (для клиента доступна через select)
-- Клиент проверяет: SELECT id FROM users WHERE user_id = 'xxx'
