-- Estudiantes: Lifeng Chen - 000215708
--              Santiago Lopez - 000229668
-- Implementacion para MySQL 8.4

USE brechas_seguridad;

DROP PROCEDURE IF EXISTS pr_poblar_modelo;

DELIMITER $$

CREATE PROCEDURE pr_poblar_modelo()
MODIFIES SQL DATA
BEGIN
    IF EXISTS (SELECT 1 FROM organizacion LIMIT 1)
       OR EXISTS (SELECT 1 FROM exposicion_usuario LIMIT 1) THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'El modelo ya contiene datos; el procedimiento solo se usa con las tablas vacias.';
    END IF;

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
END$$

DELIMITER ;

