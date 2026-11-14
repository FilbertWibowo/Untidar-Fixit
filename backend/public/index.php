<?php

// Front Controller & API Entry Point
declare(strict_types=1);

// Require Config directly
require_once __DIR__ . '/../config/config.php';

// Custom Autoloader for App\* namespace
spl_autoload_register(function ($class) {
    $prefix = 'App\\';
    $baseDir = __DIR__ . '/../src/';

    $len = strlen($prefix);
    if (strncmp($prefix, $class, $len) !== 0) {
        return;
    }

    $relativeClass = substr($class, $len);
    $file = $baseDir . str_replace('\\', '/', $relativeClass) . '.php';

    if (file_exists($file)) {
        require $file;
    }
});

use App\Config\Config;
use App\Core\Request;
use App\Core\Response;
use App\Core\Router;
use App\Middleware\CorsMiddleware;
use App\Controllers\AuthController;
use App\Controllers\LocationController;
use App\Controllers\ReportController;
use App\Controllers\UpvoteController;
use App\Controllers\AdminController;
use App\Controllers\NotificationController;

// Load Configuration from .env
Config::load(__DIR__ . '/../.env');

// Create Request instance
$request = new Request();

// Global CORS Handling
CorsMiddleware::handle($request);

// Serve static upload images with CORS headers
$uri = $request->getUri();
if (preg_match('#^/(?:api/)?uploads/(.+)$#', $uri, $m)) {
    $filePath = __DIR__ . '/uploads/' . $m[1];
    if (file_exists($filePath)) {
        $ext = strtolower(pathinfo($filePath, PATHINFO_EXTENSION));
        $mimes = ['jpg' => 'image/jpeg', 'jpeg' => 'image/jpeg', 'png' => 'image/png', 'webp' => 'image/webp'];
        if (isset($mimes[$ext])) {
            header('Access-Control-Allow-Origin: *');
            header('Access-Control-Allow-Methods: GET, OPTIONS');
            header('Access-Control-Allow-Headers: *');
            header('Content-Type: ' . $mimes[$ext]);
            header('Content-Length: ' . filesize($filePath));
            header('Cache-Control: public, max-age=86400');
            readfile($filePath);
            exit;
        }
    }
}

// Router Setup
$router = new Router();

// --- Auth Routes ---
$router->post('/api/auth/register', [AuthController::class, 'register']);
$router->post('/api/auth/login',    [AuthController::class, 'login']);
$router->post('/api/auth/logout',   [AuthController::class, 'logout']);
$router->get('/api/auth/me',        [AuthController::class, 'me']);
$router->post('/api/auth/change-password', [AuthController::class, 'changePassword']);

// --- Locations & Categories Routes ---
$router->get('/api/locations',         [LocationController::class, 'index']);
$router->get('/api/locations/resolve', [LocationController::class, 'resolveQr']);
$router->post('/api/locations',        [LocationController::class, 'store']);
$router->get('/api/locations/{id}/qr', [LocationController::class, 'getQr']);
$router->get('/api/categories',        [LocationController::class, 'getCategories']);

// --- Reports Routes ---
$router->get('/api/reports',         [ReportController::class, 'index']);
$router->get('/api/reports/mine',    [ReportController::class, 'mine']);
$router->get('/api/reports/similar', [ReportController::class, 'findSimilar']);
$router->get('/api/reports/{id}',    [ReportController::class, 'show']);
$router->post('/api/reports',        [ReportController::class, 'store']);
$router->post('/api/reports/{id}/rating', [ReportController::class, 'submitRating']);

// --- Upvote ("Saya Mengalami Hal Serupa") Routes ---
$router->post('/api/reports/{id}/upvote',   [UpvoteController::class, 'upvote']);
$router->delete('/api/reports/{id}/upvote', [UpvoteController::class, 'cancelUpvote']);

// --- Admin (Sarpras) Routes ---
$router->patch('/api/reports/{id}/verify',   [AdminController::class, 'verifyReport']);
$router->post('/api/reports/{id}/verify',    [AdminController::class, 'verifyReport']);
$router->patch('/api/reports/{id}/assign',   [AdminController::class, 'assignTechnician']);
$router->post('/api/reports/{id}/assign',    [AdminController::class, 'assignTechnician']);
$router->patch('/api/reports/{id}/complete', [AdminController::class, 'completeReport']);
$router->post('/api/reports/{id}/complete',  [AdminController::class, 'completeReport']);
$router->patch('/api/reports/{id}/reject',   [AdminController::class, 'rejectReport']);
$router->post('/api/reports/{id}/reject',    [AdminController::class, 'rejectReport']);
$router->get('/api/admin/stats',             [AdminController::class, 'stats']);
$router->get('/api/admin/export',            [AdminController::class, 'exportCsv']);
$router->get('/api/admin/technicians',       [AdminController::class, 'getTechnicians']);
$router->post('/api/admin/technicians',      [AdminController::class, 'storeTechnician']);
$router->get('/api/admin/users',             [AdminController::class, 'getUsers']);
$router->get('/api/admin/audit-logs',        [AdminController::class, 'getAuditLogs']);

// --- Notifications Routes ---
$router->get('/api/notifications',          [NotificationController::class, 'index']);
$router->patch('/api/notifications/{id}/read', [NotificationController::class, 'markAsRead']);
$router->patch('/api/notifications/read-all',  [NotificationController::class, 'markAllAsRead']);

// Health check endpoint
$router->get('/api/health', function() {
    Response::success([
        'status'    => 'ok',
        'timestamp' => date('Y-m-d H:i:s'),
        'service'   => 'Untidar Fixit API - Kampus Tuguran Untidar'
    ], 'API Untidar Fixit berjalan dengan normal.');
});

// Dispatch request
try {
    $router->dispatch($request);
} catch (\Throwable $e) {
    Response::error(
        'Terjadi kesalahan internal server.',
        500,
        Config::get('APP_DEBUG') === 'true' ? [
            'message' => $e->getMessage(),
            'file'    => $e->getFile(),
            'line'    => $e->getLine()
        ] : null
    );
}
