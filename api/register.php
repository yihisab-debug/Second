<?php
require __DIR__ . '/config.php';
requirePost();

$fullName = trim((string)input('full_name', ''));
$phone    = normalizePhone(input('phone', ''));
$password = (string)input('password', '');

if ($fullName === '') {
    jsonOut(422, 'Введите имя и фамилию');
}
if (strlen($phone) < 10) {
    jsonOut(422, 'Введите номер телефона полностью');
}
if (strlen($password) < 4) {
    jsonOut(422, 'Пароль должен быть не короче 4 символов');
}

$pdo = db();

$st = $pdo->prepare('SELECT id FROM users WHERE phone = ?');
$st->execute(array($phone));
if ($st->fetch()) {
    jsonOut(409, 'Пользователь с таким номером уже зарегистрирован');
}

try {
    $pdo->beginTransaction();

    $st = $pdo->prepare('INSERT INTO users (full_name, phone, password_hash) VALUES (?, ?, ?)');
    $st->execute(array(
        mb_substr($fullName, 0, 100),
        $phone,
        password_hash($password, PASSWORD_DEFAULT),
    ));
    $userId = (int)$pdo->lastInsertId();

    createWallet($userId, 'Основной счёт', 'KZT', 1);

    $pdo->commit();
} catch (Exception $e) {
    if ($pdo->inTransaction()) {
        $pdo->rollBack();
    }
    jsonOut(500, 'Не удалось создать аккаунт: ' . $e->getMessage());
}

$token = issueToken($userId);

jsonOut(200, 'Аккаунт создан', array(
    'token' => $token,
    'user'  => array(
        'id'        => $userId,
        'full_name' => $fullName,
        'phone'     => $phone,
        'has_pin'   => false,
    ),
));
