--NOMBRE:   Santiago Lopez
--ID:       229668
--NOMBRE:   lifeng chen
--ID:       215708

 
-- 1. Dejar limpio el ambiente (el script se puede re-ejecutar) --------
TRUNCATE exposicion_usuario, brecha, usuario, tipo_dato, organizacion, stg_sabana
    RESTART IDENTITY CASCADE;
-- 3. Repartir la sábana en las 5 tablas (en orden de dependencia) -----
-- 3.1 organizacion
INSERT INTO organizacion (nombre, sector, pais, tamano_empleados)
SELECT DISTINCT nombre_organizacion, sector_organizacion,
                pais_organizacion, tamano_empleados_organizacion::INTEGER
FROM   stg_sabana
ORDER  BY 1;
 
-- 3.2 tipo_dato
INSERT INTO tipo_dato (nombre, categoria_sensibilidad)
SELECT DISTINCT tipo_dato_expuesto, categoria_sensibilidad_dato
FROM   stg_sabana
ORDER  BY 1;
 
-- 3.3 brecha
INSERT INTO brecha (codigo_brecha, id_organizacion, vector_ataque, severidad,
                    fecha_ocurrencia, fecha_deteccion,
                    registros_afectados, costo_estimado)
SELECT DISTINCT s.codigo_brecha, o.id_organizacion, s.vector_ataque,
       s.severidad_incidente, s.fecha_ocurrencia::DATE, s.fecha_deteccion::DATE,
       s.registros_afectados_total::INTEGER, s.costo_estimado_total::NUMERIC(14,2)
FROM   stg_sabana s
JOIN   organizacion o ON o.nombre = s.nombre_organizacion
ORDER  BY 1;
 
-- 3.4 usuario
INSERT INTO usuario (codigo_usuario, pseudonimo, email_hash, id_organizacion,
                     pais_residencia, fecha_registro)
SELECT DISTINCT s.codigo_usuario, s.pseudonimo_usuario, s.email_hash_usuario,
       o.id_organizacion, s.pais_residencia_usuario, s.fecha_registro_usuario::DATE
FROM   stg_sabana s
JOIN   organizacion o ON o.nombre = s.nombre_organizacion
ORDER  BY 1;
 
-- 3.5 exposicion_usuario (tabla puente)
INSERT INTO exposicion_usuario (id_brecha, id_usuario, id_tipo_dato, fecha_notificacion)
SELECT b.id_brecha, u.id_usuario, t.id_tipo_dato, s.fecha_notificacion_usuario::DATE
FROM   stg_sabana s
JOIN   brecha    b ON b.codigo_brecha  = s.codigo_brecha
JOIN   usuario   u ON u.codigo_usuario = s.codigo_usuario
JOIN   tipo_dato t ON t.nombre         = s.tipo_dato_expuesto;
 
-- 4. VALIDACIÓN: conteos esperados vs obtenidos -----------------------
SELECT tabla, esperado, obtenido,
       CASE WHEN esperado = obtenido THEN 'OK' ELSE 'REVISAR' END AS resultado
FROM (
    SELECT 'organizacion'       AS tabla,    60 AS esperado, COUNT(*) AS obtenido FROM organizacion
    UNION ALL SELECT 'brecha',               800, COUNT(*) FROM brecha
    UNION ALL SELECT 'usuario',             7887, COUNT(*) FROM usuario
    UNION ALL SELECT 'tipo_dato',             10, COUNT(*) FROM tipo_dato
    UNION ALL SELECT 'exposicion_usuario', 40000, COUNT(*) FROM exposicion_usuario
) x;
 
-- 5. VALIDACIÓN: reconstruir la sábana desde el modelo y compararla ---
--    Si la normalización no perdió información, ambos conteos son 0.
WITH original AS (
    SELECT codigo_brecha, codigo_usuario, tipo_dato_expuesto AS tipo_dato,
           nombre_organizacion AS organizacion, severidad_incidente AS severidad,
           vector_ataque, categoria_sensibilidad_dato AS categoria,
           fecha_deteccion::DATE AS fecha_deteccion,
           fecha_notificacion_usuario::DATE AS fecha_notificacion
    FROM stg_sabana
),
reconstruida AS (
    SELECT b.codigo_brecha, u.codigo_usuario, t.nombre AS tipo_dato,
           o.nombre AS organizacion, b.severidad, b.vector_ataque,
           t.categoria_sensibilidad AS categoria,
           b.fecha_deteccion, e.fecha_notificacion
    FROM   exposicion_usuario e
    JOIN   brecha       b ON b.id_brecha       = e.id_brecha
    JOIN   usuario      u ON u.id_usuario      = e.id_usuario
    JOIN   tipo_dato    t ON t.id_tipo_dato    = e.id_tipo_dato
    JOIN   organizacion o ON o.id_organizacion = b.id_organizacion
)
SELECT (SELECT COUNT(*) FROM (SELECT * FROM original      EXCEPT SELECT * FROM reconstruida) a) AS en_sabana_y_no_en_modelo,
       (SELECT COUNT(*) FROM (SELECT * FROM reconstruida  EXCEPT SELECT * FROM original)     b) AS en_modelo_y_no_en_sabana;
 
-- 6. VALIDACIÓN: cada usuario pertenece a la organización de la brecha
SELECT COUNT(*) AS usuarios_con_org_distinta_a_la_brecha    -- esperado: 0
FROM   exposicion_usuario e
JOIN   brecha  b ON b.id_brecha  = e.id_brecha
JOIN   usuario u ON u.id_usuario = e.id_usuario
WHERE  u.id_organizacion <> b.id_organizacion;
 
-- 7. Limpiar la tabla auxiliar y actualizar estadísticas --------------
TRUNCATE stg_sabana;
ANALYZE organizacion;
ANALYZE brecha;
ANALYZE usuario;
ANALYZE tipo_dato;
ANALYZE exposicion_usuario;
 
-- 8. Vistazo rápido a los datos ---------------------------------------
SELECT * FROM organizacion       ORDER BY id_organizacion LIMIT 5;
SELECT * FROM tipo_dato          ORDER BY id_tipo_dato;
SELECT * FROM brecha             ORDER BY id_brecha LIMIT 5;
SELECT * FROM usuario            ORDER BY id_usuario LIMIT 5;
SELECT * FROM exposicion_usuario ORDER BY id_brecha, id_usuario, id_tipo_dato LIMIT 5;