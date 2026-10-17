<?php
require __DIR__ . '/config.php';
if (is_logged_in()) { header('Location: dashboard.php'); exit; }

$error = '';
$username = '';

if ($_SERVER['REQUEST_METHOD'] === 'POST') {
    csrf_check();
    $username = strtolower(trim((string)($_POST['username'] ?? '')));
    $pass     = (string)($_POST['password'] ?? '');

    $_SESSION['tries'] = $_SESSION['tries'] ?? 0;
    $_SESSION['lock']  = $_SESSION['lock'] ?? 0;

    if ($_SESSION['lock'] > time()) {
        $error = 'Too many attempts. Try again in ' . ($_SESSION['lock'] - time()) . ' seconds.';
    } elseif ($username === '' || $pass === '') {
        $error = 'Enter your username and password';
    } else {
        $q = db()->prepare('SELECT id, name, username, password_hash, status FROM admins WHERE username = ? LIMIT 1');
        $q->execute([$username]);
        $a = $q->fetch();

        if (!$a || !password_verify($pass, $a['password_hash'])) {
            $_SESSION['tries']++;
            if ($_SESSION['tries'] >= 5) { $_SESSION['lock'] = time() + 300; $_SESSION['tries'] = 0; }
            $error = 'Incorrect username or password';
        } elseif ((int)$a['status'] !== 1) {
            $error = 'Account is disabled';
        } else {
            session_regenerate_id(true);
            $_SESSION['tries'] = 0;
            $_SESSION['admin_id']       = (int)$a['id'];
            $_SESSION['admin_name']     = $a['name'];
            $_SESSION['admin_username'] = $a['username'];
            db()->prepare('UPDATE admins SET last_login = NOW() WHERE id = ?')->execute([$a['id']]);
            session_write_close();
            header('Location: dashboard.php');
            exit;
        }
    }
}

$hasAdmin = (int)db()->query('SELECT COUNT(*) FROM admins')->fetchColumn() > 0;
$authTitle = 'Welcome back';
$authSub   = 'Sign in to your admin account';
require __DIR__ . '/includes/auth_top.php';
?>
<?php if ($error): ?><div class="alert alert-danger py-2"><i class="bi bi-exclamation-circle me-1"></i><?= e($error) ?></div><?php endif; ?>
<form method="post" autocomplete="off">
    <?= csrf_field() ?>
    <div class="mb-3">
        <label class="form-label">Username</label>
        <div class="input-group">
            <span class="input-group-text"><i class="bi bi-person"></i></span>
            <input type="text" name="username" class="form-control" placeholder="username" value="<?= e($username) ?>" required autofocus>
        </div>
    </div>
    <div class="mb-4">
        <label class="form-label">Password</label>
        <div class="input-group">
            <span class="input-group-text"><i class="bi bi-lock"></i></span>
            <input type="password" id="pw" name="password" class="form-control" placeholder="••••••••" required>
            <button type="button" class="btn btn-light border" data-toggle-pass="#pw"><i class="bi bi-eye"></i></button>
        </div>
    </div>
    <button class="btn btn-primary w-100 py-2">Login <i class="bi bi-arrow-right ms-1"></i></button>
</form>
<p class="text-center text-muted small mt-4 mb-0">
    <?= $hasAdmin ? 'Need a new admin?' : 'No admin exists yet.' ?>
    <a href="register.php" class="fw-semibold text-decoration-none"><?= $hasAdmin ? 'Register' : 'Create the first admin' ?></a>
</p>
<?php require __DIR__ . '/includes/auth_bottom.php'; ?>