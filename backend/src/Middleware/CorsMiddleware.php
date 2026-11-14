<?php

namespace App\Middleware;

use App\Config\Config;
use App\Core\Request;

class CorsMiddleware {
    public static function handle(Request $request): void {
        $allowedOriginsConfig = Config::get('CORS_ALLOWED_ORIGINS', '*');
        $allowedOrigins = array_map('trim', explode(',', $allowedOriginsConfig));
        
        $origin = $_SERVER['HTTP_ORIGIN'] ?? '';

        if (!empty($origin)) {
            header("Access-Control-Allow-Origin: $origin");
            header('Access-Control-Allow-Credentials: true');
        } else {
            header('Access-Control-Allow-Origin: *');
        }

        header('Access-Control-Allow-Methods: GET, POST, PUT, PATCH, DELETE, OPTIONS');
        header('Access-Control-Allow-Headers: Content-Type, Authorization, X-Requested-With, Accept, Origin');
        header('Access-Control-Max-Age: 86400');

        if ($request->getMethod() === 'OPTIONS') {
            http_response_code(204);
            exit;
        }
    }
}
