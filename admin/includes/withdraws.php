<?php
require_once __DIR__ . '/../config.php';
require_login();

$type = $type ?? 'fcoin';
$table = $type === 'wcoin' ? 'wcoin_withdraws' : 'fcoin_withdraws';
$coinLabel = ucfirst($type);
$pdo = db();

if ($_SERVER['REQUEST_METHOD'] === 'POST') {
    csrf_check();
    $action = (string)($_POST['action'] ?? '');
    $id = (int)($_POST['id'] ?? 0);

    if ($id > 0) {
        try {
            if ($action === 'approve') {
                $pdo->beginTransaction();
                $st = $pdo->prepare("SELECT * FROM $table WHERE id = ? FOR UPDATE");
                $st->execute([$id]);
                $row = $st->fetch();

                if (!$row) {
                    $pdo->rollBack();
                    flash('danger', 'Withdraw request nahi mili');
                } elseif ((int)$row['status'] === 1) {
                    $pdo->rollBack();
                    flash('danger', 'Ye request pehle hi approve ho chuki hai');
                } else {
                    $bal = $pdo->prepare("SELECT $type AS balance FROM users WHERE id = ? FOR UPDATE");
                    $bal->execute([(int)$row['user_id']]);
                    $user = $bal->fetch();
                    $amount = (float)$row['amount'];

                    if (!$user) {
                        $pdo->rollBack();
                        flash('danger', 'User nahi mila');
                    } elseif ((float)$user['balance'] < $amount) {
                        $pdo->rollBack();
                        flash('danger', 'User ka balance kam hai (' . $amount . ' ' . $coinLabel . ' required)');
                    } else {
                        $pdo->prepare("UPDATE $table SET status = 1, remark = NULL WHERE id = ?")->execute([$id]);
                        $pdo->prepare("UPDATE users SET $type = $type - ? WHERE id = ?")
                            ->execute([$amount, (int)$row['user_id']]);
                        $pdo->commit();
                        flash('success', $amount . ' ' . $coinLabel . ' deduct ho gaye, withdraw approve');
                    }
                }
            } elseif ($action === 'pending') {
                $st = $pdo->prepare("SELECT status FROM $table WHERE id = ? LIMIT 1");
                $st->execute([$id]);
                $row = $st->fetch();
                if (!$row) {
                    flash('danger', 'Withdraw request nahi mili');
                } elseif ((int)$row['status'] === 1) {
                    flash('danger', 'Approved withdraw ko pending nahi kar sakte');
                } else {
                    $pdo->prepare("UPDATE $table SET status = 0, remark = NULL WHERE id = ?")->execute([$id]);
                    flash('success', 'Withdraw pending me daal diya');
                }
            } elseif ($action === 'reject') {
                $reason = trim((string)($_POST['reason'] ?? ''));
                $st = $pdo->prepare("SELECT status FROM $table WHERE id = ? LIMIT 1");
                $st->execute([$id]);
                $row = $st->fetch();

                if (!$row) {
                    flash('danger', 'Withdraw request nahi mili');
                } elseif ((int)$row['status'] === 1) {
                    flash('danger', 'Approved withdraw reject nahi ho sakta');
                } elseif ($reason === '' || mb_strlen($reason) > 255) {
                    flash('danger', 'Reject reason likho (max 255 characters)');
                } else {
                    $pdo->prepare("UPDATE $table SET status = 2, remark = ? WHERE id = ?")
                        ->execute([$reason, $id]);
                    flash('success', 'Withdraw reject kar diya');
                }
            } elseif ($action === 'delete') {
                $pdo->beginTransaction();
                $st = $pdo->prepare("SELECT * FROM $table WHERE id = ? FOR UPDATE");
                $st->execute([$id]);
                $row = $st->fetch();

                if (!$row) {
                    $pdo->rollBack();
                    flash('danger', 'Withdraw request nahi mili');
                } else {
                    if ((int)$row['status'] === 1) {
                        $pdo->prepare("UPDATE users SET $type = $type + ? WHERE id = ?")
                            ->execute([(float)$row['amount'], (int)$row['user_id']]);
                    }
                    $pdo->prepare("DELETE FROM $table WHERE id = ?")->execute([$id]);
                    $pdo->commit();
                    flash('success', 'Withdraw delete ho gaya, user side se bhi hat gaya');
                }
            }
        } catch (PDOException $e) {
            if ($pdo->inTransaction()) $pdo->rollBack();
            flash('danger', 'Request process nahi hui, dobara try karo');
        }
    }

    header('Location: ' . basename($_SERVER['PHP_SELF']) . '?' . http_build_query(['status' => $_POST['return_status'] ?? '']));
    exit;
}

require __DIR__ . '/header.php';

$status = (string)($_GET['status'] ?? '');
$allowed = ['pending' => 0, 'approved' => 1, 'rejected' => 2];
$where = '';
$params = [];
if (isset($allowed[$status])) {
    $where = 'WHERE w.status = ?';
    $params[] = $allowed[$status];
}

$st = $pdo->prepare(
    "SELECT w.*, u.name AS user_name, u.email AS user_email, u.phone AS user_phone, u.$type AS user_balance
     FROM $table w LEFT JOIN users u ON u.id = w.user_id
     $where ORDER BY w.id DESC LIMIT 300"
);
$st->execute($params);
$rows = $st->fetchAll();

$counts = ['all' => 0, 0 => 0, 1 => 0, 2 => 0];
foreach ($pdo->query("SELECT status, COUNT(*) AS c FROM $table GROUP BY status") as $c) {
    $counts[(int)$c['status']] = (int)$c['c'];
    $counts['all'] += (int)$c['c'];
}

$badge = [0 => 'warning', 1 => 'success', 2 => 'danger'];
$label = [0 => 'Pending', 1 => 'Approved', 2 => 'Rejected'];
$inrRate = (float)setting($type . '_inr_rate', '0');
$min = (float)setting($type . '_min_withdraw', '0');
$max = (float)setting($type . '_max_withdraw', '0');
?>
<div class="row g-3 mb-3">
    <div class="col-6 col-lg-3"><div class="card stat"><div class="stat-icon" style="background:#eceef3;color:#5b6270"><i class="bi bi-wallet2"></i></div><div><div class="lbl">Total Requests</div><div class="val"><?= number_format($counts['all']) ?></div></div></div></div>
    <div class="col-6 col-lg-3"><div class="card stat"><div class="stat-icon" style="background:#fff4dd;color:#b7791f"><i class="bi bi-hourglass-split"></i></div><div><div class="lbl">Pending</div><div class="val"><?= number_format($counts[0]) ?></div></div></div></div>
    <div class="col-6 col-lg-3"><div class="card stat"><div class="stat-icon" style="background:#e3f8ee;color:#12875a"><i class="bi bi-check2-circle"></i></div><div><div class="lbl">Approved</div><div class="val"><?= number_format($counts[1]) ?></div></div></div></div>
    <div class="col-6 col-lg-3"><div class="card stat"><div class="stat-icon" style="background:#fdecec;color:#c0392b"><i class="bi bi-x-circle"></i></div><div><div class="lbl">Rejected</div><div class="val"><?= number_format($counts[2]) ?></div></div></div></div>
</div>

<div class="card mb-3">
    <div class="card-body d-flex flex-wrap gap-3 align-items-center small text-muted">
        <span><i class="bi bi-coin me-1"></i>Minimum: <b><?= number_format($min, 2) ?> <?= e($coinLabel) ?></b></span>
        <span><i class="bi bi-coin me-1"></i>Maximum: <b><?= number_format($max, 2) ?> <?= e($coinLabel) ?></b></span>
        <?php if ($inrRate > 0): ?><span><i class="bi bi-currency-rupee me-1"></i>1 <?= e($coinLabel) ?> = INR <?= number_format($inrRate, 2) ?></span><?php endif; ?>
        <a href="settings.php" class="ms-auto">Change in Settings <i class="bi bi-arrow-right"></i></a>
    </div>
</div>

<div class="card">
    <div class="card-header d-flex flex-wrap justify-content-between align-items-center gap-2">
        <h2><?= e($coinLabel) ?> Withdraw Requests</h2>
        <div class="btn-group btn-group-sm">
            <a class="btn btn-light border <?= $status === '' ? 'active' : '' ?>" href="?">All</a>
            <a class="btn btn-light border <?= $status === 'pending' ? 'active' : '' ?>" href="?status=pending">Pending</a>
            <a class="btn btn-light border <?= $status === 'approved' ? 'active' : '' ?>" href="?status=approved">Approved</a>
            <a class="btn btn-light border <?= $status === 'rejected' ? 'active' : '' ?>" href="?status=rejected">Rejected</a>
        </div>
    </div>
    <div class="table-responsive">
        <table class="table table-hover">
            <thead><tr><th>User</th><th>Amount</th><th>UPI ID</th><th>Status</th><th>Date</th><th class="text-end">Action</th></tr></thead>
            <tbody>
            <?php foreach ($rows as $r): ?>
                <?php $stInt = (int)$r['status']; ?>
                <tr>
                    <td>
                        <div class="d-flex align-items-center gap-2">
                            <span class="avatar"><?= e(initials((string)($r['user_name'] ?? '?'))) ?></span>
                            <div>
                                <div class="fw-semibold"><?= e((string)($r['user_name'] ?? 'Unknown')) ?> <small class="text-muted fw-normal">#<?= (int)$r['user_id'] ?></small></div>
                                <small class="text-muted"><?= e((string)($r['user_email'] ?? '')) ?></small><br>
                                <small class="text-muted"><?= e((string)($r['user_phone'] ?? '')) ?></small>
                            </div>
                        </div>
                    </td>
                    <td>
                        <div class="fw-semibold text-nowrap"><?= number_format((float)$r['amount'], 2) ?> <?= e($coinLabel) ?></div>
                        <?php if ($inrRate > 0): ?><small class="text-muted">INR <?= number_format((float)$r['amount'] * $inrRate, 2) ?></small><?php endif; ?>
                        <br><small class="text-muted">Balance: <?= number_format((float)($r['user_balance'] ?? 0), 2) ?></small>
                    </td>
                    <td class="font-monospace small"><?= e((string)$r['upi_id']) ?></td>
                    <td>
                        <span class="badge rounded-pill badge-soft-<?= $badge[$stInt] ?? 'secondary' ?> px-3 py-2"><?= $label[$stInt] ?? 'Unknown' ?></span>
                        <?php if ($stInt === 2 && !empty($r['remark'])): ?>
                            <div class="small text-danger mt-1" style="max-width:180px"><?= e($r['remark']) ?></div>
                        <?php endif; ?>
                    </td>
                    <td class="text-nowrap text-muted"><?= e(date('d M Y, h:i A', strtotime((string)$r['created_at']))) ?></td>
                    <td class="text-end text-nowrap">
                        <?php if ($stInt !== 1): ?>
                            <form method="post" class="d-inline">
                                <?= csrf_field() ?>
                                <input type="hidden" name="action" value="approve">
                                <input type="hidden" name="id" value="<?= (int)$r['id'] ?>">
                                <input type="hidden" name="return_status" value="<?= e($status) ?>">
                                <button class="btn btn-sm btn-success" title="Approve & deduct coins"><i class="bi bi-check-lg"></i></button>
                            </form>
                        <?php endif; ?>
                        <?php if ($stInt !== 0): ?>
                            <form method="post" class="d-inline">
                                <?= csrf_field() ?>
                                <input type="hidden" name="action" value="pending">
                                <input type="hidden" name="id" value="<?= (int)$r['id'] ?>">
                                <input type="hidden" name="return_status" value="<?= e($status) ?>">
                                <button class="btn btn-sm btn-outline-secondary" title="Mark pending"><i class="bi bi-hourglass"></i></button>
                            </form>
                        <?php endif; ?>
                        <?php if ($stInt !== 2): ?>
                            <button class="btn btn-sm btn-outline-danger btn-reject"
                                    data-id="<?= (int)$r['id'] ?>"
                                    data-name="<?= e((string)($r['user_name'] ?? '')) ?>"
                                    title="Reject"><i class="bi bi-x-lg"></i></button>
                        <?php endif; ?>
                        <form method="post" class="d-inline" onsubmit="return confirm('Withdraw delete karna hai? User side se bhi hat jayega.')">
                            <?= csrf_field() ?>
                            <input type="hidden" name="action" value="delete">
                            <input type="hidden" name="id" value="<?= (int)$r['id'] ?>">
                            <input type="hidden" name="return_status" value="<?= e($status) ?>">
                            <button class="btn btn-sm btn-outline-dark" title="Delete"><i class="bi bi-trash"></i></button>
                        </form>
                    </td>
                </tr>
            <?php endforeach; ?>
            <?php if (!$rows): ?><tr><td colspan="6"><div class="empty"><i class="bi bi-inbox"></i>Koi withdraw request nahi mili</div></td></tr><?php endif; ?>
            </tbody>
        </table>
    </div>
</div>

<div class="modal fade" id="rejectModal" tabindex="-1">
    <div class="modal-dialog modal-dialog-centered">
        <form method="post" class="modal-content border-0 shadow" style="border-radius:1rem">
            <?= csrf_field() ?>
            <input type="hidden" name="action" value="reject">
            <input type="hidden" name="id" id="r-id">
            <input type="hidden" name="return_status" value="<?= e($status) ?>">
            <div class="modal-header border-0 pb-0">
                <div><h5 class="modal-title fw-bold">Reject Withdraw</h5><small class="text-muted" id="r-name"></small></div>
                <button type="button" class="btn-close" data-bs-dismiss="modal"></button>
            </div>
            <div class="modal-body">
                <label class="form-label">Reason (user ko dikhega)</label>
                <textarea name="reason" class="form-control" rows="3" maxlength="255" placeholder="UPI details sahi nahi hain..." required></textarea>
            </div>
            <div class="modal-footer border-0 pt-0">
                <button type="button" class="btn btn-light" data-bs-dismiss="modal">Cancel</button>
                <button class="btn btn-danger px-4">Reject</button>
            </div>
        </form>
    </div>
</div>
<?php
$extraJs = '<script>
document.addEventListener("DOMContentLoaded", function () {
  var modal;
  document.querySelectorAll(".btn-reject").forEach(function (b) {
    b.addEventListener("click", function () {
      document.getElementById("r-id").value = b.dataset.id;
      document.getElementById("r-name").textContent = b.dataset.name;
      modal = modal || new bootstrap.Modal(document.getElementById("rejectModal"));
      modal.show();
    });
  });
});
</script>';
require __DIR__ . '/footer.php';
