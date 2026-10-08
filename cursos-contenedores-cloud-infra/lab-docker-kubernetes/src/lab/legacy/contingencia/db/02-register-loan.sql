-- El préstamo entre droguerías, portado a mano del PL/SQL del central en 2016.
-- Descuenta en el origen y deja la reposición pendiente; el destino suma cuando llega la moto.
CREATE OR REPLACE FUNCTION register_loan(p_sku VARCHAR, p_origin VARCHAR, p_destination VARCHAR,
                                         p_quantity INTEGER)
RETURNS BIGINT
LANGUAGE plpgsql
AS $$
DECLARE
    v_available INTEGER;
    v_order_id  BIGINT;
BEGIN
    -- En Oracle esto era un SELECT ... FOR UPDATE con NVL; aquí COALESCE hace el mismo trabajo.
    SELECT COALESCE(quantity, 0) INTO v_available
      FROM stock_level
     WHERE store_id = p_origin AND sku = p_sku
       FOR UPDATE;

    IF v_available IS NULL OR v_available < p_quantity THEN
        RAISE EXCEPTION 'La droguería % no tiene % unidades de %', p_origin, p_quantity, p_sku;
    END IF;

    UPDATE stock_level SET quantity = quantity - p_quantity
     WHERE store_id = p_origin AND sku = p_sku;

    INSERT INTO stock_movement (store_id, sku, type, quantity)
    VALUES (p_origin, p_sku, 'LOAN_OUT', p_quantity);

    INSERT INTO replenishment_order (sku, origin_store_id, destination_store_id, quantity, status)
    VALUES (p_sku, p_origin, p_destination, p_quantity, 'PENDING')
    RETURNING id INTO v_order_id;

    RETURN v_order_id;
END;
$$;
