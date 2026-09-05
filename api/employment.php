<?php
require __DIR__ . '/config.php';

$user = currentUser();

$statuses = array();
foreach (employmentStatuses() as $code => $rules) {
    $statuses[] = array(
        'code'          => $code,
        'label'         => $rules['label'],
        'hint'          => $rules['hint'],
        'can_credit'    => (int)$rules['can_credit'] === 1,
        'need_employer' => (int)$rules['need_employer'] === 1,
        'min_income'    => (float)$rules['min_income'],
        'min_months'    => (int)$rules['min_months'],
        'max_amount'    => (float)$rules['max_amount'],
        'payment_part'  => (float)$rules['payment_part'],
    );
}

jsonOut(200, 'OK', array(
    'employment'      => employmentToArray($user),
    'statuses'        => $statuses,
    'decision'        => creditDecision($user, 0, 0, 'KZT'),
    'credit_limit'    => creditLimit($user),
    'current_payment' => activeCreditsPayment((int)$user['id']),
));
