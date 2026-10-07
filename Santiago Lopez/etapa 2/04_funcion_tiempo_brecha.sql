CREATE OR REPLACE FUNCTION fn_dias_hasta_deteccion(p_codigo_brecha VARCHAR)
RETURNS INTEGER
LANGUAGE sql STABLE
AS $$
    SELECT (b.fecha_deteccion - b.fecha_ocurrencia)
    FROM   brecha b
    WHERE  b.codigo_brecha = p_codigo_brecha;
$$;