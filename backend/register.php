<?php
require __DIR__ . '/config.php';

$in = json_input();
$name  = trim((string)($in['name'] ?? ''));
$email = strtolower(trim((string)($in['email'] ?? '')));
$phone = preg_replace('/[\s-]/', '', (string)($in['phone'] ?? ''));
$pass  = (string)($in['password'] ?? '');

if (mb_strlen($name) < 2 || mb_strlen($name) > 100) {
    respond(422, ['success' => false, 'message' => 'Enter a valid name']);
}
if (!filter_var($email, FILTER_VALIDATE_EMAIL) || strlen($email) > 190) {
    respond(422, ['success' => false, 'message' => 'Enter a valid email']);
}
if (!preg_match('/^\+?\d{10,15}$/', $phone)) {
    respond(422, ['success' => false, 'message' => 'Enter a valid phone number']);
}
if (strlen($pass) < 6) {
    respond(422, ['success' => false, 'message' => 'Password must be at least 6 characters']);
}

try {
    $pdo = db();

    $q = $pdo->prepare('SELECT email, phone FROM users WHERE email = ? OR phone = ? LIMIT 1');
    $q->execute([$email, $phone]);
    if ($row = $q->fetch()) {
        $msg = $row['email'] === $email ? 'Email is already registered' : 'Phone is already registered';
        respond(409, ['success' => false, 'message' => $msg]);
    }

    $ins = $pdo->prepare('INSERT INTO users (name, email, phone, password_hash) VALUES (?, ?, ?, ?)');
    $ins->execute([$name, $email, $phone, password_hash($pass, PASSWORD_DEFAULT)]);

    respond(201, [
        'success' => true,
        'user' => [
            'id' => (int)$pdo->lastInsertId(),
            'name' => $name,
            'email' => $email,
            'phone' => $phone,
            'fcoin' => 0,
            'dcoin' => 0,
            'wcoin' => 0,
        ],
    ]);
} catch (PDOException $e) {
    if ($e->getCode() === '23000') {
        respond(409, ['success' => false, 'message' => 'Email or phone is already registered']);
    }
    respond(500, ['success' => false, 'message' => 'Server error']);
}