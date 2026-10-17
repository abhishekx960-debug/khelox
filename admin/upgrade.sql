-- Run once in phpMyAdmin if the deposits table already exists (old install).
-- The admin panel and API also add these columns automatically on first use.
ALTER TABLE deposits ADD COLUMN coins DECIMAL(12,2) NOT NULL DEFAULT 0 AFTER amount;
ALTER TABLE deposits ADD COLUMN inr_amount DECIMAL(12,2) NOT NULL DEFAULT 0 AFTER coins;
ALTER TABLE deposits ADD COLUMN reject_reason VARCHAR(255) NULL AFTER utr;
ALTER TABLE deposits ADD COLUMN credited TINYINT(1) NOT NULL DEFAULT 0 AFTER status;
ALTER TABLE deposits ADD COLUMN updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP AFTER created_at;
