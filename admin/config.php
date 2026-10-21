<?php
define('DB_HOST', 'localhost');
define('DB_NAME', 'u758638448_khelox');
define('DB_USER', 'u758638448_khelox');
define('DB_PASS', '>w3IUDO#+47I');

// Pehla admin bina key ke ban jayega. Uske baad naya admin banane ke liye ye key chahiye.
define('ADMIN_INVITE_KEY', 'CHANGE_ME_TO_SOMETHING_LONG');

// ImgBB image hosting - image upload ke liye use hoti hai.
define('IMGBB_API_KEY', '66078ac1ded9c8184ec8c35bd8b9dc7a');

$isHttps = (!empty($_SERVER['HTTPS']) && $_SERVER['HTTPS'] !== 'off')
        || (($_SERVER['HTTP_X_FORWARDED_PROTO'] ?? '') === 'https');
session_name('KHELOXADMIN');
session_set_cookie_params([
    'lifetime' => 0,
    'path'     => '/',
    'secure'   => $isHttps,
    'httponly' => true,
    'samesite' => 'Lax',
]);
session_start();

function db(): PDO {
    static $pdo = null;
    if ($pdo === null) {
        try {
            $pdo = new PDO(
                'mysql:host=' . DB_HOST . ';dbname=' . DB_NAME . ';charset=utf8mb4',
                DB_USER, DB_PASS,
                [
                    PDO::ATTR_ERRMODE => PDO::ERRMODE_EXCEPTION,
                    PDO::ATTR_DEFAULT_FETCH_MODE => PDO::FETCH_ASSOC,
                    PDO::ATTR_EMULATE_PREPARES => false,
                ]
            );
        } catch (PDOException $e) {
            http_response_code(500);
            exit('Database connection error');
        }
    }
    return $pdo;
}

function e($v): string { return htmlspecialchars((string)$v, ENT_QUOTES, 'UTF-8'); }

function csrf_token(): string {
    if (empty($_SESSION['csrf'])) $_SESSION['csrf'] = bin2hex(random_bytes(32));
    return $_SESSION['csrf'];
}
function csrf_field(): string {
    return '<input type="hidden" name="csrf" value="' . csrf_token() . '">';
}
function csrf_check(): void {
    if (!hash_equals($_SESSION['csrf'] ?? '', (string)($_POST['csrf'] ?? ''))) {
        http_response_code(419);
        exit('Session expired, please refresh the page');
    }
}

function is_logged_in(): bool { return !empty($_SESSION['admin_id']); }

function require_login(): void {
    if (!is_logged_in()) { header('Location: login.php'); exit; }
}

function flash(string $type, string $msg): void { $_SESSION['flash'] = [$type, $msg]; }
function flash_get(): ?array {
    $f = $_SESSION['flash'] ?? null;
    unset($_SESSION['flash']);
    return $f;
}


// Logo: admin/assets/logo/KheloxLogo.png (na mile to icon dikhega)
define('LOGO_URL', 'assets/logo/KheloxLogo.png');
function logo_img(int $h = 36): string {
    return '<img src="' . LOGO_URL . '" alt="Khelox" style="height:' . $h . 'px;width:auto" '
         . 'onerror="this.style.display=\'none\';this.nextElementSibling.style.display=\'inline-block\'">'
         . '<i class="bi bi-controller" style="display:none;font-size:' . $h . 'px;line-height:1"></i>';
}
function initials(string $name): string {
    $p = preg_split('/\s+/', trim($name));
    $a = mb_strtoupper(mb_substr($p[0] ?? '?', 0, 1));
    $b = isset($p[1]) ? mb_strtoupper(mb_substr($p[1], 0, 1)) : '';
    return $a . $b;
}

// ---- Uploads (ImgBB hosting) ----
// Image validate karke ImgBB par upload karta hai aur public URL return karta hai.
function save_image(array $file, string $sub = '', int $maxBytes = 3145728): string {
    if (($file['error'] ?? UPLOAD_ERR_NO_FILE) !== UPLOAD_ERR_OK) {
        throw new RuntimeException('File upload failed, please try again');
    }
    if (($file['size'] ?? 0) > $maxBytes) {
        throw new RuntimeException('Image must be smaller than ' . round($maxBytes / 1048576, 1) . 'MB');
    }
    $info = @getimagesize($file['tmp_name']);
    if (!$info) {
        throw new RuntimeException('Sahi image file chuno');
    }
    $allowed = ['image/jpeg', 'image/png', 'image/webp', 'image/gif'];
    if (!in_array($info['mime'] ?? '', $allowed, true)) {
        throw new RuntimeException('Only JPG, PNG, WEBP or GIF files are allowed');
    }

    $data = base64_encode((string)file_get_contents($file['tmp_name']));
    $payload = http_build_query(['key' => IMGBB_API_KEY, 'image' => $data]);
    $url = 'https://api.imgbb.com/1/upload';

    $raw = false;
    if (function_exists('curl_init')) {
        $ch = curl_init($url);
        curl_setopt_array($ch, [
            CURLOPT_POST           => true,
            CURLOPT_POSTFIELDS     => $payload,
            CURLOPT_RETURNTRANSFER => true,
            CURLOPT_TIMEOUT        => 30,
        ]);
        $raw = curl_exec($ch);
        $code = (int)curl_getinfo($ch, CURLINFO_HTTP_CODE);
        $err  = curl_error($ch);
        curl_close($ch);
        if ($raw === false) {
            throw new RuntimeException('Could not connect to ImgBB: ' . $err);
        }
    } else {
        $ctx = stream_context_create(['http' => [
            'method'        => 'POST',
            'header'        => "Content-Type: application/x-www-form-urlencoded\r\n",
            'content'       => $payload,
            'timeout'       => 30,
            'ignore_errors' => true,
        ]]);
        $raw  = @file_get_contents($url, false, $ctx);
        $code = 0;
        if (isset($http_response_header[0]) && preg_match('~\s(\d{3})\s~', $http_response_header[0], $m)) {
            $code = (int)$m[1];
        }
        if ($raw === false) {
            throw new RuntimeException('Could not connect to ImgBB');
        }
    }

    $json = json_decode($raw, true);
    if (!is_array($json) || empty($json['success']) || empty($json['data']['url'])) {
        $msg = $json['error']['message'] ?? ('HTTP ' . $code);
        throw new RuntimeException('ImgBB upload failed: ' . $msg);
    }
    return (string)$json['data']['url'];
}

// Sirf local uploads delete karta hai, remote (http) URLs ko chhod deta hai.
function delete_upload(?string $relPath): void {
    if (!$relPath || preg_match('~^https?://~i', $relPath)) return;
    $path = __DIR__ . '/' . ltrim($relPath, '/');
    if (is_file($path)) @unlink($path);
}

// ---- Settings (key/value) ----
function settings_all(): array {
    static $cache = null;
    if ($cache === null) {
        $cache = [];
        foreach (db()->query('SELECT setting_key, setting_value FROM settings') as $r) {
            $cache[$r['setting_key']] = $r['setting_value'];
        }
    }
    return $cache;
}

function setting(string $key, string $default = ''): string {
    return settings_all()[$key] ?? $default;
}

function setting_set(string $key, string $value): void {
    db()->prepare('INSERT INTO settings (setting_key, setting_value) VALUES (?, ?)
                   ON DUPLICATE KEY UPDATE setting_value = VALUES(setting_value)')
        ->execute([$key, $value]);
}

/**
 * Withdraw rows track whether the amount is currently deducted from the user.
 * Old pending rows start at 0 and get deducted on their first approval.
 */
function withdraws_ensure_schema(): void {
    static $done = false;
    if ($done) return;
    $done = true;

    foreach (['fcoin_withdraws', 'wcoin_withdraws'] as $table) {
        try {
            $columns = [];
            foreach (db()->query('SHOW COLUMNS FROM ' . $table) as $col) {
                $columns[$col['Field']] = true;
            }
            if (!isset($columns['deducted'])) {
                db()->exec('ALTER TABLE ' . $table . ' ADD COLUMN deducted TINYINT(1) NOT NULL DEFAULT 0 AFTER status');
            }
        } catch (PDOException $e) {
            // Table missing: run system.sql first.
        }
    }
}

/**
 * Older installs have the deposits table without proof/rejection columns.
 * Add them on first use so existing databases keep working.
 */
function deposits_ensure_schema(): void {
    static $done = false;
    if ($done) return;
    $done = true;

    try {
        $columns = [];
        foreach (db()->query('SHOW COLUMNS FROM deposits') as $col) {
            $columns[$col['Field']] = true;
        }
        $alter = [];
        if (!isset($columns['coins'])) {
            $alter[] = 'ADD COLUMN coins DECIMAL(12,2) NOT NULL DEFAULT 0 AFTER amount';
        }
        if (!isset($columns['inr_amount'])) {
            $alter[] = 'ADD COLUMN inr_amount DECIMAL(12,2) NOT NULL DEFAULT 0 AFTER coins';
        }
        if (!isset($columns['reject_reason'])) {
            $alter[] = 'ADD COLUMN reject_reason VARCHAR(255) NULL AFTER utr';
        }
        if (!isset($columns['credited'])) {
            $alter[] = 'ADD COLUMN credited TINYINT(1) NOT NULL DEFAULT 0 AFTER status';
        }
        if (!isset($columns['updated_at'])) {
            $alter[] = 'ADD COLUMN updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP AFTER created_at';
        }
        if ($alter) {
            foreach ($alter as $clause) {
                db()->exec('ALTER TABLE deposits ' . $clause);
            }
        }
    } catch (PDOException $e) {
        // Table missing: run system.sql first.
    }
}