-- Estudiantes: Lifeng Chen - 000215708
--              Santiago Lopez - 000229668
-- Implementacion para MySQL 8.4

USE brechas_seguridad;

-- Consulta de la Etapa 3: igualdad por severidad y rango de deteccion.
-- En MySQL conviene ubicar primero la columna filtrada por igualdad y
-- despues la columna que recibe el rango de fechas.
CREATE INDEX ix_brecha_deteccion_severidad
    ON brecha (severidad, fecha_deteccion, id_organizacion, id_brecha);

-- Acceso desde sensibilidad/tipo de dato hacia brechas y usuarios.
CREATE INDEX ix_exposicion_tipo_brecha_usuario
    ON exposicion_usuario (id_tipo_dato, id_brecha, id_usuario);

-- Consulta de la Etapa 4: historial cronologico de un usuario.
-- MySQL no usa INCLUDE; las columnas adicionales forman un indice cubriente.
CREATE INDEX ix_exposicion_usuario_fecha
    ON exposicion_usuario
       (id_usuario, fecha_notificacion, id_brecha, id_tipo_dato);

-- No se duplican los indices de id_organizacion porque InnoDB crea
-- automaticamente los indices de soporte requeridos por las claves foraneas.
