--NOMBRE:   lifeng chen
--ID:       215708
--NOMBRE:   Santiago Lopez
--ID:       229668
-- | MySQL 8.4
USE brechas_seguridad;
ALTER TABLE exposicion_usuario ALTER INDEX ix_exposicion_usuario_fecha VISIBLE;

SELECT DISTINCT TABLE_NAME, INDEX_NAME, IS_VISIBLE
FROM information_schema.STATISTICS
WHERE TABLE_SCHEMA = 'brechas_seguridad'
ORDER BY TABLE_NAME, INDEX_NAME;
