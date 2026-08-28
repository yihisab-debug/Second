<?php
require __DIR__ . '/config.php';

$user     = currentUser();
$walletId = (int)input('wallet_id', 0);
$limit    = (int)input('limit', 50);
if ($limit < 1 || $limit > 200) {
    $limit = 50;
}

$sql = 'SELECT t.*, w.currency AS currency, w.title AS wallet_title
        FROM transactions t
        JOIN wallets w ON w.id = t.wallet_id
        WHERE w.user_id = ?';
$params = array((int)$user['id']);

if ($walletId > 0) {
    $sql .= ' AND w.id = ?';
    $params[] = $walletId;
}

$sql .= ' ORDER BY t.id DESC LIMIT ' . $limit;

$st = db()->prepare($sql);
$st->execute($params);

jsonOut(200, 'OK', array('transactions' => array_map('transactionToArray', $st->fetchAll())));
