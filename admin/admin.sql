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
