<?php
require __DIR__ . '/config.php';
require __DIR__ . '/admin_lib.php';

currentAdmin();

try {
    $st = db()->query(
        'SELECT c.*, (SELECT COUNT(*) FROM credits k WHERE k.creditor_id = c.id) AS used_count
         FROM creditors c
         ORDER BY c.is_active DESC, c.rate ASC, c.id ASC'
    );
    $rows = $st->fetchAll();
} catch (Exception $e) {
    jsonOut(500, 'Таблица creditors недоступна. Запустите 02_credits.sql. ' . $e->getMessage());
}

jsonOut(200, 'OK', array('services' => array_map('serviceToArray', $rows)));
