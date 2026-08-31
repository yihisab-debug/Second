<?php
require __DIR__ . '/config.php';

$user  = currentUser();
$limit = (int)input('limit', 50);
if ($limit < 1 || $limit > 200) {
    $limit = 50;
}

$st = db()->prepare(
    'SELECT * FROM notifications
     WHERE user_id = ?
     ORDER BY id DESC
     LIMIT ' . $limit
);
$st->execute(array((int)$user['id']));

jsonOut(200, 'OK', array(
    'notifications' => array_map('notificationToArray', $st->fetchAll()),
    'unread'        => unreadNotificationsCount((int)$user['id']),
));
