-- Lifeng Chen | SIGAA 000215708 | MySQL 8.4 | Etapa 4
-- Comparo la misma consulta; conservo PK, UNIQUE y restricciones FK.
-- Ejecuto en una copia de pruebas sin escrituras concurrentes.
-- Si interrumpo el archivo, ejecuto 03_restaurar_indices.sql.
USE brechas_seguridad;
SET @optimizer_previo = @@SESSION.optimizer_switch;
SET SESSION optimizer_switch = 'use_invisible_indexes=off';
ALTER TABLE exposicion_usuario ALTER INDEX ix_exposicion_usuario_fecha VISIBLE;
SET @codigo_usuario = COALESCE(@codigo_usuario, 'US-003386');


SELECT DISTINCT TABLE_NAME, INDEX_NAME, IS_VISIBLE
FROM information_schema.STATISTICS
WHERE TABLE_SCHEMA = 'brechas_seguridad'
ORDER BY TABLE_NAME, INDEX_NAME;

EXPLAIN FORMAT=JSON
SELECT
    u.codigo_usuario,
    b.codigo_brecha,
    t.nombre AS tipo_dato,
    t.categoria_sensibilidad,
    o.nombre AS organizacion,
    e.fecha_notificacion
FROM usuario u
JOIN exposicion_usuario e ON e.id_usuario = u.id_usuario
JOIN brecha b ON b.id_brecha = e.id_brecha
JOIN tipo_dato t ON t.id_tipo_dato = e.id_tipo_dato
JOIN organizacion o ON o.id_organizacion = b.id_organizacion
WHERE u.codigo_usuario = @codigo_usuario
ORDER BY e.fecha_notificacion ASC, b.codigo_brecha ASC, t.nombre ASC;

EXPLAIN ANALYZE FORMAT=TREE
SELECT
    u.codigo_usuario,
    b.codigo_brecha,
    t.nombre AS tipo_dato,
    t.categoria_sensibilidad,
    o.nombre AS organizacion,
    e.fecha_notificacion
FROM usuario u
JOIN exposicion_usuario e ON e.id_usuario = u.id_usuario
JOIN brecha b ON b.id_brecha = e.id_brecha
JOIN tipo_dato t ON t.id_tipo_dato = e.id_tipo_dato
JOIN organizacion o ON o.id_organizacion = b.id_organizacion
WHERE u.codigo_usuario = @codigo_usuario
ORDER BY e.fecha_notificacion ASC, b.codigo_brecha ASC, t.nombre ASC;

ALTER TABLE exposicion_usuario ALTER INDEX ix_exposicion_usuario_fecha VISIBLE;
SET SESSION optimizer_switch = @optimizer_previo;
