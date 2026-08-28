# MiniBank — мини-приложение мобильного банкинга

Flutter (клиент) + PHP (API) + MySQL/phpMyAdmin (база данных).

## Что умеет

| Функция | Где | Что происходит в базе |
|---|---|---|
| Регистрация | `register.php` | новая запись в `users` + автоматически счёт в `wallets` |
| Вход по телефону и паролю | `login.php` | проверка `password_verify`, выдача токена в `tokens` |
| PIN-код при запуске | `set_pin.php`, `check_pin.php` | хэш PIN в `users.pin_hash` |
| Кошельки (до 5 штук) | `wallets.php`, `wallet_create.php` | записи в `wallets`, номер счёта из 16 цифр |
| Пополнение | `deposit.php` | `balance` растёт, запись типа `deposit` |
| Вывод средств | `withdraw.php` | проверка остатка, запись `withdraw` |
| Перевод по номеру счёта | `transfer.php` | SQL-транзакция: два `UPDATE` + две записи в `transactions` |
| История операций с фильтрами | `history.php` | выборка из `transactions` |
| Профиль, смена PIN, выход | `overview.php`, `logout.php` | удаление токена |

Пароль и PIN нигде не хранятся в открытом виде — только bcrypt-хэши (`password_hash`).
Перевод выполняется внутри транзакции с блокировкой строк (`FOR UPDATE`), поэтому деньги
не могут «потеряться» или задвоиться.

---

## 1. База данных

1. Запустите **XAMPP** (или OpenServer): кнопки Start у **Apache** и **MySQL**.
2. Откройте `http://localhost/phpmyadmin`.
3. Вкладка **Импорт** → выберите файл `database/mini_bank.sql` → **Вперёд**.
4. Слева появится база `mini_bank` с таблицами `users`, `tokens`, `wallets`, `transactions`.

Если у вашего MySQL задан пароль root — впишите его в `api/config.php` в константу `DB_PASS`.

## 2. Серверная часть (PHP)

Скопируйте папку `api` в веб-каталог так, чтобы получилось:

```
C:\xampp\htdocs\minibank\api\index.php
```

Проверьте в браузере: `http://localhost/minibank/api/index.php`
Должен вернуться JSON со списком таблиц. Если видите ошибку — она же и подскажет причину
(чаще всего неверный пароль к MySQL или база не импортирована).

## 3. Приложение (Flutter)

1. Скопируйте в свой проект папку `lib`, файл `pubspec.yaml` и
   `android/app/src/main/AndroidManifest.xml` (там добавлено разрешение на интернет).
2. В терминале проекта: `flutter pub get`
3. Откройте `lib/core/api.dart` и укажите адрес сервера:

```dart
static String baseUrl = 'http://10.0.2.2/minibank/api';
```

| Где запускаете | Что писать |
|---|---|
| Эмулятор Android | `http://10.0.2.2/minibank/api` |
| Настоящий телефон по Wi-Fi | `http://192.168.X.X/minibank/api` — IP компьютера из `ipconfig` |
| Chrome / Windows-desktop | `http://localhost/minibank/api` |

4. `flutter run`

Телефон и компьютер должны быть в одной сети. Если с телефона API не открывается,
проверьте брандмауэр Windows — Apache должен быть разрешён в частной сети.

---

## Как проверить работу за 2 минуты

1. Зарегистрируйтесь → придумайте PIN → откроется главный экран со счётом на 0 ₸.
2. **Пополнить** на 10 000 → баланс на карточке изменился, в истории появилась запись.
3. В phpMyAdmin выполните `SELECT * FROM v_user_balances;` — те же данные видны в базе.
4. Зарегистрируйте второго пользователя (можно на том же эмуляторе после «Выйти»),
   скопируйте его номер счёта в профиле.
5. Вернитесь в первый аккаунт → **Перевести** → вставьте номер → кнопка «лупа» покажет
   имя получателя → перевод. В таблице `transactions` появятся сразу две строки:
   `transfer_out` у отправителя и `transfer_in` у получателя.
6. Закройте приложение и откройте снова — попросит только PIN, пароль вводить не нужно.

## Структура проекта

```
lib/
  core/      api.dart (запросы), session.dart (токен), theme.dart, format.dart (деньги, даты)
  models/    models.dart — Profile, Wallet, TxItem
  screens/   splash, login, register, pin, main_shell, home_tab, history_tab,
             profile_tab, deposit, withdraw, transfer, wallet_create
  widgets/   wallet_card (карта счёта), transaction_tile, wallet_selector, app_widgets
api/         13 PHP-эндпоинтов + config.php
database/    mini_bank.sql
```

Формат ответа API везде одинаковый:

```json
{ "status": 200, "message": "Счёт пополнен", "data": { "balance": 10000 } }
```

`status` 200 — успех, 401 — нет/протух токен, 403 — неверный PIN,
404 — не найдено, 409 — конфликт (нет денег, дубликат), 422 — ошибка в данных.

## Если что-то не работает

| Симптом | Причина |
|---|---|
| «Сервер не отвечает» | не запущен Apache или неверный `baseUrl` (для эмулятора нужен `10.0.2.2`, не `localhost`) |
| «Сервер вернул не JSON» | ошибка PHP — откройте адрес API в браузере и прочитайте текст |
| «Нет подключения к базе данных» | не импортирован `mini_bank.sql` или неверный `DB_PASS` в `config.php` |
| Просит PIN, а он забыт | на экране PIN → «Войти в другой аккаунт» → вход по паролю |
| Пустой экран после регистрации | сделайте свайп вниз (обновление) или проверьте таблицу `wallets` |
