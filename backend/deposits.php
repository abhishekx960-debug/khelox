<?php
require __DIR__ . '/config.php';
deposits_ensure_schema();

$in = json_input();
$action = (string)($in['action'] ?? 'create');
$userId = (int)($in['user_id'] ?? 0);

if ($userId <= 0) {
    respond(422, ['success' => false, 'message' => 'Invalid user']);
}

function deposit_status_label(int $status): string {
    if ($status === 1) return 'approved';
    if ($status === 2) return 'rejected';
    return 'pending';
}

function deposit_payload(array $r): array {
    return [
        'id'            => (int)$r['id'],
        'coins'         => (float)$r['coins'],
        'inr_amount'    => (float)$r['inr_amount'],
        'utr'           => (string)($r['utr'] ?? ''),
        'proof'         => (string)($r['screenshot'] ?? ''),
        'status'        => deposit_status_label((int)$r['status']),
        'reject_reason' => (string)($r['reject_reason'] ?? ''),
        'created_at'    => (string)$r['created_at'],
    ];
}

try {
    if ($action === 'history') {
        $q = db()->prepare(
            'SELECT id, coins, inr_amount, utr, screenshot, status, reject_reason, created_at
             FROM deposits WHERE user_id = ? ORDER BY id DESC LIMIT 100'
        );
        $q->execute([$userId]);
        $rows = $q->fetchAll();

        respond(200, [
            'success'  => true,
            'deposits' => array_map('deposit_payload', $rows),
        ]);
    }

    // ---- create ----
    $inr   = round((float)($in['inr_amount'] ?? 0), 2);
    $utr   = trim((string)($in['utr'] ?? ''));
    $proof = trim((string)($in['proof'] ?? ''));

    $rate = (float)setting('dcoin_inr_rate', '1');
    if ($rate <= 0) $rate = 1;

    $minCoins = (float)setting('dcoin_min_deposit', '10');
    $maxCoins = (float)setting('dcoin_max_deposit', '100000');

    if ($inr <= 0) {
        respond(422, ['success' => false, 'message' => 'Enter an amount']);
    }
    if ($utr === '' || mb_strlen($utr) < 4 || mb_strlen($utr) > 100) {
        respond(422, ['success' => false, 'message' => 'Enter a valid transaction ID']);
    }
    if ($proof === '') {
        respond(422, ['success' => false, 'message' => 'Please upload the payment proof']);
    }

    $coins = round($inr / $rate, 2);
    if ($coins < $minCoins) {
        respond(422, ['success' => false, 'message' => 'Minimum deposit is ' . $minCoins . ' Dcoin']);
    }
    if ($maxCoins > 0 && $coins > $maxCoins) {
        respond(422, ['success' => false, 'message' => 'Maximum deposit is ' . $maxCoins . ' Dcoin']);
    }

    $u = db()->prepare('SELECT id FROM users WHERE id = ? LIMIT 1');
    $u->execute([$userId]);
    if (!$u->fetch()) {
        respond(404, ['success' => false, 'message' => 'User not found']);
    }

    try {
        if (preg_match('~^https?://~i', $proof)) {
            if (!filter_var($proof, FILTER_VALIDATE_URL) || mb_strlen($proof) > 500) {
                respond(422, ['success' => false, 'message' => 'Invalid proof image URL']);
            }
            $imageUrl = $proof;
        } else {
            $imageUrl = upload_data_image($proof);
        }
    } catch (InvalidArgumentException $e) {
        respond(422, ['success' => false, 'message' => $e->getMessage()]);
    } catch (RuntimeException $e) {
        respond(502, ['success' => false, 'message' => $e->getMessage()]);
    }

    $ins = db()->prepare(
        'INSERT INTO deposits (user_id, amount, coins, inr_amount, coin_type, utr, reject_reason, screenshot, status, credited)
         VALUES (?, ?, ?, ?, "dcoin", ?, NULL, ?, 0, 0)'
    );
    $ins->execute([$userId, $coins, $coins, $inr, $utr, $imageUrl]);
    $id = (int)db()->lastInsertId();

    $q = db()->prepare(
        'SELECT id, coins, inr_amount, utr, screenshot, status, reject_reason, created_at
         FROM deposits WHERE id = ? LIMIT 1'
    );
    $q->execute([$id]);

    respond(200, [
        'success'  => true,
        'message'  => 'Deposit request sent',
        'deposit'  => deposit_payload($q->fetch()),
    ]);
} catch (PDOException $e) {
    respond(500, ['success' => false, 'message' => 'Server error']);
}
