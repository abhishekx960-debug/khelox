<?php
require __DIR__ . '/config.php';

json_input();

try {
    $rows = db()
        ->query("SELECT setting_key, setting_value FROM settings
                 WHERE setting_key IN ('support_email', 'support_phone', 'support_whatsapp', 'support_telegram', 'support_note')")
        ->fetchAll();

    $settings = [];
    foreach ($rows as $r) {
        $settings[$r['setting_key']] = (string)($r['setting_value'] ?? '');
    }

    respond(200, [
        'success' => true,
        'support' => [
            'email'    => $settings['support_email'] ?? '',
            'phone'    => $settings['support_phone'] ?? '',
            'whatsapp' => $settings['support_whatsapp'] ?? '',
            'telegram' => $settings['support_telegram'] ?? '',
            'note'     => $settings['support_note'] ?? '',
        ],
    ]);
} catch (PDOException $e) {
    respond(500, ['success' => false, 'message' => 'Server error']);
}
