<?php
// vars: $authTitle, $authSub
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
    <link href="https://fonts.googleapis.com/css2?family=Inter:wght@400;500;600;700&display=swap" rel="stylesheet">
    <link href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.3/dist/css/bootstrap.min.css" rel="stylesheet">
    <link href="https://cdn.jsdelivr.net/npm/bootstrap-icons@1.11.3/font/bootstrap-icons.min.css" rel="stylesheet">
    <link href="assets/css/admin.css?v=2" rel="stylesheet">
</head>
<body>
<div class="auth">
    <section class="auth-brand">
        <div class="d-flex align-items-center gap-3">
            <span class="brand-logo" style="min-width:56px;min-height:56px"><?= logo_img(36) ?></span>
            <div class="brand-text"><b class="fs-5">Khelox</b><small>Admin Panel</small></div>
        </div>
        <div>
            <h2>Apna gaming platform, ek jagah se manage karo.</h2>
            <p>Users, coins aur admins ko secure dashboard se control karo.</p>
            <ul>
                <li><i class="bi bi-people"></i> Users ki poori list aur search</li>
                <li><i class="bi bi-coin"></i> FCoin / DCoin / WCoin management</li>
                <li><i class="bi bi-shield-check"></i> Secure admin access</li>
            </ul>
        </div>
        <small class="text-white-50">&copy; <?= date('Y') ?> Khelox. All rights reserved.</small>
    </section>
    <section class="auth-form">
        <div class="auth-box">
            <div class="auth-logo-m"><?= logo_img(34) ?> <span>Khelox Admin</span></div>
            <h1 class="mb-1"><?= e($authTitle) ?></h1>
            <p class="text-muted mb-4"><?= e($authSub ?? '') ?></p>
            <?php if ($flash): ?><div class="alert alert-<?= e($flash[0]) ?> py-2"><?= e($flash[1]) ?></div><?php endif; ?>