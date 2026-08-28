CREATE DATABASE IF NOT EXISTS `mini_bank`
  DEFAULT CHARACTER SET utf8mb4
  COLLATE utf8mb4_unicode_ci;

USE `mini_bank`;

DROP TABLE IF EXISTS `transactions`;
DROP TABLE IF EXISTS `wallets`;
DROP TABLE IF EXISTS `tokens`;
DROP TABLE IF EXISTS `users`;

CREATE TABLE `users` (
  `id`            INT UNSIGNED NOT NULL AUTO_INCREMENT,
  `full_name`     VARCHAR(100) NOT NULL,
  `phone`         VARCHAR(20)  NOT NULL,
  `password_hash` VARCHAR(255) NOT NULL,
  `pin_hash`      VARCHAR(255) DEFAULT NULL,
  `created_at`    DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_users_phone` (`phone`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE `tokens` (
  `id`         INT UNSIGNED NOT NULL AUTO_INCREMENT,
  `user_id`    INT UNSIGNED NOT NULL,
  `token`      CHAR(64)     NOT NULL,
  `created_at` DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `expires_at` DATETIME     NOT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_tokens_token` (`token`),
  KEY `idx_tokens_user` (`user_id`),
  CONSTRAINT `fk_tokens_user` FOREIGN KEY (`user_id`)
    REFERENCES `users` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE `wallets` (
  `id`         INT UNSIGNED   NOT NULL AUTO_INCREMENT,
  `user_id`    INT UNSIGNED   NOT NULL,
  `title`      VARCHAR(60)    NOT NULL DEFAULT 'Основной',
  `number`     CHAR(16)       NOT NULL,
  `currency`   ENUM('KZT','USD','EUR') NOT NULL DEFAULT 'KZT',
  `balance`    DECIMAL(15,2)  NOT NULL DEFAULT 0.00,
  `is_default` TINYINT(1)     NOT NULL DEFAULT 0,
  `created_at` DATETIME       NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_wallets_number` (`number`),
  KEY `idx_wallets_user` (`user_id`),
  CONSTRAINT `fk_wallets_user` FOREIGN KEY (`user_id`)
    REFERENCES `users` (`id`) ON DELETE CASCADE,
  CONSTRAINT `chk_wallets_balance` CHECK (`balance` >= 0)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE `transactions` (
  `id`             INT UNSIGNED  NOT NULL AUTO_INCREMENT,
  `wallet_id`      INT UNSIGNED  NOT NULL,
  `type`           ENUM('deposit','withdraw','transfer_out','transfer_in') NOT NULL,
  `amount`         DECIMAL(15,2) NOT NULL,
  `balance_after`  DECIMAL(15,2) NOT NULL,
  `title`          VARCHAR(120)  NOT NULL,
  `counterparty`   VARCHAR(120)  DEFAULT NULL,
  `created_at`     DATETIME      NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  KEY `idx_tx_wallet` (`wallet_id`),
  KEY `idx_tx_created` (`created_at`),
  CONSTRAINT `fk_tx_wallet` FOREIGN KEY (`wallet_id`)
    REFERENCES `wallets` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;


CREATE OR REPLACE VIEW `v_user_balances` AS
SELECT
  u.id            AS user_id,
  u.full_name     AS full_name,
  u.phone         AS phone,
  w.number        AS wallet_number,
  w.title         AS wallet_title,
  w.currency      AS currency,
  w.balance       AS balance
FROM users u
JOIN wallets w ON w.user_id = u.id
ORDER BY u.id, w.id;
