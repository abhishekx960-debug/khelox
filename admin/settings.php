<?php
require_once __DIR__ . '/config.php';
require_login();
$pdo = db();

if ($_SERVER['REQUEST_METHOD'] === 'POST') {
    csrf_check();
    $action = $_POST['action'] ?? '';

    if ($action === 'save_deposit') {
        $upi = trim((string)($_POST['deposit_upi_id'] ?? ''));
        if (mb_strlen($upi) > 120) {
            flash('danger', 'UPI ID bahut lamba hai');
        } else {
            setting_set('deposit_upi_id', $upi);
            if (!empty($_FILES['deposit_qr']['name'] ?? '')) {
                try {
                    $old = setting('deposit_qr');
                    setting_set('deposit_qr', save_image($_FILES['deposit_qr']));
                    delete_upload($old);
                    flash('success', 'Deposit details save ho gayi');
                } catch (RuntimeException $ex) {
                    flash('danger', $ex->getMessage());
                }
            } else {
                flash('success', 'Deposit details save ho gayi');
            }
        }
        header('Location: settings.php');
        exit;
    }

    if ($action === 'remove_qr') {
        delete_upload(setting('deposit_qr'));
        setting_set('deposit_qr', '');
        flash('success', 'QR remove ho gaya');
        header('Location: settings.php');
        exit;
    }

    if ($action === 'save_support') {
        $email    = trim((string)($_POST['support_email'] ?? ''));
        $phone    = trim((string)($_POST['support_phone'] ?? ''));
        $whatsapp = trim((string)($_POST['support_whatsapp'] ?? ''));
        $telegram = trim((string)($_POST['support_telegram'] ?? ''));
        $note     = trim((string)($_POST['support_note'] ?? ''));

        $errors = [];
        if ($email !== '' && !filter_var($email, FILTER_VALIDATE_EMAIL)) $errors[] = 'Support email sahi nahi hai';
        if ($whatsapp !== '' && !preg_match('/^\+?\d{10,15}$/', preg_replace('/[\s-]/', '', $whatsapp))) $errors[] = 'WhatsApp number sahi nahi hai';
        if ($telegram !== '' && !preg_match('~^@?[A-Za-z0-9_]{4,32}$~', $telegram)) $errors[] = 'Telegram username sahi nahi hai';
        if (mb_strlen($note) > 500) $errors[] = 'Note 500 characters se chota rakho';

        if ($errors) {
            flash('danger', implode(' | ', $errors));
        } else {
            setting_set('support_email', $email);
            setting_set('support_phone', $phone);
            setting_set('support_whatsapp', $whatsapp);
            setting_set('support_telegram', $telegram);
            setting_set('support_note', $note);
            flash('success', 'Support details save ho gayi');
        }
        header('Location: settings.php');
        exit;
    }
}

$pageTitle = 'Settings';
$active = 'settings';
require __DIR__ . '/includes/header.php';

$qr = setting('deposit_qr');
?>
<div class="row g-3">
    <div class="col-lg-6">
        <div class="card h-100">
            <div class="card-header"><h2><i class="bi bi-qr-code-scan me-2 text-primary"></i>Deposit Details</h2></div>
            <div class="card-body">
                <p class="text-muted small">Jab user coin deposit karega to yahi QR aur UPI ID dikhega.</p>
                <form method="post" enctype="multipart/form-data" autocomplete="off">
                    <?= csrf_field() ?>
                    <input type="hidden" name="action" value="save_deposit">
                    <div class="mb-3">
                        <label class="form-label">UPI ID</label>
                        <div class="input-group">
                            <span class="input-group-text"><i class="bi bi-upc-scan"></i></span>
                            <input type="text" name="deposit_upi_id" class="form-control" maxlength="120" value="<?= e(setting('deposit_upi_id')) ?>" placeholder="khelox@upi">
                        </div>
                    </div>
                    <div class="mb-3">
                        <label class="form-label">Payment QR Code</label>
                        <input type="file" name="deposit_qr" class="form-control" accept="image/png,image/jpeg,image/webp">
                        <div class="form-text">JPG, PNG ya WEBP, max 3MB. Naya upload karne par purana replace ho jayega.</div>
                    </div>
                    <?php if ($qr): ?>
                        <div class="mb-3 d-flex align-items-center gap-3">
                            <img src="<?= e($qr) ?>" alt="QR" style="width:120px;height:120px;object-fit:contain;border:1px solid var(--line);border-radius:.75rem;background:#fff">
                            <span class="text-muted small">Current QR</span>
                        </div>
                    <?php endif; ?>
                    <button class="btn btn-primary w-100"><i class="bi bi-check-lg me-1"></i>Save Deposit Details</button>
                </form>
                <?php if ($qr): ?>
                    <form method="post" class="mt-2" onsubmit="return confirm('QR remove karna hai?')">
                        <?= csrf_field() ?>
                        <input type="hidden" name="action" value="remove_qr">
                        <button class="btn btn-outline-danger w-100"><i class="bi bi-trash me-1"></i>Remove QR</button>
                    </form>
                <?php endif; ?>
            </div>
        </div>
    </div>
    <div class="col-lg-6">
        <div class="card h-100">
            <div class="card-header"><h2><i class="bi bi-headset me-2 text-primary"></i>Customer Support Details</h2></div>
            <div class="card-body">
                <form method="post" autocomplete="off">
                    <?= csrf_field() ?>
                    <input type="hidden" name="action" value="save_support">
                    <div class="mb-3">
                        <label class="form-label">Support Email</label>
                        <div class="input-group">
                            <span class="input-group-text"><i class="bi bi-envelope"></i></span>
                            <input type="email" name="support_email" class="form-control" value="<?= e(setting('support_email')) ?>" placeholder="support@khelox.com">
                        </div>
                    </div>
                    <div class="row g-3 mb-3">
                        <div class="col-sm-6">
                            <label class="form-label">Support Phone</label>
                            <div class="input-group">
                                <span class="input-group-text"><i class="bi bi-telephone"></i></span>
                                <input type="text" name="support_phone" class="form-control" value="<?= e(setting('support_phone')) ?>" placeholder="+91 90000 00000">
                            </div>
                        </div>
                        <div class="col-sm-6">
                            <label class="form-label">WhatsApp</label>
                            <div class="input-group">
                                <span class="input-group-text"><i class="bi bi-whatsapp"></i></span>
                                <input type="text" name="support_whatsapp" class="form-control" value="<?= e(setting('support_whatsapp')) ?>" placeholder="+91 90000 00000">
                            </div>
                        </div>
                    </div>
                    <div class="mb-3">
                        <label class="form-label">Telegram</label>
                        <div class="input-group">
                            <span class="input-group-text"><i class="bi bi-telegram"></i></span>
                            <input type="text" name="support_telegram" class="form-control" value="<?= e(setting('support_telegram')) ?>" placeholder="@kheloxsupport">
                        </div>
                    </div>
                    <div class="mb-3">
                        <label class="form-label">Support Note</label>
                        <textarea name="support_note" class="form-control" rows="3" maxlength="500" placeholder="Support 10:00 AM - 8:00 PM available hai"><?= e(setting('support_note')) ?></textarea>
                    </div>
                    <button class="btn btn-primary w-100"><i class="bi bi-check-lg me-1"></i>Save Support Details</button>
                </form>
            </div>
        </div>
    </div>
</div>
<?php require __DIR__ . '/includes/footer.php'; ?>
