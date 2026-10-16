<?php
define('DB_HOST', 'localhost');
define('DB_NAME', 'u758638448_khelox');
define('DB_USER', 'u758638448_khelox');
define('DB_PASS', '>w3IUDO#+47I');

// Pehla admin bina key ke ban jayega. Uske baad naya admin banane ke liye ye key chahiye.
define('ADMIN_INVITE_KEY', 'CHANGE_ME_TO_SOMETHING_LONG');

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
        exit('Session expired, page refresh karo');
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