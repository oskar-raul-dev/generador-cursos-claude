<?php

declare(strict_types=1);

namespace App\Persistence\Mongo;

use App\Persistence\Cursors;
use Hex\Application\Page;
use Hex\Application\PageRequest;
use Hex\Application\Port\Products;
use Hex\Domain\Money;
use Hex\Domain\Product;
use MongoDB\Client;
use MongoDB\Collection;

/** Parte 3: el catálogo en MongoDB detrás del mismo puerto Products, con la librería oficial (no el paquete Eloquent de MongoDB). */
final readonly class MongoProducts implements Products
{
    private Collection $collection;

    public function __construct(string $url)
    {
        $client = new Client($url);
        $database = parse_url($url, PHP_URL_PATH);
        $this->collection = $client->selectCollection(ltrim($database ?: '/hex_catalog', '/'), 'products');
    }

    public function find(string $sku): ?Product
    {
        $doc = $this->collection->findOne(['_id' => $sku], ['typeMap' => ['root' => 'array', 'document' => 'array']]);

        return $doc === null ? null : self::toProduct($doc);
    }

    public function exists(string $sku): bool
    {
        return $this->collection->countDocuments(['_id' => $sku], ['limit' => 1]) > 0;
    }

    public function list(PageRequest $page): Page
    {
        $filter = [];
        $after = Cursors::decode($page->cursor);
        if ($after !== null) {
            $filter['sku'] = ['$gt' => $after];
        }
        $docs = $this->collection->find($filter, [
            'sort' => ['sku' => 1], 'limit' => $page->limit + 1, 'typeMap' => ['root' => 'array', 'document' => 'array'],
        ])->toArray();
        $more = count($docs) > $page->limit;
        $docs = array_slice($docs, 0, $page->limit);

        return new Page(array_map(self::toProduct(...), $docs), $more ? Cursors::encode(end($docs)['sku']) : null);
    }

    public function save(Product $product): void
    {
        $this->collection->updateOne(
            ['_id' => $product->sku],
            ['$set' => ['sku' => $product->sku, 'name' => $product->name,
                'unitPrice' => ['amount' => $product->unitPrice->text(), 'currency' => $product->unitPrice->currency]]],
            ['upsert' => true],
        );
    }

    /** @param array<string, mixed> $doc */
    private static function toProduct(array $doc): Product
    {
        return new Product($doc['sku'], $doc['name'], Money::parse($doc['unitPrice']['amount'], $doc['unitPrice']['currency']));
    }
}
