class AppStrings {
  AppStrings._();

  // App
  static const String appName = 'MoodyToy';
  static const String tagline = 'Встречайся в реальном мире';

  // Auth
  static const String login = 'Войти';
  static const String register = 'Зарегистрироваться';
  static const String loginOrRegister = 'Войти / Зарегистрироваться';
  static const String email = 'Email';
  static const String emailHint = 'your@email.com';
  static const String password = 'Пароль';
  static const String passwordHint = 'Минимум 8 символов';
  static const String forgotPassword = 'Забыл пароль?';
  static const String logout = 'Выйти из аккаунта';
  static const String loginSuccess = 'Добро пожаловать!';
  static const String registerSuccess = 'Аккаунт создан!';

  // Tabs - новый порядок из ТЗ
  static const String tabPeople = 'Люди';
  static const String tabCollection = 'Коллекция';
  static const String tabChats = 'Чаты';
  static const String tabFriends = 'Друзья';
  static const String tabProfile = 'Я';

  // Настроения (новые)
  static const String moodCoffeeBreak = 'Кофе-брейк';
  static const String moodGamer = 'Игрок';
  static const String moodDating = 'Знакомство';
  static const String moodWalk = 'Прогулка';
  static const String moodSport = 'Спорт/активность';

  // People screen
  static const String nearbyPeople = 'Люди рядом';
  static const String mapView = 'Карта';
  static const String listView = 'Список';
  static const String meButton = 'Я';
  static const String shareLocation = 'Поделиться геопозицией';
  static const String visibleOnMap = 'Вы видимы на карте';
  static const String needKeyfob = 'Нужен брелок';
  static const String filterAll = 'Все';
  static const String filterReady = 'Готов';
  static const String filterWaiting = 'Жду';
  static const String filterSad = 'Грущу';

  // Old mood strings (deprecated)
  @Deprecated('Используйте moodCoffeeBreak')
  static const String moodReady = 'Готов к встрече';
  @Deprecated('Используйте moodSport')
  static const String moodWaiting = 'Жду';
  @Deprecated('Используйте moodWalk')
  static const String moodSad = 'Грущу';
  @Deprecated('Не используется')
  static const String moodExtra = 'Особый';

  // Old filter strings (deprecated)
  @Deprecated('Используйте новые фильтры')
  static const String filterReady = 'Готов';
  @Deprecated('Используйте новые фильтры')
  static const String filterWaiting = 'Жду';
  @Deprecated('Используйте новые фильтры')
  static const String filterSad = 'Грущу';

  // Friends
  static const String friends = 'Друзья';
  static const String friendRequests = 'Запросы';
  static const String addFriend = '+ Друг';
  static const String requestSent = 'Запрос отправлен';
  static const String accept = 'Принять';
  static const String decline = 'Отклонить';
  static const String incomingRequests = 'Входящие запросы';
  static const String myFriends = 'Мои друзья';
  static const String noFriends = 'Пока нет друзей';
  static const String noRequests = 'Нет новых запросов';

  // Profile
  static const String profile = 'Профиль';
  static const String settings = 'Настройки';
  static const String editProfile = 'Редактировать профиль';
  static const String about = 'О себе';
  static const String height = 'Рост';
  static const String city = 'Город';
  static const String interests = 'Интересы';
  static const String privacy = 'Приватность';
  static const String hideProfile = 'Скрывать анкету от незнакомых';
  static const String showDistance = 'Показывать расстояние до меня';
  static const String notifications = 'Уведомления';
  static const String support = 'Поддержка и FAQ';

  // Keyfob
  static const String connectKeyfob = 'Подключить игрушку';
  static const String manageKeyfob = 'Управление брелоком';
  static const String keyfobConnected = 'Брелок подключён';
  static const String keyfobDisconnected = 'Не подключён';
  static const String bindKeyfob = 'Привязать';
  static const String unbindKeyfob = 'Отвязать';
  static const String scanning = 'Поиск устройств...';
  static const String keyfobFound = 'Устройство найдено';
  static const String keyfobBound = 'Брелок привязан!';
  static const String battery = 'Батарея';
  static const String firmwareVersion = 'Версия прошивки';
  static const String deviceId = 'ID устройства';
  static const String updateFirmware = 'Обновить прошивку';

  // Collection
  static const String myCollection = 'Моя коллекция';
  static const String shop = 'Магазин';
  static const String newItems = 'Новинки';
  static const String sale = 'Sale';
  static const String allCollections = 'Все коллекции';
  static const String addToy = 'Добавить игрушку';
  static const String buy = 'Купить';
  static const String series = 'Серия';
  static const String bound = 'Привязан';

  // Chats
  static const String generalChats = 'Общие';
  static const String personalChats = 'Личные';
  static const String noPersonalChats = 'Нет личных чатов';
  static const String sendMessage = 'Сообщение...';

  // Errors
  static const String errorGeneral = 'Что-то пошло не так';
  static const String errorNetwork = 'Нет подключения к интернету';
  static const String errorInvalidEmail = 'Некорректный email';
  static const String errorPasswordShort = 'Пароль слишком короткий (мин. 8 символов)';
  static const String errorPasswordWeak = 'Пароль должен содержать заглавную букву и цифру';
  static const String errorBluetoothOff = 'Включите Bluetooth';
  static const String errorLocationOff = 'Включите геолокацию';
  static const String errorKeyfobTaken = 'Этот брелок уже привязан к другому аккаунту';
  static const String errorScanTimeout = 'Устройство не найдено. Попробуйте ещё раз';

  // Notifications
  static const String notifNearby = 'рядом с тобой';
  static const String notifFriendRequest = 'хочет добавить тебя в друзья';
  static const String notifFriendAccepted = 'принял(а) твой запрос в друзья';
  static const String notifBattery20 = 'Батарея брелока 20%. Замени CR2032';
  static const String notifBattery10 = 'Критический заряд! Срочно замени батарейку';
  static const String notifFirmware = 'Доступно обновление брелока';

  // Distance
  static String distance(double meters) {
    if (meters < 1000) return '~${meters.round()}м';
    return '~${(meters / 1000).toStringAsFixed(1)}км';
  }

  // Tags presets
  static const List<String> defaultTags = [
    'Спорт', 'Музыка', 'Кино', 'Путешествия', 'Искусство',
    'Кофе', 'Готовка', 'Игры', 'Книги', 'Танцы',
    'Йога', 'Бег', 'Велосипед', 'Фото', 'Технологии',
    'Аниме', 'Природа', 'Автомобили', 'Мода', 'Дизайн',
  ];
}
