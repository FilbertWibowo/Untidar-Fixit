<?php
require_once __DIR__ . '/../config/config.php';

spl_autoload_register(function ($class) {
    $prefix = 'App\\';
    $baseDir = __DIR__ . '/../src/';
    $len = strlen($prefix);
    if (strncmp($prefix, $class, $len) !== 0) return;
    $file = $baseDir . str_replace('\\', '/', substr($class, $len)) . '.php';
    if (file_exists($file)) require $file;
});

App\Config\Config::load(__DIR__ . '/../.env');

$pdo = App\Core\Database::getConnection();

// Seed initial before photos for demo reports if not exists
$photos = [
    ['report_id' => 1, 'file_path' => 'uploads/photos/demo_ac_leak.jpg', 'type' => 'before'],
    ['report_id' => 2, 'file_path' => 'uploads/photos/demo_chair_broken.jpg', 'type' => 'before'],
    ['report_id' => 3, 'file_path' => 'uploads/photos/demo_projector_bad.jpg', 'type' => 'before'],
    ['report_id' => 4, 'file_path' => 'uploads/photos/demo_water_tap.jpg', 'type' => 'before'],
    ['report_id' => 5, 'file_path' => 'uploads/photos/demo_chair_broken.jpg', 'type' => 'before'],
    ['report_id' => 6, 'file_path' => 'uploads/photos/demo_ac_leak.jpg', 'type' => 'before'],
];

foreach ($photos as $p) {
    $check = $pdo->prepare("SELECT id FROM report_photos WHERE report_id = ? AND type = ?");
    $check->execute([$p['report_id'], $p['type']]);
    if (!$check->fetch()) {
        $ins = $pdo->prepare("INSERT INTO report_photos (report_id, file_path, type, uploaded_at) VALUES (?, ?, ?, NOW())");
        $ins->execute([$p['report_id'], $p['file_path'], $p['type']]);
        echo "Inserted {$p['type']} photo for report #{$p['report_id']}\n";
    }
}

// Also check after photos for completed reports
$stmt = $pdo->query("SELECT id, status FROM reports WHERE status = 'selesai'");
$done = $stmt->fetchAll(PDO::FETCH_ASSOC);
foreach ($done as $r) {
    $check = $pdo->prepare("SELECT id FROM report_photos WHERE report_id = ? AND type = 'after'");
    $check->execute([$r['id']]);
    if (!$check->fetch()) {
        $ins = $pdo->prepare("INSERT INTO report_photos (report_id, file_path, type, uploaded_at) VALUES (?, 'uploads/photos/demo_after_chair.jpg', 'after', NOW())");
        $ins->execute([$r['id']]);
        echo "Inserted after photo for completed report #{$r['id']}\n";
    }
}

echo "Demo photos seeded successfully!\n";
