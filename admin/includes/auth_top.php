<?php
$flash = flash_get();
?>
<!doctype html>
<html lang="en">
<head>
    <meta charset="utf-8">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <meta name="robots" content="noindex,nofollow">
    <title><?= e($authTitle) ?> | Khelox Admin</title>
    <link rel="icon" href="<?= LOGO_URL ?>">
    <link rel="preconnect" href="https://fonts.googleapis.com">
    <link href="https://fonts.googleapis.com/css2?family=Inter:wght@400;500;600;700;800&display=swap" rel="stylesheet">
    <link href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.3/dist/css/bootstrap.min.css" rel="stylesheet">
    <link href="https://cdn.jsdelivr.net/npm/bootstrap-icons@1.11.3/font/bootstrap-icons.min.css" rel="stylesheet">
    <link href="assets/css/admin.css?v=3" rel="stylesheet">
</head>
<body>
<div class="page-progress" id="pageProgress" aria-hidden="true"><div class="bar"></div></div>
<div class="auth">
    <section class="auth-brand">
        <div class="d-flex align-items-center gap-3">
            <span class="brand-logo" style="min-width:56px;min-height:56px"><?= logo_img(36) ?></span>
            <div class="brand-text"><b class="fs-5">Khelox</b><small>Admin Panel</small></div>
        </div>
        <div>
            <h2>Operate the platform with a clear, secure console.</h2>
            <p>Users, coins, tournaments and settings — managed from one professional dashboard.</p>
            <ul>
                <li><i class="bi bi-people"></i> User directory and coin controls</li>
                <li><i class="bi bi-trophy"></i> Tournaments, rules and payouts</li>
                <li><i class="bi bi-shield-check"></i> Role-based admin access</li>
            </ul>
        </div>
        <small class="text-white-50">&copy; <?= date('Y') ?> Khelox. All rights reserved.</small>
    </section>
    <section class="auth-form">
        <div class="auth-box">
            <div class="auth-logo-m"><?= logo_img(34) ?> <span>Khelox Admin</span></div>
            <h1 class="mb-1"><?= e($authTitle) ?></h1>
            <p class="text-muted mb-4"><?= e($authSub ?? '') ?></p>
            <?php if ($flash): ?>
                <div class="d-none" data-flash-type="<?= e($flash[0]) ?>" data-flash-msg="<?= e($flash[1]) ?>"></div>
            <?php endif; ?>
