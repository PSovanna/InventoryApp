<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use Illuminate\Http\Request;
use App\Models\Category;
use App\Models\Product;
use Illuminate\Support\Facades\Storage;

class CategoryController extends Controller
{
    public function index()
    {
        $categories = Category::all();

        return response()->json([
            'success' => true,
            'data' => $categories
        ]);
    }

    public function store(Request $request)
    {
        $data = $request->validate([
            'category_name' => 'required|string|max:50',
            'description' => 'nullable|string',
            'image' => 'nullable|image|mimes:jpg,jpeg,png,webp|max:2048',
        ]);

        if ($request->hasFile('image')) {
            $data['image'] = $request->file('image')
                ->store('categories', 'public');
        }

        $category = Category::create($data);

        return response()->json([
            'success' => true,
            'message' => 'Category created successfully!',
            'data' => $category
        ], 201);
    }

    public function show(string $id)
    {
        $category = Category::find($id);
        // $category = Category::where('category_id',$id);

        if (!$category) {
            return response()->json([
                'success' => false,
                'message' => 'Category not found!'
            ], 404);
        }

        return response()->json([
            'success' => true,
            'data' => $category
        ]);
    }

    public function update(Request $request, string $id)
    {
        $category = Category::find($id);

        if (!$category) {
            return response()->json([
                'success' => false,
                'message' => 'Category not found!'
            ], 404);
        }

        $data = $request->validate([
            'category_name' => 'required|string|max:50',
            'description' => 'nullable|string',
            'image' => 'nullable|image|mimes:jpg,jpeg,png,webp|max:2048',
        ]);

        if ($request->hasFile('image')) {

            if ($category->image) {
                Storage::disk('public')->delete($category->image);
            }

            $data['image'] = $request->file('image')
                ->store('categories', 'public');
        }

        $category->update($data);

        return response()->json([
            'success' => true,
            'message' => 'Category updated successfully!',
            'data' => $category
        ],200);
    }

    public function destroy(string $id)
    {
        try {
            $category = Category::find($id);

            if (!$category) {
                return response()->json([
                    'success' => false,
                    'message' => 'Category not found!',
                ], 404);
            }

            if (Product::where('category_id', $category->category_id)->exists()) {
                return response()->json([
                    'success' => false,
                    'message' => 'This category is linked to products and cannot be deleted.',
                ], 409);
            }

            $image = $category->image;
            $category->delete();

            if ($image) {
                Storage::disk('public')->delete($image);
            }

            return response()->json([
                'success' => true,
                'message' => 'Category deleted successfully!',
            ]);
        } catch (\Throwable $th) {
            report($th);

            return response()->json([
                'success' => false,
                'message' => 'Delete failed',
                'error'   => $th->getMessage()
                ], 500);
        }
    }
}
