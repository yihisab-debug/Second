ALTER TABLE users
    ADD COLUMN employment_status  VARCHAR(20)     NOT NULL DEFAULT '',
    ADD COLUMN employer           VARCHAR(120)    NOT NULL DEFAULT '',
    ADD COLUMN monthly_income     DECIMAL(15, 2)  NOT NULL DEFAULT 0,
    ADD COLUMN experience_months  INT             NOT NULL DEFAULT 0,
    ADD COLUMN employment_at      DATETIME        NULL;
