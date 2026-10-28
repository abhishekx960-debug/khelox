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
            flash('danger', 'UPI ID is too long');
        } else {
            setting_set('deposit_upi_id', $upi);
            if (!empty($_FILES['deposit_qr']['name'] ?? '')) {
                try {
                    $old = setting('deposit_qr');
                    setting_set('deposit_qr', save_image($_FILES['deposit_qr']));
                    delete_upload($old);
                    flash('success', 'Deposit details saved');
                } catch (RuntimeException $ex) {
                    flash('danger', $ex->getMessage());
                }
            } else {
                flash('success', 'Deposit details saved');
            }
        }
        header('Location: settings.php');
        exit;
    }

    if ($action === 'remove_qr') {
        delete_upload(setting('deposit_qr'));
        setting_set('deposit_qr', '');
        flash('success', 'QR removed');
        header('Location: settings.php');
        exit;
    }

    if ($action === 'save_finance') {
        $values = [
            'dcoin_inr_rate'     => $_POST['dcoin_inr_rate'] ?? '',
            'dcoin_min_deposit'  => $_POST['dcoin_min_deposit'] ?? '',
            'dcoin_max_deposit'  => $_POST['dcoin_max_deposit'] ?? '',
            'fcoin_min_withdraw' => $_POST['fcoin_min_withdraw'] ?? '',
            'fcoin_max_withdraw' => $_POST['fcoin_max_withdraw'] ?? '',
            'wcoin_min_withdraw' => $_POST['wcoin_min_withdraw'] ?? '',
            'wcoin_max_withdraw' => $_POST['wcoin_max_withdraw'] ?? '',
        ];

        $clean = [];
        $errors = [];
        foreach ($values as $key => $raw) {
            $raw = trim((string)$raw);
            if ($raw === '' || !is_numeric($raw) || (float)$raw < 0 || (float)$raw > 9999999999) {
                $errors[] = ucwords(str_replace('_', ' ', $key)) . ' is invalid';
                continue;
            }
            $clean[$key] = (string)round((float)$raw, 2);
        }
        if (!isset($clean['dcoin_inr_rate']) || (float)$clean['dcoin_inr_rate'] <= 0) {
            $errors[] = '1 Dcoin rate must be greater than 0';
        }

        $fcoinCoinsRaw = trim((string)($_POST['fcoin_rate_coins'] ?? ''));
        $fcoinInrRaw   = trim((string)($_POST['fcoin_rate_inr'] ?? ''));
        $fcoinCoins = null;
        $fcoinInr = null;
        if ($fcoinCoinsRaw === '' || !is_numeric($fcoinCoinsRaw) || (float)$fcoinCoinsRaw <= 0 || (float)$fcoinCoinsRaw > 9999999999) {
            $errors[] = 'Fcoin amount in the conversion must be greater than 0';
        } else {
            $fcoinCoins = round((float)$fcoinCoinsRaw, 2);
        }
        if ($fcoinInrRaw === '' || !is_numeric($fcoinInrRaw) || (float)$fcoinInrRaw <= 0 || (float)$fcoinInrRaw > 9999999999) {
            $errors[] = 'INR amount in the Fcoin conversion must be greater than 0';
        } else {
            $fcoinInr = round((float)$fcoinInrRaw, 2);
        }
        if (isset($clean['dcoin_min_deposit'], $clean['dcoin_max_deposit'])
            && (float)$clean['dcoin_max_deposit'] < (float)$clean['dcoin_min_deposit']) {
            $errors[] = 'Maximum Dcoin deposit cannot be less than the minimum';
        }
        if (isset($clean['fcoin_min_withdraw'], $clean['fcoin_max_withdraw'])
            && (float)$clean['fcoin_max_withdraw'] < (float)$clean['fcoin_min_withdraw']) {
            $errors[] = 'Maximum Fcoin withdrawal cannot be less than the minimum';
        }
        if (isset($clean['wcoin_min_withdraw'], $clean['wcoin_max_withdraw'])
            && (float)$clean['wcoin_max_withdraw'] < (float)$clean['wcoin_min_withdraw']) {
            $errors[] = 'Maximum Wcoin withdrawal cannot be less than the minimum';
        }

        if ($errors) {
            flash('danger', implode(' | ', $errors));
        } else {
            foreach ($clean as $key => $value) setting_set($key, $value);
            setting_set('fcoin_rate_coins', (string)$fcoinCoins);
            setting_set('fcoin_rate_inr', (string)$fcoinInr);
            setting_set('fcoin_inr_rate', (string)round($fcoinInr / $fcoinCoins, 8));
            flash('success', 'Coin rates and limits saved');
        }
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
        if ($email !== '' && !filter_var($email, FILTER_VALIDATE_EMAIL)) $errors[] = 'Support email is invalid';
        if ($whatsapp !== '' && !preg_match('/^\+?\d{10,15}$/', preg_replace('/[\s-]/', '', $whatsapp))) $errors[] = 'WhatsApp number is invalid';
        if ($telegram !== '' && !preg_match('~^@?[A-Za-z0-9_]{4,32}$~', $telegram)) $errors[] = 'Telegram username is invalid';
        if (mb_strlen($note) > 500) $errors[] = 'Note must be within 500 characters';

        if ($errors) {
            flash('danger', implode(' | ', $errors));
        } else {
            setting_set('support_email', $email);
            setting_set('support_phone', $phone);
            setting_set('support_whatsapp', $whatsapp);
            setting_set('support_telegram', $telegram);
            setting_set('support_note', $note);
            flash('success', 'Support details saved');
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
                <p class="text-muted small">This QR code and UPI ID will be shown to users on the deposit screen.</p>
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
                        <div class="form-text">JPG, PNG or WEBP, max 3MB. Uploading a new file replaces the old one.</div>
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
                    <form method="post" class="mt-2" onsubmit="return confirm('Remove this QR code?')">
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
                        <textarea name="support_note" class="form-control" rows="3" maxlength="500" placeholder="Support available 10:00 AM - 8:00 PM"><?= e(setting('support_note')) ?></textarea>
                    </div>
                    <button class="btn btn-primary w-100"><i class="bi bi-check-lg me-1"></i>Save Support Details</button>
                </form>
            </div>
        </div>
    </div>
</div>
<div class="card mt-3">
    <div class="card-header"><h2><i class="bi bi-sliders me-2 text-primary"></i>Coin Rates &amp; Limits</h2></div>
    <div class="card-body">
        <p class="text-muted small">These values apply immediately to the deposit and withdraw screens in the app.</p>
        <form method="post" autocomplete="off">
            <?= csrf_field() ?>
            <input type="hidden" name="action" value="save_finance">
            <div class="row g-3">
                <div class="col-lg-6">
                    <div class="p-3 rounded border h-100">
                        <h3 class="h6 fw-bold mb-3"><i class="bi bi-diamond me-1 text-info"></i>Dcoin (Deposit)</h3>
                        <div class="mb-3">
                            <label class="form-label">1 Dcoin = ? INR</label>
                            <input type="number" step="0.01" min="0.01" name="dcoin_inr_rate" class="form-control" value="<?= e(setting('dcoin_inr_rate', '1')) ?>" required>
                        </div>
                        <div class="row g-3">
                            <div class="col-sm-6">
                                <label class="form-label">Minimum Dcoin Deposit</label>
                                <input type="number" step="0.01" min="0" name="dcoin_min_deposit" class="form-control" value="<?= e(setting('dcoin_min_deposit', '10')) ?>" required>
                            </div>
                            <div class="col-sm-6">
                                <label class="form-label">Maximum Dcoin Deposit</label>
                                <input type="number" step="0.01" min="0" name="dcoin_max_deposit" class="form-control" value="<?= e(setting('dcoin_max_deposit', '100000')) ?>" required>
                            </div>
                        </div>
                    </div>
                </div>
                <div class="col-lg-6">
                    <div class="p-3 rounded border h-100">
                        <h3 class="h6 fw-bold mb-3"><i class="bi bi-coin me-1 text-warning"></i>Fcoin (Withdraw)</h3>
                        <?php
                        $fcoinRateCoins = setting('fcoin_rate_coins');
                        $fcoinRateInr = setting('fcoin_rate_inr');
                        if ($fcoinRateCoins === '' || (float)$fcoinRateCoins <= 0) {
                            $fcoinRateCoins = '1';
                        }
                        if ($fcoinRateInr === '' || (float)$fcoinRateInr <= 0) {
                            $fcoinRateInr = setting('fcoin_inr_rate', '0.50');
                        }
                        ?>
                        <div class="mb-3">
                            <label class="form-label">Fcoin = INR conversion</label>
                            <div class="d-flex align-items-center gap-2 flex-wrap">
                                <input type="number" step="0.01" min="0.01" name="fcoin_rate_coins" id="fcoinRateCoins" class="form-control" style="max-width:140px" value="<?= e($fcoinRateCoins) ?>" required>
                                <span class="fw-semibold text-nowrap">Fcoin =</span>
                                <input type="number" step="0.01" min="0.01" name="fcoin_rate_inr" id="fcoinRateInr" class="form-control" style="max-width:140px" value="<?= e($fcoinRateInr) ?>" required>
                                <span class="fw-semibold">INR</span>
                            </div>
                            <div class="form-text" id="fcoinRatePreview">Set any formula, e.g. 100 Fcoin = 50 INR or 1 Fcoin = 0.50 INR.</div>
                        </div>
                        <div class="row g-3">
                            <div class="col-sm-6">
                                <label class="form-label">Minimum Fcoin Withdraw</label>
                                <input type="number" step="0.01" min="0" name="fcoin_min_withdraw" class="form-control" value="<?= e(setting('fcoin_min_withdraw', '100')) ?>" required>
                            </div>
                            <div class="col-sm-6">
                                <label class="form-label">Maximum Fcoin Withdraw</label>
                                <input type="number" step="0.01" min="0" name="fcoin_max_withdraw" class="form-control" value="<?= e(setting('fcoin_max_withdraw', '100000')) ?>" required>
                            </div>
                        </div>
                    </div>
                </div>
                <div class="col-lg-6">
                    <div class="p-3 rounded border h-100">
                        <h3 class="h6 fw-bold mb-3"><i class="bi bi-wallet2 me-1 text-success"></i>Wcoin (Withdraw)</h3>
                        <div class="row g-3">
                            <div class="col-sm-6">
                                <label class="form-label">Minimum Wcoin Withdraw</label>
                                <input type="number" step="0.01" min="0" name="wcoin_min_withdraw" class="form-control" value="<?= e(setting('wcoin_min_withdraw', '100')) ?>" required>
                            </div>
                            <div class="col-sm-6">
                                <label class="form-label">Maximum Wcoin Withdraw</label>
                                <input type="number" step="0.01" min="0" name="wcoin_max_withdraw" class="form-control" value="<?= e(setting('wcoin_max_withdraw', '100000')) ?>" required>
                            </div>
                        </div>
                    </div>
                </div>
            </div>
            <button class="btn btn-primary mt-3"><i class="bi bi-check-lg me-1"></i>Save Coin Settings</button>
        </form>
    </div>
</div>
<script>
(function () {
    const coins = document.getElementById('fcoinRateCoins');
    const inr = document.getElementById('fcoinRateInr');
    const preview = document.getElementById('fcoinRatePreview');
    if (!coins || !inr || !preview) return;
    function updatePreview() {
        const c = parseFloat(coins.value);
        const r = parseFloat(inr.value);
        if (!c || !r || c <= 0 || r <= 0) {
            preview.textContent = 'Set any formula, e.g. 100 Fcoin = 50 INR or 1 Fcoin = 0.50 INR.';
            return;
        }
        const per = r / c;
        preview.textContent = c + ' Fcoin = ' + r + ' INR  (1 Fcoin = ' + per.toFixed(8).replace(/0+$/, '').replace(/\.$/, '') + ' INR)';
    }
    coins.addEventListener('input', updatePreview);
    inr.addEventListener('input', updatePreview);
    updatePreview();
})();
</script>
<?php require __DIR__ . '/includes/footer.php'; ?>
