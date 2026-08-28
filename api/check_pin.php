<?php
require __DIR__ . '/config.php';
requirePost();

$user = currentUser();
$pin  = preg_replace('/\D+/', '', (string)input('pin', ''));

if ($user['pin_hash'] === null || $user['pin_hash'] === '') {
    jsonOut(409, 'PIN ещё не установлен');
}
if (!password_verify($pin, $user['pin_hash'])) {
    jsonOut(403, 'Неверный PIN');
}

jsonOut(200, 'PIN подтверждён');
