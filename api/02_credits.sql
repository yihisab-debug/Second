
CREATE TABLE IF NOT EXISTS creditors (
    id          INT AUTO_INCREMENT PRIMARY KEY,
    name        VARCHAR(80)     NOT NULL,
    description VARCHAR(255)    NOT NULL DEFAULT '',
    rate        DECIMAL(5, 2)   NOT NULL DEFAULT 0,
    min_amount  DECIMAL(15, 2)  NOT NULL DEFAULT 10000,
    max_amount  DECIMAL(15, 2)  NOT NULL DEFAULT 1000000,
    min_months  INT             NOT NULL DEFAULT 3,
    max_months  INT             NOT NULL DEFAULT 60,
    currency    VARCHAR(3)      NOT NULL DEFAULT 'KZT',
    is_active   TINYINT(1)      NOT NULL DEFAULT 1,
    created_at  TIMESTAMP       NOT NULL DEFAULT CURRENT_TIMESTAMP,

    KEY idx_creditors_active (is_active, id)
) ENGINE = InnoDB DEFAULT CHARSET = utf8mb4;

CREATE TABLE IF NOT EXISTS credits (
    id              INT AUTO_INCREMENT PRIMARY KEY,
    user_id         INT             NOT NULL,
    creditor_id     INT             NOT NULL,
    wallet_id       INT             NULL,
    amount          DECIMAL(15, 2)  NOT NULL,
    rate            DECIMAL(5, 2)   NOT NULL,
    months          INT             NOT NULL,
    monthly_payment DECIMAL(15, 2)  NOT NULL,
    total_amount    DECIMAL(15, 2)  NOT NULL,
    paid_amount     DECIMAL(15, 2)  NOT NULL DEFAULT 0,
    currency        VARCHAR(3)      NOT NULL DEFAULT 'KZT',
    purpose         VARCHAR(120)    NOT NULL DEFAULT '',
    status          VARCHAR(10)     NOT NULL DEFAULT 'active',
    created_at      TIMESTAMP       NOT NULL DEFAULT CURRENT_TIMESTAMP,
    closed_at       DATETIME        NULL,

    KEY idx_credits_user (user_id, status, id),
    KEY idx_credits_creditor (creditor_id),

    CONSTRAINT fk_credits_user
        FOREIGN KEY (user_id) REFERENCES users (id)
        ON DELETE CASCADE,

    CONSTRAINT fk_credits_creditor
        FOREIGN KEY (creditor_id) REFERENCES creditors (id),

    CONSTRAINT fk_credits_wallet
        FOREIGN KEY (wallet_id) REFERENCES wallets (id)
        ON DELETE SET NULL
) ENGINE = InnoDB DEFAULT CHARSET = utf8mb4;

INSERT IGNORE INTO creditors
    (id, name, description, rate, min_amount, max_amount, min_months, max_months, currency)
VALUES
    (1, 'MiniBank Классик',   'Универсальный кредит на любые цели без залога.',        18.90,  30000.00, 1500000.00,  6, 60, 'KZT'),
    (2, 'MiniBank Экспресс',  'Небольшая сумма до зарплаты, решение за минуту.',        28.50,  10000.00,  200000.00,  3, 12, 'KZT'),
    (3, 'Народный Кредит',    'Кредит на ремонт и бытовую технику со сниженной ставкой.',15.40,  50000.00, 2000000.00, 12, 48, 'KZT'),
    (4, 'АвтоФинанс',         'Целевой кредит на покупку автомобиля.',                  13.90, 500000.00, 8000000.00, 12, 84, 'KZT'),
    (5, 'СтудентПлюс',        'Льготный кредит на обучение для студентов.',              9.90,  50000.00, 1200000.00, 12, 36, 'KZT');
