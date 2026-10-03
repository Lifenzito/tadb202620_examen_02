-- Estudiante: Lifeng Chen
-- ID SIGAA: 000215708
-- Ejecutar como root. El usuario lifenzito es creado por docker-compose.

REVOKE IF EXISTS
    ALTER,
    ALTER ROUTINE,
    CREATE,
    CREATE ROUTINE,
    CREATE TEMPORARY TABLES,
    CREATE VIEW,
    DROP,
    EVENT,
    EXECUTE,
    INDEX,
    LOCK TABLES,
    REFERENCES,
    SHOW VIEW,
    TRIGGER
ON `Distri_Cold`.*
FROM 'lifenzito'@'%';

REVOKE IF EXISTS GRANT OPTION
ON `Distri_Cold`.*
FROM 'lifenzito'@'%';

GRANT
    SELECT,
    INSERT,
    UPDATE,
    DELETE,
    CREATE TEMPORARY TABLES
ON `Distri_Cold`.*
TO 'lifenzito'@'%';

SHOW GRANTS FOR 'lifenzito'@'%';

