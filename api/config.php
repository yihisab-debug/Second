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
    $user['token'] = $token;
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

function requirePost()
{
    if (($_SERVER['REQUEST_METHOD'] ?? '') !== 'POST') {
        jsonOut(405, 'Метод не поддерживается, нужен POST');
    }
}
