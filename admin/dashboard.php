<?php
$pageTitle = 'Dashboard';
$active = 'dashboard';
require __DIR__ . '/includes/header.php';

$pdo = db();
$s = $pdo->query("SELECT COUNT(*) total,
                         COALESCE(SUM(fcoin),0) f, COALESCE(SUM(dcoin),0) d, COALESCE(SUM(wcoin),0) w,
                         COALESCE(SUM(DATE(created_at)=CURDATE()),0) today
                  FROM users")->fetch();
$recent = $pdo->query('SELECT id, name, email, phone, created_at FROM users ORDER BY id DESC LIMIT 8')->fetchAll();

// last 7 days signups
$rows = $pdo->query("SELECT DATE(created_at) d, COUNT(*) c FROM users
                     WHERE created_at >= CURDATE() - INTERVAL 6 DAY GROUP BY DATE(created_at)")->fetchAll();
$map = array_column($rows, 'c', 'd');
$labels = []; $data = [];
for ($i = 6; $i >= 0; $i--) {
    $d = date('Y-m-d', strtotime("-$i day"));
    $labels[] = date('d M', strtotime($d));
    $data[]   = (int)($map[$d] ?? 0);
}

$cards = [
    ['Total Users', number_format((int)$s['total']), 'bi-people-fill',  'ic-indigo'],
    ['New Today',   number_format((int)$s['today']), 'bi-person-plus-fill', 'ic-green'],
    ['Total FCoin', number_format((float)$s['f'], 2), 'bi-coin',        'ic-amber'],
    ['Total DCoin', number_format((float)$s['d'], 2), 'bi-cash-stack',  'ic-blue'],
    ['Total WCoin', number_format((float)$s['w'], 2), 'bi-wallet2',     'ic-rose'],
];
?>
<div class="mb-4">
    <h2 class="h4 fw-bold mb-1">Hello, <?= e(explode(' ', $_SESSION['admin_name'])[0]) ?> 👋</h2>
    <div class="text-muted">Aaj ka overview ye raha.</div>
</div>

<div class="row g-3 mb-4">
    <?php foreach ($cards as [$label, $val, $icon, $cls]): ?>
    <div class="col-6 col-md-4 col-xl">
        <div class="card h-100"><div class="stat">
            <div class="stat-icon <?= $cls ?>"><i class="bi <?= $icon ?>"></i></div>
            <div class="min-w-0"><div class="lbl"><?= $label ?></div><div class="val text-truncate"><?= $val ?></div></div>
        </div></div>
    </div>
    <?php endforeach; ?>
</div>

<div class="row g-3 mb-4">
    <div class="col-lg-8">
        <div class="card h-100">
            <div class="card-header d-flex justify-content-between align-items-center">
                <h2>New Signups</h2><span class="text-muted small">Last 7 days</span>
            </div>
            <div class="card-body"><div style="height:260px"><canvas id="signups"></canvas></div></div>
        </div>
    </div>
    <div class="col-lg-4">
        <div class="card h-100">
            <div class="card-header"><h2>Coin Summary</h2></div>
            <div class="card-body d-flex flex-column justify-content-center gap-3">
                <?php foreach ([['FCoin', $s['f'], 'chip-f'], ['DCoin', $s['d'], 'chip-d'], ['WCoin', $s['w'], 'chip-w']] as [$n, $v, $c]): ?>
                <div class="d-flex justify-content-between align-items-center">
                    <span class="chip <?= $c ?>"><i class="bi bi-coin"></i><?= $n ?></span>
                    <span class="fw-bold"><?= number_format((float)$v, 2) ?></span>
                </div>
                <?php endforeach; ?>
            </div>
        </div>
    </div>
</div>

<div class="card">
    <div class="card-header d-flex justify-content-between align-items-center">
        <h2>Recent Users</h2>
        <a href="users.php" class="btn btn-sm btn-outline-primary">View all</a>
    </div>
    <div class="table-responsive">
        <table class="table table-hover">
            <thead><tr><th>User</th><th>Phone</th><th>Joined</th></tr></thead>
            <tbody>
            <?php foreach ($recent as $u): ?>
                <tr>
                    <td>
                        <div class="d-flex align-items-center gap-2">
                            <span class="avatar avatar-sm"><?= e(initials($u['name'])) ?></span>
                            <div><div class="fw-semibold"><?= e($u['name']) ?></div><small class="text-muted"><?= e($u['email']) ?></small></div>
                        </div>
                    </td>
                    <td><?= e($u['phone']) ?></td>
                    <td class="text-nowrap text-muted"><?= e(date('d M Y, h:i A', strtotime($u['created_at']))) ?></td>
                </tr>
            <?php endforeach; ?>
            <?php if (!$recent): ?><tr><td colspan="3"><div class="empty"><i class="bi bi-inbox"></i>No users yet</div></td></tr><?php endif; ?>
            </tbody>
        </table>
    </div>
</div>
<?php
$extraJs = '<script src="https://cdn.jsdelivr.net/npm/chart.js@4.4.3/dist/chart.umd.min.js"></script>
<script>
new Chart(document.getElementById("signups"),{
  type:"bar",
  data:{labels:' . json_encode($labels) . ',datasets:[{data:' . json_encode($data) . ',backgroundColor:"rgba(91,91,214,.85)",borderRadius:8,maxBarThickness:42}]},
  options:{maintainAspectRatio:false,plugins:{legend:{display:false}},
    scales:{y:{beginAtZero:true,ticks:{precision:0},grid:{color:"#eef0f6"}},x:{grid:{display:false}}}}
});
</script>';
require __DIR__ . '/includes/footer.php';