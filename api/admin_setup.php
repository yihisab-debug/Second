<?php
/**
 * Одноразовый установщик админ-модуля.
 *
 * Откройте в браузере:  http://localhost/minibank/api/admin_setup.php
 *
 * Скрипт:
 *   1) добавляет в таблицу users колонки is_admin / is_blocked / blocked_reason / blocked_at;
 *   2) создаёт таблицу admin_log;
 *   3) создаёт (или обновляет) учётную запись администратора.
 *
 * Логин администратора:  +7 700 000 00 00
 * Пароль:                admin1234
 *
 * ВАЖНО: после успешного запуска удалите этот файл с сервера.
 */

require __DIR__ . '/config.php';

define('ADMIN_PHONE', '77000000000');
define('ADMIN_PASSWORD', 'admin1234');
define('ADMIN_NAME', 'Администратор Банка');

$pdo  = db();
$done = array();

function columnExists($table, $column)
{
    $st = db()->prepare(
        'SELECT COUNT(*) AS c FROM information_schema.COLUMNS
         WHERE TABLE_SCHEMA = ? AND TABLE_NAME = ? AND COLUMN_NAME = ?'
    );
    $st->execute(array(DB_NAME, $table, $column));
    $row = $st->fetch();
    return (int)$row['c'] > 0;
}

$columns = array(
    'is_admin'       => "TINYINT(1) NOT NULL DEFAULT 0",
    'is_blocked'     => "TINYINT(1) NOT NULL DEFAULT 0",
    'blocked_reason' => "VARCHAR(255) NOT NULL DEFAULT ''",
    'blocked_at'     => "DATETIME NULL",
);

try {
    foreach ($columns as $name => $definition) {
        if (columnExists('users', $name)) {
            $done[] = 'Колонка users.' . $name . ' уже существует';
            continue;
        }
        $pdo->exec('ALTER TABLE users ADD COLUMN ' . $name . ' ' . $definition);
        $done[] = 'Добавлена колонка users.' . $name;
    }

    $pdo->exec(
        "CREATE TABLE IF NOT EXISTS admin_log (
            id          INT AUTO_INCREMENT PRIMARY KEY,
            admin_id    INT             NOT NULL,
            action      VARCHAR(40)     NOT NULL,
            target_type VARCHAR(30)     NOT NULL DEFAULT '',
            target_id   INT             NOT NULL DEFAULT 0,
            details     VARCHAR(255)    NOT NULL DEFAULT '',
            created_at  TIMESTAMP       NOT NULL DEFAULT CURRENT_TIMESTAMP,
            KEY idx_admin_log_admin (admin_id, id)
        ) ENGINE = InnoDB DEFAULT CHARSET = utf8mb4"
    );
    $done[] = 'Таблица admin_log готова';

    $st = $pdo->prepare('SELECT id FROM users WHERE phone = ?');
    $st->execute(array(ADMIN_PHONE));
    $existing = $st->fetch();

    if ($existing) {
        $st = $pdo->prepare(
            'UPDATE users
             SET is_admin = 1, is_blocked = 0, blocked_reason = \'\', blocked_at = NULL,
                 password_hash = ?
             WHERE id = ?'
        );
        $st->execute(array(password_hash(ADMIN_PASSWORD, PASSWORD_DEFAULT), (int)$existing['id']));
        $adminId = (int)$existing['id'];
        $done[]  = 'Учётная запись администратора обновлена (id = ' . $adminId . ')';
    } else {
        $st = $pdo->prepare(
            'INSERT INTO users (full_name, phone, password_hash, is_admin)
             VALUES (?, ?, ?, 1)'
        );
        $st->execute(array(
            ADMIN_NAME,
            ADMIN_PHONE,
            password_hash(ADMIN_PASSWORD, PASSWORD_DEFAULT),
        ));
        $adminId = (int)$pdo->lastInsertId();
        createWallet($adminId, 'Служебный счёт', 'KZT', 1);
        $done[] = 'Создана учётная запись администратора (id = ' . $adminId . ')';
    }
} catch (Exception $e) {
    jsonOut(500, 'Ошибка установки: ' . $e->getMessage(), array('steps' => $done));
}

jsonOut(200, 'Админ-модуль установлен. Удалите файл admin_setup.php!', array(
    'steps'    => $done,
    'login'    => prettyPhone(ADMIN_PHONE),
    'password' => ADMIN_PASSWORD,
));
