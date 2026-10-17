<?php
require_once __DIR__ . '/config.php';
require_login();
$pdo = db();

if ($_SERVER['REQUEST_METHOD'] === 'POST') {
    csrf_check();
    $action = $_POST['action'] ?? '';

    if ($action === 'add') {
        $title   = trim((string)($_POST['title'] ?? ''));
        $message = trim((string)($_POST['message'] ?? ''));
        $errors = [];
        if (mb_strlen($title) < 2 || mb_strlen($title) > 150) $errors[] = 'Title must be 2-150 characters';
        if (mb_strlen($message) < 2 || mb_strlen($message) > 1000) $errors[] = 'Message must be 2-1000 characters';

        if (!$errors) {
            $pdo->prepare('INSERT INTO notifications (title, message) VALUES (?, ?)')->execute([$title, $message]);
            flash('success', 'Notification added');
        } else {
            flash('danger', implode(' | ', $errors));
        }
        header('Location: notifications.php');
        exit;
    }

    if ($action === 'toggle') {
        $id = (int)($_POST['id'] ?? 0);
        if ($id > 0) {
            $pdo->prepare('UPDATE notifications SET status = 1 - status WHERE id = ?')->execute([$id]);
            flash('success', 'Status updated');
        }
        header('Location: notifications.php');
        exit;
    }

    if ($action === 'delete') {
        $id = (int)($_POST['id'] ?? 0);
        $pdo->prepare('DELETE FROM notifications WHERE id = ?')->execute([$id]);
        flash('success', 'Notification deleted');
        header('Location: notifications.php');
        exit;
    }
}

$pageTitle = 'Manage Notifications';
$active = 'notifications';
require __DIR__ . '/includes/header.php';

$items = $pdo->query('SELECT id, title, message, status, created_at FROM notifications ORDER BY id DESC')->fetchAll();
?>
<div class="row g-3">
    <div class="col-lg-4">
        <div class="card">
            <div class="card-header"><h2>Add Notification</h2></div>
            <div class="card-body">
                <form method="post" autocomplete="off">
                    <?= csrf_field() ?>
                    <input type="hidden" name="action" value="add">
                    <div class="mb-3">
                        <label class="form-label">Title</label>
                        <input type="text" name="title" class="form-control" maxlength="150" placeholder="New offer live!" required>
                    </div>
                    <div class="mb-3">
                        <label class="form-label">Message</label>
                        <textarea name="message" class="form-control" rows="5" maxlength="1000" placeholder="Claim today's bonus..." required></textarea>
                    </div>
                    <button class="btn btn-primary w-100"><i class="bi bi-bell me-1"></i>Add Notification</button>
                </form>
            </div>
        </div>
    </div>
    <div class="col-lg-8">
        <div class="card">
            <div class="card-header"><h2>All Notifications <span class="text-muted fw-normal">(<?= count($items) ?>)</span></h2></div>
            <div class="table-responsive">
                <table class="table table-hover">
                    <thead><tr><th>Notification</th><th>Status</th><th class="text-end">Action</th></tr></thead>
                    <tbody>
                    <?php foreach ($items as $n): ?>
                        <tr>
                            <td>
                                <div class="fw-semibold"><?= e($n['title']) ?></div>
                                <small class="text-muted d-block"><?= e($n['message']) ?></small>
                                <small class="text-muted"><?= e(date('d M Y, h:i A', strtotime($n['created_at']))) ?></small>
                            </td>
                            <td><span class="badge rounded-pill badge-soft-<?= $n['status'] ? 'success' : 'secondary' ?> px-3 py-2"><?= $n['status'] ? 'Active' : 'Disabled' ?></span></td>
                            <td class="text-end text-nowrap">
                                <form method="post" class="d-inline">
                                    <?= csrf_field() ?>
                                    <input type="hidden" name="action" value="toggle">
                                    <input type="hidden" name="id" value="<?= (int)$n['id'] ?>">
                                    <button class="btn btn-sm btn-outline-<?= $n['status'] ? 'secondary' : 'success' ?>"><?= $n['status'] ? 'Disable' : 'Enable' ?></button>
                                </form>
                                <form method="post" class="d-inline" onsubmit="return confirm('Delete this item?')">
                                    <?= csrf_field() ?>
                                    <input type="hidden" name="action" value="delete">
                                    <input type="hidden" name="id" value="<?= (int)$n['id'] ?>">
                                    <button class="btn btn-sm btn-outline-danger"><i class="bi bi-trash"></i></button>
                                </form>
                            </td>
                        </tr>
                    <?php endforeach; ?>
                    <?php if (!$items): ?><tr><td colspan="3"><div class="empty"><i class="bi bi-bell"></i>No notifications yet</div></td></tr><?php endif; ?>
                    </tbody>
                </table>
            </div>
        </div>
    </div>
</div>
<?php require __DIR__ . '/includes/footer.php'; ?>
