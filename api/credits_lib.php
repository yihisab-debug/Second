<?php

function annuityPayment($amount, $rate, $months)
{
    $amount = (float)$amount;
    $months = (int)$months;
    $monthRate = (float)$rate / 100 / 12;

    if ($months < 1) {
        return round($amount, 2);
    }
    if ($monthRate <= 0) {
        return round($amount / $months, 2);
    }

    $k = pow(1 + $monthRate, $months);
    return round($amount * $monthRate * $k / ($k - 1), 2);
}

function creditorToArray($row)
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

function creditToArray($row)
{
    $total     = (float)$row['total_amount'];
    $paid      = (float)$row['paid_amount'];
    $remaining = round($total - $paid, 2);
    if ($remaining < 0) {
        $remaining = 0;
    }

    return array(
        'id'              => (int)$row['id'],
        'creditor_id'     => (int)$row['creditor_id'],
        'creditor_name'   => isset($row['creditor_name']) ? $row['creditor_name'] : '',
        'wallet_id'       => $row['wallet_id'] === null ? 0 : (int)$row['wallet_id'],
        'wallet_title'    => isset($row['wallet_title']) && $row['wallet_title'] !== null ? $row['wallet_title'] : '',
        'amount'          => (float)$row['amount'],
        'rate'            => (float)$row['rate'],
        'months'          => (int)$row['months'],
        'monthly_payment' => (float)$row['monthly_payment'],
        'total_amount'    => $total,
        'paid_amount'     => $paid,
        'remaining'       => $remaining,
        'currency'        => $row['currency'],
        'purpose'         => $row['purpose'],
        'status'          => $row['status'],
        'created_at'      => $row['created_at'],
        'closed_at'       => $row['closed_at'] === null ? '' : $row['closed_at'],
    );
}

function creditorById($id)
{
    $st = db()->prepare('SELECT * FROM creditors WHERE id = ? AND is_active = 1');
    $st->execute(array((int)$id));
    $row = $st->fetch();
    if (!$row) {
        jsonOut(404, 'Кредитор не найден');
    }
    return $row;
}

function creditOfUser($creditId, $userId)
{
    $st = db()->prepare(
        'SELECT c.*, cr.name AS creditor_name
         FROM credits c
         JOIN creditors cr ON cr.id = c.creditor_id
         WHERE c.id = ? AND c.user_id = ?'
    );
    $st->execute(array((int)$creditId, (int)$userId));
    $row = $st->fetch();
    if (!$row) {
        jsonOut(404, 'Кредит не найден');
    }
    return $row;
}
