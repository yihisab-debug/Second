<?php
require __DIR__ . '/config.php';
require __DIR__ . '/credits_lib.php';

$user = currentUser();

try {
    $st = db()->prepare(
        'SELECT c.*, cr.name AS creditor_name, w.title AS wallet_title
         FROM credits c
         JOIN creditors cr ON cr.id = c.creditor_id
         LEFT JOIN wallets w ON w.id = c.wallet_id
         WHERE c.user_id = ?
         ORDER BY c.status ASC, c.id DESC'
    );
    $st->execute(array((int)$user['id']));
    $rows = $st->fetchAll();
} catch (Exception $e) {
    jsonOut(500, 'Таблица credits недоступна. Запустите 02_credits.sql. ' . $e->getMessage());
}

$credits = array_map('creditToArray', $rows);

$debt    = 0.0;
$monthly = 0.0;
$active  = 0;
foreach ($credits as $credit) {
    if ($credit['status'] === 'active') {
        $active++;
        $debt    += $credit['remaining'];
        $monthly += $credit['monthly_payment'];
    }
}

jsonOut(200, 'OK', array(
    'credits' => $credits,
    'summary' => array(
        'active_count'    => $active,
        'total_debt'      => round($debt, 2),
        'monthly_payment' => round($monthly, 2),
        'currency'        => 'KZT',
    ),
));
