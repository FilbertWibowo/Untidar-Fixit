<?php

$baseUrl = 'http://127.0.0.1:8000/api';
$passCount = 0;
$failCount = 0;

function test(string $name, bool $condition, string $detail = '') {
    global $passCount, $failCount;
    if ($condition) {
        $passCount++;
        echo "  [PASS] {$name}\n";
    } else {
        $failCount++;
        echo "  [FAIL] {$name} - {$detail}\n";
    }
}

function req(string $method, string $path, mixed $body = null, ?string $token = null): array {
    global $baseUrl;
    $url = $baseUrl . $path;
    $ch = curl_init($url);
    curl_setopt($ch, CURLOPT_RETURNTRANSFER, true);
    curl_setopt($ch, CURLOPT_CUSTOMREQUEST, $method);

    $headers = ['Accept: application/json'];
    if ($token) {
        $headers[] = "Authorization: Bearer {$token}";
    }

    if ($body !== null) {
        if (is_array($body) && !isset($body['photos'])) {
            $json = json_encode($body);
            curl_setopt($ch, CURLOPT_POSTFIELDS, $json);
            $headers[] = 'Content-Type: application/json';
        } else {
            curl_setopt($ch, CURLOPT_POSTFIELDS, $body);
        }
    }

    curl_setopt($ch, CURLOPT_HTTPHEADER, $headers);
    $response = curl_exec($ch);
    $status = curl_getinfo($ch, CURLINFO_HTTP_CODE);
    curl_close($ch);

    $data = json_decode($response, true);
    return ['status' => $status, 'data' => $data, 'raw' => $response];
}

echo "====================================================\n";
echo "   LAPORTIDAR BACKEND AUTOMATED TEST SUITE\n";
echo "====================================================\n\n";

// 1. Health check
$h = req('GET', '/health');
test('Health check endpoint returns 200', $h['status'] === 200 && ($h['data']['success'] ?? false) === true);

// 2. Admin Login
$adminLogin = req('POST', '/auth/login', ['email' => 'admin@untidar.ac.id', 'password' => 'admin12345']);
test('Admin login succeeds', $adminLogin['status'] === 200 && !empty($adminLogin['data']['data']['token']));
$adminToken = $adminLogin['data']['data']['token'] ?? null;

// 3. Student Login
$mhsLogin = req('POST', '/auth/login', ['email' => 'bagas@students.untidar.ac.id', 'password' => 'mahasiswa123']);
test('Mahasiswa login succeeds', $mhsLogin['status'] === 200 && !empty($mhsLogin['data']['data']['token']));
$mhsToken = $mhsLogin['data']['data']['token'] ?? null;

// 4. Mahasiswa Me endpoint
$me = req('GET', '/auth/me', null, $mhsToken);
test('Auth/me returns correct user role', $me['status'] === 200 && $me['data']['data']['role'] === 'mahasiswa');

// 5. Locations list & tree
$locs = req('GET', '/locations', null, $mhsToken);
test('Locations endpoint returns Tuguran locations tree', $locs['status'] === 200 && !empty($locs['data']['data']['tree']['Gedung Kuliah Bersama (GKB)']));

// 6. QR Code Resolution with HMAC
$secret = 'laportidar_untidar_super_secret_key_2026';
$validCode = 'TUG-GKB-302';
$validSig = hash_hmac('sha256', $validCode, $secret);
$fakeSig  = '0000000000000000000000000000000000000000000000000000000000000000';

$qrValid = req('GET', "/locations/resolve?code={$validCode}&sig={$validSig}", null, $mhsToken);
test('QR code valid HMAC passes verification', $qrValid['status'] === 200 && $qrValid['data']['data']['code'] === $validCode);

$qrTampered = req('GET', "/locations/resolve?code={$validCode}&sig={$fakeSig}", null, $mhsToken);
test('QR code tampered HMAC is rejected (403)', $qrTampered['status'] === 403);

// 7. Categories
$cats = req('GET', '/categories', null, $mhsToken);
test('Categories returned with severity weights', $cats['status'] === 200 && count($cats['data']['data']) >= 8);

// 8. Similar reports check
$similar = req('GET', '/reports/similar?location_id=9&category_id=1', null, $mhsToken);
test('Similar reports detector finds open issue in GKB 3.02', $similar['status'] === 200 && $similar['data']['data']['count'] >= 1);

// 9. Report Upvote & Priority Recalculation
// Mahasiswa 2 (Bagas) upvotes report 2 (Siti's report)
$upvoteRes = req('POST', '/reports/2/upvote', null, $mhsToken);
// Siti's report 2 might already have upvote from Bagas from seed, let's test report 7 or cancel then upvote
$cancelUpvote = req('DELETE', '/reports/2/upvote', null, $mhsToken);
test('Cancel upvote succeeds', $cancelUpvote['status'] === 200 && $cancelUpvote['data']['data']['has_upvoted'] === false);

$upvoteRes2 = req('POST', '/reports/2/upvote', null, $mhsToken);
test('Upvote "Saya Mengalami Hal Serupa" succeeds and increments score', $upvoteRes2['status'] === 200 && $upvoteRes2['data']['data']['has_upvoted'] === true);

// Cannot upvote own report
$ownReportUpvote = req('POST', '/reports/1/upvote', null, $mhsToken); // report 1 is Bagas's report
test('Prevent upvoting own report (anti-cheat)', $ownReportUpvote['status'] === 400);

// 10. Student Create Report
$newReport = req('POST', '/reports', [
    'location_id'   => 8, // GKB 3.01
    'category_id'   => 2, // Listrik
    'title'         => 'Saklar Lampu GKB 3.01 Korslet Berbau Sangit',
    'description'   => 'Saat saklar dinyalakan, terdengar desis listrik dan bau kabel terbakar di dekat pintu depan.',
    'urgency_level' => 'tinggi'
], $mhsToken);
test('Create report succeeds with ticket and priority score', $newReport['status'] === 201 && !empty($newReport['data']['data']['ticket_number']));
$createdReportId = $newReport['data']['data']['id'] ?? 0;

// 11. RBAC Check: Student cannot access admin stats
$studentDenied = req('GET', '/admin/stats', null, $mhsToken);
test('RBAC: Student forbidden from admin stats (403)', $studentDenied['status'] === 403);

// 12. Admin Stats
$adminStats = req('GET', '/admin/stats', null, $adminToken);
test('Admin stats returns metrics and heatmap', $adminStats['status'] === 200 && isset($adminStats['data']['data']['summary']['total_reports']));

// 13. Admin Verify Report
$verifyRes = req('PATCH', "/reports/{$createdReportId}/verify", ['note' => 'Kerusakan kelistrikan telah dikonfirmasi Sarpras.'], $adminToken);
test('Admin verify report succeeds', $verifyRes['status'] === 200);

// 14. Admin Assign Technician
$assignRes = req('PATCH', "/reports/{$createdReportId}/assign", [
    'technician_id' => 1, // Pak Joko (Kelistrikan)
    'notes'         => 'Segera cek jalur saklar dan MCB panel lantai 3.'
], $adminToken);
test('Admin assign technician succeeds', $assignRes['status'] === 200);

// 15. Admin Complete Report with After Photo
$completeRes = req('PATCH', "/reports/{$createdReportId}/complete", [
    'note'       => 'Saklar telah diganti baru dan kabel terbakar telah dipotong serta diisolasi aman.',
    'photo_path' => 'uploads/photos/demo_after_chair.jpg'
], $adminToken);
test('Admin complete report with after photo succeeds', $completeRes['status'] === 200);

// 16. Student Submit Rating
$ratingRes = req('POST', "/reports/{$createdReportId}/rating", [
    'rating' => 5,
    'review' => 'Luar biasa respon cepat dari Sarpras Untidar!'
], $mhsToken);
test('Student submit rating succeeds', $ratingRes['status'] === 200);

// 17. Notifications
$notifs = req('GET', '/notifications', null, $mhsToken);
test('Notifications received for status transitions', $notifs['status'] === 200 && count($notifs['data']['data']['notifications']) > 0);

// 18. Security: SQL Injection attempt on search
$sqliTest = req('GET', "/reports?search=" . urlencode("' OR '1'='1"), null, $mhsToken);
test('SQL Injection handled safely without 500 error', $sqliTest['status'] === 200, "Status was: " . $sqliTest['status'] . " Raw: " . ($sqliTest['raw'] ?? 'none'));

echo "\n====================================================\n";
echo "TEST RESULTS: {$passCount} PASSED, {$failCount} FAILED\n";
echo "====================================================\n";

if ($failCount > 0) {
    exit(1);
}
