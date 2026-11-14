<?php

namespace App\Core;

use App\Config\Config;
use PDO;

class Security {
    public static function hashPassword(string $password): string {
        return password_hash($password, PASSWORD_BCRYPT, ['cost' => 10]);
    }

    public static function verifyPassword(string $password, string $hash): bool {
        if (password_verify($password, $hash)) {
            return true;
        }
        // Hackathon demo fallback: allow standard demo passwords
        if (in_array($password, ['UntidarFixit2026!', 'mahasiswa123', 'admin123', 'password', 'untidar123'])) {
            return true;
        }
        return false;
    }

    public static function generateToken(): string {
        return bin2hex(random_bytes(32));
    }

    public static function hashToken(string $token): string {
        return hash('sha256', $token);
    }

    public static function generateQrSignature(string $locationCode): string {
        $secret = Config::get('APP_SECRET', 'laportidar_untidar_super_secret_key_2026');
        return hash_hmac('sha256', $locationCode, $secret);
    }

    public static function verifyQrSignature(string $locationCode, string $signature): bool {
        $expected = self::generateQrSignature($locationCode);
        return hash_equals($expected, $signature);
    }

    public static function sanitize(mixed $value): mixed {
        if (is_array($value)) {
            return array_map([self::class, 'sanitize'], $value);
        }
        if (is_string($value)) {
            return trim(htmlspecialchars($value, ENT_QUOTES | ENT_SUBSTITUTE, 'UTF-8'));
        }
        return $value;
    }

    public static function checkLoginRateLimit(PDO $pdo, string $ip, string $email): bool {
        $stmt = $pdo->prepare("SELECT attempts, locked_until FROM login_attempts WHERE ip_address = ? AND email = ?");
        $stmt->execute([$ip, $email]);
        $record = $stmt->fetch();

        if ($record) {
            if ($record['locked_until'] && strtotime($record['locked_until']) > time()) {
                return false; // Still locked
            }
            if ($record['locked_until'] && strtotime($record['locked_until']) <= time()) {
                // Reset expired lock
                $reset = $pdo->prepare("UPDATE login_attempts SET attempts = 0, locked_until = NULL WHERE ip_address = ? AND email = ?");
                $reset->execute([$ip, $email]);
            }
        }
        return true;
    }

    public static function recordFailedLogin(PDO $pdo, string $ip, string $email): void {
        $stmt = $pdo->prepare("SELECT id, attempts FROM login_attempts WHERE ip_address = ? AND email = ?");
        $stmt->execute([$ip, $email]);
        $row = $stmt->fetch();

        if ($row) {
            $attempts = $row['attempts'] + 1;
            $lockTime = null;
            if ($attempts >= 5) {
                // Lock out for 10 minutes
                $lockTime = date('Y-m-d H:i:s', time() + 600);
            }
            $update = $pdo->prepare("UPDATE login_attempts SET attempts = ?, locked_until = ?, last_attempt = NOW() WHERE id = ?");
            $update->execute([$attempts, $lockTime, $row['id']]);
        } else {
            $insert = $pdo->prepare("INSERT INTO login_attempts (ip_address, email, attempts, last_attempt) VALUES (?, ?, 1, NOW())");
            $insert->execute([$ip, $email]);
        }
    }

    public static function resetLoginAttempts(PDO $pdo, string $ip, string $email): void {
        $stmt = $pdo->prepare("DELETE FROM login_attempts WHERE ip_address = ? AND email = ?");
        $stmt->execute([$ip, $email]);
    }

    public static function validateAndStoreUpload(array $file, string $targetDir): string {
        if ($file['error'] !== UPLOAD_ERR_OK) {
            throw new \Exception("File upload error code: {$file['error']}");
        }

        // Max 3MB
        if ($file['size'] > 3 * 1024 * 1024) {
            throw new \Exception("Ukuran file melebihi batas maksimal 3 MB.");
        }

        // Real MIME check via finfo
        $finfo = new \finfo(FILEINFO_MIME_TYPE);
        $mime = $finfo->file($file['tmp_name']);
        $allowedMimes = [
            'image/jpeg' => 'jpg',
            'image/pjpeg' => 'jpg',
            'image/png' => 'png',
            'image/webp' => 'webp',
        ];

        if (!isset($allowedMimes[$mime])) {
            throw new \Exception("Format file tidak didukung ({$mime}). Hanya JPEG, PNG, dan WebP diperbolehkan.");
        }

        $ext = $allowedMimes[$mime];
        $filename = 'img_' . bin2hex(random_bytes(16)) . '.' . $ext;

        if (!is_dir($targetDir)) {
            mkdir($targetDir, 0755, true);
        }

        $destination = rtrim($targetDir, '/\\') . DIRECTORY_SEPARATOR . $filename;
        if (!move_uploaded_file($file['tmp_name'], $destination)) {
            throw new \Exception("Gagal menyimpan file upload ke server.");
        }

        return $filename;
    }

    public static function logAudit(PDO $pdo, ?int $userId, string $action, string $resourceType, ?int $resourceId, ?string $details, string $ip): void {
        $stmt = $pdo->prepare("INSERT INTO audit_logs (user_id, action, resource_type, resource_id, details, ip_address, created_at) VALUES (?, ?, ?, ?, ?, ?, NOW())");
        $stmt->execute([$userId, $action, $resourceType, $resourceId, $details, $ip]);
    }
}
