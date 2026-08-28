<?php
require __DIR__ . '/config.php';
requirePost();

$phone    = normalizePhone(input('phone', input('login', '')));
$password = (string)input('password', '');

if ($phone === '' || $password === '') {
    jsonOut(422, 'Заполните телефон и пароль');
}

$st = db()->prepare('SELECT * FROM users WHERE phone = ?');
$st->execute(array($phone));
$user = $st->fetch();

if (!$user || !password_verify($password, $user['password_hash'])) {
    jsonOut(401, 'Неверный телефон или пароль');
}

$token = issueToken((int)$user['id']);

jsonOut(200, 'Вход выполнен', array(
    'token' => $token,
    'user'  => array(
        'id'        => (int)$user['id'],
        'full_name' => $user['full_name'],
        'phone'     => $user['phone'],
        'has_pin'   => $user['pin_hash'] !== null && $user['pin_hash'] !== '',
    ),
));
