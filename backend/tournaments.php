<?php
require __DIR__ . '/config.php';

$in = json_input();
$game = (string)($in['game'] ?? '');
if (!in_array($game, ['br', 'cs', 'community'], true)) {
    respond(422, ['success' => false, 'message' => 'Invalid game']);
}

try {
    games_ensure_schema();

    $st = db()->prepare(
        'SELECT t.id, t.game, t.title, t.prize_pool, t.entry_fee, t.slots, t.start_at,
                t.description, t.status, t.rule_id, r.points AS rule_points
         FROM tournaments t
         LEFT JOIN game_rules r ON r.id = t.rule_id
         WHERE t.game = ?
         ORDER BY t.start_at ASC, t.id ASC'
    );
    $st->execute([$game]);

    $items = [];
    foreach ($st->fetchAll() as $r) {
        $points = json_decode((string)($r['rule_points'] ?? ''), true);
        $items[] = [
            'id'          => (int)$r['id'],
            'game'        => $r['game'],
            'title'       => $r['title'],
            'prize_pool'  => (float)$r['prize_pool'],
            'entry_fee'   => (float)$r['entry_fee'],
            'slots'       => (int)$r['slots'],
            'start_at'    => $r['start_at'],
            'description' => (string)($r['description'] ?? ''),
            'status'      => $r['status'],
            'rule_id'     => $r['rule_id'] !== null ? (int)$r['rule_id'] : null,
            'rules'       => is_array($points) ? array_values($points) : [],
        ];
    }

    respond(200, ['success' => true, 'tournaments' => $items]);
} catch (PDOException $e) {
    respond(500, ['success' => false, 'message' => 'Server error']);
}
