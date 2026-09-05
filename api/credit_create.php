<?php
require __DIR__ . '/config.php';
require __DIR__ . '/credits_lib.php';
requirePost();

$user     = currentUser();
$creditor = creditorById(input('creditor_id', 0));
$wallet   = walletOfUser(input('wallet_id', 0), (int)$user['id']);
$amount   = parseAmount(input('amount', 0));
$months   = (int)input('months', 0);
$purpose  = trim((string)input('purpose', ''));

if ($wallet['currency'] !== $creditor['currency']) {
    jsonOut(422, 'Кредитор выдаёт кредиты в ' . $creditor['currency']
        . ', выберите счёт в этой валюте');
}

if ($amount < (float)$creditor['min_amount'] || $amount > (float)$creditor['max_amount']) {
    jsonOut(422, 'Сумма должна быть от ' . (float)$creditor['min_amount']
        . ' до ' . (float)$creditor['max_amount'] . ' ' . $creditor['currency']);
}

if ($months < (int)$creditor['min_months'] || $months > (int)$creditor['max_months']) {
    jsonOut(422, 'Срок должен быть от ' . (int)$creditor['min_months']
        . ' до ' . (int)$creditor['max_months'] . ' месяцев');
}

$st = db()->prepare('SELECT COUNT(*) AS c FROM credits WHERE user_id = ? AND status = ?');
$st->execute(array((int)$user['id'], 'active'));
$openCredits = (int)$st->fetch()['c'];
if ($openCredits >= 3) {
    jsonOut(409, 'У вас уже 3 активных кредита. Погасите один, чтобы оформить новый');
}

$rate    = (float)$creditor['rate'];
$monthly = annuityPayment($amount, $rate, $months);
$total   = round($monthly * $months, 2);

requireCreditAllowed($user, $amount, $monthly, $creditor['currency']);

$pdo = db();
try {
    $pdo->beginTransaction();

    $st = $pdo->prepare('SELECT balance FROM wallets WHERE id = ? FOR UPDATE');
    $st->execute(array((int)$wallet['id']));
    $balance = (float)$st->fetch()['balance'];

    $newBalance = round($balance + $amount, 2);

    $st = $pdo->prepare('UPDATE wallets SET balance = ? WHERE id = ?');
    $st->execute(array($newBalance, (int)$wallet['id']));

    $st = $pdo->prepare(
        'INSERT INTO credits
            (user_id, creditor_id, wallet_id, amount, rate, months,
             monthly_payment, total_amount, paid_amount, currency, purpose, status)
         VALUES (?, ?, ?, ?, ?, ?, ?, ?, 0, ?, ?, ?)'
    );
    $st->execute(array(
        (int)$user['id'],
        (int)$creditor['id'],
        (int)$wallet['id'],
        $amount,
        $rate,
        $months,
        $monthly,
        $total,
        $creditor['currency'],
        mb_substr($purpose, 0, 120),
        'active',
    ));
    $creditId = (int)$pdo->lastInsertId();

    logTransaction(
        (int)$wallet['id'],
        'deposit',
        $amount,
        $newBalance,
        'Кредит: ' . $creditor['name'],
        $creditor['name']
    );

    notify(
        (int)$user['id'],
        'credit',
        'Кредит одобрен',
        $creditor['name'] . ', ' . $months . ' мес., ставка ' . $rate . '%',
        $amount,
        $creditor['currency']
    );

    $pdo->commit();
} catch (Exception $e) {
    if ($pdo->inTransaction()) {
        $pdo->rollBack();
    }
    jsonOut(500, 'Не удалось оформить кредит: ' . $e->getMessage());
}

jsonOut(200, 'Кредит оформлен', array(
    'credit_id'       => $creditId,
    'monthly_payment' => $monthly,
    'total_amount'    => $total,
    'balance'         => $newBalance,
));
