-- Estudiante: Lifeng Chen
-- ID SIGAA: 000215708
-- Motor: MySQL 8.4

SELECT
    VERSION() AS version_mysql,
    DATABASE() AS base_activa,
    CURRENT_USER() AS usuario_conectado,
    @@hostname AS servidor,
    @@port AS puerto_mysql;

SHOW DATABASES;
SHOW GRANTS FOR CURRENT_USER();

