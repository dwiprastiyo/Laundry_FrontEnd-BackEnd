<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    /**
     * Run the migrations.
     */
    public function up(): void
    {
        Schema::create('orders', function (Blueprint $table) {
        $table->id();
        $table->foreignId('user_id')->constrained()->cascadeOnDelete();
        $table->string('service_type'); // "Cuci Basah", "Setrika", dsb
        $table->decimal('weight_kg', 8, 2)->nullable();
        $table->integer('total_price');
        $table->string('status')->default('menunggu_konfirmasi'); // menunggu_konfirmasi, dijemput, diproses, selesai
        $table->boolean('is_free_reward')->default(false); // Apakah pesanan ini pakai gratisan reward?
        $table->text('notes')->nullable(); // Catatan tambahan (parfum dll)
        $table->timestamps();
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::dropIfExists('orders');
    }
};
