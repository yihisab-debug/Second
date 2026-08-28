<?php
require __DIR__ . '/config.php';

$user = currentUser();
$pdo  = db();

$st = $pdo->prepare('SELECT * FROM wallets WHERE user_id = ? ORDER BY is_default DESC, id ASC');
$st->execute(array((int)$user['id']));
$wallets = array_map('walletToArray', $st->fetchAll());

$st = $pdo->prepare(
    'SELECT t.*, w.currency AS currency, w.title AS wallet_title
     FROM transactions t
     JOIN wallets w ON w.id = t.wallet_id
     WHERE w.user_id = ?
     ORDER BY t.id DESC
     LIMIT 10'
);
$st->execute(array((int)$user['id']));
$transactions = array_map('transactionToArray', $st->fetchAll());

jsonOut(200, 'OK', array(
    'user' => array(
        'id'        => (int)$user['id'],
        'full_name' => $user['full_name'],
        'phone'     => $user['phone'],
        'has_pin'   => $user['pin_hash'] !== null && $user['pin_hash'] !== '',
    ),
    'wallets'      => $wallets,
    'transactions' => $transactions,
));
