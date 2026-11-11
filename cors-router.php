<?php

// Local development router: php -S 127.0.0.1:8000 -t public cors-router.php
$origin = $_SERVER['HTTP_ORIGIN'] ?? '';
$requestPath = parse_url($_SERVER['REQUEST_URI'], PHP_URL_PATH) ?: '/';
// Laravel's CORS middleware handles API responses. Avoid duplicate headers.
$laravelHandlesCors = str_starts_with($requestPath, '/api/') && $_SERVER['REQUEST_METHOD'] !== 'OPTIONS';
if (! $laravelHandlesCors && preg_match('#^https?://(localhost|127\.0\.0\.1)(:\d+)?$#', $origin)) {
    header('Access-Control-Allow-Origin: '.$origin);
    header('Vary: Origin');
    header('Access-Control-Allow-Methods: GET, POST, PUT, PATCH, DELETE, OPTIONS');
    header('Access-Control-Allow-Headers: Accept, Content-Type, Authorization, X-Requested-With');
}

if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    http_response_code(204);
    return;
}

$path = rawurldecode(parse_url($_SERVER['REQUEST_URI'], PHP_URL_PATH) ?: '/');
if (str_contains($path, "\0")) {
    http_response_code(400);
    return;
}

$public = realpath(__DIR__.'/public');
$storage = realpath(__DIR__.'/storage/app/public');
$file = realpath($public.$path);
$within = static fn ($file, $root) => $root !== false
    && str_starts_with(str_replace('\\', '/', $file), str_replace('\\', '/', $root).'/');

// Stream static assets here so images retain the CORS headers.
// PHP requests and application routes always go through Laravel.
if ($file !== false && is_file($file)
    && ($within($file, $public) || (str_starts_with($path, '/storage/') && $within($file, $storage)))
    && ! in_array(strtolower(pathinfo($file, PATHINFO_EXTENSION)), ['php', 'phtml', 'phar'])) {
    if (! in_array($_SERVER['REQUEST_METHOD'], ['GET', 'HEAD'])) {
        http_response_code(405);
        header('Allow: GET, HEAD, OPTIONS');
        return;
    }
    $extension = strtolower(pathinfo($file, PATHINFO_EXTENSION));
    $types = ['css' => 'text/css', 'js' => 'application/javascript', 'svg' => 'image/svg+xml'];
    header('Content-Type: '.($types[$extension] ?? (new finfo(FILEINFO_MIME_TYPE))->file($file)));
    header('Content-Length: '.filesize($file));
    if ($_SERVER['REQUEST_METHOD'] !== 'HEAD') {
        readfile($file);
    }
    return;
}

require __DIR__.'/public/index.php';
