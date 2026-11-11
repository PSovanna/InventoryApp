<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Product;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Storage;

class ProductController extends Controller
{
    /**
     * Display a listing of the resource.
     */
    public function index()
    {
        $products = Product::with('category')->where('isDeleted', false)->get();

        return response()->json($products);
    }

    /**
     * Store a newly created resource in storage.
     */
    public function store(Request $request)
    {
        $data = $request->validate([
            'product_name' => 'required|string|max:100',
            'description' => 'nullable|string',
            'category_id' => 'required|integer|exists:categories,category_id',
            'price' => 'required|numeric|min:0|max:99999999.99',
            'image' => 'nullable|image|mimes:jpg,jpeg,png,webp|max:2048',
        ]);

        $imagePath = null;

        try {
            if ($request->hasFile('image')) {
                $imagePath = $request->file('image')->store('products', 'public');

                if ($imagePath === false) {
                    throw new \RuntimeException('Unable to store product image.');
                }

                $data['image'] = $imagePath;
            }

            $product = Product::create($data);
        } catch (\Throwable $exception) {
            if ($imagePath) {
                Storage::disk('public')->delete($imagePath);
            }

            throw $exception;
        }

        return response()->json([
            'success' => true,
            'message' => 'Product created successfully!',
            'data' => $product,
        ], 201);
    }

    /**
     * Display the specified resource.
     */
    public function show(string $id)
    {
        $product = Product::with('category')->where('isDeleted', false)->find($id);

        if (! $product) {
            return response()->json(['success' => false, 'message' => 'Product not found!'], 404);
        }

        return response()->json(['success' => true, 'data' => $product]);
    }

    /**
     * Update the specified resource in storage.
     */
    public function update(Request $request, string $id)
    {
        $product = Product::where('isDeleted', false)->find($id);

        if (! $product) {
            return response()->json(['success' => false, 'message' => 'Product not found!'], 404);
        }

        $data = $request->validate([
            'product_name' => 'sometimes|required|string|max:100',
            'description' => 'sometimes|nullable|string',
            'category_id' => 'sometimes|required|integer|exists:categories,category_id',
            'price' => 'sometimes|required|numeric|min:0|max:99999999.99',
            'image' => 'sometimes|nullable|image|mimes:jpg,jpeg,png,webp|max:2048',
        ]);

        $oldImage = $product->image;
        $imagePath = null;
        // Keep the existing image unless a replacement file is uploaded.
        unset($data['image']);

        try {
            if ($request->hasFile('image')) {
                $imagePath = $request->file('image')->store('products', 'public');

                if ($imagePath === false) {
                    throw new \RuntimeException('Unable to store product image.');
                }

                $data['image'] = $imagePath;
            }

            $product->update($data);
        } catch (\Throwable $exception) {
            if ($imagePath) {
                Storage::disk('public')->delete($imagePath);
            }

            throw $exception;
        }

        if ($imagePath && $oldImage) {
            Storage::disk('public')->delete($oldImage);
        }

        return response()->json([
            'success' => true,
            'message' => 'Product updated successfully!',
            'data' => $product->load('category'),
        ]);
    }

    /**
     * Remove the specified resource from storage.
     */
    public function destroy(string $id)
    {
        $product = Product::where('isDeleted', false)->find($id);

        if (! $product) {
            return response()->json(['success' => false, 'message' => 'Product not found!'], 404);
        }

        $product->isDeleted = true;
        $product->save();

        return response()->json([
            'success' => true,
            'message' => 'Product deleted successfully!',
        ]);
    }
}
