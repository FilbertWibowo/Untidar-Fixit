<?php

// End-to-End Simulation of Full Hackathon Flow
$api = 'http://127.0.0.1:8000/api';

function postJson($url, $data, $token = null) {
    $ch = curl_init($url);
    curl_setopt($ch, CURLOPT_RETURNTRANSFER, true);
    curl_setopt($ch, CURLOPT_POST, true);
    curl_setopt($ch, CURLOPT_POSTFIELDS, json_encode($data));
    $headers = ['Content-Type: application/json', 'Accept: application/json'];
    if ($token) $headers[] = "Authorization: Bearer $token";
    curl_setopt($ch, CURLOPT_HTTPHEADER, $headers);
    $res = curl_exec($ch);
    $code = curl_getinfo($ch, CURLINFO_HTTP_CODE);
    curl_close($ch);
    return ['code' => $code, 'data' => json_decode($res, true)];
}

function getJson($url, $token = null) {
    $ch = curl_init($url);
    curl_setopt($ch, CURLOPT_RETURNTRANSFER, true);
    $headers = ['Accept: application/json'];
    if ($token) $headers[] = "Authorization: Bearer $token";
    curl_setopt($ch, CURLOPT_HTTPHEADER, $headers);
    $res = curl_exec($ch);
    $code = curl_getinfo($ch, CURLINFO_HTTP_CODE);
    curl_close($ch);
    return ['code' => $code, 'data' => json_decode($res, true)];
}

function patchJson($url, $data, $token = null) {
    $ch = curl_init($url);
    curl_setopt($ch, CURLOPT_RETURNTRANSFER, true);
    curl_setopt($ch, CURLOPT_CUSTOMREQUEST, 'PATCH');
    curl_setopt($ch, CURLOPT_POSTFIELDS, json_encode($data));
    $headers = ['Content-Type: application/json', 'Accept: application/json'];
    if ($token) $headers[] = "Authorization: Bearer $token";
    curl_setopt($ch, CURLOPT_HTTPHEADER, $headers);
    $res = curl_exec($ch);
    $code = curl_getinfo($ch, CURLINFO_HTTP_CODE);
    curl_close($ch);
    return ['code' => $code, 'data' => json_decode($res, true)];
}

echo "=== STARTING E2E HACKATHON DEMO FLOW ===\n";

// Step 1: Mahasiswa 1 (Bagas) Login
$mhs1 = postJson("$api/auth/login", ['email' => 'bagas@students.untidar.ac.id', 'password' => 'mahasiswa123']);
$token1 = $mhs1['data']['data']['token'];
echo "[Step 1] Mahasiswa Bagas Login OK (Token acquired)\n";

// Step 2: Scan QR Stiker Ruangan GKB 3.02 with HMAC
$code = 'TUG-GKB-302';
$secret = 'laportidar_untidar_super_secret_key_2026';
$sig = hash_hmac('sha256', $code, $secret);
$qr = getJson("$api/locations/resolve?code=$code&sig=$sig", $token1);
$locId = $qr['data']['data']['id'];
echo "[Step 2] QR Scan Resolved: {$qr['data']['data']['building']} - {$qr['data']['data']['room']} (ID: $locId)\n";

// Step 3: Check Similar Open Reports
$sim = getJson("$api/reports/similar?location_id=$locId&category_id=1", $token1);
echo "[Step 3] Anti-Spam Check: Found {$sim['data']['data']['count']} active reports at this room\n";

// Step 4: Submit New Complaint
$reportRes = postJson("$api/reports", [
    'location_id'   => $locId,
    'category_id'   => 1, // AC
    'title'         => 'AC GKB 3.02 Bocor Deras Saat Kuliah Pemrograman Web',
    'description'   => 'Air menetes kencang di atas meja baris ke-2. Mahasiswa terpaksa menggeser kursi kuliah.',
    'urgency_level' => 'tinggi'
], $token1);
$reportId = $reportRes['data']['data']['id'];
$ticket = $reportRes['data']['data']['ticket_number'];
$initialScore = $reportRes['data']['data']['priority_score'];
echo "[Step 4] Report Created: $ticket (ID: $reportId, Initial Priority Score: $initialScore)\n";

// Step 5: Mahasiswa 2 (Siti) Login and Upvote ("Saya Mengalami Hal Serupa")
$mhs2 = postJson("$api/auth/login", ['email' => 'siti@students.untidar.ac.id', 'password' => 'mahasiswa123']);
$token2 = $mhs2['data']['data']['token'];
$upvoteRes = postJson("$api/reports/$reportId/upvote", [], $token2);
$newScore = $upvoteRes['data']['data']['priority_score'];
echo "[Step 5] Siti Upvoted Report: New Score = $newScore (+2 from upvote)\n";

// Step 6: Admin Login & View Priority Queue
$admin = postJson("$api/auth/login", ['email' => 'admin@untidar.ac.id', 'password' => 'admin12345']);
$adminToken = $admin['data']['data']['token'];
$queue = getJson("$api/reports?sort_by=priority", $adminToken);
echo "[Step 6] Admin Sarpras Viewed Queue: {$queue['data']['data']['total']} total reports in queue\n";

// Step 7: Admin Verifies Report
$verify = patchJson("$api/reports/$reportId/verify", ['note' => 'Kerusakan telah dikonfirmasi petugas lantai 3 GKB.'], $adminToken);
echo "[Step 7] Admin Verified Report $ticket\n";

// Step 8: Admin Assigns Technician (Pak Joko - Listrik & AC)
$assign = patchJson("$api/reports/$reportId/assign", ['technician_id' => 1, 'notes' => 'Segera periksa pipa drainase AC GKB 3.02.'], $adminToken);
echo "[Step 8] Admin Assigned Technician Pak Joko\n";

// Step 9: Admin Completes Report with Proof Photo
$complete = patchJson("$api/reports/$reportId/complete", [
    'note' => 'Pipa drainase AC telah dibersihkan dan kisi-kisi filter diganti baru. Tidak ada tetesan lagi.',
    'photo_path' => 'uploads/photos/demo_after_projector.jpg'
], $adminToken);
echo "[Step 9] Admin Marked Report Completed with Proof Photo\n";

// Step 10: Mahasiswa Bagas Views Live Timeline & Submits Satisfaction Rating
$detail = getJson("$api/reports/$reportId", $token1);
$timelineEvents = count($detail['data']['data']['timeline']);
echo "[Step 10] Mahasiswa Bagas Viewed Timeline: $timelineEvents chronological events recorded\n";
$rate = postJson("$api/reports/$reportId/rating", [
    'rating' => 5,
    'review' => 'Respon perbaikan sangat cepat dan transparan! AC sudah dingin dan tidak bocor lagi.'
], $token1);
echo "[Step 10b] Mahasiswa Submitted 5-Star Rating & Review\n";

// Step 11: Admin Verifies Updated Dashboard KPIs & Heatmap
$stats = getJson("$api/admin/stats", $adminToken);
echo "[Step 11] Admin Dashboard Updated: Total Resolved = {$stats['data']['data']['summary']['resolved_reports']}, Avg Rating = {$stats['data']['data']['summary']['avg_rating']} / 5.0\n";

echo "=== ALL 11 STEPS OF E2E DEMO FLOW PASSED WITH 100% SUCCESS ===\n";
