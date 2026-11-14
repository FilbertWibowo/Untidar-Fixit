<?php
$all = [];
for ($p = 1; $p <= 4; $p++) {
    $url = "https://data.untidar.ac.id/Aset/FrontDaftarRuangKuliah?page=" . $p;
    $ctx = stream_context_create([
        "ssl" => ["verify_peer" => false, "verify_peer_name" => false],
        "http" => ["header" => "User-Agent: Mozilla/5.0\r\n"]
    ]);
    $html = @file_get_contents($url, false, $ctx);
    if ($html) {
        preg_match_all("/<tr>\s*<td>(\d+)<\/td>\s*<td>(.*?)<\/td>\s*<td>(.*?)<\/td>\s*<td>(.*?)<\/td>\s*<td>(.*?)<\/td>\s*<td>(.*?)<\/td>\s*<\/tr>/is", $html, $matches, PREG_SET_ORDER);
        foreach ($matches as $m) {
            $all[] = [
                "no" => trim($m[1]),
                "gedung" => trim($m[2]),
                "lantai" => trim($m[3]),
                "ruang" => trim($m[4]),
                "kapasitas" => trim($m[5]),
                "luas" => trim($m[6])
            ];
        }
    }
}
echo "Total rooms fetched: " . count($all) . PHP_EOL;
file_put_contents(__DIR__ . "/backend/database/untidar_rooms.json", json_encode($all, JSON_PRETTY_PRINT | JSON_UNESCAPED_UNICODE));

$gedungs = [];
foreach ($all as $item) {
    $gedungs[$item["gedung"]][] = $item;
}
echo "Daftar Gedung dari data.untidar.ac.id:\n";
foreach ($gedungs as $g => $items) {
    echo "- $g: " . count($items) . " ruangan\n";
}
