<?php
require __DIR__ . '/config.php';

$in = json_input();
$email = strtolower(trim((string)($in['email'] ?? '')));
$pass  = (string)($in['password'] ?? '');

if ($email === '' || $pass === '') {
    respond(422, ['success' => false, 'message' => 'Enter your email and password']);
}

try {
    $q = db()->prepare('SELECT id, name, email, phone, fcoin, dcoin, wcoin, password_hash FROM users WHERE email = ? LIMIT 1');
    $q->execute([$email]);
    $u = $q->fetch();

    if (!$u || !password_verify($pass, $u['password_hash'])) {
        respond(401, ['success' => false, 'message' => 'Incorrect email or password']);
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