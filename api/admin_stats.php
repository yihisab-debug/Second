<?php
require __DIR__ . '/config.php';
require __DIR__ . '/admin_lib.php';

currentAdmin();

$pdo = db();

function scalarValue($sql)
{
    try {
        $st  = db()->query($sql);
        $row = $st->fetch();
        $val = $row === false ? 0 : array_values($row)[0];
        return $val === null ? 0 : $val;
    } catch (Exception $e) {
        return 0;
    }
}

$stats = array(
    'users_total'       => (int)scalarValue('SELECT COUNT(*) FROM users'),
    'users_blocked'     => (int)scalarValue('SELECT COUNT(*) FROM users WHERE is_blocked = 1'),
    'users_admins'      => (int)scalarValue('SELECT COUNT(*) FROM users WHERE is_admin = 1'),
    'wallets_total'     => (int)scalarValue('SELECT COUNT(*) FROM wallets'),
    'balance_kzt'       => (float)scalarValue("SELECT COALESCE(SUM(balance), 0) FROM wallets WHERE currency = 'KZT'"),
    'creditors_total'   => (int)scalarValue('SELECT COUNT(*) FROM creditors'),
    'creditors_active'  => (int)scalarValue('SELECT COUNT(*) FROM creditors WHERE is_active = 1'),
    'products_total'    => (int)scalarValue('SELECT COUNT(*) FROM deposit_products'),
    'products_active'   => (int)scalarValue('SELECT COUNT(*) FROM deposit_products WHERE is_active = 1'),
    'credits_active'    => (int)scalarValue("SELECT COUNT(*) FROM credits WHERE status = 'active'"),
    'credits_debt'      => (float)scalarValue("SELECT COALESCE(SUM(total_amount - paid_amount), 0) FROM credits WHERE status = 'active'"),
    'deposits_active'   => (int)scalarValue("SELECT COUNT(*) FROM deposits WHERE status = 'active'"),
    'deposits_amount'   => (float)scalarValue("SELECT COALESCE(SUM(amount), 0) FROM deposits WHERE status = 'active'"),
);

$log = array();
try {
    $st = $pdo->query(
        'SELECT l.*, u.full_name AS admin_name
         FROM admin_log l
         LEFT JOIN users u ON u.id = l.admin_id
         ORDER BY l.id DESC
         LIMIT 15'
    );
    foreach ($st->fetchAll() as $row) {
        $log[] = array(
            'id'          => (int)$row['id'],
            'admin_name'  => $row['admin_name'] === null ? '' : $row['admin_name'],
            'action'      => $row['action'],
            'target_type' => $row['target_type'],
            'target_id'   => (int)$row['target_id'],
            'details'     => $row['details'],
            'created_at'  => $row['created_at'],
        );
    }
} catch (Exception $e) {
    $log = array();
}

jsonOut(200, 'OK', array(
    'stats' => $stats,
    'log'   => $log,
));
