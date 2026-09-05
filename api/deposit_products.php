<?php
require __DIR__ . '/config.php';
require __DIR__ . '/deposits_lib.php';

currentUser();

try {
    $st = db()->query('SELECT * FROM deposit_products WHERE is_active = 1 ORDER BY rate DESC, id ASC');
    $rows = $st->fetchAll();
} catch (Exception $e) {
    jsonOut(500, 'Таблица deposit_products недоступна. Запустите 03_deposits.sql. ' . $e->getMessage());
}

jsonOut(200, 'OK', array(
    'products' => array_map('depositProductToArray', $rows),
));
