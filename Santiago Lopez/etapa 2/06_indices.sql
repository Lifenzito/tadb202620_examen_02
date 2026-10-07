-- Búsqueda de brechas por rango de fecha de detección y severidad
CREATE INDEX IF NOT EXISTS ix_brecha_deteccion_severidad
    ON brecha (fecha_deteccion, severidad);
 
-- Acceso desde un tipo de dato hacia sus exposiciones y brechas
CREATE INDEX IF NOT EXISTS ix_exposicion_tipo_brecha_usuario
    ON exposicion_usuario (id_tipo_dato, id_brecha, id_usuario);
 
-- Exposiciones de un usuario ordenadas por fecha de notificación
CREATE INDEX IF NOT EXISTS ix_exposicion_usuario_fecha
    ON exposicion_usuario (id_usuario, fecha_notificacion)
    INCLUDE (id_brecha, id_tipo_dato);
 
-- Índices sobre las FK hacia organizacion
CREATE INDEX IF NOT EXISTS ix_brecha_organizacion  ON brecha  (id_organizacion);
CREATE INDEX IF NOT EXISTS ix_usuario_organizacion ON usuario (id_organizacion);
 