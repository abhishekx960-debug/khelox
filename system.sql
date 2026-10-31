-- Khelox complete database schema
-- Run this file once in phpMyAdmin (select your existing database first).
-- Safe to re-run: every table uses CREATE TABLE IF NOT EXISTS.

-- ---------------------------------------------------------------
-- Users (Flutter app / backend API)
-- ---------------------------------------------------------------
CREATE TABLE IF NOT EXISTS users (
  id            INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  name          VARCHAR(100)  NOT NULL,
  email         VARCHAR(190)  NOT NULL,
  phone         VARCHAR(20)   NOT NULL,
  password_hash VARCHAR(255)  NOT NULL,
  fcoin         DECIMAL(12,2) NOT NULL DEFAULT 0,
  dcoin         DECIMAL(12,2) NOT NULL DEFAULT 0,
  wcoin         DECIMAL(12,2) NOT NULL DEFAULT 0,
  created_at    TIMESTAMP     NOT NULL DEFAULT CURRENT_TIMESTAMP,
  UNIQUE KEY uq_email (email),
  UNIQUE KEY uq_phone (phone)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- ---------------------------------------------------------------
-- Admins (admin panel)
-- ---------------------------------------------------------------
CREATE TABLE IF NOT EXISTS admins (
  id            INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  name          VARCHAR(100) NOT NULL,
  username      VARCHAR(50)  NOT NULL,
  email         VARCHAR(190) NOT NULL,
  phone         VARCHAR(20)  NOT NULL,
  password_hash VARCHAR(255) NOT NULL,
  status        TINYINT(1)   NOT NULL DEFAULT 1,
  last_login    DATETIME     NULL,
  created_at    TIMESTAMP    NOT NULL DEFAULT CURRENT_TIMESTAMP,
  UNIQUE KEY uq_admin_username (username),
  UNIQUE KEY uq_admin_email (email),
  UNIQUE KEY uq_admin_phone (phone)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- ---------------------------------------------------------------
-- Settings (key/value): deposit QR/UPI, support details, coin rates
-- ---------------------------------------------------------------
CREATE TABLE IF NOT EXISTS settings (
  setting_key   VARCHAR(100) NOT NULL PRIMARY KEY,
  setting_value TEXT         NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- Fresh-install defaults. Existing values are never overwritten.
INSERT IGNORE INTO settings (setting_key, setting_value) VALUES
  ('dcoin_inr_rate', '1'),
  ('dcoin_min_deposit', '10'),
  ('dcoin_max_deposit', '100000'),
  ('fcoin_inr_rate', '0.50'),
  ('fcoin_rate_coins', '1'),
  ('fcoin_rate_inr', '0.50'),
  ('fcoin_min_withdraw', '100'),
  ('fcoin_max_withdraw', '100000'),
  ('wcoin_min_withdraw', '100'),
  ('wcoin_max_withdraw', '100000'),
  ('deposit_upi_id', ''),
  ('deposit_qr', ''),
  ('support_email', ''),
  ('support_phone', ''),
  ('support_whatsapp', ''),
  ('support_telegram', ''),
  ('support_note', '');

-- ---------------------------------------------------------------
-- Manage Carousels
-- ---------------------------------------------------------------
CREATE TABLE IF NOT EXISTS carousels (
  id            INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  title         VARCHAR(150) NOT NULL,
  image         VARCHAR(255) NOT NULL,
  more_info_url VARCHAR(500) NULL,
  status        TINYINT(1)   NOT NULL DEFAULT 1,
  sort_order    INT          NOT NULL DEFAULT 0,
  created_at    TIMESTAMP    NOT NULL DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- ---------------------------------------------------------------
-- Manage Notifications
-- ---------------------------------------------------------------
CREATE TABLE IF NOT EXISTS notifications (
  id         INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  title      VARCHAR(150) NOT NULL,
  message    TEXT         NOT NULL,
  status     TINYINT(1)   NOT NULL DEFAULT 1,
  created_at TIMESTAMP    NOT NULL DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- ---------------------------------------------------------------
-- Manage Deposits (Dcoin)
-- status: 0 = pending, 1 = approved, 2 = rejected
-- credited: 1 = coins already added to user wallet
-- ---------------------------------------------------------------
CREATE TABLE IF NOT EXISTS deposits (
  id            INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  user_id       INT UNSIGNED NOT NULL,
  amount        DECIMAL(12,2) NOT NULL DEFAULT 0,
  coins         DECIMAL(12,2) NOT NULL DEFAULT 0,
  inr_amount    DECIMAL(12,2) NOT NULL DEFAULT 0,
  coin_type     VARCHAR(10)   NOT NULL DEFAULT 'dcoin',
  utr           VARCHAR(100)  NULL,
  reject_reason VARCHAR(255)  NULL,
  screenshot    VARCHAR(255)  NULL,
  status        TINYINT(1)    NOT NULL DEFAULT 0,
  credited      TINYINT(1)    NOT NULL DEFAULT 0,
  created_at    TIMESTAMP     NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at    TIMESTAMP     NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  KEY idx_deposit_user (user_id),
  KEY idx_deposit_status (status)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- ---------------------------------------------------------------
-- Manage Fcoin Withdraws
-- status: 0 = pending, 1 = approved, 2 = rejected
-- deducted: 1 = amount currently held from the user's balance
-- ---------------------------------------------------------------
CREATE TABLE IF NOT EXISTS fcoin_withdraws (
  id         INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  user_id    INT UNSIGNED NOT NULL,
  amount     DECIMAL(12,2) NOT NULL DEFAULT 0,
  upi_id     VARCHAR(120)  NULL,
  remark     VARCHAR(255)  NULL,
  status     TINYINT(1)    NOT NULL DEFAULT 0,
  deducted   TINYINT(1)    NOT NULL DEFAULT 0,
  created_at TIMESTAMP     NOT NULL DEFAULT CURRENT_TIMESTAMP,
  KEY idx_fwithdraw_user (user_id),
  KEY idx_fwithdraw_status (status)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- ---------------------------------------------------------------
-- Manage Wcoin Withdraws
-- status: 0 = pending, 1 = approved, 2 = rejected
-- deducted: 1 = amount currently held from the user's balance
-- ---------------------------------------------------------------
CREATE TABLE IF NOT EXISTS wcoin_withdraws (
  id         INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  user_id    INT UNSIGNED NOT NULL,
  amount     DECIMAL(12,2) NOT NULL DEFAULT 0,
  upi_id     VARCHAR(120)  NULL,
  remark     VARCHAR(255)  NULL,
  status     TINYINT(1)    NOT NULL DEFAULT 0,
  deducted   TINYINT(1)    NOT NULL DEFAULT 0,
  created_at TIMESTAMP     NOT NULL DEFAULT CURRENT_TIMESTAMP,
  KEY idx_wwithdraw_user (user_id),
  KEY idx_wwithdraw_status (status)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- ---------------------------------------------------------------
-- Premium Zone: Game Rules (Free Fire rule sets, points stored as JSON)
-- ---------------------------------------------------------------
CREATE TABLE IF NOT EXISTS game_rules (
  id         INT UNSIGNED NOT NULL AUTO_INCREMENT PRIMARY KEY,
  points     MEDIUMTEXT   NOT NULL,
  created_at TIMESTAMP    NOT NULL DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- ---------------------------------------------------------------
-- Premium Zone: Tournaments
-- game: 'br' = Free Fire BR, 'cs' = Free Fire CS, 'community' = Free Fire Community
-- status: upcoming / live / completed / cancelled (admin panel decides)
-- ---------------------------------------------------------------
CREATE TABLE IF NOT EXISTS tournaments (
  id          INT UNSIGNED NOT NULL AUTO_INCREMENT PRIMARY KEY,
  game        VARCHAR(20)   NOT NULL,
  title       VARCHAR(150)  NOT NULL,
  prize_pool  DECIMAL(12,2) NOT NULL DEFAULT 0,
  entry_fee   DECIMAL(12,2) NOT NULL DEFAULT 0,
  slots       INT UNSIGNED  NOT NULL DEFAULT 0,
  start_at    DATETIME      NOT NULL,
  rule_id     INT UNSIGNED  NULL,
  description TEXT          NULL,
  status      VARCHAR(10)   NOT NULL DEFAULT 'upcoming',
  created_at  TIMESTAMP     NOT NULL DEFAULT CURRENT_TIMESTAMP,
  KEY idx_game_status (game, status)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- ---------------------------------------------------------------
-- Old installs only: if the deposits table already existed without
-- these columns, the admin panel/API adds them automatically on first
-- use. If you prefer running them manually, execute these one time:
--
-- ALTER TABLE deposits ADD COLUMN coins DECIMAL(12,2) NOT NULL DEFAULT 0 AFTER amount;
-- ALTER TABLE deposits ADD COLUMN inr_amount DECIMAL(12,2) NOT NULL DEFAULT 0 AFTER coins;
-- ALTER TABLE deposits ADD COLUMN reject_reason VARCHAR(255) NULL AFTER utr;
-- ALTER TABLE deposits ADD COLUMN credited TINYINT(1) NOT NULL DEFAULT 0 AFTER status;
-- ALTER TABLE deposits ADD COLUMN updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
--   ON UPDATE CURRENT_TIMESTAMP AFTER created_at;
-- ---------------------------------------------------------------