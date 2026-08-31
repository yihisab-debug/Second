<?php
require __DIR__ . '/config.php';
requirePost();

$user = currentUser();
$id   = (int)input('id', 0);

if ($id > 0) {
    $st = db()->prepare('UPDATE notifications SET is_read = 1 WHERE id = ? AND user_id = ?');
    $st->execute(array($id, (int)$user['id']));
} else {
    $st = db()->prepare('UPDATE notifications SET is_read = 1 WHERE user_id = ? AND is_read = 0');
    $st->execute(array((int)$user['id']));
}

jsonOut(200, 'Уведомления прочитаны', array(
    'unread' => unreadNotificationsCount((int)$user['id']),
));
