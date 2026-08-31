<?php
require __DIR__ . '/config.php';

$user  = currentUser();
$phone = normalizePhone(input('phone', ''));

if (strlen($phone) < 10) {
    jsonOut(422, 'Введите номер телефона полностью');
}
if ($phone === normalizePhone($user['phone'])) {
    jsonOut(422, 'Это ваш собственный номер');
}

$st = db()->prepare('SELECT id, full_name, phone FROM users WHERE phone = ?');
$st->execute(array($phone));
$found = $st->fetch();

if (!$found) {
    jsonOut(404, 'Клиент с таким номером не найден');
}

$st = db()->prepare('SELECT DISTINCT currency FROM wallets WHERE user_id = ? ORDER BY currency');
$st->execute(array((int)$found['id']));

$currencies = array();
foreach ($st->fetchAll() as $row) {
    $currencies[] = $row['currency'];
}

if (count($currencies) === 0) {
    jsonOut(409, 'У этого клиента ещё нет открытых счетов');
}

jsonOut(200, 'OK', array(
    'user_id'      => (int)$found['id'],
    'full_name'    => $found['full_name'],
    'phone'        => $found['phone'],
    'phone_pretty' => prettyPhone($found['phone']),
    'currencies'   => $currencies,
));
