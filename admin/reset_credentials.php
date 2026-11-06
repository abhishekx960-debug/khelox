<?php
require __DIR__ . '/config.php';
if (is_logged_in()) { header('Location: dashboard.php'); exit; }

// Reset key = ADMIN_INVITE_KEY from config.php. Default value par reset band rahega.
$keyIsDefault = ADMIN_INVITE_KEY === 'CHANGE_ME_TO_SOMETHING_LONG' || ADMIN_INVITE_KEY === '';

$errors = [];
$old = ['identifier' => '', 'new_username' => ''];

if ($_SERVER['REQUEST_METHOD'] === 'POST') {
    csrf_check();
    $old['identifier']   = strtolower(trim((string)($_POST['identifier'] ?? '')));
    $old['new_username'] = strtolower(trim((string)($_POST['new_username'] ?? '')));
    $key   = (string)($_POST['reset_key'] ?? '');
    $pass  = (string)($_POST['password'] ?? '');
    $pass2 = (string)($_POST['password2'] ?? '');

    $_SESSION['rtries'] = $_SESSION['rtries'] ?? 0;
    $_SESSION['rlock']  = $_SESSION['rlock'] ?? 0;

    if ($keyIsDefault) {
        $errors[] = 'Reset is disabled. Set a strong ADMIN_INVITE_KEY in config.php first';
    } elseif ($_SESSION['rlock'] > time()) {
        $errors[] = 'Too many attempts. Try again in ' . ($_SESSION['rlock'] - time()) . ' seconds.';
    } elseif (!hash_equals(ADMIN_INVITE_KEY, $key)) {
        $_SESSION['rtries']++;
        if ($_SESSION['rtries'] >= 5) { $_SESSION['rlock'] = time() + 300; $_SESSION['rtries'] = 0; }
        $errors[] = 'Incorrect reset key';
    } else {
        $phone = preg_replace('/[\s-]/', '', $old['identifier']);
        if ($old['identifier'] === '') $errors[] = 'Enter the admin username, email or phone';
        if ($old['new_username'] !== '' && !preg_match('/^[a-z0-9_]{4,30}$/', $old['new_username'])) {
            $errors[] = 'Username 4-30 chars: a-z, 0-9, _ only';
        }
        if (strlen($pass) < 8) $errors[] = 'Password must be at least 8 characters';
        if ($pass !== $pass2) $errors[] = 'Passwords do not match';

        if (!$errors) {
            try {
                $q = db()->prepare('SELECT id, username FROM admins WHERE username = ? OR email = ? OR phone = ? LIMIT 1');
                $q->execute([$old['identifier'], $old['identifier'], $phone]);
                $admin = $q->fetch();

                if (!$admin) {
                    $errors[] = 'No admin found with that username, email or phone';
                } else {
                    $newUser = $old['new_username'] !== '' ? $old['new_username'] : $admin['username'];
                    $dup = db()->prepare('SELECT id FROM admins WHERE username = ? AND id <> ? LIMIT 1');
                    $dup->execute([$newUser, $admin['id']]);
                    if ($dup->fetch()) {
                        $errors[] = 'Username is already taken';
                    } else {
                        db()->prepare('UPDATE admins SET username = ?, password_hash = ? WHERE id = ?')
                            ->execute([$newUser, password_hash($pass, PASSWORD_DEFAULT), $admin['id']]);
                        $_SESSION['rtries'] = 0;
                        flash('success', 'Credentials updated. Login with your new details.');
                        header('Location: login.php');
                        exit;
                    }
                }
            } catch (PDOException $e) {
                $errors[] = 'Server error, please try again';
            }
        }
    }
}

$authTitle = 'Reset credentials';
$authSub   = 'Enter the reset key to set a new username / password';
require __DIR__ . '/includes/auth_top.php';
?>
<?php if ($keyIsDefault): ?>
    <div class="alert alert-warning py-2 small">Reset is locked. Change <code>ADMIN_INVITE_KEY</code> in <code>config.php</code> to a long secret, then use it here.</div>
<?php endif; ?>
<?php if ($errors): ?>
    <div class="alert alert-danger py-2"><ul class="mb-0 ps-3 small"><?php foreach ($errors as $er): ?><li><?= e($er) ?></li><?php endforeach; ?></ul></div>
<?php endif; ?>
<form method="post" autocomplete="off">
    <?= csrf_field() ?>
    <div class="mb-3">
        <label class="form-label">Reset Key</label>
        <div class="input-group"><span class="input-group-text"><i class="bi bi-key"></i></span>
            <input type="password" id="rk" name="reset_key" class="form-control" required autofocus>
            <button type="button" class="btn btn-light border" data-toggle-pass="#rk"><i class="bi bi-eye"></i></button></div>
    </div>
    <div class="mb-3">
        <label class="form-label">Admin (username, email or phone)</label>
        <div class="input-group"><span class="input-group-text"><i class="bi bi-person"></i></span>
            <input type="text" name="identifier" class="form-control" value="<?= e($old['identifier']) ?>" required></div>
    </div>
    <div class="mb-3">
        <label class="form-label">New Username <span class="text-muted fw-normal">(optional)</span></label>
        <div class="input-group"><span class="input-group-text">@</span>
            <input type="text" name="new_username" class="form-control" value="<?= e($old['new_username']) ?>" placeholder="leave blank to keep current"></div>
    </div>
    <div class="row g-3 mb-3">
        <div class="col-sm-6">
            <label class="form-label">New Password</label>
            <div class="input-group"><span class="input-group-text"><i class="bi bi-lock"></i></span>
                <input type="password" name="password" class="form-control" minlength="8" required></div>
        </div>
        <div class="col-sm-6">
            <label class="form-label">Confirm Password</label>
            <div class="input-group"><span class="input-group-text"><i class="bi bi-lock-fill"></i></span>
                <input type="password" name="password2" class="form-control" minlength="8" required></div>
        </div>
    </div>
    <button class="btn btn-primary w-100 py-2 mt-2" <?= $keyIsDefault ? 'disabled' : '' ?>>Reset Credentials</button>
</form>
<p class="text-center text-muted small mt-4 mb-0"><a href="login.php" class="fw-semibold text-decoration-none"><i class="bi bi-arrow-left me-1"></i>Back to login</a></p>
<?php require __DIR__ . '/includes/auth_bottom.php'; ?>