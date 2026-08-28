<?php
require __DIR__ . '/config.php';
requirePost();

$user = currentUser();

$st = db()->prepare('DELETE FROM tokens WHERE token = ?');
$st->execute(array($user['token']));

jsonOut(200, 'Вы вышли из приложения');
