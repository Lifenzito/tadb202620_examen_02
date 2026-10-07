# Etapa 2 - Modelo de datos en MySQL 8.4

Esta carpeta contiene la adaptación a MySQL 8.4 del mismo modelo relacional implementado por Santiago en PostgreSQL. Se conservaron las cinco tablas normalizadas, la tabla temporal de carga, las restricciones, la vista, la función, el procedimiento y los índices.

## Preparación de los CSV

Desde la raíz del repositorio, con el contenedor `mysql-cadena-frio` encendido, copio los cuatro archivos al directorio seguro de importación de MySQL:

```bash
docker cp "datos_brechas/sabana_brechas_seguridad_lote_1/sabana_brechas_seguridad_lote_1.csv" mysql-cadena-frio:/var/lib/mysql-files/
docker cp "datos_brechas/sabana_brechas_seguridad_lote_2/sabana_brechas_seguridad_lote_2.csv" mysql-cadena-frio:/var/lib/mysql-files/
docker cp "datos_brechas/sabana_brechas_seguridad_lote_3/sabana_brechas_seguridad_lote_3.csv" mysql-cadena-frio:/var/lib/mysql-files/
docker cp "datos_brechas/sabana_brechas_seguridad_lote_4/sabana_brechas_seguridad_lote_4.csv" mysql-cadena-frio:/var/lib/mysql-files/
```

## Orden de ejecución

1. `00_creacion_tablas.sql`
2. `01_carga_de_datos.sql`
3. `02_creacion_vistas.sql`
4. `04_funcion_tiempo_brecha.sql`
5. `05_procedimiento_almacenado.sql`
6. `06_indices.sql`
7. `03_usuario_lector.sql`, después de reemplazar localmente la contraseña de ejemplo.

El script de carga valida los conteos esperados: 60 organizaciones, 800 brechas, 7.887 usuarios, 10 tipos de dato y 40.000 exposiciones.

La contraseña real del usuario lector no se almacena en GitHub.

## Validación realizada

Ejecuté los siete scripts contra el contenedor local `mysql:8.4`. La carga terminó con todos los conteos en estado `OK`, cero filas sin reconstruir y cero usuarios relacionados con una organización incorrecta. También comprobé la vista, la función, el procedimiento, los índices y los permisos mínimos del usuario lector.

**Estudiante:** Lifeng Chen  
**ID SIGAA:** 000215708  
**Motor:** MySQL 8.4
