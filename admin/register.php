<?php
require __DIR__ . '/config.php';

$adminCount = (int)db()->query('SELECT COUNT(*) FROM admins')->fetchColumn();
$firstAdmin = $adminCount === 0;

$errors = [];
$old = ['name' => '', 'username' => '', 'email' => '', 'phone' => ''];

if ($_SERVER['REQUEST_METHOD'] === 'POST') {
    csrf_check();
    $old['name']     = trim((string)($_POST['name'] ?? ''));
    $old['username'] = strtolower(trim((string)($_POST['username'] ?? '')));
    $old['email']    = strtolower(trim((string)($_POST['email'] ?? '')));
    $old['phone']    = preg_replace('/[\s-]/', '', (string)($_POST['phone'] ?? ''));
    $pass    = (string)($_POST['password'] ?? '');
    $pass2   = (string)($_POST['password2'] ?? '');
    $key     = (string)($_POST['invite_key'] ?? '');

    if (!$firstAdmin && !hash_equals(ADMIN_INVITE_KEY, $key)) $errors[] = 'Invite key galat hai';
    if (mb_strlen($old['name']) < 2 || mb_strlen($old['name']) > 100) $errors[] = 'Sahi naam daalo';
    if (!preg_match('/^[a-z0-9_]{4,30}$/', $old['username'])) $errors[] = 'Username 4-30 chars: a-z, 0-9, _ only';
    if (!filter_var($old['email'], FILTER_VALIDATE_EMAIL) || strlen($old['email']) > 190) $errors[] = 'Sahi email daalo';
    if (!preg_match('/^\+?\d{10,15}$/', $old['phone'])) $errors[] = 'Sahi phone number daalo';
    if (strlen($pass) < 8) $errors[] = 'Password kam se kam 8 characters';
    if ($pass !== $pass2) $errors[] = 'Passwords match nahi karte';

    if (!$errors) {
        try {
            $q = db()->prepare('SELECT username, email, phone FROM admins WHERE username = ? OR email = ? OR phone = ? LIMIT 1');
            $q->execute([$old['username'], $old['email'], $old['phone']]);
            if ($r = $q->fetch()) {
                if ($r['username'] === $old['username']) $errors[] = 'Username already liya hua hai';
                elseif ($r['email'] === $old['email'])   $errors[] = 'Email already registered hai';
                else                                      $errors[] = 'Phone already registered hai';
            } else {
                db()->prepare('INSERT INTO admins (name, username, email, phone, password_hash) VALUES (?,?,?,?,?)')
                    ->execute([$old['name'], $old['username'], $old['email'], $old['phone'], password_hash($pass, PASSWORD_DEFAULT)]);
                flash('success', 'Admin ban gaya. Ab login karo.');
                header('Location: login.php');
                exit;
            }
        } catch (PDOException $e) {
            $errors[] = 'Server error, dobara try karo';
        }
    }
}

$authTitle = 'Create admin account';
$authSub   = $firstAdmin ? 'Pehla admin - invite key ki zaroorat nahi' : 'Naya admin banane ke liye invite key chahiye';
require __DIR__ . '/includes/auth_top.php';
?>
<?php if ($errors): ?>
    <div class="alert alert-danger py-2"><ul class="mb-0 ps-3 small"><?php foreach ($errors as $er): ?><li><?= e($er) ?></li><?php endforeach; ?></ul></div>
<?php endif; ?>
<form method="post" autocomplete="off">
    <?= csrf_field() ?>
    <div class="mb-3">
        <label class="form-label">Full Name</label>
        <div class="input-group"><span class="input-group-text"><i class="bi bi-person-vcard"></i></span>
            <input type="text" name="name" class="form-control" value="<?= e($old['name']) ?>" required></div>
    </div>
    <div class="row g-3 mb-3">
        <div class="col-sm-6">
            <label class="form-label">Username</label>
            <div class="input-group"><span class="input-group-text">@</span>
                <input type="text" name="username" class="form-control" value="<?= e($old['username']) ?>" required></div>
        </div>
        <div class="col-sm-6">
            <label class="form-label">Phone</label>
            <div class="input-group"><span class="input-group-text"><i class="bi bi-telephone"></i></span>
                <input type="tel" name="phone" class="form-control" value="<?= e($old['phone']) ?>" required></div>
        </div>
    </div>
    <div class="mb-3">
        <label class="form-label">Email</label>
        <div class="input-group"><span class="input-group-text"><i class="bi bi-envelope"></i></span>
            <input type="email" name="email" class="form-control" value="<?= e($old['email']) ?>" required></div>
    </div>
    <div class="row g-3 mb-3">
        <div class="col-sm-6">
            <label class="form-label">Password</label>
            <div class="input-group"><span class="input-group-text"><i class="bi bi-lock"></i></span>
                <input type="password" id="pw1" name="password" class="form-control" minlength="8" required></div>
        </div>
        <div class="col-sm-6">
            <label class="form-label">Confirm Password</label>
            <div class="input-group"><span class="input-group-text"><i class="bi bi-lock-fill"></i></span>
                <input type="password" id="pw2" name="password2" class="form-control" minlength="8" required></div>
        </div>
    </div>
    <?php if (!$firstAdmin): ?>
    <div class="mb-3">
        <label class="form-label">Invite Key</label>
        <div class="input-group"><span class="input-group-text"><i class="bi bi-key"></i></span>
            <input type="password" id="ik" name="invite_key" class="form-control" required>
            <button type="button" class="btn btn-light border" data-toggle-pass="#ik"><i class="bi bi-eye"></i></button></div>
    </div>
    <?php endif; ?>
    <button class="btn btn-primary w-100 py-2 mt-2">Register</button>
</form>
<p class="text-center text-muted small mt-4 mb-0">Already admin? <a href="login.php" class="fw-semibold text-decoration-none">Login</a></p>
<?php require __DIR__ . '/includes/auth_bottom.php'; ?>