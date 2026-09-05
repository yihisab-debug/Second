<?php

define('DB_HOST', 'localhost');
define('DB_NAME', 'mini_bank');
define('DB_USER', 'root');
define('DB_PASS', 'root');

header('Content-Type: application/json; charset=utf-8');
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Headers: Content-Type, Authorization');
header('Access-Control-Allow-Methods: POST, GET, OPTIONS');

if (($_SERVER['REQUEST_METHOD'] ?? '') === 'OPTIONS') {
    exit;
}

function db()
{
    static $pdo = null;
    if ($pdo === null) {
        try {
            $pdo = new PDO(
                'mysql:host=' . DB_HOST . ';dbname=' . DB_NAME . ';charset=utf8mb4',
                DB_USER,
                DB_PASS,
                array(
                    PDO::ATTR_ERRMODE            => PDO::ERRMODE_EXCEPTION,
                    PDO::ATTR_DEFAULT_FETCH_MODE => PDO::FETCH_ASSOC,
                    PDO::ATTR_EMULATE_PREPARES   => false,
                )
            );
        } catch (PDOException $e) {
            jsonOut(500, 'Нет подключения к базе данных: ' . $e->getMessage());
        }
    }
    return $pdo;
}

function jsonOut($status, $message, $data = array())
{
    echo json_encode(
        array('status' => $status, 'message' => $message, 'data' => $data),
        JSON_UNESCAPED_UNICODE
    );
    exit;
}

function input($key, $default = null)
{
    static $json = null;
    if ($json === null) {
        $raw = file_get_contents('php://input');
        $decoded = json_decode($raw, true);
        $json = is_array($decoded) ? $decoded : array();
    }
    if (isset($_POST[$key])) return $_POST[$key];
    if (isset($json[$key]))  return $json[$key];
    if (isset($_GET[$key]))  return $_GET[$key];
    return $default;
}

function normalizePhone($phone)
{
    $digits = preg_replace('/\D+/', '', (string)$phone);
    if (strlen($digits) === 11 && $digits[0] === '8') {
        $digits = '7' . substr($digits, 1);
    }
    return $digits;
}

function prettyPhone($phone)
{
    $d = normalizePhone($phone);
    if (strlen($d) === 11 && $d[0] === '7') {
        return '+' . $d[0] . ' (' . substr($d, 1, 3) . ') '
            . substr($d, 4, 3) . '-' . substr($d, 7, 2) . '-' . substr($d, 9, 2);
    }
    if (strlen($d) === 10) {
        return substr($d, 0, 3) . ' ' . substr($d, 3, 3)
            . '-' . substr($d, 6, 2) . '-' . substr($d, 8, 2);
    }
    return $d;
}

function maskPhone($phone)
{
    $d = normalizePhone($phone);
    if (strlen($d) === 11 && $d[0] === '7') {
        return '+' . $d[0] . ' (' . substr($d, 1, 3) . ') ***-**-' . substr($d, 9, 2);
    }
    if (strlen($d) === 10) {
        return substr($d, 0, 3) . ' ***-**-' . substr($d, 8, 2);
    }
    return $d;
}

function parseAmount($value)
{
    $value = str_replace(array(' ', ','), array('', '.'), (string)$value);
    if (!is_numeric($value)) {
        jsonOut(422, 'Некорректная сумма');
    }
    $amount = round((float)$value, 2);
    if ($amount <= 0) {
        jsonOut(422, 'Сумма должна быть больше нуля');
    }
    if ($amount > 100000000) {
        jsonOut(422, 'Слишком большая сумма');
    }
    return $amount;
}

function currentUser()
{
    $token = trim((string)input('token', ''));
    if ($token === '') {
        $header = isset($_SERVER['HTTP_AUTHORIZATION']) ? $_SERVER['HTTP_AUTHORIZATION'] : '';
        if (stripos($header, 'Bearer ') === 0) {
            $token = substr($header, 7);
        }
    }
    if ($token === '') {
        jsonOut(401, 'Требуется вход в приложение');
    }

    $st = db()->prepare(
        'SELECT u.* FROM tokens t
         JOIN users u ON u.id = t.user_id
         WHERE t.token = ? AND t.expires_at > NOW()'
    );
    $st->execute(array($token));
    $user = $st->fetch();

    if (!$user) {
        jsonOut(401, 'Сессия истекла, войдите заново');
    }

    if (isset($user['is_blocked']) && (int)$user['is_blocked'] === 1) {
        $reason = isset($user['blocked_reason']) ? trim((string)$user['blocked_reason']) : '';
        jsonOut(403, $reason === ''
            ? 'Аккаунт заблокирован администратором банка'
            : 'Аккаунт заблокирован: ' . $reason);
    }

    $user['token'] = $token;
    return $user;
}

function isAdminUser($user)
{
    return isset($user['is_admin']) && (int)$user['is_admin'] === 1;
}

function currentAdmin()
{
    $user = currentUser();
    if (!isAdminUser($user)) {
        jsonOut(403, 'Раздел доступен только администратору');
    }
    return $user;
}

function issueToken($userId)
{
    $token = bin2hex(random_bytes(32));
    $st = db()->prepare(
        'INSERT INTO tokens (user_id, token, expires_at)
         VALUES (?, ?, DATE_ADD(NOW(), INTERVAL 30 DAY))'
    );
    $st->execute(array($userId, $token));
    return $token;
}

function generateWalletNumber()
{
    $pdo = db();
    for ($i = 0; $i < 20; $i++) {
        $number = '4400';
        for ($j = 0; $j < 12; $j++) {
            $number .= (string)random_int(0, 9);
        }
        $st = $pdo->prepare('SELECT id FROM wallets WHERE number = ?');
        $st->execute(array($number));
        if (!$st->fetch()) {
            return $number;
        }
    }
    jsonOut(500, 'Не удалось создать номер счёта, попробуйте ещё раз');
}

function createWallet($userId, $title, $currency, $isDefault = 0)
{
    $allowed = array('KZT', 'USD', 'EUR');
    $currency = strtoupper((string)$currency);
    if (!in_array($currency, $allowed, true)) {
        $currency = 'KZT';
    }
    $title = trim((string)$title);
    if ($title === '') {
        $title = 'Кошелёк';
    }
    $st = db()->prepare(
        'INSERT INTO wallets (user_id, title, number, currency, balance, is_default)
         VALUES (?, ?, ?, ?, 0, ?)'
    );
    $st->execute(array($userId, mb_substr($title, 0, 60), generateWalletNumber(), $currency, $isDefault ? 1 : 0));
    return (int)db()->lastInsertId();
}

function walletOfUser($walletId, $userId)
{
    $st = db()->prepare('SELECT * FROM wallets WHERE id = ? AND user_id = ?');
    $st->execute(array((int)$walletId, (int)$userId));
    $wallet = $st->fetch();
    if (!$wallet) {
        jsonOut(404, 'Кошелёк не найден');
    }
    return $wallet;
}

function walletToArray($row)
{
    return array(
        'id'         => (int)$row['id'],
        'title'      => $row['title'],
        'number'     => $row['number'],
        'currency'   => $row['currency'],
        'balance'    => (float)$row['balance'],
        'is_default' => (int)$row['is_default'] === 1,
        'created_at' => $row['created_at'],
    );
}

function transactionToArray($row)
{
    return array(
        'id'            => (int)$row['id'],
        'wallet_id'     => (int)$row['wallet_id'],
        'type'          => $row['type'],
        'amount'        => (float)$row['amount'],
        'balance_after' => (float)$row['balance_after'],
        'title'         => $row['title'],
        'counterparty'  => $row['counterparty'],
        'currency'      => isset($row['currency']) ? $row['currency'] : 'KZT',
        'wallet_title'  => isset($row['wallet_title']) ? $row['wallet_title'] : '',
        'created_at'    => $row['created_at'],
    );
}

function logTransaction($walletId, $type, $amount, $balanceAfter, $title, $counterparty = null)
{
    $st = db()->prepare(
        'INSERT INTO transactions (wallet_id, type, amount, balance_after, title, counterparty)
         VALUES (?, ?, ?, ?, ?, ?)'
    );
    $st->execute(array((int)$walletId, $type, $amount, $balanceAfter, $title, $counterparty));
}

function notify($userId, $type, $title, $body = '', $amount = null, $currency = null)
{
    $st = db()->prepare(
        'INSERT INTO notifications (user_id, type, title, body, amount, currency)
         VALUES (?, ?, ?, ?, ?, ?)'
    );
    $st->execute(array(
        (int)$userId,
        mb_substr((string)$type, 0, 30),
        mb_substr((string)$title, 0, 120),
        mb_substr((string)$body, 0, 255),
        $amount === null ? null : round((float)$amount, 2),
        $currency === null ? null : mb_substr((string)$currency, 0, 3),
    ));
    return (int)db()->lastInsertId();
}

function notificationToArray($row)
{
    return array(
        'id'         => (int)$row['id'],
        'type'       => $row['type'],
        'title'      => $row['title'],
        'body'       => $row['body'],
        'amount'     => $row['amount'] === null ? null : (float)$row['amount'],
        'currency'   => $row['currency'] === null ? '' : $row['currency'],
        'is_read'    => (int)$row['is_read'] === 1,
        'created_at' => $row['created_at'],
    );
}

function unreadNotificationsCount($userId)
{
    try {
        $st = db()->prepare('SELECT COUNT(*) AS c FROM notifications WHERE user_id = ? AND is_read = 0');
        $st->execute(array((int)$userId));
        $row = $st->fetch();
        return (int)$row['c'];
    } catch (Exception $e) {
        return 0;
    }
}

function employmentStatuses()
{
    return array(
        'employed' => array(
            'label'         => 'Работаю официально',
            'hint'          => 'Трудовой договор и стабильная зарплата',
            'can_credit'    => 1,
            'need_employer' => 1,
            'min_income'    => 85000,
            'min_months'    => 3,
            'max_amount'    => 5000000,
            'payment_part'  => 0.50,
        ),
        'self_employed' => array(
            'label'         => 'ИП или самозанятый',
            'hint'          => 'Свой бизнес, доход меняется по месяцам',
            'can_credit'    => 1,
            'need_employer' => 1,
            'min_income'    => 120000,
            'min_months'    => 6,
            'max_amount'    => 3000000,
            'payment_part'  => 0.40,
        ),
        'retired' => array(
            'label'         => 'Пенсионер',
            'hint'          => 'Получаю пенсию каждый месяц',
            'can_credit'    => 1,
            'need_employer' => 0,
            'min_income'    => 60000,
            'min_months'    => 0,
            'max_amount'    => 1000000,
            'payment_part'  => 0.35,
        ),
        'student' => array(
            'label'         => 'Студент',
            'hint'          => 'Учусь, есть стипендия или подработка',
            'can_credit'    => 1,
            'need_employer' => 0,
            'min_income'    => 50000,
            'min_months'    => 0,
            'max_amount'    => 500000,
            'payment_part'  => 0.30,
        ),
        'unemployed' => array(
            'label'         => 'Временно не работаю',
            'hint'          => 'Постоянного дохода сейчас нет',
            'can_credit'    => 0,
            'need_employer' => 0,
            'min_income'    => 0,
            'min_months'    => 0,
            'max_amount'    => 0,
            'payment_part'  => 0,
        ),
    );
}

function employmentStatus($code)
{
    $all  = employmentStatuses();
    $code = (string)$code;
    return isset($all[$code]) ? $all[$code] : null;
}

function toKzt($amount, $currency)
{
    switch (strtoupper((string)$currency)) {
        case 'USD':
            return round((float)$amount * 500, 2);
        case 'EUR':
            return round((float)$amount * 540, 2);
        default:
            return round((float)$amount, 2);
    }
}

function moneyKzt($value)
{
    return number_format((float)$value, 0, ',', ' ') . ' ₸';
}

function employmentToArray($user)
{
    $code  = isset($user['employment_status']) ? (string)$user['employment_status'] : '';
    $rules = employmentStatus($code);

    return array(
        'status'            => $rules === null ? '' : $code,
        'status_label'      => $rules === null ? '' : $rules['label'],
        'employer'          => isset($user['employer']) ? (string)$user['employer'] : '',
        'monthly_income'    => isset($user['monthly_income']) ? (float)$user['monthly_income'] : 0.0,
        'experience_months' => isset($user['experience_months']) ? (int)$user['experience_months'] : 0,
        'is_filled'         => $rules !== null,
        'can_credit'        => $rules !== null && (int)$rules['can_credit'] === 1,
        'min_income'        => $rules === null ? 0.0 : (float)$rules['min_income'],
        'min_months'        => $rules === null ? 0 : (int)$rules['min_months'],
        'max_amount'        => $rules === null ? 0.0 : (float)$rules['max_amount'],
        'payment_part'      => $rules === null ? 0.0 : (float)$rules['payment_part'],
        'updated_at'        => isset($user['employment_at']) && $user['employment_at'] !== null
            ? $user['employment_at']
            : '',
    );
}

function activeCreditsPayment($userId)
{
    try {
        $st = db()->prepare(
            'SELECT monthly_payment, currency FROM credits WHERE user_id = ? AND status = ?'
        );
        $st->execute(array((int)$userId, 'active'));

        $total = 0;
        foreach ($st->fetchAll() as $row) {
            $total += toKzt($row['monthly_payment'], $row['currency']);
        }
        return round($total, 2);
    } catch (Exception $e) {
        return 0.0;
    }
}

function creditLimit($user)
{
    $code  = isset($user['employment_status']) ? $user['employment_status'] : '';
    $rules = employmentStatus($code);

    if ($rules === null || (int)$rules['can_credit'] !== 1) {
        return 0.0;
    }

    $income = isset($user['monthly_income']) ? (float)$user['monthly_income'] : 0.0;
    $free   = round($income * $rules['payment_part'], 2) - activeCreditsPayment((int)$user['id']);

    if ($free <= 0) {
        return 0.0;
    }

    $byIncome = round($free * 12, 2);
    return $byIncome < (float)$rules['max_amount'] ? $byIncome : (float)$rules['max_amount'];
}

function creditDecision($user, $amount, $monthlyPayment, $currency)
{
    $code  = isset($user['employment_status']) ? (string)$user['employment_status'] : '';
    $rules = employmentStatus($code);

    if ($rules === null) {
        return array(
            'allowed' => false,
            'message' => 'Сначала укажите статус занятости в профиле, без него кредит не оформляется',
        );
    }

    if ((int)$rules['can_credit'] !== 1) {
        return array(
            'allowed' => false,
            'message' => 'Со статусом «' . $rules['label'] . '» банк кредит не выдаёт',
        );
    }

    $income = isset($user['monthly_income']) ? (float)$user['monthly_income'] : 0.0;
    if ($income < (float)$rules['min_income']) {
        return array(
            'allowed' => false,
            'message' => 'Для статуса «' . $rules['label'] . '» нужен доход от '
                . moneyKzt($rules['min_income']) . ' в месяц, а указано ' . moneyKzt($income),
        );
    }

    $experience = isset($user['experience_months']) ? (int)$user['experience_months'] : 0;
    if ($experience < (int)$rules['min_months']) {
        return array(
            'allowed' => false,
            'message' => 'Нужен стаж от ' . (int)$rules['min_months']
                . ' мес., а указано ' . $experience,
        );
    }

    $amountKzt = toKzt($amount, $currency);
    if ($amountKzt > (float)$rules['max_amount']) {
        return array(
            'allowed' => false,
            'message' => 'Со статусом «' . $rules['label'] . '» максимальная сумма кредита — '
                . moneyKzt($rules['max_amount']),
        );
    }

    $payment = toKzt($monthlyPayment, $currency) + activeCreditsPayment((int)$user['id']);
    $allowed = round($income * $rules['payment_part'], 2);

    if ($payment > $allowed) {
        return array(
            'allowed' => false,
            'message' => 'Платежи по кредитам составят ' . moneyKzt($payment)
                . ' в месяц, а с вашим доходом банк одобряет до ' . moneyKzt($allowed),
        );
    }

    return array(
        'allowed' => true,
        'message' => 'Кредит одобрен',
    );
}

function requireCreditAllowed($user, $amount, $monthlyPayment, $currency)
{
    $decision = creditDecision($user, $amount, $monthlyPayment, $currency);
    if (!$decision['allowed']) {
        jsonOut(403, $decision['message']);
    }
    return $decision;
}

function requirePost()
{
    if (($_SERVER['REQUEST_METHOD'] ?? '') !== 'POST') {
        jsonOut(405, 'Метод не поддерживается, нужен POST');
    }
}
