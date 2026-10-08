<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;

// Esquema de G1 y la siembra de las dos tablas de datos: categorías y códigos de razón.
return new class extends Migration
{
    public function up(): void
    {
        Schema::create('categories', function (Blueprint $table) {
            $table->string('name')->primary();
        });

        // Una tabla de datos, no un enum del contrato: se agregan códigos sin cambiar el OpenAPI.
        Schema::create('reason_codes', function (Blueprint $table) {
            $table->string('code')->primary();
            $table->string('description');
            $table->boolean('active')->default(true);
        });

        Schema::create('products', function (Blueprint $table) {
            $table->string('sku')->primary();
            $table->string('name');
            $table->string('category');
            // Un producto descontinuado no se borra: cambia de estado y guarda por qué.
            $table->string('status')->default('ACTIVE');
            $table->string('status_reason_code')->nullable();
        });

        DB::table('categories')->insert(array_map(
            fn ($name) => ['name' => $name],
            ['venta libre', 'cuidado personal', 'bebés', 'nutrición'],
        ));
        DB::table('reason_codes')->insert([
            ['code' => 'DISCONTINUED_BY_SUPPLIER', 'description' => 'El proveedor dejó de fabricarlo o de venderlo'],
            ['code' => 'SANITARY_RECALL', 'description' => 'Retiro sanitario ordenado por el INVIMA'],
            ['code' => 'LOW_ROTATION', 'description' => 'Baja rotación en las droguerías'],
            ['code' => 'REPLACED', 'description' => 'Reemplazado por otra presentación'],
        ]);
    }

    public function down(): void
    {
        Schema::dropIfExists('products');
        Schema::dropIfExists('reason_codes');
        Schema::dropIfExists('categories');
    }
};
