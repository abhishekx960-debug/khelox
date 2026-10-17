<?php
require_once __DIR__ . '/config.php';
require_login();
$pdo = db();

if ($_SERVER['REQUEST_METHOD'] === 'POST') {
    csrf_check();
    $action = $_POST['action'] ?? '';

    if ($action === 'add') {
        $title = trim((string)($_POST['title'] ?? ''));
        $url   = trim((string)($_POST['more_info_url'] ?? ''));
        $errors = [];
        if (mb_strlen($title) < 2 || mb_strlen($title) > 150) $errors[] = 'Title 2-150 characters ka hona chahiye';
        if ($url !== '' && !filter_var($url, FILTER_VALIDATE_URL)) $errors[] = 'More info URL sahi nahi hai';
        if (empty($_FILES['image']['name'] ?? '')) $errors[] = 'Carousel image upload karo';

        if (!$errors) {
            try {
                $image = save_image($_FILES['image']);
                $pdo->prepare('INSERT INTO carousels (title, image, more_info_url) VALUES (?, ?, ?)')
                    ->execute([$title, $image, $url !== '' ? $url : null]);
                flash('success', 'Carousel add ho gaya');
            } catch (RuntimeException $ex) {
                $errors[] = $ex->getMessage();
            }
        }
        if ($errors) flash('danger', implode(' | ', $errors));
        header('Location: carousels.php');
        exit;
    }

    if ($action === 'toggle') {
        $id = (int)($_POST['id'] ?? 0);
        if ($id > 0) {
            $pdo->prepare('UPDATE carousels SET status = 1 - status WHERE id = ?')->execute([$id]);
            flash('success', 'Status update ho gaya');
        }
        header('Location: carousels.php');
        exit;
    }

    if ($action === 'delete') {
        $id = (int)($_POST['id'] ?? 0);
        $st = $pdo->prepare('SELECT image FROM carousels WHERE id = ? LIMIT 1');
        $st->execute([$id]);
        if ($row = $st->fetch()) {
            $pdo->prepare('DELETE FROM carousels WHERE id = ?')->execute([$id]);
            delete_upload($row['image']);
            flash('success', 'Carousel delete ho gaya');
        }
        header('Location: carousels.php');
        exit;
    }
}

$pageTitle = 'Manage Carousels';
$active = 'carousels';
require __DIR__ . '/includes/header.php';

$items = $pdo->query('SELECT id, title, image, more_info_url, status, created_at FROM carousels ORDER BY sort_order ASC, id DESC')->fetchAll();
?>
<div class="row g-3">
    <div class="col-lg-4">
        <div class="card">
            <div class="card-header"><h2>Add Carousel</h2></div>
            <div class="card-body">
                <form method="post" enctype="multipart/form-data" autocomplete="off">
                    <?= csrf_field() ?>
                    <input type="hidden" name="action" value="add">
                    <div class="mb-3">
                        <label class="form-label">Title</label>
                        <input type="text" name="title" class="form-control" maxlength="150" placeholder="Diwali Bonus" required>
                    </div>
                    <div class="mb-3">
                        <label class="form-label">Carousel Image</label>
                        <input type="file" name="image" class="form-control" accept="image/png,image/jpeg,image/webp,image/gif" required>
                        <div class="form-text">JPG, PNG, WEBP ya GIF, max 3MB.</div>
                    </div>
                    <div class="mb-3">
                        <label class="form-label">More Info URL</label>
                        <input type="url" name="more_info_url" class="form-control" placeholder="https://khelox.com/offer">
                        <div class="form-text">Optional. User "More info" par click kare to yahi URL khulega.</div>
                    </div>
                    <button class="btn btn-primary w-100"><i class="bi bi-plus-lg me-1"></i>Add Carousel</button>
                </form>
            </div>
        </div>
    </div>
    <div class="col-lg-8">
        <div class="card">
            <div class="card-header d-flex justify-content-between align-items-center">
                <h2>All Carousels <span class="text-muted fw-normal">(<?= count($items) ?>)</span></h2>
            </div>
            <div class="table-responsive">
                <table class="table table-hover">
                    <thead><tr><th>Carousel</th><th>More Info</th><th>Status</th><th class="text-end">Action</th></tr></thead>
                    <tbody>
                    <?php foreach ($items as $c): ?>
                        <tr>
                            <td>
                                <div class="d-flex align-items-center gap-3">
                                    <img src="<?= e($c['image']) ?>" alt="" style="width:96px;height:52px;object-fit:cover;border-radius:.6rem;border:1px solid var(--line)">
                                    <div class="min-w-0">
                                        <div class="fw-semibold text-truncate"><?= e($c['title']) ?></div>
                                        <small class="text-muted"><?= e(date('d M Y, h:i A', strtotime($c['created_at']))) ?></small>
                                    </div>
                                </div>
                            </td>
                            <td>
                                <?php if ($c['more_info_url']): ?>
                                    <a href="<?= e($c['more_info_url']) ?>" target="_blank" rel="noopener" class="text-truncate d-inline-block" style="max-width:220px"><?= e($c['more_info_url']) ?></a>
                                <?php else: ?><span class="text-muted">-</span><?php endif; ?>
                            </td>
                            <td><span class="badge rounded-pill badge-soft-<?= $c['status'] ? 'success' : 'secondary' ?> px-3 py-2"><?= $c['status'] ? 'Active' : 'Disabled' ?></span></td>
                            <td class="text-end text-nowrap">
                                <form method="post" class="d-inline">
                                    <?= csrf_field() ?>
                                    <input type="hidden" name="action" value="toggle">
                                    <input type="hidden" name="id" value="<?= (int)$c['id'] ?>">
                                    <button class="btn btn-sm btn-outline-<?= $c['status'] ? 'secondary' : 'success' ?>"><?= $c['status'] ? 'Disable' : 'Enable' ?></button>
                                </form>
                                <form method="post" class="d-inline" onsubmit="return confirm('Pakka delete karna hai?')">
                                    <?= csrf_field() ?>
                                    <input type="hidden" name="action" value="delete">
                                    <input type="hidden" name="id" value="<?= (int)$c['id'] ?>">
                                    <button class="btn btn-sm btn-outline-danger"><i class="bi bi-trash"></i></button>
                                </form>
                            </td>
                        </tr>
                    <?php endforeach; ?>
                    <?php if (!$items): ?><tr><td colspan="4"><div class="empty"><i class="bi bi-images"></i>Abhi koi carousel nahi</div></td></tr><?php endif; ?>
                    </tbody>
                </table>
            </div>
        </div>
    </div>
</div>
<?php require __DIR__ . '/includes/footer.php'; ?>
