<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

// El catálogo propio del portal: una copia que se reemplaza cada noche desde Contingencia.
return new class extends Migration
{
    public function up(): void
    {
        Schema::create('products', function (Blueprint $table) {
            $table->string('sku')->primary();
            $table->string('name');
            $table->string('category');
            $table->unsignedInteger('price');
            $table->timestamp('synced_at');
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('products');
    }
};
