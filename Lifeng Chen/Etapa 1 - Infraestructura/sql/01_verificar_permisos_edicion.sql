-- Estudiante: Lifeng Chen
-- ID SIGAA: 000215708
-- Ejecutar conectado como lifenzito sobre la base Distri_Cold.
-- La tabla es temporal y desaparece al cerrar la sesion.

SELECT CURRENT_USER() AS usuario_conectado, DATABASE() AS base_activa;
SHOW GRANTS FOR CURRENT_USER();

CREATE TEMPORARY TABLE prueba_permisos_etapa_1 (
    id INT PRIMARY KEY,
    descripcion VARCHAR(100) NOT NULL
);

INSERT INTO prueba_permisos_etapa_1 (id, descripcion)
VALUES (1, 'permiso de insercion correcto');

UPDATE prueba_permisos_etapa_1
SET descripcion = 'permiso de actualizacion correcto'
WHERE id = 1;

SELECT * FROM prueba_permisos_etapa_1;

DELETE FROM prueba_permisos_etapa_1
WHERE id = 1;

DROP TEMPORARY TABLE prueba_permisos_etapa_1;

