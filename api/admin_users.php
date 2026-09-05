<?php
require __DIR__ . '/config.php';
require __DIR__ . '/admin_lib.php';

$admin = currentAdmin();

$query  = trim((string)input('q', ''));
$filter = (string)input('filter', 'all'); // all | blocked | active

$where  = array();
$params = array();

if ($query !== '') {
    $digits = normalizePhone($query);
    $where[] = '(u.full_name LIKE ? OR u.phone LIKE ?)';
    $params[] = '%' . $query . '%';
    $params[] = '%' . ($digits !== '' ? $digits : $query) . '%';
}
if ($filter === 'blocked') {
    $where[] = 'u.is_blocked = 1';
}
if ($filter === 'active') {
    $where[] = 'u.is_blocked = 0';
}

$sql =
    'SELECT u.*,
            (SELECT COUNT(*) FROM wallets w WHERE w.user_id = u.id) AS wallets_count,
            (SELECT COALESCE(SUM(w.balance), 0) FROM wallets w WHERE w.user_id = u.id AND w.currency = \'KZT\') AS balance,
            (SELECT COUNT(*) FROM credits c WHERE c.user_id = u.id AND c.status = \'active\') AS credits_count,
            (SELECT COUNT(*) FROM deposits d WHERE d.user_id = u.id AND d.status = \'active\') AS deposits_count
     FROM users u';

if (count($where) > 0) {
    $sql .= ' WHERE ' . implode(' AND ', $where);
}
$sql .= ' ORDER BY u.is_blocked DESC, u.id DESC LIMIT 200';

try {
    $st = db()->prepare($sql);
    $st->execute($params);
    $rows = $st->fetchAll();
} catch (Exception $e) {
    jsonOut(500, 'Не удалось получить список клиентов: ' . $e->getMessage());
}

jsonOut(200, 'OK', array(
    'users'    => array_map('adminUserToArray', $rows),
    'admin_id' => (int)$admin['id'],
));
