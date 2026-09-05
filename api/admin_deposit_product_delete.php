<?php
require __DIR__ . '/config.php';
require __DIR__ . '/admin_lib.php';

requirePost();
$admin = currentAdmin();

deleteService('deposit_products', 'deposits', 'product_id', (int)$admin['id'], 'Депозитная программа');
