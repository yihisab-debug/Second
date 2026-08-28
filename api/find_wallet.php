<?php
require __DIR__ . '/config.php';

$user   = currentUser();
$number = preg_replace('/\D+/', '', (string)input('number', ''));

if (strlen($number) !== 16) {
    jsonOut(422, 'Введите 16 цифр номера счёта');
}

$st = db()->prepare(
    'SELECT w.number, w.currency, u.full_name
     FROM wallets w JOIN users u ON u.id = w.user_id
     WHERE w.number = ?'
);
$st->execute(array($number));
$wallet = $st->fetch();

if (!$wallet) {
    jsonOut(404, 'Счёт не найден');
}

jsonOut(200, 'OK', array(
    'number'    => $wallet['number'],
    'currency'  => $wallet['currency'],
    'full_name' => $wallet['full_name'],
));
