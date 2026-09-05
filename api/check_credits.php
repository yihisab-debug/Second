<?php
require __DIR__ . '/config.php';

$report = array(
    'files' => array(
        'credits_lib.php'   => file_exists(__DIR__ . '/credits_lib.php'),
        'creditors.php'     => file_exists(__DIR__ . '/creditors.php'),
        'credits.php'       => file_exists(__DIR__ . '/credits.php'),
        'credit_create.php' => file_exists(__DIR__ . '/credit_create.php'),
        'credit_pay.php'    => file_exists(__DIR__ . '/credit_pay.php'),
    ),
    'tables' => array(
        'creditors' => false,
        'credits'   => false,
    ),
    'creditors_count' => 0,
);

foreach (db()->query('SHOW TABLES') as $row) {
    $name = array_values($row)[0];
    if (isset($report['tables'][$name])) {
        $report['tables'][$name] = true;
    }
}

if ($report['tables']['creditors']) {
    $row = db()->query('SELECT COUNT(*) AS c FROM creditors')->fetch();
    $report['creditors_count'] = (int)$row['c'];
}

jsonOut(200, 'Проверка раздела «Кредиты»', $report);
