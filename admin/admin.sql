-- Run once in phpMyAdmin (DB: u758638448_khelox)
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

-- Manage Carousels
CREATE TABLE IF NOT EXISTS carousels (
  id            INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  title         VARCHAR(150) NOT NULL,
  image         VARCHAR(255) NOT NULL,
  more_info_url VARCHAR(500) NULL,
  status        TINYINT(1)   NOT NULL DEFAULT 1,
  sort_order    INT          NOT NULL DEFAULT 0,
  created_at    TIMESTAMP    NOT NULL DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- Manage Notifications
CREATE TABLE IF NOT EXISTS notifications (
  id         INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  title      VARCHAR(150) NOT NULL,
  message    TEXT         NOT NULL,
  status     TINYINT(1)   NOT NULL DEFAULT 1,
  created_at TIMESTAMP    NOT NULL DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- Settings (deposit QR/UPI + customer support details)
CREATE TABLE IF NOT EXISTS settings (
  setting_key   VARCHAR(100) NOT NULL PRIMARY KEY,
  setting_value TEXT         NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- Manage Deposits (table ready, admin page upcoming)
CREATE TABLE IF NOT EXISTS deposits (
  id            INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  user_id       INT UNSIGNED NOT NULL,
  amount        DECIMAL(12,2) NOT NULL DEFAULT 0,
  coin_type     VARCHAR(10)   NOT NULL DEFAULT 'fcoin',
  utr           VARCHAR(100)  NULL,
  screenshot    VARCHAR(255)  NULL,
  status        TINYINT(1)    NOT NULL DEFAULT 0,
  created_at    TIMESTAMP     NOT NULL DEFAULT CURRENT_TIMESTAMP,
  KEY idx_deposit_user (user_id),
  KEY idx_deposit_status (status)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- Manage Fcoin Withdraws (table ready, admin page upcoming)
CREATE TABLE IF NOT EXISTS fcoin_withdraws (
  id         INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  user_id    INT UNSIGNED NOT NULL,
  amount     DECIMAL(12,2) NOT NULL DEFAULT 0,
  upi_id     VARCHAR(120)  NULL,
  remark     VARCHAR(255)  NULL,
  status     TINYINT(1)    NOT NULL DEFAULT 0,
  created_at TIMESTAMP     NOT NULL DEFAULT CURRENT_TIMESTAMP,
  KEY idx_fwithdraw_user (user_id),
  KEY idx_fwithdraw_status (status)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- Manage Wcoin Withdraws (table ready, admin page upcoming)
CREATE TABLE IF NOT EXISTS wcoin_withdraws (
  id         INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  user_id    INT UNSIGNED NOT NULL,
  amount     DECIMAL(12,2) NOT NULL DEFAULT 0,
  upi_id     VARCHAR(120)  NULL,
  remark     VARCHAR(255)  NULL,
  status     TINYINT(1)    NOT NULL DEFAULT 0,
  created_at TIMESTAMP     NOT NULL DEFAULT CURRENT_TIMESTAMP,
  KEY idx_wwithdraw_user (user_id),
  KEY idx_wwithdraw_status (status)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
