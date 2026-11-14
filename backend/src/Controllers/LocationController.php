<?php

namespace App\Controllers;

use App\Core\Database;
use App\Core\Request;
use App\Core\Response;
use App\Core\Security;
use App\Middleware\AuthMiddleware;
use PDO;

class LocationController {
    public function index(Request $request): void {
        AuthMiddleware::authenticate($request);
        $pdo = Database::getConnection();

        $stmt = $pdo->query("
            SELECT id, building, floor, room, code, qr_signature, is_active 
            FROM locations 
            WHERE is_active = 1 
            ORDER BY building ASC, floor ASC, room ASC
        ");
        $locations = $stmt->fetchAll();

        // Build hierarchical tree
        $tree = [];
        foreach ($locations as $loc) {
            $b = $loc['building'];
            $f = $loc['floor'];
            if (!isset($tree[$b])) {
                $tree[$b] = [];
            }
            if (!isset($tree[$b][$f])) {
                $tree[$b][$f] = [];
            }
            $tree[$b][$f][] = $loc;
        }

        Response::success([
            'flat' => $locations,
            'tree' => $tree
        ], 'Daftar lokasi Kampus Tuguran.');
    }

    public function resolveQr(Request $request): void {
        AuthMiddleware::authenticate($request);

        $code = trim($request->getQuery('code', ''));
        $sig  = trim($request->getQuery('sig', ''));

        if (empty($code)) {
            Response::error('Kode lokasi wajib disertakan.', 400);
        }

        $pdo = Database::getConnection();

        // 1. Find location by unique code
        $stmt = $pdo->prepare("SELECT id, building, floor, room, code, qr_signature, is_active FROM locations WHERE code = ? LIMIT 1");
        $stmt->execute([$code]);
        $loc = $stmt->fetch();

        if (!$loc) {
            Response::error('Lokasi ruangan tidak ditemukan di sistem Kampus Tuguran.', 404);
        }

        // 2. If signature is supplied, verify HMAC
        if (!empty($sig)) {
            if (!Security::verifyQrSignature($code, $sig)) {
                Response::error('QR Code tidak valid atau tanda tangan digital (HMAC) dipalsukan.', 403);
            }
        }

        Response::success($loc, 'Lokasi berhasil terverifikasi.');
    }

    public function getCategories(Request $request): void {
        AuthMiddleware::authenticate($request);
        $pdo = Database::getConnection();

        $stmt = $pdo->query("SELECT id, name, icon, severity_weight FROM categories ORDER BY id ASC");
        $cats = $stmt->fetchAll();

        Response::success($cats, 'Daftar kategori fasilitas.');
    }

    public function store(Request $request): void {
        $admin = AuthMiddleware::requireRole($request, 'admin');

        $building = trim($request->input('building', ''));
        $floor = trim($request->input('floor', ''));
        $room = trim($request->input('room', ''));
        $code = strtoupper(trim($request->input('code', '')));

        if (empty($building) || empty($floor) || empty($room)) {
            Response::error('Gedung, lantai, dan nama ruangan wajib diisi.', 422);
        }

        if (empty($code)) {
            // Auto generate code e.g. TUG-GKB-301
            $bShort = strtoupper(substr(preg_replace('/[^A-Za-z0-9]/', '', $building), 0, 4));
            $rShort = strtoupper(substr(preg_replace('/[^A-Za-z0-9]/', '', $room), 0, 4));
            $code = "TUG-{$bShort}-{$rShort}-" . rand(10, 99);
        }

        $sig = Security::generateQrSignature($code);
        $pdo = Database::getConnection();

        // Check if code exists
        $check = $pdo->prepare("SELECT id FROM locations WHERE code = ?");
        $check->execute([$code]);
        if ($check->fetch()) {
            Response::error("Kode lokasi {$code} sudah ada. Gunakan kode lain.", 409);
        }

        $stmt = $pdo->prepare("INSERT INTO locations (building, floor, room, code, qr_signature, is_active, created_at) VALUES (?, ?, ?, ?, ?, 1, NOW())");
        $stmt->execute([Security::sanitize($building), Security::sanitize($floor), Security::sanitize($room), $code, $sig]);
        $id = (int)$pdo->lastInsertId();

        Security::logAudit($pdo, $admin['id'], 'CREATE_LOCATION', 'locations', $id, "Menambah lokasi {$code}: {$building} - {$floor} - {$room}", $request->getIp());

        Response::success([
            'id'           => $id,
            'building'     => $building,
            'floor'        => $floor,
            'room'         => $room,
            'code'         => $code,
            'qr_signature' => $sig,
            'is_active'    => 1,
        ], 'Lokasi berhasil ditambahkan.', 201);
    }

    public function getQr(Request $request, array $params): void {
        AuthMiddleware::authenticate($request);
        $id = (int)($params['id'] ?? 0);

        $pdo = Database::getConnection();
        $stmt = $pdo->prepare("SELECT id, building, floor, room, code, qr_signature FROM locations WHERE id = ?");
        $stmt->execute([$id]);
        $loc = $stmt->fetch();

        if (!$loc) {
            Response::notFound("Lokasi tidak ditemukan.");
        }

        // Return QR payload data for rendering/printing sticker
        $qrPayload = json_encode([
            'app'  => 'laportidar',
            'code' => $loc['code'],
            'sig'  => $loc['qr_signature']
        ]);

        Response::success([
            'location'   => $loc,
            'qr_payload' => $qrPayload,
            'print_url'  => "laportidar://report?code={$loc['code']}&sig={$loc['qr_signature']}"
        ], 'Data QR Stiker Lokasi.');
    }
}
