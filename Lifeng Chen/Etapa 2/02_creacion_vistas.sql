-- Estudiantes: Lifeng Chen - 000215708
--              Santiago Lopez - 000229668
-- Implementacion para MySQL 8.4

USE brechas_seguridad;

CREATE OR REPLACE VIEW v_exposicion_detalle AS
SELECT
    u.codigo_usuario,
    b.codigo_brecha,
    o.nombre AS organizacion,
    b.vector_ataque,
    b.severidad,
    b.fecha_ocurrencia,
    b.fecha_deteccion,
    t.nombre AS tipo_dato,
    t.categoria_sensibilidad,
    e.fecha_notificacion
FROM exposicion_usuario e
JOIN usuario u
    ON u.id_usuario = e.id_usuario
JOIN brecha b
    ON b.id_brecha = e.id_brecha
JOIN organizacion o
    ON o.id_organizacion = b.id_organizacion
JOIN tipo_dato t
    ON t.id_tipo_dato = e.id_tipo_dato;

