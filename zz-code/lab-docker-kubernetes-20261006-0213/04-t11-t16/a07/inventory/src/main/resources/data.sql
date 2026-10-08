-- La siembra: los códigos de razón de los movimientos. ON CONFLICT DO NOTHING (lo entienden SQLite y
-- Postgres), porque corre en cada migración.
INSERT INTO reason_codes (code, description, applies_to) VALUES
    ('COUNT_DIFF',    'Diferencia encontrada en un conteo de la droguería', 'ADJUSTMENT'),
    ('DAMAGED',       'Producto averiado o vencido que sale del inventario', 'ADJUSTMENT'),
    ('TRANSFER_LOST', 'Traslado despachado que nunca llegó al destino', 'ADJUSTMENT'),
    ('ENTRY_ERROR',   'Error de digitación en una entrada anterior', 'RESTOCK,ADJUSTMENT'),
    ('THEFT',         'Faltante por hurto', 'ADJUSTMENT'),
    -- G11 (Fase 24): la compensación de la reserva de un préstamo que no siguió.
    ('LOAN_RELEASED', 'Reserva de un préstamo liberada por la saga', 'ADJUSTMENT')
ON CONFLICT (code) DO NOTHING;
