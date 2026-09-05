<?php
require __DIR__ . '/config.php';
require __DIR__ . '/deposits_lib.php';
requirePost();

$user    = currentUser();
$deposit = depositOfUser(input('deposit_id', 0), (int)$user['id']);

if ($deposit['status'] !== 'active') {
    jsonOut(409, 'Вклад уже закрыт');
}

$walletId = (int)input('wallet_id', 0);
if ($walletId <= 0) {
    $walletId = (int)$deposit['wallet_id'];
}
$wallet = walletOfUser($walletId, (int)$user['id']);

if ($wallet['currency'] !== $deposit['currency']) {
    jsonOut(422, 'Вклад в ' . $deposit['currency'] . ', выберите счёт в этой валюте');
}

$matured = (int)$deposit['is_matured'] === 1;
$income  = $matured ? (float)$deposit['income'] : 0.0;
$payout  = round((float)$deposit['amount'] + $income, 2);

$pdo = db();
try {
    $pdo->beginTransaction();

    $st = $pdo->prepare('SELECT balance FROM wallets WHERE id = ? FOR UPDATE');
    $st->execute(array((int)$wallet['id']));
    $balance = (float)$st->fetch()['balance'];

    $newBalance = round($balance + $payout, 2);

    $st = $pdo->prepare('UPDATE wallets SET balance = ? WHERE id = ?');
    $st->execute(array($newBalance, (int)$wallet['id']));

    $st = $pdo->prepare(
        'UPDATE deposits
         SET status = ?, income = ?, total_amount = ?, wallet_id = ?, closed_at = NOW()
         WHERE id = ?'
    );
    $st->execute(array('closed', $income, $payout, (int)$wallet['id'], (int)$deposit['id']));

    logTransaction(
        (int)$wallet['id'],
        'deposit',
        $payout,
        $newBalance,
        $matured ? 'Закрытие вклада' : 'Досрочное закрытие вклада',
        $deposit['product_name']
    );

    notify(
        (int)$user['id'],
        'deposit_close',
        $matured ? 'Вклад закрыт' : 'Вклад закрыт досрочно',
        $matured
            ? $deposit['product_name'] . ' · доход ' . number_format($income, 2, ',', ' ')
                . ' ' . $deposit['currency']
            : $deposit['product_name'] . ' · проценты не начислены',
        $payout,
        $deposit['currency']
    );

    $pdo->commit();
} catch (Exception $e) {
    if ($pdo->inTransaction()) {
        $pdo->rollBack();
    }
    jsonOut(500, 'Не удалось закрыть вклад: ' . $e->getMessage());
}

jsonOut(200, $matured ? 'Вклад закрыт, доход начислен' : 'Вклад закрыт досрочно, без процентов', array(
    'payout'  => $payout,
    'income'  => $income,
    'matured' => $matured,
    'balance' => $newBalance,
));
