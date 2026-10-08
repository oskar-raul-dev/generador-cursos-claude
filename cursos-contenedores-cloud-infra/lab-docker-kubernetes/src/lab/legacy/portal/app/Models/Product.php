<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class Product extends Model
{
    protected $primaryKey = 'sku';
    public $incrementing = false;
    protected $keyType = 'string';
    public $timestamps = false;
    protected $fillable = ['sku', 'name', 'category', 'price', 'synced_at'];
    protected $casts = ['synced_at' => 'datetime'];
}
