<?php
require __DIR__ . '/config.php';
require __DIR__ . '/deposits_lib.php';
requirePost();

$user    = currentUser();
$product = depositProductById(input('product_id', 0));
$wallet  = walletOfUser(input('wallet_id', 0), (int)$user['id']);
$amount  = parseAmount(input('amount', 0));
$months  = (int)input('months', 0);

if ($wallet['currency'] !== $product['currency']) {
    jsonOut(422, 'Вклад открывается в ' . $product['currency']
        . ', выберите счёт в этой валюте');
}

if ($amount < (float)$product['min_amount'] || $amount > (float)$product['max_amount']) {
    jsonOut(422, 'Сумма должна быть от ' . (float)$product['min_amount']
        . ' до ' . (float)$product['max_amount'] . ' ' . $product['currency']);
}

if ($months < (int)$product['min_months'] || $months > (int)$product['max_months']) {
    jsonOut(422, 'Срок должен быть от ' . (int)$product['min_months']
        . ' до ' . (int)$product['max_months'] . ' месяцев');
}

$st = db()->prepare('SELECT COUNT(*) AS c FROM deposits WHERE user_id = ? AND status = ?');
$st->execute(array((int)$user['id'], 'active'));
$openDeposits = (int)$st->fetch()['c'];
if ($openDeposits >= 5) {
    jsonOut(409, 'Одновременно можно держать не больше 5 вкладов');
}

$rate   = (float)$product['rate'];
$income = depositIncome($amount, $rate, $months);
$total  = round($amount + $income, 2);

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

    $st = $pdo->prepare(
        'INSERT INTO deposits
            (user_id, product_id, wallet_id, amount, rate, months,
             income, total_amount, currency, status, ends_at)
         VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, DATE_ADD(NOW(), INTERVAL ' . $months . ' MONTH))'
    );
    $st->execute(array(
        (int)$user['id'],
        (int)$product['id'],
        (int)$wallet['id'],
        $amount,
        $rate,
        $months,
        $income,
        $total,
        $product['currency'],
        'active',
    ));
    $depositId = (int)$pdo->lastInsertId();

    logTransaction(
        (int)$wallet['id'],
        'withdraw',
        $amount,
        $newBalance,
        'Открытие вклада',
        $product['name']
    );

    notify(
        (int)$user['id'],
        'deposit_open',
        'Вклад открыт',
        $product['name'] . ' · ' . $months . ' мес. · ставка ' . $rate . '% · -'
            . number_format($amount, 2, ',', ' ') . ' ' . $product['currency']
    );

    $pdo->commit();
} catch (Exception $e) {
    if ($pdo->inTransaction()) {
        $pdo->rollBack();
    }
    jsonOut(500, 'Не удалось открыть вклад: ' . $e->getMessage());
}

jsonOut(200, 'Вклад открыт', array(
    'deposit_id'   => $depositId,
    'income'       => $income,
    'total_amount' => $total,
    'balance'      => $newBalance,
));
