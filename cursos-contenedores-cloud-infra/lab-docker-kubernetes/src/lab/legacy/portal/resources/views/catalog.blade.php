<!doctype html>
<html lang="es">
<head>
    <meta charset="utf-8">
    <title>Droguerías La Vecina · Portal de Pedidos y Ventas Web</title>
    <style>
        body { font-family: sans-serif; margin: 2rem; color: #1f2937; }
        table { border-collapse: collapse; }
        th, td { padding: .4rem .8rem; border-bottom: 1px solid #e5e7eb; text-align: left; }
        td.price { text-align: right; }
    </style>
</head>
<body>
    <h1>Droguerías La Vecina</h1>
    <p>Siempre llega. Catálogo sincronizado: {{ $syncedAt ? $syncedAt->format('d/m/Y H:i') : 'nunca' }}</p>
    <table>
        <thead><tr><th>Código</th><th>Producto</th><th>Categoría</th><th>Precio</th></tr></thead>
        <tbody>
        @forelse ($products as $product)
            <tr>
                <td>{{ $product->sku }}</td>
                <td>{{ $product->name }}</td>
                <td>{{ $product->category }}</td>
                <td class="price">$ {{ number_format($product->price, 0, ',', '.') }}</td>
            </tr>
        @empty
            <tr><td colspan="4">El catálogo todavía no se ha sincronizado.</td></tr>
        @endforelse
        </tbody>
    </table>
</body>
</html>
