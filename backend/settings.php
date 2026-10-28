<?php
require __DIR__ . '/config.php';

json_input();

try {
    $fcoinInrRate = (float)setting('fcoin_inr_rate', '0.50');
    $fcoinRateCoins = (float)setting('fcoin_rate_coins', '0');
    $fcoinRateInr = (float)setting('fcoin_rate_inr', '0');
    if ($fcoinRateCoins <= 0) $fcoinRateCoins = 1;
    if ($fcoinRateInr <= 0) $fcoinRateInr = $fcoinInrRate > 0 ? $fcoinInrRate : 0.50;

    respond(200, [
        'success' => true,
        'settings' => [
            'dcoin_inr_rate'       => (float)setting('dcoin_inr_rate', '1'),
            'dcoin_min_deposit'    => (float)setting('dcoin_min_deposit', '10'),
            'dcoin_max_deposit'    => (float)setting('dcoin_max_deposit', '100000'),
            'fcoin_inr_rate'       => $fcoinInrRate,
            'fcoin_rate_coins'     => $fcoinRateCoins,
            'fcoin_rate_inr'       => $fcoinRateInr,
            'fcoin_min_withdraw'   => (float)setting('fcoin_min_withdraw', '100'),
            'fcoin_max_withdraw'   => (float)setting('fcoin_max_withdraw', '100000'),
            'wcoin_min_withdraw'   => (float)setting('wcoin_min_withdraw', '100'),
            'wcoin_max_withdraw'   => (float)setting('wcoin_max_withdraw', '100000'),
            'deposit_upi_id'       => setting('deposit_upi_id'),
            'deposit_qr'           => setting('deposit_qr'),
        ],
    ]);
} catch (PDOException $e) {
    respond(500, ['success' => false, 'message' => 'Server error']);
}
