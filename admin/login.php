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

$authTitle = 'Sign in';
$authSub   = 'Use your admin credentials to continue';
require __DIR__ . '/includes/auth_top.php';
?>
<?php if ($error): ?><div class="d-none" data-flash-type="danger" data-flash-msg="<?= e($error) ?>"></div><?php endif; ?>
<form method="post" autocomplete="username">
    <?= csrf_field() ?>
    <div class="mb-3">
        <label class="form-label" for="username">Username</label>
        <div class="input-group">
            <span class="input-group-text"><i class="bi bi-person"></i></span>
            <input type="text" id="username" name="username" class="form-control" placeholder="Enter username" value="<?= e($username) ?>" required autofocus autocomplete="username">
        </div>
    </div>
    <div class="mb-4">
        <label class="form-label" for="pw">Password</label>
        <div class="input-group">
            <span class="input-group-text"><i class="bi bi-lock"></i></span>
            <input type="password" id="pw" name="password" class="form-control" placeholder="Enter password" required autocomplete="current-password">
            <button type="button" class="btn btn-light border" data-toggle-pass="#pw" aria-label="Show password"><i class="bi bi-eye"></i></button>
        </div>
    </div>
    <button type="submit" class="btn btn-primary w-100 auth-submit">Sign in <i class="bi bi-arrow-right ms-1"></i></button>
</form>
<p class="text-center text-muted small mt-4 mb-0">
    Forgot your login? <a href="reset_credentials.php" class="fw-semibold text-decoration-none">Reset credentials</a>
</p>
<?php require __DIR__ . '/includes/auth_bottom.php'; ?>