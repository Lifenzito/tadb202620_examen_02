-- Estudiantes: Lifeng Chen - 000215708
--              Santiago Lopez - 000229668
-- Implementacion para MySQL 8.4

USE brechas_seguridad;

DROP FUNCTION IF EXISTS fn_dias_hasta_deteccion;

DELIMITER $$

CREATE FUNCTION fn_dias_hasta_deteccion(p_codigo_brecha VARCHAR(10))
RETURNS INT
DETERMINISTIC
READS SQL DATA
BEGIN
    DECLARE v_dias INT;

    SELECT DATEDIFF(b.fecha_deteccion, b.fecha_ocurrencia)
    INTO v_dias
    FROM brecha b
    WHERE b.codigo_brecha = p_codigo_brecha;

    RETURN v_dias;
END$$

DELIMITER ;

