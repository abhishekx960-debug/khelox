<?php
require __DIR__ . '/config.php';

$in = json_input();
$id = (int)($in['id'] ?? 0);

if ($id <= 0) {
    respond(422, ['success' => false, 'message' => 'Invalid user']);
}

try {
    $q = db()->prepare('SELECT id, name, email, phone, fcoin, dcoin, wcoin FROM users WHERE id = ? LIMIT 1');
    $q->execute([$id]);
    $u = $q->fetch();

    if (!$u) {
        respond(404, ['success' => false, 'message' => 'User not found']);
    }

    respond(200, [
        'success' => true,
        'user' => [
            'id' => (int)$u['id'],
            'name' => $u['name'],
            'email' => $u['email'],
            'phone' => $u['phone'],
            'fcoin' => (float)$u['fcoin'],
            'dcoin' => (float)$u['dcoin'],
            'wcoin' => (float)$u['wcoin'],
        ],
    ]);
} catch (PDOException $e) {
    respond(500, ['success' => false, 'message' => 'Server error']);
}