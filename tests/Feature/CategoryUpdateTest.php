<?php

namespace Tests\Feature;

use App\Models\Category;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Http\UploadedFile;
use Illuminate\Support\Facades\Storage;
use Tests\TestCase;

class CategoryUpdateTest extends TestCase
{
    use RefreshDatabase;

    public function test_post_with_method_override_updates_category_and_replaces_image(): void
    {
        Storage::fake('public');
        Storage::disk('public')->put('categories/old.jpg', 'old image');
        $category = Category::create([
            'category_name' => 'Old name',
            'image' => 'categories/old.jpg',
        ]);

        $response = $this->post('/api/categories/'.$category->category_id, [
            '_method' => 'PUT',
            'category_name' => 'Cambodian Food',
            'description' => 'Local Food of Cambodia',
            'image' => UploadedFile::fake()->image('AmokKhmer.jpg'),
        ], ['Accept' => 'application/json']);

        $response->assertOk()->assertJsonPath('success', true);
        $category->refresh();
        $this->assertSame('Cambodian Food', $category->category_name);
        $this->assertSame('Local Food of Cambodia', $category->description);
        Storage::disk('public')->assertExists($category->image);
        Storage::disk('public')->assertMissing('categories/old.jpg');
    }

    public function test_update_without_image_preserves_existing_image(): void
    {
        Storage::fake('public');
        Storage::disk('public')->put('categories/old.jpg', 'old image');
        $category = Category::create([
            'category_name' => 'Old name',
            'image' => 'categories/old.jpg',
        ]);

        $this->putJson('/api/categories/'.$category->category_id, [
            'category_name' => 'New name',
        ])->assertOk();

        $this->assertSame('New name', $category->fresh()->category_name);
        $this->assertSame('categories/old.jpg', $category->fresh()->image);
        Storage::disk('public')->assertExists('categories/old.jpg');
    }

    public function test_missing_category_returns_the_api_error_response(): void
    {
        $this->putJson('/api/categories/999', [
            'category_name' => 'Cambodian Food',
        ])->assertNotFound()->assertExactJson([
            'success' => false,
            'message' => 'Category not found!',
        ]);
    }

    public function test_update_requires_a_category_id_in_the_url(): void
    {
        $this->post('/api/categories', [
            '_method' => 'PUT',
            'category_name' => 'Cambodian Food',
        ], ['Accept' => 'application/json'])->assertStatus(405);
    }
}
