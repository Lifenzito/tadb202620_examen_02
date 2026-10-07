--NOMBRE:   lifeng chen
--ID:       215708
--NOMBRE:   Santiago Lopez
--ID:       229668
-- | MySQL 8.4 | Etapa 3
-- Comparo la misma consulta; conservo PK, UNIQUE y restricciones FK.
-- Ejecuto en una copia de pruebas sin escrituras concurrentes.
-- Si interrumpo el archivo, ejecuto 03_restaurar_indices.sql.
USE brechas_seguridad;
SET @optimizer_previo = @@SESSION.optimizer_switch;
SET SESSION optimizer_switch = 'use_invisible_indexes=off';
ALTER TABLE brecha ALTER INDEX ix_brecha_deteccion_severidad VISIBLE;
ALTER TABLE exposicion_usuario ALTER INDEX ix_exposicion_tipo_brecha_usuario VISIBLE;
SET @fecha_final = (SELECT MAX(fecha_deteccion) FROM brecha);
SET @fecha_inicio = DATE_SUB(@fecha_final, INTERVAL 12 MONTH);


SELECT DISTINCT TABLE_NAME, INDEX_NAME, IS_VISIBLE
FROM information_schema.STATISTICS
WHERE TABLE_SCHEMA = 'brechas_seguridad'
ORDER BY TABLE_NAME, INDEX_NAME;

EXPLAIN FORMAT=JSON
SELECT
    o.nombre AS organizacion,
    b.codigo_brecha,
    b.fecha_deteccion,
    b.vector_ataque,
    COUNT(DISTINCT e.id_usuario) AS usuarios_afectados
FROM brecha b
JOIN organizacion o ON o.id_organizacion = b.id_organizacion
JOIN exposicion_usuario e ON e.id_brecha = b.id_brecha
WHERE b.fecha_deteccion BETWEEN @fecha_inicio AND @fecha_final
  AND b.severidad IN ('Alta', 'Critica')
  AND EXISTS (
      SELECT 1
      FROM exposicion_usuario ec
      JOIN tipo_dato t ON t.id_tipo_dato = ec.id_tipo_dato
      WHERE ec.id_brecha = b.id_brecha
        AND t.categoria_sensibilidad = 'Critica'
  )
GROUP BY b.id_brecha, o.nombre, b.codigo_brecha,
         b.fecha_deteccion, b.vector_ataque
ORDER BY usuarios_afectados DESC, b.codigo_brecha ASC;

EXPLAIN ANALYZE FORMAT=TREE
SELECT
    o.nombre AS organizacion,
    b.codigo_brecha,
    b.fecha_deteccion,
    b.vector_ataque,
    COUNT(DISTINCT e.id_usuario) AS usuarios_afectados
FROM brecha b
JOIN organizacion o ON o.id_organizacion = b.id_organizacion
JOIN exposicion_usuario e ON e.id_brecha = b.id_brecha
WHERE b.fecha_deteccion BETWEEN @fecha_inicio AND @fecha_final
  AND b.severidad IN ('Alta', 'Critica')
  AND EXISTS (
      SELECT 1
      FROM exposicion_usuario ec
      JOIN tipo_dato t ON t.id_tipo_dato = ec.id_tipo_dato
      WHERE ec.id_brecha = b.id_brecha
        AND t.categoria_sensibilidad = 'Critica'
  )
GROUP BY b.id_brecha, o.nombre, b.codigo_brecha,
         b.fecha_deteccion, b.vector_ataque
ORDER BY usuarios_afectados DESC, b.codigo_brecha ASC;

ALTER TABLE brecha ALTER INDEX ix_brecha_deteccion_severidad VISIBLE;
ALTER TABLE exposicion_usuario ALTER INDEX ix_exposicion_tipo_brecha_usuario VISIBLE;
SET SESSION optimizer_switch = @optimizer_previo;
