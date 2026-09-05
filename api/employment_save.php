<?php
require __DIR__ . '/config.php';
requirePost();

$user   = currentUser();
$status = trim((string)input('employment_status', ''));
$rules  = employmentStatus($status);

if ($rules === null) {
    jsonOut(422, 'Выберите статус занятости из списка');
}

$employer   = trim((string)input('employer', ''));
$income     = str_replace(array(' ', ','), array('', '.'), (string)input('monthly_income', '0'));
$experience = (int)input('experience_months', 0);

if (!is_numeric($income)) {
    jsonOut(422, 'Доход указан неверно');
}

$income = round((float)$income, 2);

if ($income < 0) {
    jsonOut(422, 'Доход не может быть отрицательным');
}
if ($income > 100000000) {
    jsonOut(422, 'Слишком большой доход');
}
if ($experience < 0 || $experience > 600) {
    jsonOut(422, 'Стаж укажите в месяцах, от 0 до 600');
}

if ((int)$rules['can_credit'] !== 1) {
    $employer   = '';
    $income     = 0;
    $experience = 0;
}

if ((int)$rules['need_employer'] === 1 && $employer === '') {
    jsonOut(422, 'Укажите место работы');
}

$employer = mb_substr($employer, 0, 120);

try {
    $st = db()->prepare(
        'UPDATE users
         SET employment_status = ?, employer = ?, monthly_income = ?,
             experience_months = ?, employment_at = NOW()
         WHERE id = ?'
    );
    $st->execute(array($status, $employer, $income, $experience, (int)$user['id']));
} catch (Exception $e) {
    jsonOut(500, 'Не удалось сохранить статус занятости: ' . $e->getMessage());
}

$user['employment_status'] = $status;
$user['employer']          = $employer;
$user['monthly_income']    = $income;
$user['experience_months'] = $experience;

$decision = creditDecision($user, 0, 0, 'KZT');

notify(
    (int)$user['id'],
    'employment',
    'Статус занятости обновлён',
    $decision['allowed']
        ? $rules['label'] . ', кредиты доступны'
        : $decision['message']
);

jsonOut(200, 'Статус занятости сохранён', array(
    'employment'   => employmentToArray($user),
    'decision'     => $decision,
    'credit_limit' => creditLimit($user),
));
