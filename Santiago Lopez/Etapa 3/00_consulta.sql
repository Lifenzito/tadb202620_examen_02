--NOMBRE:   lifeng chen
--ID:       215708
--NOMBRE:   Santiago Lopez
--ID:       229668
-- MySQL 8.4 | brechas_seguridad
-- Etapa 3: brechas criticas del ultimo anio disponible.
USE brechas_seguridad;

-- Intervalo cerrado: desde doce meses antes de MAX(fecha_deteccion)
-- hasta esa fecha maxima. No uso la fecha del reloj del servidor.
SET @fecha_final = (SELECT MAX(fecha_deteccion) FROM brecha);
SET @fecha_inicio = DATE_SUB(@fecha_final, INTERVAL 12 MONTH);

SELECT
    o.nombre AS organizacion,
    b.codigo_brecha,
    b.fecha_deteccion,
    b.vector_ataque,
    COUNT(DISTINCT e.id_usuario) AS usuarios_afectados
FROM brecha b
JOIN organizacion o ON o.id_organizacion = b.id_organizacion
JOIN exposicion_usuario e ON e.id_brecha = b.id_brecha
WHERE b.fecha_deteccion BETWEEN @fecha_inicio AND @fecha_final
  AND b.severidad IN ('Alta', 'Critica')
  AND EXISTS (
      SELECT 1
      FROM exposicion_usuario ec
      JOIN tipo_dato t ON t.id_tipo_dato = ec.id_tipo_dato
      WHERE ec.id_brecha = b.id_brecha
        AND t.categoria_sensibilidad = 'Critica'
  )
GROUP BY b.id_brecha, o.nombre, b.codigo_brecha,
         b.fecha_deteccion, b.vector_ataque
ORDER BY usuarios_afectados DESC, b.codigo_brecha ASC;
