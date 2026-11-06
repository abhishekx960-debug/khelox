<?php
require_once __DIR__ . '/../config.php';
require_login();
$pageTitle = $pageTitle ?? 'Admin';
$active    = $active ?? '';
$nav = [
    'Overview' => [
        'dashboard' => ['dashboard.php', 'bi-grid-1x2-fill', 'Dashboard'],
        'users'     => ['users.php',     'bi-people-fill',   'Users'],
    ],
    'Games' => [
        'games_br'        => ['game_tournaments.php?game=br',        'bi-fire',         'Free Fire BR'],
        'games_cs'        => ['game_tournaments.php?game=cs',        'bi-shield-fill',  'Free Fire CS'],
        'games_community' => ['game_tournaments.php?game=community', 'bi-people',       'Community'],
        'games_rules'     => ['game_rules.php',                      'bi-list-check',   'Rules'],
    ],
    'Content' => [
        'carousels'     => ['carousels.php',     'bi-images', 'Carousels'],
        'notifications' => ['notifications.php', 'bi-bell',   'Notifications'],
    ],
    'Finance' => [
        'fcoin_withdraws' => ['fcoin_withdraws.php', 'bi-coin',       'FCoin Withdraws'],
        'deposits'        => ['deposits.php',        'bi-cash-stack', 'Deposits'],
        'wcoin_withdraws' => ['wcoin_withdraws.php', 'bi-wallet2',    'WCoin Withdraws'],
    ],
    'System' => [
        'admins'   => ['admins.php',   'bi-shield-lock-fill', 'Admins'],
        'settings' => ['settings.php', 'bi-gear',             'Settings'],
    ],
];
function sidebar_html(array $nav, string $active): string {
    ob_start(); ?>
    <div class="sidebar-inner">
        <a href="dashboard.php" class="brand">
            <span class="brand-logo"><?= logo_img(26) ?></span>
            <span class="brand-text"><b>Khelox</b><small>Admin Panel</small></span>
        </a>
        <nav class="sidebar-nav" aria-label="Admin">
            <?php foreach ($nav as $group => $items): ?>
                <div class="nav-label"><?= e($group) ?></div>
                <ul class="side-nav">
                    <?php foreach ($items as $key => [$href, $icon, $label]): ?>
                        <li>
                            <a href="<?= $href ?>" class="<?= $active === $key ? 'active' : '' ?>">
                                <i class="bi <?= $icon ?>"></i><?= e($label) ?>
                            </a>
                        </li>
                    <?php endforeach; ?>
                </ul>
            <?php endforeach; ?>
        </nav>
        <div class="side-user">
            <span class="avatar"><?= e(initials($_SESSION['admin_name'] ?? '?')) ?></span>
            <div class="flex-grow-1 text-truncate">
                <div class="text-truncate fw-semibold"><?= e($_SESSION['admin_name'] ?? '') ?></div>
                <small>@<?= e($_SESSION['admin_username'] ?? '') ?></small>
            </div>
            <a href="logout.php" class="text-white-50" title="Logout" aria-label="Logout"><i class="bi bi-box-arrow-right fs-5"></i></a>
        </div>
    </div>
    <?php return ob_get_clean();
}
$flash = flash_get();
?>
<!doctype html>
<html lang="en">
<head>
    <meta charset="utf-8">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <meta name="robots" content="noindex,nofollow">
    <title><?= e($pageTitle) ?> | Khelox Admin</title>
    <link rel="icon" href="<?= LOGO_URL ?>">
    <link rel="preconnect" href="https://fonts.googleapis.com">
    <link href="https://fonts.googleapis.com/css2?family=Inter:wght@400;500;600;700;800&display=swap" rel="stylesheet">
    <link href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.3/dist/css/bootstrap.min.css" rel="stylesheet">
    <link href="https://cdn.jsdelivr.net/npm/bootstrap-icons@1.11.3/font/bootstrap-icons.min.css" rel="stylesheet">
    <link href="assets/css/admin.css?v=3" rel="stylesheet">
</head>
<body>
<div class="page-progress" id="pageProgress" aria-hidden="true"><div class="bar"></div></div>
<aside class="sidebar d-none d-lg-flex"><?= sidebar_html($nav, $active) ?></aside>
<div class="offcanvas offcanvas-start d-lg-none" tabindex="-1" id="mobileNav"><?= sidebar_html($nav, $active) ?></div>

<div class="main">
    <header class="topbar">
        <div class="d-flex align-items-center gap-2">
            <button class="btn btn-light d-lg-none" data-bs-toggle="offcanvas" data-bs-target="#mobileNav" aria-label="Open menu"><i class="bi bi-list fs-5"></i></button>
            <h1><?= e($pageTitle) ?></h1>
        </div>
        <div class="d-flex align-items-center gap-3">
            <span class="text-muted small d-none d-md-inline"><i class="bi bi-calendar3 me-1"></i><?= date('D, d M Y') ?></span>
            <div class="dropdown">
                <a href="#" class="d-flex align-items-center text-decoration-none" data-bs-toggle="dropdown" aria-label="Account menu">
                    <span class="avatar avatar-sm"><?= e(initials($_SESSION['admin_name'] ?? '?')) ?></span>
                </a>
                <ul class="dropdown-menu dropdown-menu-end">
                    <li class="px-3 py-2"><div class="fw-semibold"><?= e($_SESSION['admin_name'] ?? '') ?></div><small class="text-muted">@<?= e($_SESSION['admin_username'] ?? '') ?></small></li>
                    <li><hr class="dropdown-divider"></li>
                    <li><a class="dropdown-item" href="settings.php"><i class="bi bi-gear me-2"></i>Settings</a></li>
                    <li><a class="dropdown-item text-danger" href="logout.php"><i class="bi bi-box-arrow-right me-2"></i>Logout</a></li>
                </ul>
            </div>
        </div>
    </header>
    <main class="content">
        <?php if ($flash): ?>
            <div class="d-none" data-flash-type="<?= e($flash[0]) ?>" data-flash-msg="<?= e($flash[1]) ?>"></div>
        <?php endif; ?>
