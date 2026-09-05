<?php
require __DIR__ . '/config.php';
require __DIR__ . '/admin_lib.php';

requirePost();
$admin = currentAdmin();

$userId = (int)input('user_id', 0);
$block  = (string)input('block', '1') === '1';
$reason = trim((string)input('reason', ''));

if ($userId < 1) {
    jsonOut(422, 'Не выбран клиент');
}
if ($userId === (int)$admin['id']) {
    jsonOut(422, 'Нельзя заблокировать самого себя');
}

$pdo = db();
$st  = $pdo->prepare('SELECT * FROM users WHERE id = ?');
$st->execute(array($userId));
$target = $st->fetch();

if (!$target) {
    jsonOut(404, 'Клиент не найден');
}
if ($block && isAdminUser($target)) {
    jsonOut(403, 'Нельзя заблокировать другого администратора');
}

try {
    $pdo->beginTransaction();

    if ($block) {
        if ($reason === '') {
            $reason = 'Нарушение правил обслуживания';
        }
        $reason = mb_substr($reason, 0, 255);

        $st = $pdo->prepare(
            'UPDATE users SET is_blocked = 1, blocked_reason = ?, blocked_at = NOW() WHERE id = ?'
        );
        $st->execute(array($reason, $userId));

        // разлогиниваем клиента на всех устройствах
        $st = $pdo->prepare('DELETE FROM tokens WHERE user_id = ?');
        $st->execute(array($userId));

        notify(
            $userId,
            'account_blocked',
            'Аккаунт заблокирован',
            'Причина: ' . $reason
        );
    } else {
        $st = $pdo->prepare(
            'UPDATE users SET is_blocked = 0, blocked_reason = \'\', blocked_at = NULL WHERE id = ?'
        );
        $st->execute(array($userId));

        notify(
            $userId,
            'account_unblocked',
            'Аккаунт разблокирован',
            'Доступ к приложению восстановлен'
        );
    }

    $pdo->commit();
} catch (Exception $e) {
    if ($pdo->inTransaction()) {
        $pdo->rollBack();
    }
    jsonOut(500, 'Не удалось изменить статус клиента: ' . $e->getMessage());
}

adminLog(
    (int)$admin['id'],
    $block ? 'user_block' : 'user_unblock',
    'users',
    $userId,
    $block ? $reason : ''
);

jsonOut(200, $block ? 'Клиент заблокирован' : 'Клиент разблокирован', array(
    'user_id'    => $userId,
    'is_blocked' => $block,
));
