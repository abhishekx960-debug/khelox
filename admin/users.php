<?php
require_once __DIR__ . '/config.php';
require_login();
$pdo = db();

if ($_SERVER['REQUEST_METHOD'] === 'POST' && ($_POST['action'] ?? '') === 'coins') {
    csrf_check();
    $id = (int)($_POST['id'] ?? 0);
    $vals = [];
    foreach (['fcoin', 'dcoin', 'wcoin'] as $c) {
        $v = $_POST[$c] ?? '';
        if (!is_numeric($v) || $v < 0 || $v > 9999999999) { $vals = null; break; }
        $vals[] = round((float)$v, 2);
    }
    if ($id > 0 && $vals) {
        $pdo->prepare('UPDATE users SET fcoin=?, dcoin=?, wcoin=? WHERE id=?')->execute([...$vals, $id]);
        flash('success', 'Coins update ho gaye');
    } else {
        flash('danger', 'Invalid coin value');
    }
    header('Location: users.php?' . http_build_query(['q' => $_GET['q'] ?? '', 'page' => $_GET['page'] ?? 1]));
    exit;
}

$pageTitle = 'Users';
$active = 'users';
require __DIR__ . '/includes/header.php';

$q = trim((string)($_GET['q'] ?? ''));
$page = max(1, (int)($_GET['page'] ?? 1));
$per = 20;
$where = ''; $params = [];
if ($q !== '') {
    $where = 'WHERE name LIKE ? OR email LIKE ? OR phone LIKE ?';
    $like = '%' . $q . '%';
    $params = [$like, $like, $like];
}
$cnt = $pdo->prepare("SELECT COUNT(*) FROM users $where");
$cnt->execute($params);
$total = (int)$cnt->fetchColumn();
$pages = max(1, (int)ceil($total / $per));
$page = min($page, $pages);
$off = ($page - 1) * $per;

$st = $pdo->prepare("SELECT id, name, email, phone, fcoin, dcoin, wcoin, created_at FROM users $where ORDER BY id DESC LIMIT $per OFFSET $off");
$st->execute($params);
$users = $st->fetchAll();
?>
<div class="card">
    <div class="card-header">
        <div class="row g-2 align-items-center">
            <div class="col-md"><h2>All Users <span class="text-muted fw-normal">(<?= number_format($total) ?>)</span></h2></div>
            <div class="col-md-5 col-lg-4">
                <form method="get" class="input-group">
                    <span class="input-group-text"><i class="bi bi-search"></i></span>
                    <input type="text" name="q" class="form-control" placeholder="Name, email ya phone" value="<?= e($q) ?>">
                    <?php if ($q !== ''): ?><a href="users.php" class="btn btn-light border" title="Reset"><i class="bi bi-x-lg"></i></a><?php endif; ?>
                </form>
            </div>
        </div>
    </div>
    <div class="table-responsive">
        <table class="table table-hover">
            <thead><tr><th>User</th><th>Phone</th><th>Coins</th><th>Joined</th><th class="text-end">Action</th></tr></thead>
            <tbody>
            <?php foreach ($users as $u): ?>
                <tr>
                    <td>
                        <div class="d-flex align-items-center gap-2">
                            <span class="avatar"><?= e(initials($u['name'])) ?></span>
                            <div>
                                <div class="fw-semibold"><?= e($u['name']) ?> <small class="text-muted fw-normal">#<?= (int)$u['id'] ?></small></div>
                                <small class="text-muted"><?= e($u['email']) ?></small>
                            </div>
                        </div>
                    </td>
                    <td><?= e($u['phone']) ?></td>
                    <td>
                        <div class="d-flex flex-wrap gap-1">
                            <span class="chip chip-f">F <?= number_format((float)$u['fcoin'], 2) ?></span>
                            <span class="chip chip-d">D <?= number_format((float)$u['dcoin'], 2) ?></span>
                            <span class="chip chip-w">W <?= number_format((float)$u['wcoin'], 2) ?></span>
                        </div>
                    </td>
                    <td class="text-nowrap text-muted"><?= e(date('d M Y', strtotime($u['created_at']))) ?></td>
                    <td class="text-end">
                        <button class="btn btn-sm btn-outline-primary btn-edit"
                                data-id="<?= (int)$u['id'] ?>" data-name="<?= e($u['name']) ?>"
                                data-f="<?= e($u['fcoin']) ?>" data-d="<?= e($u['dcoin']) ?>" data-w="<?= e($u['wcoin']) ?>">
                            <i class="bi bi-pencil-square me-1"></i>Coins
                        </button>
                    </td>
                </tr>
            <?php endforeach; ?>
            <?php if (!$users): ?><tr><td colspan="5"><div class="empty"><i class="bi bi-search"></i>Koi user nahi mila</div></td></tr><?php endif; ?>
            </tbody>
        </table>
    </div>
    <?php if ($pages > 1): ?>
    <div class="card-footer bg-white d-flex justify-content-between align-items-center" style="border-radius:0 0 1rem 1rem">
        <small class="text-muted">Page <?= $page ?> of <?= $pages ?></small>
        <ul class="pagination pagination-sm mb-0">
            <li class="page-item <?= $page <= 1 ? 'disabled' : '' ?>"><a class="page-link" href="?<?= e(http_build_query(['q' => $q, 'page' => $page - 1])) ?>">&laquo;</a></li>
            <?php for ($i = max(1, $page - 2); $i <= min($pages, $page + 2); $i++): ?>
                <li class="page-item <?= $i === $page ? 'active' : '' ?>"><a class="page-link" href="?<?= e(http_build_query(['q' => $q, 'page' => $i])) ?>"><?= $i ?></a></li>
            <?php endfor; ?>
            <li class="page-item <?= $page >= $pages ? 'disabled' : '' ?>"><a class="page-link" href="?<?= e(http_build_query(['q' => $q, 'page' => $page + 1])) ?>">&raquo;</a></li>
        </ul>
    </div>
    <?php endif; ?>
</div>

<div class="modal fade" id="coinModal" tabindex="-1">
    <div class="modal-dialog modal-dialog-centered">
        <form method="post" class="modal-content border-0 shadow" style="border-radius:1rem">
            <?= csrf_field() ?>
            <input type="hidden" name="action" value="coins">
            <input type="hidden" name="id" id="m-id">
            <div class="modal-header border-0 pb-0">
                <div><h5 class="modal-title fw-bold">Edit Coins</h5><small class="text-muted" id="m-name"></small></div>
                <button type="button" class="btn-close" data-bs-dismiss="modal"></button>
            </div>
            <div class="modal-body">
                <div class="mb-3"><label class="form-label">FCoin</label><input type="number" step="0.01" min="0" name="fcoin" id="m-f" class="form-control" required></div>
                <div class="mb-3"><label class="form-label">DCoin</label><input type="number" step="0.01" min="0" name="dcoin" id="m-d" class="form-control" required></div>
                <div><label class="form-label">WCoin</label><input type="number" step="0.01" min="0" name="wcoin" id="m-w" class="form-control" required></div>
            </div>
            <div class="modal-footer border-0 pt-0">
                <button type="button" class="btn btn-light" data-bs-dismiss="modal">Cancel</button>
                <button class="btn btn-primary px-4">Save</button>
            </div>
        </form>
    </div>
</div>
<?php
$extraJs = '<script>
document.addEventListener("DOMContentLoaded",function(){
  var modal;
  document.querySelectorAll(".btn-edit").forEach(function(b){
    b.addEventListener("click",function(){
      document.getElementById("m-id").value=b.dataset.id;
      document.getElementById("m-name").textContent=b.dataset.name;
      document.getElementById("m-f").value=b.dataset.f;
      document.getElementById("m-d").value=b.dataset.d;
      document.getElementById("m-w").value=b.dataset.w;
      modal=modal||new bootstrap.Modal(document.getElementById("coinModal"));
      modal.show();
    });
  });
});
</script>';
require __DIR__ . '/includes/footer.php';