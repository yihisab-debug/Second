<?php
require __DIR__ . '/config.php';
require __DIR__ . '/deposits_lib.php';

$user = currentUser();

try {
    $st = db()->prepare(
        'SELECT d.*, p.name AS product_name, w.title AS wallet_title,
                TIMESTAMPDIFF(DAY, d.opened_at, d.ends_at) AS days_total,
                GREATEST(TIMESTAMPDIFF(DAY, NOW(), d.ends_at), 0) AS days_left,
                CASE WHEN NOW() >= d.ends_at THEN 1 ELSE 0 END AS is_matured
         FROM deposits d
         JOIN deposit_products p ON p.id = d.product_id
         LEFT JOIN wallets w ON w.id = d.wallet_id
         WHERE d.user_id = ?
         ORDER BY d.status ASC, d.id DESC'
    );
    $st->execute(array((int)$user['id']));
    $rows = $st->fetchAll();
} catch (Exception $e) {
    jsonOut(500, 'Таблица deposits недоступна. Запустите 03_deposits.sql. ' . $e->getMessage());
}

$deposits = array_map('depositToArray', $rows);

$saved  = 0.0;
$income = 0.0;
$active = 0;
foreach ($deposits as $deposit) {
    if ($deposit['status'] === 'active') {
        $active++;
        $saved  += $deposit['amount'];
        $income += $deposit['income'];
    }
}

jsonOut(200, 'OK', array(
    'deposits' => $deposits,
    'summary'  => array(
        'active_count'    => $active,
        'total_saved'     => round($saved, 2),
        'expected_income' => round($income, 2),
        'currency'        => 'KZT',
    ),
));
