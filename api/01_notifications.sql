CREATE TABLE IF NOT EXISTS notifications (
    id          INT AUTO_INCREMENT PRIMARY KEY,
    user_id     INT             NOT NULL,
    type        VARCHAR(30)     NOT NULL DEFAULT 'info',
    title       VARCHAR(120)    NOT NULL,
    body        VARCHAR(255)    NOT NULL DEFAULT '',
    amount      DECIMAL(15, 2)  NULL,
    currency    VARCHAR(3)      NULL,
    is_read     TINYINT(1)      NOT NULL DEFAULT 0,
    created_at  TIMESTAMP       NOT NULL DEFAULT CURRENT_TIMESTAMP,

    KEY idx_notifications_user (user_id, is_read, id),

    CONSTRAINT fk_notifications_user
        FOREIGN KEY (user_id) REFERENCES users (id)
        ON DELETE CASCADE
) ENGINE = InnoDB DEFAULT CHARSET = utf8mb4;
