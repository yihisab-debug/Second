<?php
require __DIR__ . '/config.php';
require __DIR__ . '/admin_lib.php';

requirePost();
$admin = currentAdmin();

deleteService('creditors', 'credits', 'creditor_id', (int)$admin['id'], 'Кредитная программа');
