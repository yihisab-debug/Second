<?php
require __DIR__ . '/config.php';
requirePost();

$user   = currentUser();
$wallet = walletOfUser(input('wallet_id', 0), (int)$user['id']);
$amount = parseAmount(input('amount', 0));
$target = trim((string)input('target', 'Наличные'));

$pdo = db();
try {
    $pdo->beginTransaction();

    $st = $pdo->prepare('SELECT balance FROM wallets WHERE id = ? FOR UPDATE');
    $st->execute(array((int)$wallet['id']));
    $balance = (float)$st->fetch()['balance'];

    if ($balance + 0.001 < $amount) {
        $pdo->rollBack();
        jsonOut(409, 'Недостаточно средств на счёте');
    }

    $newBalance = round($balance - $amount, 2);

    $st = $pdo->prepare('UPDATE wallets SET balance = ? WHERE id = ?');
    $st->execute(array($newBalance, (int)$wallet['id']));

    logTransaction((int)$wallet['id'], 'withdraw', $amount, $newBalance, 'Вывод средств', $target);

    $pdo->commit();
} catch (Exception $e) {
    if ($pdo->inTransaction()) {
        $pdo->rollBack();
    }
    jsonOut(500, 'Не удалось вывести средства: ' . $e->getMessage());
}

jsonOut(200, 'Средства выведены', array('balance' => $newBalance));
