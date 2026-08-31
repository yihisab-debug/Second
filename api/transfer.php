<?php
require __DIR__ . '/config.php';
requirePost();

$user    = currentUser();
$from    = walletOfUser(input('wallet_id', 0), (int)$user['id']);
$amount  = parseAmount(input('amount', 0));
$number  = preg_replace('/\D+/', '', (string)input('to_number', ''));
$comment = trim((string)input('comment', ''));

if (strlen($number) !== 16) {
    jsonOut(422, 'Номер счёта получателя должен содержать 16 цифр');
}
if ($number === $from['number']) {
    jsonOut(422, 'Нельзя перевести самому себе на тот же счёт');
}

$pdo = db();

$st = $pdo->prepare(
    'SELECT w.*, u.full_name, u.id AS owner_id, u.phone AS owner_phone FROM wallets w
     JOIN users u ON u.id = w.user_id
     WHERE w.number = ?'
);
$st->execute(array($number));
$to = $st->fetch();

if (!$to) {
    jsonOut(404, 'Счёт получателя не найден');
}
if ($to['currency'] !== $from['currency']) {
    jsonOut(409, 'Валюты счетов не совпадают');
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

    $title = $comment !== '' ? mb_substr($comment, 0, 120) : 'Перевод';

    logTransaction((int)$from['id'], 'transfer_out', $amount, $fromAfter, $title, $to['full_name']);
    logTransaction((int)$to['id'], 'transfer_in', $amount, $toAfter, $title, $user['full_name']);

    if ((int)$to['owner_id'] !== (int)$user['id']) {
        $notifyBody = 'От: ' . $user['full_name'] . ' · ' . maskPhone($user['phone'])
            . ' · счёт «' . $to['title'] . '»';
        if ($comment !== '') {
            $notifyBody .= ' · ' . mb_substr($comment, 0, 60);
        }

        notify(
            (int)$to['owner_id'],
            'transfer_in',
            'Пополнение счёта',
            $notifyBody,
            $amount,
            $to['currency']
        );
    }

    $pdo->commit();
} catch (Exception $e) {
    if ($pdo->inTransaction()) {
        $pdo->rollBack();
    }
    jsonOut(500, 'Перевод не выполнен: ' . $e->getMessage());
}

jsonOut(200, 'Перевод выполнен', array(
    'balance'   => $fromAfter,
    'recipient' => $to['full_name'],
));
