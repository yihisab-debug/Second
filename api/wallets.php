<?php
require __DIR__ . '/config.php';

$user = currentUser();

$st = db()->prepare('SELECT * FROM wallets WHERE user_id = ? ORDER BY is_default DESC, id ASC');
$st->execute(array((int)$user['id']));

jsonOut(200, 'OK', array('wallets' => array_map('walletToArray', $st->fetchAll())));
