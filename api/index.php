<?php
require __DIR__ . '/config.php';

$tables = array();
try {
    foreach (db()->query('SHOW TABLES') as $row) {
        $tables[] = array_values($row)[0];
    }
} catch (Exception $e) {
    jsonOut(500, 'База не отвечает: ' . $e->getMessage());
}

jsonOut(200, 'MiniBank API работает', array(
    'php_version' => PHP_VERSION,
    'database'    => DB_NAME,
    'tables'      => $tables,
));
