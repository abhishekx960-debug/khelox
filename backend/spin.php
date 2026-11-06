<?php
require __DIR__ . '/config.php';
spin_ensure_schema();

/*
 * Spin wheel API. Everything time-related uses the DATABASE clock (UTC), so
 * changing the phone's date/time can never touch the limit.
 *
 * Rule: SPIN_LIMIT spins per rolling SPIN_WINDOW_HOURS window.
 * Window starts at the first spin. When it ends, used resets to 0
 * (unused spins never carry over; limit is always SPIN_LIMIT).
 *
 * Optional settings keys: spin_daily_limit (default 10),
 *                         spin_window_hours (default 24)
 */

// KheloX Spin Wheel Configuration & Weights (5 & 10 = 65%, Try Again = 20%)
// Order MUST match the app wheel. 'percentage' must sum to 100.
const SPIN_SEGMENTS = [
    ['index' => 0, 'reward' => 10,  'percentage' => 35.00], // Common
    ['index' => 1, 'reward' => 25,  'percentage' => 5.00],  // Common / Medium (Reduced)
    ['index' => 2, 'reward' => 5,   'percentage' => 30.00], // Very Common
    ['index' => 3, 'reward' => 50,  'percentage' => 3.00],  // Decent Reward (Reduced)
    ['index' => 4, 'reward' => 100, 'percentage' => 1.00],  // Rare Reward (Reduced)
    ['index' => 5, 'reward' => 0,   'percentage' => 20.00], // Try Again / Better Luck
    ['index' => 6, 'reward' => 200, 'percentage' => 0.25],  // Jackpot (Extremely Rare)
    ['index' => 7, 'reward' => 20,  'percentage' => 5.75],  // Frequent small reward
];

function spin_rewards(): array {
    return array_map(fn($s) => (int)$s['reward'], SPIN_SEGMENTS);
}

function spin_ensure_schema(): void {
    static $done = false;
    if ($done) return;
    $done = true;
    try {
        db()->exec('CREATE TABLE IF NOT EXISTS spin_state (
            user_id INT UNSIGNED NOT NULL PRIMARY KEY,
            window_start DATETIME NULL,
            used INT UNSIGNED NOT NULL DEFAULT 0
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4');
        db()->exec('CREATE TABLE IF NOT EXISTS spin_logs (
            id INT UNSIGNED NOT NULL AUTO_INCREMENT PRIMARY KEY,
            user_id INT UNSIGNED NOT NULL,
            reward DECIMAL(12,2) NOT NULL DEFAULT 0,
            created_at DATETIME NOT NULL,
            KEY idx_spin_user (user_id)
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4');
    } catch (PDOException $e) {
        // reported as server error below if still missing
    }
}

function spin_limit(): int {
    return max(1, (int)setting('spin_daily_limit', '10'));
}

function spin_hours(): int {
    return max(1, (int)setting('spin_window_hours', '24'));
}

/** Current window for user. Returns [active(bool), used, reset_in_seconds]. */
function spin_window(PDO $pdo, int $userId, bool $lock): array {
    $h = spin_hours();
    $sql = "SELECT used, window_start,
                   TIMESTAMPDIFF(SECOND, UTC_TIMESTAMP(), DATE_ADD(window_start, INTERVAL $h HOUR)) AS left_s
            FROM spin_state WHERE user_id = ?" . ($lock ? ' FOR UPDATE' : '');
    $q = $pdo->prepare($sql);
    $q->execute([$userId]);
    $r = $q->fetch();
    if (!$r || $r['window_start'] === null || (int)$r['left_s'] <= 0) {
        return [false, 0, 0];
    }
    return [true, (int)$r['used'], (int)$r['left_s']];
}

function spin_status_payload(PDO $pdo, int $userId, bool $lock = false): array {
    $limit = spin_limit();
    [$active, $used, $left] = spin_window($pdo, $userId, $lock);
    $remaining = max(0, $limit - $used);

    $f = $pdo->prepare('SELECT fcoin FROM users WHERE id = ?');
    $f->execute([$userId]);

    return [
        'limit'     => $limit,
        'used'      => $used,
        'remaining' => $remaining,
        // seconds until the limit resets (server computed); 0 if no active window
        'reset_in'  => $active ? $left : 0,
        'rewards'   => spin_rewards(),
        'fcoin'     => (float)($f->fetchColumn() ?: 0),
    ];
}

function spin_pick(): int {
    // percentage -> basis points (0.25% = 25) so random_int stays integer.
    $total = 0;
    foreach (SPIN_SEGMENTS as $seg) {
        $total += (int)round($seg['percentage'] * 100);
    }
    $roll = random_int(1, $total);
    foreach (SPIN_SEGMENTS as $seg) {
        $roll -= (int)round($seg['percentage'] * 100);
        if ($roll <= 0) return (int)$seg['index'];
    }
    return 0;
}

$in = json_input();
$action = (string)($in['action'] ?? 'status');
$userId = (int)($in['user_id'] ?? 0);

if ($userId <= 0) {
    respond(422, ['success' => false, 'message' => 'Invalid user']);
}

try {
    $pdo = db();

    if ($action === 'status') {
        respond(200, ['success' => true, 'spin' => spin_status_payload($pdo, $userId)]);
    }

    // ---- spin ----
    $pdo->beginTransaction();

    // Row lock on the user serialises parallel spin requests (no double spin).
    $u = $pdo->prepare('SELECT id FROM users WHERE id = ? FOR UPDATE');
    $u->execute([$userId]);
    if (!$u->fetch()) {
        $pdo->rollBack();
        respond(404, ['success' => false, 'message' => 'User not found']);
    }

    $limit = spin_limit();
    [$active, $used, $left] = spin_window($pdo, $userId, true);

    if ($active && $used >= $limit) {
        $status = spin_status_payload($pdo, $userId);
        $pdo->rollBack();
        respond(429, [
            'success' => false,
            'message' => 'Spin limit reached. Try again after reset.',
            'spin'    => $status,
        ]);
    }

    if ($active) {
        $pdo->prepare('UPDATE spin_state SET used = used + 1 WHERE user_id = ?')->execute([$userId]);
    } else {
        // New window starts now (DB clock), used = 1.
        $pdo->prepare(
            'INSERT INTO spin_state (user_id, window_start, used) VALUES (?, UTC_TIMESTAMP(), 1)
             ON DUPLICATE KEY UPDATE window_start = VALUES(window_start), used = VALUES(used)'
        )->execute([$userId]);
    }

    $index  = spin_pick();
    $reward = (int)SPIN_SEGMENTS[$index]['reward'];

    if ($reward > 0) {
        $pdo->prepare('UPDATE users SET fcoin = fcoin + ? WHERE id = ?')->execute([$reward, $userId]);
    }
    $pdo->prepare('INSERT INTO spin_logs (user_id, reward, created_at) VALUES (?, ?, UTC_TIMESTAMP())')
        ->execute([$userId, $reward]);

    $status = spin_status_payload($pdo, $userId);
    $pdo->commit();

    respond(200, [
        'success' => true,
        'index'   => $index,
        'reward'  => $reward,
        'spin'    => $status,
    ]);
} catch (Throwable $e) {
    if (isset($pdo) && $pdo instanceof PDO && $pdo->inTransaction()) {
        $pdo->rollBack();
    }
    respond(500, ['success' => false, 'message' => 'Server error']);
}