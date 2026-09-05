<?php

function depositIncome($amount, $rate, $months)
{
    $amount = (float)$amount;
    $months = (int)$months;
    if ($months < 1) {
        return 0.0;
    }
    return round($amount * ((float)$rate / 100) * $months / 12, 2);
}

function depositProductToArray($row)
{
    return array(
        'id'          => (int)$row['id'],
        'name'        => $row['name'],
        'description' => $row['description'],
        'rate'        => (float)$row['rate'],
        'min_amount'  => (float)$row['min_amount'],
        'max_amount'  => (float)$row['max_amount'],
        'min_months'  => (int)$row['min_months'],
        'max_months'  => (int)$row['max_months'],
        'currency'    => $row['currency'],
        'is_active'   => (int)$row['is_active'] === 1,
    );
}

function depositToArray($row)
{
    $daysTotal = isset($row['days_total']) ? (int)$row['days_total'] : 0;
    $daysLeft  = isset($row['days_left']) ? (int)$row['days_left'] : 0;

    $progress = 0.0;
    if ($daysTotal > 0) {
        $progress = ($daysTotal - $daysLeft) / $daysTotal;
        if ($progress < 0) {
            $progress = 0.0;
        }
        if ($progress > 1) {
            $progress = 1.0;
        }
    }

    return array(
        'id'           => (int)$row['id'],
        'product_id'   => (int)$row['product_id'],
        'product_name' => isset($row['product_name']) ? $row['product_name'] : '',
        'wallet_id'    => $row['wallet_id'] === null ? 0 : (int)$row['wallet_id'],
        'wallet_title' => isset($row['wallet_title']) && $row['wallet_title'] !== null ? $row['wallet_title'] : '',
        'amount'       => (float)$row['amount'],
        'rate'         => (float)$row['rate'],
        'months'       => (int)$row['months'],
        'income'       => (float)$row['income'],
        'total_amount' => (float)$row['total_amount'],
        'currency'     => $row['currency'],
        'status'       => $row['status'],
        'opened_at'    => $row['opened_at'],
        'ends_at'      => $row['ends_at'],
        'closed_at'    => $row['closed_at'] === null ? '' : $row['closed_at'],
        'days_left'    => $daysLeft,
        'progress'     => round($progress, 4),
        'is_matured'   => isset($row['is_matured']) && (int)$row['is_matured'] === 1,
    );
}

function depositProductById($id)
{
    $st = db()->prepare('SELECT * FROM deposit_products WHERE id = ? AND is_active = 1');
    $st->execute(array((int)$id));
    $row = $st->fetch();
    if (!$row) {
        jsonOut(404, 'Программа вклада не найдена');
    }
    return $row;
}

function depositOfUser($depositId, $userId)
{
    $st = db()->prepare(
        'SELECT d.*, p.name AS product_name,
                CASE WHEN NOW() >= d.ends_at THEN 1 ELSE 0 END AS is_matured
         FROM deposits d
         JOIN deposit_products p ON p.id = d.product_id
         WHERE d.id = ? AND d.user_id = ?'
    );
    $st->execute(array((int)$depositId, (int)$userId));
    $row = $st->fetch();
    if (!$row) {
        jsonOut(404, 'Вклад не найден');
    }
    return $row;
}
