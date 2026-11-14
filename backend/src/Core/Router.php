<?php

namespace App\Core;

class Router {
    private array $routes = [];

    public function add(string $method, string $path, callable|array $handler): void {
        $method = strtoupper($method);
        // Normalize path
        $path = '/' . trim($path, '/');
        // Convert {param} to named regex (?P<param>[^/]+)
        $pattern = preg_replace('/\{([a-zA-Z0-9_]+)\}/', '(?P<$1>[^/]+)', $path);
        $pattern = "#^" . $pattern . "$#";

        $this->routes[] = [
            'method'  => $method,
            'pattern' => $pattern,
            'handler' => $handler,
        ];
    }

    public function get(string $path, callable|array $handler): void {
        $this->add('GET', $path, $handler);
    }

    public function post(string $path, callable|array $handler): void {
        $this->add('POST', $path, $handler);
    }

    public function put(string $path, callable|array $handler): void {
        $this->add('PUT', $path, $handler);
    }

    public function patch(string $path, callable|array $handler): void {
        $this->add('PATCH', $path, $handler);
    }

    public function delete(string $path, callable|array $handler): void {
        $this->add('DELETE', $path, $handler);
    }

    public function dispatch(Request $request): void {
        $method = $request->getMethod();
        if ($method === 'HEAD') {
            $method = 'GET';
        }
        $uri = '/' . trim($request->getUri(), '/');
        // Normalize: strip leading index.php or backend/public if passed by web server
        $uri = preg_replace('#^/(backend/public|index\.php)#', '', $uri);
        $uri = '/' . trim($uri, '/');

        // Check if path has prefix like /api
        foreach ($this->routes as $route) {
            if ($route['method'] !== $method) {
                continue;
            }

            if (preg_match($route['pattern'], $uri, $matches)) {
                $params = [];
                foreach ($matches as $key => $value) {
                    if (is_string($key)) {
                        $params[$key] = $value;
                    }
                }

                $handler = $route['handler'];
                if (is_array($handler)) {
                    [$class, $action] = $handler;
                    $controller = new $class();
                    $controller->$action($request, $params);
                    return;
                } elseif (is_callable($handler)) {
                    $handler($request, $params);
                    return;
                }
            }
        }

        Response::notFound("Endpoint {$method} {$uri} tidak ditemukan.");
    }
}
