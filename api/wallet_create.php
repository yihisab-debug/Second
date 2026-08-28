<?php
require __DIR__ . '/config.php';
requirePost();

$user     = currentUser();
$title    = trim((string)input('title', ''));
$currency = strtoupper((string)input('currency', 'KZT'));

if ($title === '') {
    jsonOut(422, 'Введите название кошелька');
}

$st = db()->prepare('SELECT COUNT(*) AS c FROM wallets WHERE user_id = ?');
$st->execute(array((int)$user['id']));
$count = (int)$st->fetch()['c'];
if ($count >= 5) {
    jsonOut(409, 'Больше 5 кошельков создать нельзя');
}

$walletId = createWallet((int)$user['id'], $title, $currency, 0);

$st = db()->prepare('SELECT * FROM wallets WHERE id = ?');
$st->execute(array($walletId));

jsonOut(200, 'Кошелёк создан', array('wallet' => walletToArray($st->fetch())));
