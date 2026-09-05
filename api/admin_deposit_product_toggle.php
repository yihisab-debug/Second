<?php
require __DIR__ . '/config.php';
require __DIR__ . '/admin_lib.php';

requirePost();
$admin = currentAdmin();

toggleService('deposit_products', (int)$admin['id'], 'Депозитная программа');
