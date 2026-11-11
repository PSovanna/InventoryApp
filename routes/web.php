<?php

use Illuminate\Support\Facades\Route;

Route::get('/', function () {
    return response()->json([
        'message' => 'Restaurant catalog API. Run flutter_app for the Dart interface.',
        'categories' => url('/api/categories'),
        'products' => url('/api/products'),
    ]);
});
