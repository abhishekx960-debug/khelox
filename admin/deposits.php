<?php
require_once __DIR__ . '/config.php';
require_login();
deposits_ensure_schema();
$pdo = db();

if ($_SERVER['REQUEST_METHOD'] === 'POST') {
    csrf_check();
    $action = (string)($_POST['action'] ?? '');
    $id = (int)($_POST['id'] ?? 0);

    if ($id > 0) {
        try {
            if ($action === 'approve') {
                $pdo->beginTransaction();
                $st = $pdo->prepare('SELECT * FROM deposits WHERE id = ? FOR UPDATE');
                $st->execute([$id]);
                $row = $st->fetch();

                if (!$row) {
                    $pdo->rollBack();
                    flash('danger', 'Deposit request nahi mili');
                } elseif ((int)$row['credited'] === 1) {
                    $pdo->rollBack();
                    flash('danger', 'Ye deposit pehle hi approve ho chuka hai');
                } else {
                    $coins = (float)$row['coins'];
                    if ($coins <= 0) $coins = (float)$row['amount'];

                    $pdo->prepare('UPDATE deposits SET status = 1, credited = 1, reject_reason = NULL WHERE id = ?')
                        ->execute([$id]);
                    $pdo->prepare('UPDATE users SET dcoin = dcoin + ? WHERE id = ?')
                        ->execute([$coins, (int)$row['user_id']]);
                    $pdo->commit();
                    flash('success', 'Deposit approve ho gaya, ' . $coins . ' Dcoin add kiye gaye');
                }
            } elseif ($action === 'pending') {
                $st = $pdo->prepare('SELECT credited FROM deposits WHERE id = ? LIMIT 1');
                $st->execute([$id]);
                $row = $st->fetch();
                if (!$row) {
                    flash('danger', 'Deposit request nahi mili');
                } elseif ((int)$row['credited'] === 1) {
                    flash('danger', 'Approved deposit ko pending nahi kar sakte, coins already add ho chuke hain');
                } else {
                    $pdo->prepare('UPDATE deposits SET status = 0, reject_reason = NULL WHERE id = ?')
                        ->execute([$id]);
                    flash('success', 'Deposit pending me daal diya');
                }
            } elseif ($action === 'reject') {
                $reason = trim((string)($_POST['reason'] ?? ''));
                $st = $pdo->prepare('SELECT credited FROM deposits WHERE id = ? LIMIT 1');
                $st->execute([$id]);
                $row = $st->fetch();

                if (!$row) {
                    flash('danger', 'Deposit request nahi mili');
                } elseif ((int)$row['credited'] === 1) {
                    flash('danger', 'Approved deposit reject nahi ho sakta');
                } elseif ($reason === '' || mb_strlen($reason) > 255) {
                    flash('danger', 'Reject reason likho (max 255 characters)');
                } else {
                    $pdo->prepare('UPDATE deposits SET status = 2, reject_reason = ? WHERE id = ?')
                        ->execute([$reason, $id]);
                    flash('success', 'Deposit reject kar diya');
                }
            } elseif ($action === 'delete') {
                $pdo->beginTransaction();
                $st = $pdo->prepare('SELECT * FROM deposits WHERE id = ? FOR UPDATE');
                $st->execute([$id]);
                $row = $st->fetch();

                if (!$row) {
                    $pdo->rollBack();
                    flash('danger', 'Deposit request nahi mili');
                } else {
                    if ((int)$row['credited'] === 1) {
                        $coins = (float)$row['coins'];
                        if ($coins <= 0) $coins = (float)$row['amount'];
                        $pdo->prepare('UPDATE users SET dcoin = GREATEST(0, dcoin - ?) WHERE id = ?')
                            ->execute([$coins, (int)$row['user_id']]);
                    }
                    $pdo->prepare('DELETE FROM deposits WHERE id = ?')->execute([$id]);
                    $pdo->commit();
                    flash('success', 'Deposit delete ho gaya, user side se bhi hat gaya');
                }
            }
        } catch (PDOException $e) {
            if ($pdo->inTransaction()) $pdo->rollBack();
            flash('danger', 'Request process nahi hui, dobara try karo');
        }
    }

    header('Location: deposits.php?' . http_build_query(['status' => $_POST['return_status'] ?? '']));
    exit;
}

$pageTitle = 'Manage Deposits';
$active = 'deposits';
require __DIR__ . '/includes/header.php';

$status = (string)($_GET['status'] ?? '');
$allowed = ['pending' => 0, 'approved' => 1, 'rejected' => 2];
$where = '';
$params = [];
if (isset($allowed[$status])) {
    $where = 'WHERE d.status = ?';
    $params[] = $allowed[$status];
}

$st = $pdo->prepare(
    "SELECT d.*, u.name AS user_name, u.email AS user_email, u.phone AS user_phone
     FROM deposits d LEFT JOIN users u ON u.id = d.user_id
     $where ORDER BY d.id DESC LIMIT 300"
);
$st->execute($params);
$rows = $st->fetchAll();

$counts = ['all' => 0, 0 => 0, 1 => 0, 2 => 0];
foreach ($pdo->query('SELECT status, COUNT(*) AS c FROM deposits GROUP BY status') as $c) {
    $counts[(int)$c['status']] = (int)$c['c'];
    $counts['all'] += (int)$c['c'];
}

$badge = [0 => 'warning', 1 => 'success', 2 => 'danger'];
$label = [0 => 'Pending', 1 => 'Approved', 2 => 'Rejected'];
?>
<div class="row g-3 mb-3">
    <div class="col-6 col-lg-3"><div class="card stat"><div class="stat-icon" style="background:#eceef3;color:#5b6270"><i class="bi bi-cash-stack"></i></div><div><div class="lbl">Total Requests</div><div class="val"><?= number_format($counts['all']) ?></div></div></div></div>
    <div class="col-6 col-lg-3"><div class="card stat"><div class="stat-icon" style="background:#fff4dd;color:#b7791f"><i class="bi bi-hourglass-split"></i></div><div><div class="lbl">Pending</div><div class="val"><?= number_format($counts[0]) ?></div></div></div></div>
    <div class="col-6 col-lg-3"><div class="card stat"><div class="stat-icon" style="background:#e3f8ee;color:#12875a"><i class="bi bi-check2-circle"></i></div><div><div class="lbl">Approved</div><div class="val"><?= number_format($counts[1]) ?></div></div></div></div>
    <div class="col-6 col-lg-3"><div class="card stat"><div class="stat-icon" style="background:#fdecec;color:#c0392b"><i class="bi bi-x-circle"></i></div><div><div class="lbl">Rejected</div><div class="val"><?= number_format($counts[2]) ?></div></div></div></div>
</div>

<div class="card">
    <div class="card-header d-flex flex-wrap justify-content-between align-items-center gap-2">
        <h2>Deposit Requests</h2>
        <div class="btn-group btn-group-sm">
            <a class="btn btn-light border <?= $status === '' ? 'active' : '' ?>" href="deposits.php">All</a>
            <a class="btn btn-light border <?= $status === 'pending' ? 'active' : '' ?>" href="deposits.php?status=pending">Pending</a>
            <a class="btn btn-light border <?= $status === 'approved' ? 'active' : '' ?>" href="deposits.php?status=approved">Approved</a>
            <a class="btn btn-light border <?= $status === 'rejected' ? 'active' : '' ?>" href="deposits.php?status=rejected">Rejected</a>
        </div>
    </div>
    <div class="table-responsive">
        <table class="table table-hover">
            <thead><tr><th>User</th><th>Deposit</th><th>UTR / Proof</th><th>Status</th><th>Date</th><th class="text-end">Action</th></tr></thead>
            <tbody>
            <?php foreach ($rows as $r): ?>
                <?php
                    $stInt = (int)$r['status'];
                    $coins = (float)$r['coins'];
                    if ($coins <= 0) $coins = (float)$r['amount'];
                    $inr = (float)$r['inr_amount'];
                ?>
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
                        <div class="fw-semibold text-nowrap"><?= number_format($coins, 2) ?> Dcoin</div>
                        <small class="text-muted"><?= $inr > 0 ? 'INR ' . number_format($inr, 2) : '-' ?></small>
                    </td>
                    <td>
                        <div class="small font-monospace"><?= e((string)$r['utr']) ?></div>
                        <?php if (!empty($r['screenshot'])): ?>
                            <a href="<?= e($r['screenshot']) ?>" target="_blank" rel="noopener">
                                <img src="<?= e($r['screenshot']) ?>" alt="Proof" style="width:56px;height:56px;object-fit:cover;border-radius:.5rem;border:1px solid var(--line)">
                            </a>
                        <?php else: ?><span class="text-muted small">No proof</span><?php endif; ?>
                    </td>
                    <td>
                        <span class="badge rounded-pill badge-soft-<?= $badge[$stInt] ?? 'secondary' ?> px-3 py-2"><?= $label[$stInt] ?? 'Unknown' ?></span>
                        <?php if ($stInt === 2 && !empty($r['reject_reason'])): ?>
                            <div class="small text-danger mt-1" style="max-width:180px"><?= e($r['reject_reason']) ?></div>
                        <?php endif; ?>
                        <?php if (!empty($r['credited'])): ?>
                            <div class="small text-success mt-1"><i class="bi bi-check2"></i> Coins added</div>
                        <?php endif; ?>
                    </td>
                    <td class="text-nowrap text-muted"><?= e(date('d M Y, h:i A', strtotime((string)$r['created_at']))) ?></td>
                    <td class="text-end text-nowrap">
                        <?php if ($stInt !== 1 && !(int)$r['credited']): ?>
                            <form method="post" class="d-inline">
                                <?= csrf_field() ?>
                                <input type="hidden" name="action" value="approve">
                                <input type="hidden" name="id" value="<?= (int)$r['id'] ?>">
                                <input type="hidden" name="return_status" value="<?= e($status) ?>">
                                <button class="btn btn-sm btn-success" title="Approve & add coins"><i class="bi bi-check-lg"></i></button>
                            </form>
                        <?php endif; ?>
                        <?php if ($stInt !== 0 && !(int)$r['credited']): ?>
                            <form method="post" class="d-inline">
                                <?= csrf_field() ?>
                                <input type="hidden" name="action" value="pending">
                                <input type="hidden" name="id" value="<?= (int)$r['id'] ?>">
                                <input type="hidden" name="return_status" value="<?= e($status) ?>">
                                <button class="btn btn-sm btn-outline-secondary" title="Mark pending"><i class="bi bi-hourglass"></i></button>
                            </form>
                        <?php endif; ?>
                        <?php if ($stInt !== 2 && !(int)$r['credited']): ?>
                            <button class="btn btn-sm btn-outline-danger btn-reject"
                                    data-id="<?= (int)$r['id'] ?>"
                                    data-name="<?= e((string)($r['user_name'] ?? '')) ?>"
                                    title="Reject"><i class="bi bi-x-lg"></i></button>
                        <?php endif; ?>
                        <form method="post" class="d-inline" onsubmit="return confirm('Deposit delete karna hai? User side se bhi hat jayega.')">
                            <?= csrf_field() ?>
                            <input type="hidden" name="action" value="delete">
                            <input type="hidden" name="id" value="<?= (int)$r['id'] ?>">
                            <input type="hidden" name="return_status" value="<?= e($status) ?>">
                            <button class="btn btn-sm btn-outline-dark" title="Delete"><i class="bi bi-trash"></i></button>
                        </form>
                    </td>
                </tr>
            <?php endforeach; ?>
            <?php if (!$rows): ?><tr><td colspan="6"><div class="empty"><i class="bi bi-inbox"></i>Koi deposit request nahi mili</div></td></tr><?php endif; ?>
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
                <div><h5 class="modal-title fw-bold">Reject Deposit</h5><small class="text-muted" id="r-name"></small></div>
                <button type="button" class="btn-close" data-bs-dismiss="modal"></button>
            </div>
            <div class="modal-body">
                <label class="form-label">Reason (user ko dikhega)</label>
                <textarea name="reason" class="form-control" rows="3" maxlength="255" placeholder="Payment verify nahi hua..." required></textarea>
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
require __DIR__ . '/includes/footer.php';
