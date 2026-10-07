-- Estudiantes: Lifeng Chen - 000215708
--              Santiago Lopez - 000229668
-- Sustituir la contrasena de ejemplo localmente antes de ejecutar.
-- La contrasena real no se publica en GitHub.

USE brechas_seguridad;

CREATE USER IF NOT EXISTS 'brechas_lector'@'%'
    IDENTIFIED BY 'REEMPLAZAR_CONTRASENA_LOCAL';

GRANT SELECT ON brechas_seguridad.organizacion
    TO 'brechas_lector'@'%';
GRANT SELECT ON brechas_seguridad.tipo_dato
    TO 'brechas_lector'@'%';
GRANT SELECT ON brechas_seguridad.brecha
    TO 'brechas_lector'@'%';
GRANT SELECT ON brechas_seguridad.usuario
    TO 'brechas_lector'@'%';
GRANT SELECT ON brechas_seguridad.exposicion_usuario
    TO 'brechas_lector'@'%';
GRANT SELECT ON brechas_seguridad.v_exposicion_detalle
    TO 'brechas_lector'@'%';

GRANT EXECUTE ON FUNCTION brechas_seguridad.fn_dias_hasta_deteccion
    TO 'brechas_lector'@'%';

SHOW GRANTS FOR 'brechas_lector'@'%';

