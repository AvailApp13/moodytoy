# MoodyToy 🧸

Приложение знакомств с Bluetooth-брелоком Radioland 832-B2

## Стек

| Слой | Технология |
|------|-----------|
| Flutter | 3.22+, Dart 3.4+ |
| State | GetX ^4.6.6 |
| Backend | Supabase |
| Карты | Amap / Gaode (Китай) |
| BLE | flutter_blue_plus |
| Push | JPush (Китай) |
| GPS | geolocator |

## Быстрый старт

### 1. Установить Flutter
```bash
flutter --version  # должна быть 3.22+
flutter doctor     # все галочки зелёные
```

### 2. Клонировать и установить зависимости
```bash
git clone <repo>
cd moodytoy
flutter pub get
```

### 3. Настроить .env
```bash
cp .env .env.local
# Заполнить ключи:
```
```
SUPABASE_URL=https://your-project.supabase.co
SUPABASE_ANON_KEY=your-anon-key
AMAP_IOS_KEY=your-amap-ios-key
AMAP_ANDROID_KEY=your-amap-android-key
JPUSH_APP_KEY=your-jpush-app-key
```

### 4. Создать базу данных
В Supabase Dashboard → SQL Editor выполнить `supabase_migrations.sql`

Обязательно включить Realtime для таблицы `users` в:
Dashboard → Database → Replication

### 5. Запустить
```bash
flutter run
```

## BLE — Radioland 832-B2

UUID уже прописаны в `lib/core/constants/ble_constants.dart`:

| Параметр | Значение |
|---------|---------|
| Service | `00001803-494c-4f47-4943-544543480000` |
| Write | `00001805-494c-4f47-4943-544543480000` |
| Notify | `00001804-494c-4f47-4943-544543480000` |
| iBeacon | `FDA50693-A4E2-4FB1-AFCF-C6EB07647825` |

**⚠️ После получения брелока:** нажать кнопку, посмотреть лог в Flutter и заполнить `buttonByte*` в `ble_constants.dart`

## Архитектура

```
lib/
├── app/            # Корень, роуты
├── core/
│   ├── constants/  # Цвета, строки, BLE UUID
│   └── services/   # BLE, GPS, Supabase, Push
├── data/
│   ├── models/     # UserModel, FriendshipModel...
│   └── repositories/ # Auth, User, Friends...
├── features/
│   ├── auth/       # Вход/регистрация
│   ├── people/     # Карта + список
│   ├── collection/ # Коллекция + магазин
│   ├── friends/    # Друзья
│   └── profile/    # Профиль + брелок
└── shared/         # Общие виджеты, тема
```

## MVP ограничения

- ✅ Регистрация: только email + пароль
- ✅ Face ID: mock (всегда true)
- ✅ BLE UUID: реальные от Radioland 832-B2
- ⏳ Байты кнопки: определить после получения брелока
- ⏳ Amap ключи: зарегистрировать на lbs.amap.com
- ⏳ JPush ключ: зарегистрировать на jpush.cn

## Следующие шаги

1. Получить брелок → определить байты кнопки
2. Зарегистрировать Amap API ключ
3. Зарегистрировать JPush App Key
4. Добавить SMS верификацию (раздел 1)
5. Включить Face++ (раскомментировать в face_service.dart)
