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

if (isset($user['is_blocked']) && (int)$user['is_blocked'] === 1) {
    $reason = isset($user['blocked_reason']) ? trim((string)$user['blocked_reason']) : '';
    jsonOut(403, $reason === ''
        ? 'Аккаунт заблокирован администратором банка'
        : 'Аккаунт заблокирован: ' . $reason);
}

$token = issueToken((int)$user['id']);

jsonOut(200, 'Вход выполнен', array(
    'token' => $token,
    'user'  => array(
        'id'        => (int)$user['id'],
        'full_name' => $user['full_name'],
        'phone'     => $user['phone'],
        'has_pin'   => $user['pin_hash'] !== null && $user['pin_hash'] !== '',
        'is_admin'  => isAdminUser($user),
    ),
));
