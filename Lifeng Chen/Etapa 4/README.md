# Etapa 4 — Historial de exposición

**Lifeng Chen · SIGAA 000215708 · MySQL 8.4**

Consulté el historial por código de usuario: brecha, tipo de dato, sensibilidad, organización responsable y fecha de notificación. Lo ordené cronológicamente y añadí desempates por brecha y tipo de dato.

Incluí la consulta, los planes sin/con el índice de mejora, la restauración, el CSV real, las mediciones y el Word con capturas y los 20 registros del ejemplo `US-003386`, correspondientes a 12 brechas. Elegí este usuario porque tiene el mayor número de exposiciones en los datos; la consulta funciona con cualquier código.

## Cómo lo ejecuto

1. Parto de la Etapa 2 cargada y validada. En mi cliente MySQL fijo `SET @codigo_usuario = 'US-003386';` o el código que quiera revisar, y ejecuto `00_consulta.sql` en esa misma sesión.
2. Ejecuto `01_plan_sin_indices.sql`, `02_plan_con_indices.sql` y `03_restaurar_indices.sql` sobre una copia sin escrituras concurrentes, con permiso `ALTER`. Si interrumpo un script, ejecuto la restauración inmediatamente.
3. Repito las pruebas de ambas etapas con `04_verificar.py` de la Etapa 3, usando el comando indicado en su README. Las pruebas incluyen un usuario diferente y un código inexistente.

Obtuve los mismos 20 resultados antes y después. En siete pares con caché caliente, la mediana pasó de 2,05 a 0,0946 ms; el costo estimado JSON pasó de 916,00 a 24,05. El índice quedó visible. El ordenamiento final sigue presente por los desempates sobre tablas relacionadas.
