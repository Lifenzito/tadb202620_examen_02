# Etapa 3 — Brechas críticas

**Lifeng Chen · SIGAA 000215708 · MySQL 8.4**

Identifiqué las brechas de severidad Alta o Critica con algún dato de sensibilidad Critica. Conté todos sus usuarios distintos, no solo los del dato crítico. Tomé el intervalo inclusivo del 22/09/2025 al 22/09/2026: doce meses antes de la fecha máxima de detección disponible.

Incluí la consulta, dos scripts de planes, la restauración de índices, las pruebas reproducibles, las salidas reales en `evidencias/` y el documento Word con capturas y los 109 registros resultantes.

## Cómo lo ejecuto

1. Cargo los cuatro CSV y ejecuto la Etapa 2 en el orden de su README: `00`, `01`, `02`, `04`, `05`, `06`, `03`. No repito la carga sobre tablas pobladas.
2. En mi cliente MySQL ejecuto `00_consulta.sql`, `01_plan_sin_indices.sql`, `02_plan_con_indices.sql` y `03_restaurar_indices.sql`, en ese orden. Comparo en una copia sin escrituras concurrentes; necesito permiso `ALTER` para la visibilidad. Si interrumpo una medición, ejecuto inmediatamente `03_restaurar_indices.sql`.
3. Para repetir las pruebas de ambas etapas desde la raíz del repositorio, con Python 3 y Docker disponibles, uso:

```bash
python3 "Lifeng Chen/Etapa 3/04_verificar.py" \
  --container mysql-cadena-frio --salida "$HOME/pruebas-brechas"
```

El contenedor debe tener `MYSQL_ROOT_PASSWORD` configurada; el script la lee dentro del contenedor sin imprimirla. La salida nueva no reemplaza las capturas ni el Word de esta corrida.

Obtuve los mismos 109 resultados antes y después. En siete pares con caché caliente, la mediana pasó de 12,10 a 9,89 ms. El costo estimado JSON subió de 287,29 a 891,30; no lo confundí con tiempo real. Terminé con todos los índices visibles.
