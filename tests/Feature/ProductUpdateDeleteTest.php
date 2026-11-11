<?php

namespace Tests\Feature;

use App\Models\Category;
use App\Models\Product;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Http\UploadedFile;
use Illuminate\Support\Facades\Storage;
use Tests\TestCase;

class ProductUpdateDeleteTest extends TestCase
{
    use RefreshDatabase;

    private function product(): Product
    {
        $category = Category::create(['category_name' => 'Food']);

        return Product::create([
            'category_id' => $category->category_id,
            'product_name' => 'Fish Amok',
            'price' => 6.50,
            'image' => 'products/old.jpg',
        ]);
    }

    public function test_partial_update_preserves_image_and_other_fields(): void
    {
        $product = $this->product();
        $this->patchJson('/api/products/'.$product->product_id, ['price' => 7])
            ->assertOk()->assertJsonPath('data.price', '7.00');
        $this->assertSame('Fish Amok', $product->fresh()->product_name);
        $this->assertSame('products/old.jpg', $product->fresh()->image);
    }

    public function test_image_can_be_replaced_with_method_override(): void
    {
        Storage::fake('public');
        Storage::disk('public')->put('products/old.jpg', 'old image');
        $product = $this->product();
        $response = $this->post('/api/products/'.$product->product_id, [
            '_method' => 'PUT',
            'image' => UploadedFile::fake()->image('new.jpg'),
        ], ['Accept' => 'application/json']);
        $response->assertOk();
        Storage::disk('public')->assertExists($response->json('data.image'));
        Storage::disk('public')->assertMissing('products/old.jpg');
    }

    public function test_invalid_update_leaves_product_unchanged(): void
    {
        $product = $this->product();
        $this->patchJson('/api/products/'.$product->product_id, [
            'price' => -1, 'category_id' => 999,
        ])->assertUnprocessable()->assertJsonValidationErrors(['price', 'category_id']);
        $this->assertSame('6.50', $product->fresh()->price);
    }

    public function test_deleted_product_is_retained_but_hidden_and_cannot_be_updated(): void
    {
        $product = $this->product();
        $url = '/api/products/'.$product->product_id;
        $this->getJson($url)->assertOk()->assertJsonPath('data.category.category_name', 'Food');
        $this->deleteJson($url)->assertOk()->assertJsonPath('success', true);
        $this->assertTrue($product->fresh()->isDeleted);
        $this->getJson('/api/products')->assertExactJson([]);
        $this->getJson($url)->assertNotFound();
        $this->patchJson($url, ['price' => 8])->assertNotFound();
        $this->deleteJson($url)->assertNotFound();
    }

    public function test_missing_products_return_not_found(): void
    {
        $this->getJson('/api/products/999')->assertNotFound();
        $this->patchJson('/api/products/999', ['price' => 8])->assertNotFound();
        $this->deleteJson('/api/products/999')->assertNotFound();
    }
}
