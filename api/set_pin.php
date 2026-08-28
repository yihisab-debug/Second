<?php
require __DIR__ . '/config.php';
requirePost();

$user = currentUser();
$pin  = preg_replace('/\D+/', '', (string)input('pin', ''));

if (strlen($pin) !== 4) {
    jsonOut(422, 'PIN должен состоять из 4 цифр');
}

if ($user['pin_hash'] !== null && $user['pin_hash'] !== '') {
    $current = preg_replace('/\D+/', '', (string)input('current_pin', ''));
    if (!password_verify($current, $user['pin_hash'])) {
        jsonOut(403, 'Текущий PIN введён неверно');
    }
}

$st = db()->prepare('UPDATE users SET pin_hash = ? WHERE id = ?');
$st->execute(array(password_hash($pin, PASSWORD_DEFAULT), (int)$user['id']));

jsonOut(200, 'PIN сохранён');
