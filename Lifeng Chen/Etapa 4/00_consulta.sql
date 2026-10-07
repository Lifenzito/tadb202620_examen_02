-- Lifeng Chen | SIGAA 000215708 | MySQL 8.4 | brechas_seguridad
-- Etapa 4: historial de exposicion por codigo de usuario.
USE brechas_seguridad;

-- Puedo fijar otro codigo en esta sesion antes de ejecutar el archivo.
-- US-003386 es un ejemplo existente; no limita la consulta a ese usuario.
SET @codigo_usuario = COALESCE(@codigo_usuario, 'US-003386');

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
