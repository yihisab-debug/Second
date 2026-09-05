<?php
require __DIR__ . '/config.php';
require __DIR__ . '/admin_lib.php';

requirePost();
$admin = currentAdmin();

toggleService('creditors', (int)$admin['id'], 'Кредитная программа');
