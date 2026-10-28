<?php
require_once __DIR__ . '/config.php';
require_login();
$pdo = db();
games_ensure_schema();

$game = (string)($_GET['game'] ?? 'br');
if (!isset(GAME_MODES[$game])) $game = 'br';
$gameName = GAME_MODES[$game];
$self = 'game_tournaments.php?game=' . $game;

const T_STATUSES = ['upcoming' => 'Upcoming', 'ongoing' => 'Ongoing', 'results' => 'Results'];

if ($_SERVER['REQUEST_METHOD'] === 'POST') {
    csrf_check();
    $action = $_POST['action'] ?? '';

    if ($action === 'create') {
        $title = trim((string)($_POST['title'] ?? ''));
        $prize = $_POST['prize_pool'] ?? '';
        $fee   = $_POST['entry_fee'] ?? '';
        $slots = $_POST['slots'] ?? '';
        $when  = trim((string)($_POST['start_at'] ?? ''));
        $ruleId = (int)($_POST['rule_id'] ?? 0);
        $desc  = trim((string)($_POST['description'] ?? ''));

        $errors = [];
        if (mb_strlen($title) < 2 || mb_strlen($title) > 150) $errors[] = 'Title must be 2-150 characters';
        if (!is_numeric($prize) || $prize < 0) $errors[] = 'Prizepool is invalid';
        if (!is_numeric($fee) || $fee < 0) $errors[] = 'Entry fees is invalid';
        if (!ctype_digit((string)$slots) || (int)$slots < 1) $errors[] = 'Slots must be 1 or more';
        $ts = $when !== '' ? strtotime($when) : false;
        if ($ts === false) $errors[] = 'Date & Time is invalid';
        if ($ruleId > 0) {
            $st = $pdo->prepare('SELECT id FROM game_rules WHERE id = ?');
            $st->execute([$ruleId]);
            if (!$st->fetch()) $errors[] = 'Selected rule not found';
        }
        if (mb_strlen($desc) > 5000) $errors[] = 'Description is too long';

        if (!$errors) {
            $pdo->prepare('INSERT INTO tournaments (game, title, prize_pool, entry_fee, slots, start_at, rule_id, description)
                           VALUES (?, ?, ?, ?, ?, ?, ?, ?)')
                ->execute([$game, $title, $prize, $fee, (int)$slots, date('Y-m-d H:i:s', $ts),
                           $ruleId > 0 ? $ruleId : null, $desc !== '' ? $desc : null]);
            flash('success', 'Tournament created');
        } else {
            flash('danger', implode(' | ', $errors));
        }
        header('Location: ' . $self);
        exit;
    }

    if ($action === 'status') {
        $id = (int)($_POST['id'] ?? 0);
        $status = (string)($_POST['status'] ?? '');
        if ($id > 0 && isset(T_STATUSES[$status])) {
            $pdo->prepare('UPDATE tournaments SET status = ? WHERE id = ? AND game = ?')->execute([$status, $id, $game]);
            flash('success', 'Status updated');
        }
        header('Location: ' . $self);
        exit;
    }

    if ($action === 'delete') {
        $id = (int)($_POST['id'] ?? 0);
        if ($id > 0) {
            $pdo->prepare('DELETE FROM tournaments WHERE id = ? AND game = ?')->execute([$id, $game]);
            flash('success', 'Tournament deleted');
        }
        header('Location: ' . $self);
        exit;
    }
}

$pageTitle = $gameName;
$active = 'games_' . $game;
require __DIR__ . '/includes/header.php';

$rules = $pdo->query('SELECT id, points FROM game_rules ORDER BY id ASC')->fetchAll();
$st = $pdo->prepare('SELECT t.*, r.id AS rid FROM tournaments t LEFT JOIN game_rules r ON r.id = t.rule_id
                     WHERE t.game = ? ORDER BY t.start_at DESC, t.id DESC');
$st->execute([$game]);
$items = $st->fetchAll();
$badge = ['upcoming' => 'warning', 'ongoing' => 'success', 'results' => 'secondary'];
?>
<div class="d-flex justify-content-between align-items-center mb-3">
    <div>
        <h2 class="h5 mb-0"><?= e($gameName) ?> Tournaments <span class="text-muted fw-normal">(<?= count($items) ?>)</span></h2>
    </div>
    <button class="btn btn-primary" data-bs-toggle="modal" data-bs-target="#createModal">
        <i class="bi bi-plus-lg me-1"></i>Create Tournaments
    </button>
</div>

<div class="card">
    <div class="table-responsive">
        <table class="table table-hover align-middle">
            <thead>
                <tr><th>Tournament</th><th>Prizepool</th><th>Entry Fees</th><th>Slots</th><th>Date &amp; Time</th><th>Rule</th><th>Status</th><th class="text-end">Action</th></tr>
            </thead>
            <tbody>
            <?php foreach ($items as $t): ?>
                <tr>
                    <td>
                        <div class="fw-semibold"><?= e($t['title']) ?></div>
                        <?php if ($t['description']): ?><small class="text-muted d-inline-block text-truncate" style="max-width:240px"><?= e($t['description']) ?></small><?php endif; ?>
                    </td>
                    <td>₹<?= e(rtrim(rtrim(number_format((float)$t['prize_pool'], 2, '.', ''), '0'), '.')) ?></td>
                    <td><?= (float)$t['entry_fee'] > 0 ? '₹' . e(rtrim(rtrim(number_format((float)$t['entry_fee'], 2, '.', ''), '0'), '.')) : 'Free' ?></td>
                    <td><?= (int)$t['slots'] ?></td>
                    <td class="text-nowrap"><?= e(date('d M Y, h:i A', strtotime($t['start_at']))) ?></td>
                    <td><?= $t['rid'] ? '<span class="badge rounded-pill badge-soft-primary px-3 py-2">Rule #' . (int)$t['rid'] . '</span>' : '<span class="text-muted">-</span>' ?></td>
                    <td><span class="badge rounded-pill badge-soft-<?= $badge[$t['status']] ?? 'secondary' ?> px-3 py-2"><?= e(T_STATUSES[$t['status']] ?? $t['status']) ?></span></td>
                    <td class="text-end text-nowrap">
                        <form method="post" class="d-inline-flex gap-1">
                            <?= csrf_field() ?>
                            <input type="hidden" name="action" value="status">
                            <input type="hidden" name="id" value="<?= (int)$t['id'] ?>">
                            <select name="status" class="form-select form-select-sm" onchange="this.form.submit()" style="width:auto">
                                <?php foreach (T_STATUSES as $k => $label): ?>
                                    <option value="<?= $k ?>" <?= $t['status'] === $k ? 'selected' : '' ?>><?= $label ?></option>
                                <?php endforeach; ?>
                            </select>
                        </form>
                        <form method="post" class="d-inline" onsubmit="return confirm('Delete this tournament?')">
                            <?= csrf_field() ?>
                            <input type="hidden" name="action" value="delete">
                            <input type="hidden" name="id" value="<?= (int)$t['id'] ?>">
                            <button class="btn btn-sm btn-outline-danger"><i class="bi bi-trash"></i></button>
                        </form>
                    </td>
                </tr>
            <?php endforeach; ?>
            <?php if (!$items): ?>
                <tr><td colspan="8"><div class="empty"><i class="bi bi-trophy"></i>No tournaments yet</div></td></tr>
            <?php endif; ?>
            </tbody>
        </table>
    </div>
</div>

<div class="modal fade" id="createModal" tabindex="-1" aria-hidden="true">
    <div class="modal-dialog modal-dialog-centered modal-lg modal-dialog-scrollable">
        <form method="post" class="modal-content" autocomplete="off">
            <?= csrf_field() ?>
            <input type="hidden" name="action" value="create">
            <div class="modal-header">
                <h5 class="modal-title">Create Tournament &middot; <?= e($gameName) ?></h5>
                <button type="button" class="btn-close" data-bs-dismiss="modal"></button>
            </div>
            <div class="modal-body">
                <div class="row g-3">
                    <div class="col-12">
                        <label class="form-label">Title</label>
                        <input type="text" name="title" class="form-control" maxlength="150" placeholder="Sunday Showdown" required>
                    </div>
                    <div class="col-md-4">
                        <label class="form-label">Prizepool (₹)</label>
                        <input type="number" name="prize_pool" class="form-control" min="0" step="0.01" placeholder="5000" required>
                    </div>
                    <div class="col-md-4">
                        <label class="form-label">Entry Fees (₹)</label>
                        <input type="number" name="entry_fee" class="form-control" min="0" step="0.01" placeholder="50" required>
                    </div>
                    <div class="col-md-4">
                        <label class="form-label">Slots</label>
                        <input type="number" name="slots" class="form-control" min="1" step="1" placeholder="48" required>
                    </div>
                    <div class="col-md-6">
                        <label class="form-label">Date &amp; Time</label>
                        <input type="datetime-local" name="start_at" class="form-control" required>
                    </div>
                    <div class="col-md-6">
                        <label class="form-label">Select Rules</label>
                        <select name="rule_id" class="form-select">
                            <option value="0">No rules</option>
                            <?php foreach ($rules as $r):
                                $pts = json_decode((string)$r['points'], true);
                                $cnt = is_array($pts) ? count($pts) : 0; ?>
                                <option value="<?= (int)$r['id'] ?>">Rule #<?= (int)$r['id'] ?> (<?= $cnt ?> points)</option>
                            <?php endforeach; ?>
                        </select>
                        <?php if (!$rules): ?>
                            <div class="form-text">Koi rule nahi hai. Pehle <a href="game_rules.php">Rules</a> page par rule banao.</div>
                        <?php endif; ?>
                    </div>
                    <div class="col-12">
                        <label class="form-label">Description</label>
                        <textarea name="description" class="form-control" rows="4" maxlength="5000" placeholder="Tournament ke baare me likho..."></textarea>
                    </div>
                </div>
            </div>
            <div class="modal-footer">
                <button type="button" class="btn btn-light" data-bs-dismiss="modal">Cancel</button>
                <button class="btn btn-primary"><i class="bi bi-check-lg me-1"></i>Create Tournament</button>
            </div>
        </form>
    </div>
</div>
<?php require __DIR__ . '/includes/footer.php'; ?>
