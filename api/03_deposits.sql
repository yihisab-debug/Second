CREATE TABLE IF NOT EXISTS deposit_products (
    id          INT AUTO_INCREMENT PRIMARY KEY,
    name        VARCHAR(80)     NOT NULL,
    description VARCHAR(255)    NOT NULL DEFAULT '',
    rate        DECIMAL(5, 2)   NOT NULL DEFAULT 0,
    min_amount  DECIMAL(15, 2)  NOT NULL DEFAULT 10000,
    max_amount  DECIMAL(15, 2)  NOT NULL DEFAULT 10000000,
    min_months  INT             NOT NULL DEFAULT 3,
    max_months  INT             NOT NULL DEFAULT 36,
    currency    VARCHAR(3)      NOT NULL DEFAULT 'KZT',
    is_active   TINYINT(1)      NOT NULL DEFAULT 1,
    created_at  TIMESTAMP       NOT NULL DEFAULT CURRENT_TIMESTAMP,

    KEY idx_deposit_products_active (is_active, id)
) ENGINE = InnoDB DEFAULT CHARSET = utf8mb4;

CREATE TABLE IF NOT EXISTS deposits (
    id           INT AUTO_INCREMENT PRIMARY KEY,
    user_id      INT             NOT NULL,
    product_id   INT             NOT NULL,
    wallet_id    INT             NULL,
    amount       DECIMAL(15, 2)  NOT NULL,
    rate         DECIMAL(5, 2)   NOT NULL,
    months       INT             NOT NULL,
    income       DECIMAL(15, 2)  NOT NULL DEFAULT 0,
    total_amount DECIMAL(15, 2)  NOT NULL DEFAULT 0,
    currency     VARCHAR(3)      NOT NULL DEFAULT 'KZT',
    status       VARCHAR(10)     NOT NULL DEFAULT 'active',
    opened_at    TIMESTAMP       NOT NULL DEFAULT CURRENT_TIMESTAMP,
    ends_at      DATETIME        NOT NULL,
    closed_at    DATETIME        NULL,

    KEY idx_deposits_user (user_id, status, id),
    KEY idx_deposits_product (product_id),
    KEY idx_deposits_wallet (wallet_id)
) ENGINE = InnoDB DEFAULT CHARSET = utf8mb4;

INSERT IGNORE INTO deposit_products
    (id, name, description, rate, min_amount, max_amount, min_months, max_months, currency)
VALUES
    (1, 'Накопительный',  'Классический вклад с ежемесячным начислением процентов.',      13.50,  20000.00, 5000000.00,  3, 36, 'KZT'),
    (2, 'Срочный Максимум','Повышенная ставка при размещении на длительный срок.',         16.20, 100000.00,10000000.00, 12, 36, 'KZT'),
    (3, 'Первый вклад',   'Небольшая сумма и короткий срок — для первого опыта.',          10.80,  10000.00,  500000.00,  3, 12, 'KZT'),
    (4, 'Детский',        'Долгосрочный вклад на будущее ребёнка.',                        14.90,  50000.00, 3000000.00, 12, 36, 'KZT'),
    (5, 'Пенсионный',     'Льготная ставка для пенсионных накоплений.',                    15.40,  30000.00, 4000000.00,  6, 36, 'KZT');
