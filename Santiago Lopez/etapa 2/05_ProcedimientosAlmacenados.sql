CREATE OR REPLACE PROCEDURE pr_poblar_modelo()
LANGUAGE plpgsql
AS $$
BEGIN
    IF EXISTS (SELECT 1 FROM organizacion) OR EXISTS (SELECT 1 FROM exposicion_usuario) THEN
        RAISE EXCEPTION 'El modelo ya contiene datos; pr_poblar_modelo solo se usa con las tablas vacías.';
    END IF;
 
    INSERT INTO organizacion (nombre, sector, pais, tamano_empleados)
    SELECT DISTINCT nombre_organizacion, sector_organizacion,
                    pais_organizacion, tamano_empleados_organizacion::INTEGER
    FROM   stg_sabana
    ORDER  BY 1;
 
    INSERT INTO tipo_dato (nombre, categoria_sensibilidad)
    SELECT DISTINCT tipo_dato_expuesto, categoria_sensibilidad_dato
    FROM   stg_sabana
    ORDER  BY 1;
 
    INSERT INTO brecha (codigo_brecha, id_organizacion, vector_ataque, severidad,
                        fecha_ocurrencia, fecha_deteccion,
                        registros_afectados, costo_estimado)
    SELECT DISTINCT s.codigo_brecha, o.id_organizacion, s.vector_ataque,
           s.severidad_incidente, s.fecha_ocurrencia::DATE, s.fecha_deteccion::DATE,
           s.registros_afectados_total::INTEGER, s.costo_estimado_total::NUMERIC(14,2)
    FROM   stg_sabana s
    JOIN   organizacion o ON o.nombre = s.nombre_organizacion
    ORDER  BY 1;
 
    INSERT INTO usuario (codigo_usuario, pseudonimo, email_hash, id_organizacion,
                         pais_residencia, fecha_registro)
    SELECT DISTINCT s.codigo_usuario, s.pseudonimo_usuario, s.email_hash_usuario,
           o.id_organizacion, s.pais_residencia_usuario, s.fecha_registro_usuario::DATE
    FROM   stg_sabana s
    JOIN   organizacion o ON o.nombre = s.nombre_organizacion
    ORDER  BY 1;
 
    INSERT INTO exposicion_usuario (id_brecha, id_usuario, id_tipo_dato, fecha_notificacion)
    SELECT b.id_brecha, u.id_usuario, t.id_tipo_dato, s.fecha_notificacion_usuario::DATE
    FROM   stg_sabana s
    JOIN   brecha    b ON b.codigo_brecha  = s.codigo_brecha
    JOIN   usuario   u ON u.codigo_usuario = s.codigo_usuario
    JOIN   tipo_dato t ON t.nombre         = s.tipo_dato_expuesto;
END
$$;