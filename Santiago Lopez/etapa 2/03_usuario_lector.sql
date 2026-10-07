DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'brechas_lector') THEN
        CREATE ROLE brechas_lector LOGIN PASSWORD 'Lector_Brechas_2026'
            NOSUPERUSER NOCREATEDB NOCREATEROLE;
    END IF;
END
$$;
 
DO $$
BEGIN
    EXECUTE format('GRANT CONNECT ON DATABASE %I TO brechas_lector', current_database());
END
$$;
 
GRANT USAGE ON SCHEMA public TO brechas_lector;

REVOKE EXECUTE ON FUNCTION  fn_dias_hasta_deteccion(VARCHAR) FROM PUBLIC;
REVOKE EXECUTE ON PROCEDURE pr_poblar_modelo()               FROM PUBLIC;
 
GRANT SELECT ON organizacion, tipo_dato, brecha, usuario,
                exposicion_usuario, v_exposicion_detalle
    TO brechas_lector;
GRANT EXECUTE ON FUNCTION fn_dias_hasta_deteccion(VARCHAR) TO brechas_lector;
-- brechas_lector NO recibe ningún privilegio sobre stg_sabana ni sobre
-- pr_poblar_modelo().