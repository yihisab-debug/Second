<?php
require __DIR__ . '/config.php';
require __DIR__ . '/admin_lib.php';

currentAdmin();

try {
    $st = db()->query(
        'SELECT p.*, (SELECT COUNT(*) FROM deposits d WHERE d.product_id = p.id) AS used_count
         FROM deposit_products p
         ORDER BY p.is_active DESC, p.rate DESC, p.id ASC'
    );
    $rows = $st->fetchAll();
} catch (Exception $e) {
    jsonOut(500, 'Таблица deposit_products недоступна. Запустите 03_deposits.sql. ' . $e->getMessage());
}

jsonOut(200, 'OK', array('services' => array_map('serviceToArray', $rows)));
