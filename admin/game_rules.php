<?php
require_once __DIR__ . '/config.php';
require_login();
$pdo = db();
games_ensure_schema();

if ($_SERVER['REQUEST_METHOD'] === 'POST') {
    csrf_check();
    $action = $_POST['action'] ?? '';

    if ($action === 'create') {
        $raw = $_POST['points'] ?? [];
        $points = [];
        if (is_array($raw)) {
            foreach ($raw as $p) {
                $p = trim((string)$p);
                if ($p !== '') $points[] = mb_substr($p, 0, 500);
            }
        }
        if (!$points) {
            flash('danger', 'Kam se kam ek point likho');
        } elseif (count($points) > 100) {
            flash('danger', 'Max 100 points allowed');
        } else {
            $pdo->prepare('INSERT INTO game_rules (points) VALUES (?)')
                ->execute([json_encode($points, JSON_UNESCAPED_UNICODE)]);
            flash('success', 'Rule #' . $pdo->lastInsertId() . ' created');
        }
        header('Location: game_rules.php');
        exit;
    }

    if ($action === 'delete') {
        $id = (int)($_POST['id'] ?? 0);
        if ($id > 0) {
            // Tournaments using this rule simply lose the rule link.
            $pdo->prepare('UPDATE tournaments SET rule_id = NULL WHERE rule_id = ?')->execute([$id]);
            $pdo->prepare('DELETE FROM game_rules WHERE id = ?')->execute([$id]);
            flash('success', 'Rule deleted');
        }
        header('Location: game_rules.php');
        exit;
    }
}

$pageTitle = 'Rules';
$active = 'games_rules';
require __DIR__ . '/includes/header.php';

$rules = $pdo->query('SELECT r.id, r.points, r.created_at,
                             (SELECT COUNT(*) FROM tournaments t WHERE t.rule_id = r.id) AS used
                      FROM game_rules r ORDER BY r.id DESC')->fetchAll();
?>
<div class="d-flex justify-content-between align-items-center mb-3">
    <h2 class="h5 mb-0">Rules <span class="text-muted fw-normal">(<?= count($rules) ?>)</span></h2>
    <button class="btn btn-primary" data-bs-toggle="modal" data-bs-target="#ruleModal">
        <i class="bi bi-plus-lg me-1"></i>Create Rules
    </button>
</div>

<div class="row g-3">
<?php foreach ($rules as $r):
    $pts = json_decode((string)$r['points'], true);
    if (!is_array($pts)) $pts = []; ?>
    <div class="col-md-6 col-xl-4">
        <div class="card h-100">
            <div class="card-header d-flex justify-content-between align-items-center">
                <h2 class="mb-0">Rule #<?= (int)$r['id'] ?></h2>
                <div class="d-flex align-items-center gap-2">
                    <span class="badge rounded-pill badge-soft-secondary px-3 py-2">Used in <?= (int)$r['used'] ?></span>
                    <form method="post" onsubmit="return confirm('Delete Rule #<?= (int)$r['id'] ?>?')">
                        <?= csrf_field() ?>
                        <input type="hidden" name="action" value="delete">
                        <input type="hidden" name="id" value="<?= (int)$r['id'] ?>">
                        <button class="btn btn-sm btn-outline-danger"><i class="bi bi-trash"></i></button>
                    </form>
                </div>
            </div>
            <div class="card-body">
                <?php foreach ($pts as $i => $p): ?>
                    <div class="mb-2"><b>Point <?= $i + 1 ?> -</b> <?= e($p) ?></div>
                <?php endforeach; ?>
            </div>
        </div>
    </div>
<?php endforeach; ?>
<?php if (!$rules): ?>
    <div class="col-12"><div class="card"><div class="empty"><i class="bi bi-list-check"></i>No rules yet. "Create Rules" par click karo.</div></div></div>
<?php endif; ?>
</div>

<div class="modal fade" id="ruleModal" tabindex="-1" aria-hidden="true">
    <div class="modal-dialog modal-dialog-centered modal-lg modal-dialog-scrollable">
        <form method="post" class="modal-content" autocomplete="off">
            <?= csrf_field() ?>
            <input type="hidden" name="action" value="create">
            <div class="modal-header">
                <h5 class="modal-title">Create Rule</h5>
                <button type="button" class="btn-close" data-bs-dismiss="modal"></button>
            </div>
            <div class="modal-body">
                <div id="pointRows" class="d-grid gap-2"></div>
                <button type="button" id="addPoint" class="btn btn-outline-primary btn-sm mt-3"><i class="bi bi-plus-lg me-1"></i>Add Point</button>
                <div class="form-text mt-2">Har point alag likho. Save karne par ye poora ek Rule (#number) ban jayega.</div>
            </div>
            <div class="modal-footer">
                <button type="button" class="btn btn-light" data-bs-dismiss="modal">Cancel</button>
                <button class="btn btn-primary"><i class="bi bi-check-lg me-1"></i>Save Rule</button>
            </div>
        </form>
    </div>
</div>
<?php
$extraJs = <<<'JS'
<script>
(function () {
    var wrap = document.getElementById('pointRows');
    function renumber() {
        wrap.querySelectorAll('.rule-point-row').forEach(function (row, i) {
            row.querySelector('.input-group-text').textContent = 'Point ' + (i + 1) + ' -';
        });
    }
    function addRow(focus) {
        var row = document.createElement('div');
        row.className = 'input-group rule-point-row';
        row.innerHTML = '<span class="input-group-text"></span>' +
            '<input type="text" name="points[]" class="form-control" maxlength="500" placeholder="Rule likho...">' +
            '<button type="button" class="btn btn-outline-danger" title="Remove"><i class="bi bi-x-lg"></i></button>';
        row.querySelector('button').addEventListener('click', function () {
            if (wrap.children.length > 1) { row.remove(); renumber(); }
            else row.querySelector('input').value = '';
        });
        wrap.appendChild(row);
        renumber();
        if (focus) row.querySelector('input').focus();
    }
    document.getElementById('addPoint').addEventListener('click', function () { addRow(true); });
    addRow(false);
    addRow(false);
})();
</script>
JS;
require __DIR__ . '/includes/footer.php';
?>
