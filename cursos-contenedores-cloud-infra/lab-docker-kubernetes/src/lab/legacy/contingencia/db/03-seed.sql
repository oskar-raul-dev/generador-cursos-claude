-- Datos iniciales del laboratorio: pocos, pero con nombres de la casa.
INSERT INTO store (id, name, city) VALUES
  ('DRO-001', 'La Vecina Cabecera',      'Bucaramanga'),
  ('DRO-002', 'La Vecina Cañaveral',     'Floridablanca'),
  ('DRO-003', 'La Vecina Girón Centro',  'Girón'),
  ('DRO-004', 'La Vecina Plaza Real',    'Tunja'),
  ('DRO-005', 'La Vecina Sogamoso',      'Sogamoso'),
  ('DRO-006', 'La Vecina Duitama',       'Duitama'),
  ('DRO-007', 'La Vecina Chapinero',     'Bogotá'),
  ('DRO-008', 'La Vecina Chía',          'Chía');

INSERT INTO product (sku, name, category) VALUES
  ('SKU-0001', 'Acetaminofén 500 mg x 10 tabletas', 'venta libre'),
  ('SKU-0002', 'Ibuprofeno 400 mg x 10 tabletas',   'venta libre'),
  ('SKU-0003', 'Salbutamol inhalador 100 mcg',       'venta libre'),
  ('SKU-0004', 'Loratadina 10 mg x 10 tabletas',     'venta libre'),
  ('SKU-0005', 'Suero oral sabor coco 500 ml',       'nutrición'),
  ('SKU-0006', 'Pañales etapa 3 x 30',               'bebés'),
  ('SKU-0007', 'Protector solar FPS 50 120 ml',      'cuidado personal'),
  ('SKU-0008', 'Alcohol antiséptico 700 ml',         'cuidado personal');

-- El mismo precio de lista en todas las droguerías, salvo Bogotá, que tiene otro flete.
INSERT INTO price (sku, store_id, amount)
SELECT p.sku, s.id,
       CASE p.sku WHEN 'SKU-0001' THEN 4500  WHEN 'SKU-0002' THEN 6900
                  WHEN 'SKU-0003' THEN 21900 WHEN 'SKU-0004' THEN 8500
                  WHEN 'SKU-0005' THEN 7200  WHEN 'SKU-0006' THEN 52900
                  WHEN 'SKU-0007' THEN 48500 ELSE 12900 END
       + CASE WHEN s.city IN ('Bogotá', 'Chía') THEN 300 ELSE 0 END
  FROM product p CROSS JOIN store s;

INSERT INTO stock_level (store_id, sku, quantity, reorder_threshold)
SELECT s.id, p.sku, 20 + (ascii(right(s.id, 1)) + ascii(right(p.sku, 1))) % 30, 8
  FROM product p CROSS JOIN store s;

INSERT INTO rider (name, plate) VALUES
  ('Jhon Fredy Ardila', 'BUC12F'),
  ('Yeison Patiño',  'BUC48G'),
  ('Camilo Quintero','BOG31H'),
  ('Diana Garzón',   'BOG77K');

INSERT INTO dispatch (store_id, address, status) VALUES
  ('DRO-001', 'Calle 48 # 33-21, Cabecera',        'PENDING'),
  ('DRO-007', 'Carrera 13 # 57-40, Chapinero',     'PENDING'),
  ('DRO-008', 'Avenida Pradilla # 9-15, Chía',     'PENDING');
