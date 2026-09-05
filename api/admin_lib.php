<?php

/**
 * Общие функции админ-панели: журнал действий, валидация услуг,
 * преобразование строк БД в массивы для JSON.
 */

function adminLog($adminId, $action, $targetType = '', $targetId = 0, $details = '')
{
    try {
        $st = db()->prepare(
            'INSERT INTO admin_log (admin_id, action, target_type, target_id, details)
             VALUES (?, ?, ?, ?, ?)'
        );
        $st->execute(array(
            (int)$adminId,
            mb_substr((string)$action, 0, 40),
            mb_substr((string)$targetType, 0, 30),
            (int)$targetId,
            mb_substr((string)$details, 0, 255),
        ));
    } catch (Exception $e) {
        // журнал не должен ломать основную операцию
    }
}

function adminUserToArray($row)
{
    return array(
        'id'             => (int)$row['id'],
        'full_name'      => $row['full_name'],
        'phone'          => $row['phone'],
        'phone_pretty'   => prettyPhone($row['phone']),
        'is_admin'       => isset($row['is_admin']) && (int)$row['is_admin'] === 1,
        'is_blocked'     => isset($row['is_blocked']) && (int)$row['is_blocked'] === 1,
        'blocked_reason' => isset($row['blocked_reason']) ? (string)$row['blocked_reason'] : '',
        'blocked_at'     => isset($row['blocked_at']) && $row['blocked_at'] !== null ? $row['blocked_at'] : '',
        'created_at'     => $row['created_at'],
        'wallets_count'  => isset($row['wallets_count']) ? (int)$row['wallets_count'] : 0,
        'balance'        => isset($row['balance']) ? round((float)$row['balance'], 2) : 0.0,
        'credits_count'  => isset($row['credits_count']) ? (int)$row['credits_count'] : 0,
        'deposits_count' => isset($row['deposits_count']) ? (int)$row['deposits_count'] : 0,
        'employment'     => employmentToArray($row),
    );
}

function serviceToArray($row)
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
        'used_count'  => isset($row['used_count']) ? (int)$row['used_count'] : 0,
        'created_at'  => $row['created_at'],
    );
}

/**
 * Проверяет и нормализует поля новой услуги (кредитная программа или вклад).
 * Возвращает готовый массив значений либо отдаёт ошибку 422.
 */
function readServiceInput()
{
    $name        = trim((string)input('name', ''));
    $description = trim((string)input('description', ''));
    $rate        = str_replace(',', '.', (string)input('rate', ''));
    $minAmount   = str_replace(array(' ', ','), array('', '.'), (string)input('min_amount', ''));
    $maxAmount   = str_replace(array(' ', ','), array('', '.'), (string)input('max_amount', ''));
    $minMonths   = (int)input('min_months', 0);
    $maxMonths   = (int)input('max_months', 0);
    $currency    = strtoupper(trim((string)input('currency', 'KZT')));
    $isActive    = (string)input('is_active', '1');

    if (mb_strlen($name) < 3) {
        jsonOut(422, 'Название должно содержать минимум 3 символа');
    }
    if (mb_strlen($name) > 80) {
        jsonOut(422, 'Название не длиннее 80 символов');
    }
    if (!is_numeric($rate)) {
        jsonOut(422, 'Ставка указана неверно');
    }
    $rate = round((float)$rate, 2);
    if ($rate < 0 || $rate > 100) {
        jsonOut(422, 'Ставка должна быть в диапазоне от 0 до 100 %');
    }
    if (!is_numeric($minAmount) || !is_numeric($maxAmount)) {
        jsonOut(422, 'Суммы указаны неверно');
    }
    $minAmount = round((float)$minAmount, 2);
    $maxAmount = round((float)$maxAmount, 2);
    if ($minAmount <= 0) {
        jsonOut(422, 'Минимальная сумма должна быть больше нуля');
    }
    if ($maxAmount < $minAmount) {
        jsonOut(422, 'Максимальная сумма не может быть меньше минимальной');
    }
    if ($maxAmount > 100000000) {
        jsonOut(422, 'Максимальная сумма слишком большая');
    }
    if ($minMonths < 1 || $minMonths > 240) {
        jsonOut(422, 'Минимальный срок — от 1 до 240 месяцев');
    }
    if ($maxMonths < $minMonths || $maxMonths > 240) {
        jsonOut(422, 'Максимальный срок не может быть меньше минимального');
    }
    if (!in_array($currency, array('KZT', 'USD', 'EUR'), true)) {
        $currency = 'KZT';
    }

    return array(
        'name'        => mb_substr($name, 0, 80),
        'description' => mb_substr($description, 0, 255),
        'rate'        => $rate,
        'min_amount'  => $minAmount,
        'max_amount'  => $maxAmount,
        'min_months'  => $minMonths,
        'max_months'  => $maxMonths,
        'currency'    => $currency,
        'is_active'   => ($isActive === '0' || $isActive === 'false') ? 0 : 1,
    );
}

/**
 * Универсальное сохранение услуги.
 * $table       — creditors или deposit_products
 * $usageTable  — credits или deposits
 * $usageColumn — creditor_id или product_id
 */
function saveService($table, $adminId, $entityLabel)
{
    $id     = (int)input('id', 0);
    $fields = readServiceInput();
    $pdo    = db();

    if ($id > 0) {
        $st = $pdo->prepare('SELECT id FROM ' . $table . ' WHERE id = ?');
        $st->execute(array($id));
        if (!$st->fetch()) {
            jsonOut(404, $entityLabel . ' не найдена');
        }

        $st = $pdo->prepare(
            'UPDATE ' . $table . '
             SET name = ?, description = ?, rate = ?, min_amount = ?, max_amount = ?,
                 min_months = ?, max_months = ?, currency = ?, is_active = ?
             WHERE id = ?'
        );
        $st->execute(array(
            $fields['name'], $fields['description'], $fields['rate'],
            $fields['min_amount'], $fields['max_amount'],
            $fields['min_months'], $fields['max_months'],
            $fields['currency'], $fields['is_active'], $id,
        ));

        adminLog($adminId, 'service_update', $table, $id, $fields['name']);
        jsonOut(200, $entityLabel . ' обновлена', array('id' => $id));
    }

    $st = $pdo->prepare(
        'INSERT INTO ' . $table . '
            (name, description, rate, min_amount, max_amount, min_months, max_months, currency, is_active)
         VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)'
    );
    $st->execute(array(
        $fields['name'], $fields['description'], $fields['rate'],
        $fields['min_amount'], $fields['max_amount'],
        $fields['min_months'], $fields['max_months'],
        $fields['currency'], $fields['is_active'],
    ));

    $newId = (int)$pdo->lastInsertId();
    adminLog($adminId, 'service_create', $table, $newId, $fields['name']);
    jsonOut(200, $entityLabel . ' добавлена', array('id' => $newId));
}

/**
 * Удаление услуги: если ей уже пользуются клиенты — только отключение.
 */
function deleteService($table, $usageTable, $usageColumn, $adminId, $entityLabel)
{
    $id = (int)input('id', 0);
    if ($id < 1) {
        jsonOut(422, 'Не выбрана запись');
    }

    $pdo = db();
    $st  = $pdo->prepare('SELECT * FROM ' . $table . ' WHERE id = ?');
    $st->execute(array($id));
    $row = $st->fetch();
    if (!$row) {
        jsonOut(404, $entityLabel . ' не найдена');
    }

    $st = $pdo->prepare('SELECT COUNT(*) AS c FROM ' . $usageTable . ' WHERE ' . $usageColumn . ' = ?');
    $st->execute(array($id));
    $used = (int)$st->fetch()['c'];

    if ($used > 0) {
        $st = $pdo->prepare('UPDATE ' . $table . ' SET is_active = 0 WHERE id = ?');
        $st->execute(array($id));
        adminLog($adminId, 'service_disable', $table, $id, $row['name']);
        jsonOut(200, $entityLabel . ' уже используется клиентами, поэтому она снята с продажи, а не удалена');
    }

    $st = $pdo->prepare('DELETE FROM ' . $table . ' WHERE id = ?');
    $st->execute(array($id));
    adminLog($adminId, 'service_delete', $table, $id, $row['name']);
    jsonOut(200, $entityLabel . ' удалена');
}

/**
 * Включение / отключение услуги без открытия формы.
 */
function toggleService($table, $adminId, $entityLabel)
{
    $id     = (int)input('id', 0);
    $active = (string)input('is_active', '1') === '1' ? 1 : 0;

    if ($id < 1) {
        jsonOut(422, 'Не выбрана запись');
    }

    $pdo = db();
    $st  = $pdo->prepare('SELECT name FROM ' . $table . ' WHERE id = ?');
    $st->execute(array($id));
    $row = $st->fetch();
    if (!$row) {
        jsonOut(404, $entityLabel . ' не найдена');
    }

    $st = $pdo->prepare('UPDATE ' . $table . ' SET is_active = ? WHERE id = ?');
    $st->execute(array($active, $id));

    adminLog($adminId, $active ? 'service_enable' : 'service_disable', $table, $id, $row['name']);
    jsonOut(200, $active ? $entityLabel . ' снова доступна клиентам' : $entityLabel . ' снята с продажи');
}
