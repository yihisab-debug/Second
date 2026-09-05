<?php
require __DIR__ . '/config.php';
require __DIR__ . '/credits_lib.php';
requirePost();

$user   = currentUser();
$credit = creditOfUser(input('credit_id', 0), (int)$user['id']);
$wallet = walletOfUser(input('wallet_id', 0), (int)$user['id']);
$amount = parseAmount(input('amount', 0));

if ($credit['status'] !== 'active') {
    jsonOut(409, 'Кредит уже закрыт');
}

if ($wallet['currency'] !== $credit['currency']) {
    jsonOut(422, 'Кредит в ' . $credit['currency'] . ', выберите счёт в этой валюте');
}

$remaining = round((float)$credit['total_amount'] - (float)$credit['paid_amount'], 2);
if ($amount > $remaining) {
    $amount = $remaining;
}

$pdo = db();
try {
    $pdo->beginTransaction();

    $st = $pdo->prepare('SELECT balance FROM wallets WHERE id = ? FOR UPDATE');
    $st->execute(array((int)$wallet['id']));
    $balance = (float)$st->fetch()['balance'];

    if ($balance < $amount) {
        $pdo->rollBack();
        jsonOut(422, 'Недостаточно средств на счёте');
    }

    $newBalance = round($balance - $amount, 2);
    $st = $pdo->prepare('UPDATE wallets SET balance = ? WHERE id = ?');
    $st->execute(array($newBalance, (int)$wallet['id']));

    $paid   = round((float)$credit['paid_amount'] + $amount, 2);
    $closed = $paid >= (float)$credit['total_amount'] - 0.01;

    if ($closed) {
        $st = $pdo->prepare(
            'UPDATE credits SET paid_amount = ?, status = ?, closed_at = NOW() WHERE id = ?'
        );
        $st->execute(array($paid, 'closed', (int)$credit['id']));
    } else {
        $st = $pdo->prepare('UPDATE credits SET paid_amount = ? WHERE id = ?');
        $st->execute(array($paid, (int)$credit['id']));
    }

    logTransaction(
        (int)$wallet['id'],
        'withdraw',
        $amount,
        $newBalance,
        'Погашение кредита',
        $credit['creditor_name']
    );

    notify(
        (int)$user['id'],
        'credit_payment',
        $closed ? 'Кредит закрыт' : 'Платёж по кредиту принят',
        $credit['creditor_name'] . ' · -'
            . number_format($amount, 2, ',', ' ') . ' ' . $credit['currency']
    );

    $pdo->commit();
} catch (Exception $e) {
    if ($pdo->inTransaction()) {
        $pdo->rollBack();
    }
    jsonOut(500, 'Не удалось провести платёж: ' . $e->getMessage());
}

jsonOut(200, $closed ? 'Кредит полностью погашен' : 'Платёж принят', array(
    'paid_amount' => $paid,
    'remaining'   => round((float)$credit['total_amount'] - $paid, 2),
    'closed'      => $closed,
    'balance'     => $newBalance,
));
