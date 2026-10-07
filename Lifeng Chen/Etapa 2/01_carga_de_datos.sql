-- Estudiantes: Lifeng Chen - 000215708
--              Santiago Lopez - 000229668
-- Carga y normalizacion de 40.000 registros en MySQL 8.4

USE brechas_seguridad;

SET FOREIGN_KEY_CHECKS = 0;
TRUNCATE TABLE exposicion_usuario;
TRUNCATE TABLE brecha;
TRUNCATE TABLE usuario;
TRUNCATE TABLE tipo_dato;
TRUNCATE TABLE organizacion;
TRUNCATE TABLE stg_sabana;
SET FOREIGN_KEY_CHECKS = 1;

LOAD DATA INFILE '/var/lib/mysql-files/sabana_brechas_seguridad_lote_1.csv'
INTO TABLE stg_sabana
CHARACTER SET utf8mb4
FIELDS TERMINATED BY ',' OPTIONALLY ENCLOSED BY '"' ESCAPED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 LINES
(
    nombre_organizacion, sector_organizacion, pais_organizacion,
    tamano_empleados_organizacion, codigo_brecha, fecha_ocurrencia,
    fecha_deteccion, vector_ataque, severidad_incidente,
    registros_afectados_total, costo_estimado_total, codigo_usuario,
    pseudonimo_usuario, email_hash_usuario, pais_residencia_usuario,
    fecha_registro_usuario, tipo_dato_expuesto,
    categoria_sensibilidad_dato, fecha_notificacion_usuario
);

LOAD DATA INFILE '/var/lib/mysql-files/sabana_brechas_seguridad_lote_2.csv'
INTO TABLE stg_sabana
CHARACTER SET utf8mb4
FIELDS TERMINATED BY ',' OPTIONALLY ENCLOSED BY '"' ESCAPED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 LINES
(
    nombre_organizacion, sector_organizacion, pais_organizacion,
    tamano_empleados_organizacion, codigo_brecha, fecha_ocurrencia,
    fecha_deteccion, vector_ataque, severidad_incidente,
    registros_afectados_total, costo_estimado_total, codigo_usuario,
    pseudonimo_usuario, email_hash_usuario, pais_residencia_usuario,
    fecha_registro_usuario, tipo_dato_expuesto,
    categoria_sensibilidad_dato, fecha_notificacion_usuario
);

LOAD DATA INFILE '/var/lib/mysql-files/sabana_brechas_seguridad_lote_3.csv'
INTO TABLE stg_sabana
CHARACTER SET utf8mb4
FIELDS TERMINATED BY ',' OPTIONALLY ENCLOSED BY '"' ESCAPED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 LINES
(
    nombre_organizacion, sector_organizacion, pais_organizacion,
    tamano_empleados_organizacion, codigo_brecha, fecha_ocurrencia,
    fecha_deteccion, vector_ataque, severidad_incidente,
    registros_afectados_total, costo_estimado_total, codigo_usuario,
    pseudonimo_usuario, email_hash_usuario, pais_residencia_usuario,
    fecha_registro_usuario, tipo_dato_expuesto,
    categoria_sensibilidad_dato, fecha_notificacion_usuario
);

LOAD DATA INFILE '/var/lib/mysql-files/sabana_brechas_seguridad_lote_4.csv'
INTO TABLE stg_sabana
CHARACTER SET utf8mb4
FIELDS TERMINATED BY ',' OPTIONALLY ENCLOSED BY '"' ESCAPED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 LINES
(
    nombre_organizacion, sector_organizacion, pais_organizacion,
    tamano_empleados_organizacion, codigo_brecha, fecha_ocurrencia,
    fecha_deteccion, vector_ataque, severidad_incidente,
    registros_afectados_total, costo_estimado_total, codigo_usuario,
    pseudonimo_usuario, email_hash_usuario, pais_residencia_usuario,
    fecha_registro_usuario, tipo_dato_expuesto,
    categoria_sensibilidad_dato, fecha_notificacion_usuario
);

INSERT INTO organizacion (nombre, sector, pais, tamano_empleados)
SELECT DISTINCT
    nombre_organizacion,
    sector_organizacion,
    pais_organizacion,
    CAST(tamano_empleados_organizacion AS UNSIGNED)
FROM stg_sabana
ORDER BY nombre_organizacion;

INSERT INTO tipo_dato (nombre, categoria_sensibilidad)
SELECT DISTINCT tipo_dato_expuesto, categoria_sensibilidad_dato
FROM stg_sabana
ORDER BY tipo_dato_expuesto;

INSERT INTO brecha (
    codigo_brecha, id_organizacion, vector_ataque, severidad,
    fecha_ocurrencia, fecha_deteccion, registros_afectados, costo_estimado
)
SELECT DISTINCT
    s.codigo_brecha,
    o.id_organizacion,
    s.vector_ataque,
    s.severidad_incidente,
    CAST(s.fecha_ocurrencia AS DATE),
    CAST(s.fecha_deteccion AS DATE),
    CAST(s.registros_afectados_total AS UNSIGNED),
    CAST(s.costo_estimado_total AS DECIMAL(14,2))
FROM stg_sabana s
JOIN organizacion o
    ON o.nombre = s.nombre_organizacion
ORDER BY s.codigo_brecha;

INSERT INTO usuario (
    codigo_usuario, pseudonimo, email_hash, id_organizacion,
    pais_residencia, fecha_registro
)
SELECT DISTINCT
    s.codigo_usuario,
    s.pseudonimo_usuario,
    s.email_hash_usuario,
    o.id_organizacion,
    s.pais_residencia_usuario,
    CAST(s.fecha_registro_usuario AS DATE)
FROM stg_sabana s
JOIN organizacion o
    ON o.nombre = s.nombre_organizacion
ORDER BY s.codigo_usuario;

INSERT INTO exposicion_usuario (
    id_brecha, id_usuario, id_tipo_dato, fecha_notificacion
)
SELECT
    b.id_brecha,
    u.id_usuario,
    t.id_tipo_dato,
    CAST(s.fecha_notificacion_usuario AS DATE)
FROM stg_sabana s
JOIN brecha b
    ON b.codigo_brecha = s.codigo_brecha
JOIN usuario u
    ON u.codigo_usuario = s.codigo_usuario
JOIN tipo_dato t
    ON t.nombre = s.tipo_dato_expuesto;

-- Conteos definidos en el enunciado.
SELECT tabla, esperado, obtenido,
       CASE WHEN esperado = obtenido THEN 'OK' ELSE 'REVISAR' END AS resultado
FROM (
    SELECT 'organizacion' AS tabla, 60 AS esperado, COUNT(*) AS obtenido
    FROM organizacion
    UNION ALL
    SELECT 'brecha', 800, COUNT(*) FROM brecha
    UNION ALL
    SELECT 'usuario', 7887, COUNT(*) FROM usuario
    UNION ALL
    SELECT 'tipo_dato', 10, COUNT(*) FROM tipo_dato
    UNION ALL
    SELECT 'exposicion_usuario', 40000, COUNT(*) FROM exposicion_usuario
) AS conteos;

-- Verifica que cada fila de la sabana se pueda reconstruir sin perdida.
SELECT COUNT(*) AS filas_no_reconstruidas
FROM stg_sabana s
LEFT JOIN organizacion o
    ON o.nombre = s.nombre_organizacion
LEFT JOIN brecha b
    ON b.codigo_brecha = s.codigo_brecha
   AND b.id_organizacion = o.id_organizacion
LEFT JOIN usuario u
    ON u.codigo_usuario = s.codigo_usuario
   AND u.id_organizacion = o.id_organizacion
LEFT JOIN tipo_dato t
    ON t.nombre = s.tipo_dato_expuesto
   AND t.categoria_sensibilidad = s.categoria_sensibilidad_dato
LEFT JOIN exposicion_usuario e
    ON e.id_brecha = b.id_brecha
   AND e.id_usuario = u.id_usuario
   AND e.id_tipo_dato = t.id_tipo_dato
   AND e.fecha_notificacion = CAST(s.fecha_notificacion_usuario AS DATE)
WHERE e.id_brecha IS NULL;

-- Verifica la dependencia funcional usuario -> organizacion.
SELECT COUNT(*) AS usuarios_con_org_distinta_a_la_brecha
FROM exposicion_usuario e
JOIN brecha b
    ON b.id_brecha = e.id_brecha
JOIN usuario u
    ON u.id_usuario = e.id_usuario
WHERE u.id_organizacion <> b.id_organizacion;

ANALYZE TABLE organizacion, brecha, usuario, tipo_dato, exposicion_usuario;

SELECT * FROM organizacion ORDER BY id_organizacion LIMIT 5;
SELECT * FROM tipo_dato ORDER BY id_tipo_dato;
SELECT * FROM brecha ORDER BY id_brecha LIMIT 5;
SELECT * FROM usuario ORDER BY id_usuario LIMIT 5;
SELECT * FROM exposicion_usuario
ORDER BY id_brecha, id_usuario, id_tipo_dato
LIMIT 5;

