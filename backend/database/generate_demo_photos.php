<?php
$dir = __DIR__ . '/../public/uploads/photos';
if (!is_dir($dir)) {
    mkdir($dir, 0777, true);
}
$files = [
    'demo_ac_leak.jpg' => [200, 50, 50, 'AC Bocor GKB 3.02'],
    'demo_water_tap.jpg' => [40, 100, 200, 'Kran Air Patah Toilet GKB'],
    'demo_projector_bad.jpg' => [180, 150, 40, 'Proyektor Kuning GKB 3.01'],
    'demo_projector_good.jpg' => [40, 180, 80, 'Proyektor Selesai Diperbaiki'],
    'demo_chair_broken.jpg' => [150, 80, 40, 'Kursi Sandaran Patah FT.201'],
    'demo_chair_fixed.jpg' => [40, 160, 60, 'Kursi Diperbaiki Kokoh'],
    'demo_after_projector.jpg' => [40, 180, 80, 'Kabel HDMI Diganti Baru'],
    'demo_after_chair.jpg' => [40, 160, 60, 'Papan Sandaran Kayu Baru']
];

foreach ($files as $name => $spec) {
    $im = imagecreatetruecolor(600, 400);
    $bg = imagecolorallocate($im, $spec[0], $spec[1], $spec[2]);
    $txt = imagecolorallocate($im, 255, 255, 255);
    imagefill($im, 0, 0, $bg);
    imagestring($im, 5, 50, 180, $spec[3], $txt);
    imagestring($im, 3, 50, 210, "Bukti Dokumentasi Sarpras Untidar - Tuguran", $txt);
    imagejpeg($im, $dir . '/' . $name, 85);
    imagedestroy($im);
}

// Add an .htaccess in uploads directory to prevent script execution
file_put_contents(__DIR__ . '/../public/uploads/.htaccess', "php_flag engine off\n<FilesMatch \"\.(php|php5|phtml|phar)$\">\nOrder Deny,Allow\nDeny from all\n</FilesMatch>\n");

echo "Demo photos and upload security .htaccess created successfully.\n";
