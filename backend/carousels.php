<?php
require __DIR__ . '/config.php';

json_input();

try {
    $rows = db()
        ->query('SELECT id, title, image, more_info_url FROM carousels WHERE status = 1 ORDER BY sort_order ASC, id DESC')
        ->fetchAll();

    $items = [];
    foreach ($rows as $r) {
        $items[] = [
            'id'            => (int)$r['id'],
            'title'         => $r['title'],
            'image'         => $r['image'],
            'more_info_url' => (string)($r['more_info_url'] ?? ''),
        ];
    }

    respond(200, ['success' => true, 'carousels' => $items]);
} catch (PDOException $e) {
    respond(500, ['success' => false, 'message' => 'Server error']);
}
