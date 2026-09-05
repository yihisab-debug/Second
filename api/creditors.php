<?php
require __DIR__ . '/config.php';
require __DIR__ . '/credits_lib.php';

currentUser();

try {
    $st = db()->query('SELECT * FROM creditors WHERE is_active = 1 ORDER BY rate ASC, id ASC');
    $rows = $st->fetchAll();
} catch (Exception $e) {
    jsonOut(500, 'Таблица creditors недоступна. Запустите 02_credits.sql. ' . $e->getMessage());
}

jsonOut(200, 'OK', array(
    'creditors' => array_map('creditorToArray', $rows),
));
