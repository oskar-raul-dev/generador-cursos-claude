<?php

namespace App\Console\Commands;

use App\Models\Product;
use Illuminate\Console\Command;
use Illuminate\Support\Facades\DB;
use SoapClient;

// La sincronización nocturna: borra el catálogo y lo vuelve a traer entero de Contingencia.
class SyncCatalog extends Command
{
    protected $signature = 'catalog:sync';
    protected $description = 'Trae el catálogo de Contingencia por SOAP y reemplaza el del portal';

    public function handle(): int
    {
        $client = new SoapClient(config('services.contingencia.url'), [
            'login' => config('services.contingencia.user'),
            'password' => config('services.contingencia.password'),
            'cache_wsdl' => WSDL_CACHE_NONE,
        ]);
        $items = $client->listCatalog()->return ?? [];
        $items = is_array($items) ? $items : [$items];  // un solo producto llega como objeto
        $now = now();

        DB::transaction(function () use ($items, $now) {
            Product::query()->delete();
            foreach ($items as $item) {
                Product::create([
                    'sku' => $item->sku,
                    'name' => $item->name,
                    'category' => $item->category,
                    'price' => $item->referencePrice,
                    'synced_at' => $now,
                ]);
            }
        });

        $this->info(count($items).' productos sincronizados desde Contingencia');
        return self::SUCCESS;
    }
}
