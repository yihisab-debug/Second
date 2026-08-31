<?php
require __DIR__ . '/config.php';
requirePost();

$user    = currentUser();
$from    = walletOfUser(input('wallet_id', 0), (int)$user['id']);
$amount  = parseAmount(input('amount', 0));
$phone   = normalizePhone(input('to_phone', ''));
$comment = trim((string)input('comment', ''));

if (strlen($phone) < 10) {
    jsonOut(422, 'Введите номер телефона получателя полностью');
}
if ($phone === normalizePhone($user['phone'])) {
    jsonOut(422, 'Нельзя перевести деньги самому себе');
}

$pdo = db();

$st = $pdo->prepare('SELECT id, full_name, phone FROM users WHERE phone = ?');
$st->execute(array($phone));
$receiver = $st->fetch();

if (!$receiver) {
    jsonOut(404, 'Клиент с таким номером не найден');
}

$st = $pdo->prepare(
    'SELECT * FROM wallets
     WHERE user_id = ? AND currency = ?
     ORDER BY is_default DESC, id ASC
     LIMIT 1'
);
$st->execute(array((int)$receiver['id'], $from['currency']));
$to = $st->fetch();

if (!$to) {
    jsonOut(409, 'У получателя нет счёта в валюте ' . $from['currency']);
}
if ((int)$to['id'] === (int)$from['id']) {
    jsonOut(422, 'Нельзя перевести на тот же самый счёт');
}

try {
    $pdo->beginTransaction();

    $ids = array((int)$from['id'], (int)$to['id']);
    sort($ids);
    $st = $pdo->prepare('SELECT id, balance FROM wallets WHERE id IN (?, ?) ORDER BY id FOR UPDATE');
    $st->execute($ids);

    $locked = array();
    foreach ($st->fetchAll() as $row) {
        $locked[(int)$row['id']] = (float)$row['balance'];
    }

    $fromBalance = $locked[(int)$from['id']];
    $toBalance   = $locked[(int)$to['id']];

    if ($fromBalance + 0.001 < $amount) {
        $pdo->rollBack();
        jsonOut(409, 'Недостаточно средств для перевода');
    }

    $fromAfter = round($fromBalance - $amount, 2);
    $toAfter   = round($toBalance + $amount, 2);

    $upd = $pdo->prepare('UPDATE wallets SET balance = ? WHERE id = ?');
    $upd->execute(array($fromAfter, (int)$from['id']));
    $upd->execute(array($toAfter, (int)$to['id']));

    $title = $comment !== '' ? mb_substr($comment, 0, 120) : 'Перевод по номеру телефона';

    logTransaction((int)$from['id'], 'transfer_out', $amount, $fromAfter, $title, $receiver['full_name']);
    logTransaction((int)$to['id'], 'transfer_in', $amount, $toAfter, $title, $user['full_name']);

    $notifyBody = 'От: ' . $user['full_name'] . ' · ' . maskPhone($user['phone'])
        . ' · счёт «' . $to['title'] . '»';
    if ($comment !== '') {
        $notifyBody .= ' · ' . mb_substr($comment, 0, 60);
    }

    notify(
        (int)$receiver['id'],
        'transfer_in',
        'Пополнение счёта',
        $notifyBody,
        $amount,
        $to['currency']
    );

    $pdo->commit();
} catch (Exception $e) {
    if ($pdo->inTransaction()) {
        $pdo->rollBack();
    }
    jsonOut(500, 'Перевод не выполнен: ' . $e->getMessage());
}

jsonOut(200, 'Перевод выполнен', array(
    'balance'         => $fromAfter,
    'recipient'       => $receiver['full_name'],
    'recipient_phone' => prettyPhone($receiver['phone']),
));
