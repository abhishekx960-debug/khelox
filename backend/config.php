<?php
// Upload folder: public_html/api/  (Hostinger pe DB host "localhost" hota hai)
define('DB_HOST', 'localhost');
define('DB_NAME', 'u758638448_khelox');
define('DB_USER', 'u758638448_khelox');
define('DB_PASS', '>w3IUDO#+47I');

// Image hosting for payment proof screenshots.
define('IMGBB_API_KEY', '66078ac1ded9c8184ec8c35bd8b9dc7a');

header('Content-Type: application/json; charset=utf-8');

// Flutter Web se aane wale cross-origin requests allow karo.
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: POST, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type, Accept');
header('Access-Control-Max-Age: 86400');
if (($_SERVER['REQUEST_METHOD'] ?? '') === 'OPTIONS') {
    http_response_code(204);
    exit;
}

function respond(int $code, array $payload): void {
    http_response_code($code);
    echo json_encode($payload, JSON_UNESCAPED_UNICODE);
    exit;
}

function db(): PDO {
    static $pdo = null;
    if ($pdo === null) {
        try {
            $pdo = new PDO(
                'mysql:host=' . DB_HOST . ';dbname=' . DB_NAME . ';charset=utf8mb4',
                DB_USER,
                DB_PASS,
                [
                    PDO::ATTR_ERRMODE => PDO::ERRMODE_EXCEPTION,
                    PDO::ATTR_DEFAULT_FETCH_MODE => PDO::FETCH_ASSOC,
                    PDO::ATTR_EMULATE_PREPARES => false,
                ]
            );
        } catch (PDOException $e) {
            respond(500, ['success' => false, 'message' => 'Database error']);
        }
    }
    return $pdo;
}

function json_input(): array {
    if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
        respond(405, ['success' => false, 'message' => 'POST only']);
    }
    $data = json_decode(file_get_contents('php://input'), true);
    return is_array($data) ? $data : [];
}

/**
 * Settings table is shared with the admin panel, so no schema change is
 * needed for the finance rates/limits. Missing keys fall back to defaults.
 */
function settings_all(): array {
    static $cache = null;
    if ($cache === null) {
        $cache = [];
        try {
            foreach (db()->query('SELECT setting_key, setting_value FROM settings') as $r) {
                $cache[$r['setting_key']] = (string)($r['setting_value'] ?? '');
            }
        } catch (PDOException $e) {
            $cache = [];
        }
    }
    return $cache;
}

function setting(string $key, string $default = ''): string {
    $value = settings_all()[$key] ?? '';
    return $value !== '' ? $value : $default;
}

/**
 * The deposits table existed before proof/rejection support. This keeps the
 * live database usable without asking the admin to run SQL manually.
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
        // Table may not exist yet; system.sql creates it.
    }
}

/**
 * Uploads a base64 data-URL image to ImgBB and returns the public URL.
 */
function upload_data_image(string $dataUrl): string {
    if (!preg_match('~^data:(image/(?:png|jpeg|jpg|webp|gif));base64,(.+)$~s', $dataUrl, $m)) {
        throw new InvalidArgumentException('Please choose a valid image file');
    }
    $raw = base64_decode($m[2], true);
    if ($raw === false || $raw === '') {
        throw new InvalidArgumentException('Could not read the image');
    }
    if (strlen($raw) > 3145728) {
        throw new InvalidArgumentException('Image must be smaller than 3MB');
    }

    $payload = http_build_query([
        'key'   => IMGBB_API_KEY,
        'image' => base64_encode($raw),
    ]);
    $url = 'https://api.imgbb.com/1/upload';

    $result = false;
    if (function_exists('curl_init')) {
        $ch = curl_init($url);
        curl_setopt_array($ch, [
            CURLOPT_POST           => true,
            CURLOPT_POSTFIELDS     => $payload,
            CURLOPT_RETURNTRANSFER => true,
            CURLOPT_TIMEOUT        => 30,
        ]);
        $result = curl_exec($ch);
        curl_close($ch);
    } else {
        $ctx = stream_context_create(['http' => [
            'method'        => 'POST',
            'header'        => "Content-Type: application/x-www-form-urlencoded\r\n",
            'content'       => $payload,
            'timeout'       => 30,
            'ignore_errors' => true,
        ]]);
        $result = @file_get_contents($url, false, $ctx);
    }

    if ($result === false) {
        throw new RuntimeException('Image upload failed, please try again');
    }
    $json = json_decode($result, true);
    if (!is_array($json) || empty($json['success']) || empty($json['data']['url'])) {
        throw new RuntimeException('Image upload failed, please try again');
    }
    return (string)$json['data']['url'];
}