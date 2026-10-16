<?php
require __DIR__ . '/config.php';
header('Location: ' . (is_logged_in() ? 'dashboard.php' : 'login.php'));
exit;
