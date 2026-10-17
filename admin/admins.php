<?php
require_once __DIR__ . '/config.php';
require_login();
$pdo = db();

if ($_SERVER['REQUEST_METHOD'] === 'POST' && ($_POST['action'] ?? '') === 'toggle') {
    csrf_check();
    $id = (int)($_POST['id'] ?? 0);
    if ($id === (int)$_SESSION['admin_id']) {
        flash('danger', 'You cannot disable your own account');
    } elseif ($id > 0) {
        $pdo->prepare('UPDATE admins SET status = 1 - status WHERE id = ?')->execute([$id]);
        flash('success', 'Status updated');
    }
    header('Location: admins.php');
    exit;
}

$pageTitle = 'Admins';
$active = 'admins';
require __DIR__ . '/includes/header.php';

$admins = $pdo->query('SELECT id, name, username, email, phone, status, last_login FROM admins ORDER BY id')->fetchAll();
?>
<div class="card">
    <div class="card-header d-flex justify-content-between align-items-center">
        <h2>All Admins <span class="text-muted fw-normal">(<?= count($admins) ?>)</span></h2>
        <a href="register.php" target="_blank" class="btn btn-sm btn-primary"><i class="bi bi-plus-lg me-1"></i>Add Admin</a>
    </div>
    <div class="table-responsive">
        <table class="table table-hover">
            <thead><tr><th>Admin</th><th>Phone</th><th>Last Login</th><th>Status</th><th class="text-end">Action</th></tr></thead>
            <tbody>
            <?php foreach ($admins as $a): $me = (int)$a['id'] === (int)$_SESSION['admin_id']; ?>
                <tr>
                    <td>
                        <div class="d-flex align-items-center gap-2">
                            <span class="avatar"><?= e(initials($a['name'])) ?></span>
                            <div>
                                <div class="fw-semibold"><?= e($a['name']) ?> <?= $me ? '<span class="badge text-bg-light border">You</span>' : '' ?></div>
                                <small class="text-muted">@<?= e($a['username']) ?> &middot; <?= e($a['email']) ?></small>
                            </div>
                        </div>
                    </td>
                    <td><?= e($a['phone']) ?></td>
                    <td class="text-nowrap text-muted"><?= $a['last_login'] ? e(date('d M Y, h:i A', strtotime($a['last_login']))) : '-' ?></td>
                    <td><span class="badge rounded-pill badge-soft-<?= $a['status'] ? 'success' : 'secondary' ?> px-3 py-2"><?= $a['status'] ? 'Active' : 'Disabled' ?></span></td>
                    <td class="text-end">
                        <?php if (!$me): ?>
                        <form method="post" class="d-inline" onsubmit="return confirm('Are you sure?')">
                            <?= csrf_field() ?>
                            <input type="hidden" name="action" value="toggle">
                            <input type="hidden" name="id" value="<?= (int)$a['id'] ?>">
                            <button class="btn btn-sm btn-outline-<?= $a['status'] ? 'danger' : 'success' ?>"><?= $a['status'] ? 'Disable' : 'Enable' ?></button>
                        </form>
                        <?php endif; ?>
                    </td>
                </tr>
            <?php endforeach; ?>
            </tbody>
        </table>
    </div>
</div>
<?php require __DIR__ . '/includes/footer.php'; ?>