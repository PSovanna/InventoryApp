<?php

namespace Tests\Feature;

use App\Models\Category;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Http\UploadedFile;
use Illuminate\Support\Facades\Storage;
use Tests\TestCase;

class ProductStoreTest extends TestCase
{
    use RefreshDatabase;

    public function test_product_can_be_created_with_an_image(): void
    {
        Storage::fake('public');
        $category = Category::create(['category_name' => 'Cambodian Food']);

        $response = $this->postJson('/api/products', [
            'product_name' => 'Fish Amok',
            'description' => 'Steamed fish curry.',
            'category_id' => $category->category_id,
            'price' => 6.50,
            'image' => UploadedFile::fake()->image('amok.jpg'),
        ]);

        $response->assertCreated()->assertJsonPath('success', true);
        $this->assertDatabaseHas('products', [
            'product_name' => 'Fish Amok',
            'category_id' => $category->category_id,
            'price' => 6.50,
            'isDeleted' => false,
        ]);
        Storage::disk('public')->assertExists($response->json('data.image'));
    }

    public function test_invalid_product_returns_validation_errors(): void
    {
        $this->postJson('/api/products', [
            'category_id' => 999,
            'price' => -1,
        ])->assertUnprocessable()->assertJsonValidationErrors([
            'product_name', 'category_id', 'price',
        ]);

        $this->assertDatabaseCount('products', 0);
    }

    public function test_product_can_be_created_without_optional_fields(): void
    {
        $category = Category::create(['category_name' => 'Cambodian Food']);

        $this->postJson('/api/products', [
            'product_name' => 'Khmer Noodles',
            'category_id' => $category->category_id,
            'price' => 4,
        ])->assertCreated()->assertJsonPath('data.price', '4.00');
    }
}
