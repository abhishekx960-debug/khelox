<?php
require __DIR__ . '/config.php';
withdraws_ensure_schema();

$in = json_input();
$action = (string)($in['action'] ?? 'create');
$userId = (int)($in['user_id'] ?? 0);

if ($userId <= 0) {
    respond(422, ['success' => false, 'message' => 'Invalid user']);
}

function withdraw_table(string $type): string {
    return $type === 'wcoin' ? 'wcoin_withdraws' : 'fcoin_withdraws';
}

function withdraw_status_label(int $status): string {
    if ($status === 1) return 'approved';
    if ($status === 2) return 'rejected';
    return 'pending';
}

function withdraw_payload(string $type, array $r): array {
    return [
        'id'         => (int)$r['id'],
        'type'       => $type,
        'amount'     => (float)$r['amount'],
        'upi_id'     => (string)($r['upi_id'] ?? ''),
        'status'     => withdraw_status_label((int)$r['status']),
        'remark'     => (string)($r['remark'] ?? ''),
        'created_at' => (string)$r['created_at'],
    ];
}

try {
    if ($action === 'history') {
        $items = [];
        foreach (['fcoin', 'wcoin'] as $type) {
            $q = db()->prepare(
                'SELECT id, amount, upi_id, status, remark, created_at
                 FROM ' . withdraw_table($type) . ' WHERE user_id = ? ORDER BY id DESC LIMIT 100'
            );
            $q->execute([$userId]);
            foreach ($q->fetchAll() as $row) {
                $items[] = withdraw_payload($type, $row);
            }
        }
        usort($items, fn($a, $b) => strcmp($b['created_at'], $a['created_at']));

        respond(200, ['success' => true, 'withdrawals' => $items]);
    }

    // ---- create ----
    $type = (string)($in['type'] ?? 'fcoin');
    if (!in_array($type, ['fcoin', 'wcoin'], true)) {
        respond(422, ['success' => false, 'message' => 'Invalid coin type']);
    }

    $amount = round((float)($in['amount'] ?? 0), 2);
    $upiId  = trim((string)($in['upi_id'] ?? ''));

    $min = (float)setting($type . '_min_withdraw', '100');
    $max = (float)setting($type . '_max_withdraw', '100000');

    if ($amount <= 0) {
        respond(422, ['success' => false, 'message' => 'Enter an amount']);
    }
    if ($amount < $min) {
        respond(422, ['success' => false, 'message' => 'Minimum ' . ucfirst($type) . ' withdrawal is ' . $min]);
    }
    if ($max > 0 && $amount > $max) {
        respond(422, ['success' => false, 'message' => 'Maximum ' . ucfirst($type) . ' withdrawal is ' . $max]);
    }
    if ($upiId === '' || mb_strlen($upiId) > 120) {
        respond(422, ['success' => false, 'message' => 'Enter a valid UPI ID']);
    }

    $pdo = db();
    $pdo->beginTransaction();

    $q = $pdo->prepare('SELECT ' . $type . ' AS balance FROM users WHERE id = ? FOR UPDATE');
    $q->execute([$userId]);
    $row = $q->fetch();
    if (!$row) {
        $pdo->rollBack();
        respond(404, ['success' => false, 'message' => 'User not found']);
    }
    if ((float)$row['balance'] < $amount) {
        $pdo->rollBack();
        respond(422, ['success' => false, 'message' => 'Insufficient balance']);
    }

    // Coins are held as soon as the request is created. Approval only updates
    // the status; rejection or deleting a held request returns the coins.
    $pdo->prepare('UPDATE users SET ' . $type . ' = ' . $type . ' - ? WHERE id = ?')
        ->execute([$amount, $userId]);

    $ins = $pdo->prepare(
        'INSERT INTO ' . withdraw_table($type) . ' (user_id, amount, upi_id, remark, status, deducted) VALUES (?, ?, ?, NULL, 0, 1)'
    );
    $ins->execute([$userId, $amount, $upiId]);
    $id = (int)$pdo->lastInsertId();

    $q = $pdo->prepare(
        'SELECT id, amount, upi_id, status, remark, created_at
         FROM ' . withdraw_table($type) . ' WHERE id = ? LIMIT 1'
    );
    $q->execute([$id]);
    $created = withdraw_payload($type, $q->fetch());
    $pdo->commit();

    respond(200, [
        'success'     => true,
        'message'     => 'Withdrawal request sent',
        'withdrawal'  => $created,
    ]);
} catch (PDOException $e) {
    if (isset($pdo) && $pdo instanceof PDO && $pdo->inTransaction()) {
        $pdo->rollBack();
    }
    respond(500, ['success' => false, 'message' => 'Server error']);
}
