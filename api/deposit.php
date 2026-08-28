<?php
require __DIR__ . '/config.php';
requirePost();

$user   = currentUser();
$wallet = walletOfUser(input('wallet_id', 0), (int)$user['id']);
$amount = parseAmount(input('amount', 0));
$source = trim((string)input('source', 'Банковская карта'));

$pdo = db();
try {
    $pdo->beginTransaction();

    $st = $pdo->prepare('SELECT balance FROM wallets WHERE id = ? FOR UPDATE');
    $st->execute(array((int)$wallet['id']));
    $balance = (float)$st->fetch()['balance'];

    $newBalance = round($balance + $amount, 2);

    $st = $pdo->prepare('UPDATE wallets SET balance = ? WHERE id = ?');
    $st->execute(array($newBalance, (int)$wallet['id']));

    logTransaction((int)$wallet['id'], 'deposit', $amount, $newBalance, 'Пополнение', $source);

    $pdo->commit();
} catch (Exception $e) {
    if ($pdo->inTransaction()) {
        $pdo->rollBack();
    }
    jsonOut(500, 'Не удалось пополнить счёт: ' . $e->getMessage());
}

jsonOut(200, 'Счёт пополнен', array('balance' => $newBalance));
