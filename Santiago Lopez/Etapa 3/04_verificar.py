#!/usr/bin/env python3
"""Lifeng Chen, SIGAA 000215708. Pruebas reproducibles de Etapas 3 y 4."""
import argparse
import calendar
import csv
import datetime as dt
import hashlib
import io
import json
import re
import statistics
import subprocess
from pathlib import Path


ROOT = Path(__file__).resolve().parents[2]
AUTOR = 'Lifeng Chen | SIGAA 000215708 | MySQL 8.4'
INDICES = [
    ('brecha', 'ix_brecha_deteccion_severidad'),
    ('exposicion_usuario', 'ix_exposicion_tipo_brecha_usuario'),
    ('exposicion_usuario', 'ix_exposicion_usuario_fecha'),
]


def partes(etapa):
    archivo = ROOT / 'Lifeng Chen' / f'Etapa {etapa}' / '00_consulta.sql'
    inicio, consulta = archivo.read_text(encoding='utf-8').split('\nSELECT\n', 1)
    return inicio, 'SELECT\n' + consulta


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--container', required=True)
    parser.add_argument('--salida', type=Path, required=True)
    parser.add_argument('--repeticiones', type=int, default=7)
    args = parser.parse_args()
    if args.repeticiones < 3:
        parser.error('Uso al menos tres mediciones por escenario.')
    destino = args.salida.resolve()
    destino.mkdir(parents=True, exist_ok=True)

    def ejecutar(sql):
        # La clave se resuelve dentro del contenedor; no aparece en argumentos.
        cmd = ['docker', 'exec', '-i', args.container, 'sh', '-c',
               'MYSQL_PWD="$MYSQL_ROOT_PASSWORD" exec mysql -uroot '
               '--batch --raw --default-character-set=utf8mb4']
        r = subprocess.run(cmd, input=sql, text=True, encoding='utf-8',
                           capture_output=True, check=True)
        return r.stdout

    def filas(sql):
        return list(csv.DictReader(io.StringIO(ejecutar(sql)), delimiter='\t'))

    def guardar_csv(path, registros):
        if not registros:
            raise AssertionError('No hay filas para el archivo de evidencia.')
        with path.open('w', encoding='utf-8', newline='') as f:
            w = csv.DictWriter(f, fieldnames=registros[0].keys())
            w.writeheader()
            w.writerows(registros)

    def guardar_texto(path, texto):
        path.write_text(AUTOR + '\n' + texto, encoding='utf-8')

    def visibles():
        ejecutar('USE brechas_seguridad;\n' + '\n'.join(
            f'ALTER TABLE {t} ALTER INDEX {i} VISIBLE;' for t, i in INDICES))

    def escenario(etapa, modo):
        indices = INDICES[:2] if etapa == 3 else INDICES[2:]
        visibilidad = 'INVISIBLE' if modo == 'sin' else 'VISIBLE'
        ejecutar('USE brechas_seguridad;\n' + '\n'.join(
            f'ALTER TABLE {t} ALTER INDEX {i} {visibilidad};'
            for t, i in indices))

    def analizar(etapa):
        inicio, consulta = partes(etapa)
        salida = ejecutar(inicio + "\nSET SESSION optimizer_switch = "
                          "'use_invisible_indexes=off';\n"
                          'EXPLAIN ANALYZE FORMAT=TREE\n' + consulta)
        arbol = salida.split('EXPLAIN\n', 1)[1]
        raiz = re.search(r'actual time=[\d.eE+-]+\.\.([\d.eE+-]+) rows=(\d+) loops=(\d+)',
                         arbol.splitlines()[0])
        assert raiz and raiz[3] == '1', 'No encuentro el iterador raiz.'
        return float(raiz[1]), int(raiz[2]), arbol

    version = filas('SELECT VERSION() AS version;')[0]['version']
    assert version.startswith('8.4.'), f'Motor inesperado: {version}'
    esperados = {'organizacion': 60, 'brecha': 800, 'usuario': 7887,
                 'tipo_dato': 10, 'exposicion_usuario': 40000, 'stg_sabana': 40000}
    conteos = filas('USE brechas_seguridad;\n' + ' UNION ALL '.join(
        f"SELECT '{t}' AS tabla, COUNT(*) AS obtenido FROM {t}" for t in esperados) + ';')
    for fila in conteos:
        assert int(fila['obtenido']) == esperados[fila['tabla']], fila
        fila['esperado'] = esperados[fila['tabla']]
        fila['resultado'] = 'OK'
    guardar_csv(destino / 'conteos_Lifeng_Chen_000215708.csv', conteos)

    csvs = sorted((ROOT / 'datos_brechas').rglob('*.csv'))
    assert len(csvs) == 4
    sabana = []
    for archivo in csvs:
        with archivo.open(encoding='utf-8-sig', newline='') as f:
            sabana.extend(csv.DictReader(f))
    assert len(sabana) == 40000
    pruebas = ['MySQL 8.4 y seis conteos exactos: OK',
               'Cuatro CSV originales con 40.000 filas: OK']
    metadatos = {
        'autor': AUTOR, 'fecha_utc': dt.datetime.now(dt.timezone.utc).isoformat(),
        'version': version, 'repeticiones_por_escenario': args.repeticiones,
        'metodo': 'Una ejecucion de calentamiento por escenario; pares alternados. '
                  'Tiempos del iterador raiz EXPLAIN ANALYZE, no del cliente. '
                  'Cache caliente, sin escrituras concurrentes ni hints de indice.',
        'csv_sha256': {str(p.relative_to(ROOT)): hashlib.sha256(p.read_bytes()).hexdigest()
                       for p in csvs},
        'etapas': {},
    }
    try:
        visibles()
        for etapa in (3, 4):
            carpeta = destino / f'etapa{etapa}'
            carpeta.mkdir(exist_ok=True)
            inicio, consulta = partes(etapa)
            for nombre in ('01_plan_sin_indices.sql', '02_plan_con_indices.sql'):
                script = ROOT / 'Lifeng Chen' / f'Etapa {etapa}' / nombre
                texto = script.read_text(encoding='utf-8')
                assert texto.count(consulta) == 2, 'La consulta difiere entre versiones.'
                guardar_texto(carpeta / nombre.replace('.sql', '.txt'), ejecutar(texto))
            pruebas.append(f'Etapa {etapa}: scripts SQL ejecutados y consulta identica: OK')

            resultados = {}
            costos = {}
            mediciones = {'sin': [], 'con': []}
            for modo in ('sin', 'con'):
                escenario(etapa, modo)
                resultados[modo] = filas(inicio + '\n' + consulta)
                indices = filas("SELECT DISTINCT TABLE_NAME, INDEX_NAME, IS_VISIBLE "
                                "FROM information_schema.STATISTICS WHERE TABLE_SCHEMA = "
                                "'brechas_seguridad' ORDER BY TABLE_NAME, INDEX_NAME;")
                guardar_csv(carpeta / f'indices_{modo}_Lifeng_Chen_000215708.csv', indices)
                raw = ejecutar(inicio + "\nSET SESSION optimizer_switch = "
                               "'use_invisible_indexes=off';\nEXPLAIN FORMAT=JSON\n" + consulta)
                plan = json.loads(raw.split('EXPLAIN\n', 1)[1])
                costos[modo] = float(plan['query_block']['cost_info']['query_cost'])
                (carpeta / f'plan_{modo}.json').write_text(
                    json.dumps({'autor': AUTOR, 'explain': plan}, indent=2), encoding='utf-8')
                analizar(etapa)
            assert resultados['sin'] == resultados['con']
            guardar_csv(carpeta / f'resultados_etapa{etapa}_Lifeng_Chen_000215708.csv',
                        resultados['con'])
            for n in range(args.repeticiones):
                for modo in (('sin', 'con') if n % 2 == 0 else ('con', 'sin')):
                    escenario(etapa, modo)
                    ms, cantidad, arbol = analizar(etapa)
                    assert cantidad == len(resultados[modo])
                    mediciones[modo].append({'iteracion': n + 1, 'ms': ms,
                                             'filas': cantidad, 'arbol': arbol})
            for modo in ('sin', 'con'):
                mediana = statistics.median(m['ms'] for m in mediciones[modo])
                muestra = min(mediciones[modo], key=lambda m: abs(m['ms'] - mediana))
                guardar_texto(carpeta / f'plan_{modo}.txt', muestra['arbol'])
            lista = [{'autor': 'Lifeng Chen', 'sigaa': '000215708', 'escenario': modo,
                      'iteracion': m['iteracion'], 'tiempo_raiz_ms': m['ms'],
                      'filas_reales': m['filas'], 'costo_estimado_json': costos[modo]}
                     for modo in ('sin', 'con') for m in mediciones[modo]]
            guardar_csv(carpeta / 'mediciones_Lifeng_Chen_000215708.csv', lista)
            info = {'filas': len(resultados['con']), 'costos_estimados': costos,
                    'mediana_ms': {modo: statistics.median(m['ms'] for m in mediciones[modo])
                                   for modo in ('sin', 'con')}, 'mediciones': mediciones}
            metadatos['etapas'][str(etapa)] = info
            pruebas.append(f'Etapa {etapa}: resultados iguales sin/con, '
                           f'{len(resultados["con"])} filas y {args.repeticiones} pares: OK')
            visibles()

        ultimo = max(dt.date.fromisoformat(r['fecha_deteccion']) for r in sabana)
        primero = ultimo.replace(year=ultimo.year - 1, day=min(
            ultimo.day, calendar.monthrange(ultimo.year - 1, ultimo.month)[1]))
        grupos = {}
        for r in sabana:
            fecha = dt.date.fromisoformat(r['fecha_deteccion'])
            if primero <= fecha <= ultimo and r['severidad_incidente'] in ('Alta', 'Critica'):
                g = grupos.setdefault(r['codigo_brecha'], {'fila': r, 'usuarios': set(),
                                                         'criticos': set()})
                g['usuarios'].add(r['codigo_usuario'])
                if r['categoria_sensibilidad_dato'] == 'Critica':
                    g['criticos'].add(r['codigo_usuario'])
        esperadas3 = [{'organizacion': g['fila']['nombre_organizacion'], 'codigo_brecha': c,
                      'fecha_deteccion': g['fila']['fecha_deteccion'],
                      'vector_ataque': g['fila']['vector_ataque'],
                      'usuarios_afectados': str(len(g['usuarios']))}
                     for c, g in grupos.items() if g['criticos']]
        esperadas3.sort(key=lambda r: (-int(r['usuarios_afectados']), r['codigo_brecha']))
        assert filas('\n'.join(partes(3))) == esperadas3
        diferencias = [{'codigo_brecha': c, 'todos_los_usuarios': len(g['usuarios']),
                        'solo_usuarios_con_dato_critico': len(g['criticos'])}
                       for c, g in sorted(grupos.items())
                       if g['criticos'] and g['usuarios'] != g['criticos']]
        assert diferencias, 'Los datos no prueban la diferencia semantica.'
        guardar_csv(destino / 'etapa3' / 'control_conteo_Lifeng_Chen_000215708.csv', diferencias)
        pruebas.append('Etapa 3: contraste independiente con CSV, rango cerrado, '
                       'severidad, EXISTS, COUNT DISTINCT, orden y conteo de todos: OK')
        metadatos['etapas']['3'].update({'fecha_inicio': str(primero), 'fecha_final': str(ultimo),
                                        'brechas_con_conteo_critico_incompleto': len(diferencias),
                                        'max_usuarios': max(int(r['usuarios_afectados']) for r in esperadas3),
                                        'min_usuarios': min(int(r['usuarios_afectados']) for r in esperadas3)})

        codigo = 'US-003386'
        esperadas4 = [{'codigo_usuario': codigo, 'codigo_brecha': r['codigo_brecha'],
                      'tipo_dato': r['tipo_dato_expuesto'],
                      'categoria_sensibilidad': r['categoria_sensibilidad_dato'],
                      'organizacion': r['nombre_organizacion'],
                      'fecha_notificacion': r['fecha_notificacion_usuario']}
                     for r in sabana if r['codigo_usuario'] == codigo]
        esperadas4.sort(key=lambda r: (r['fecha_notificacion'], r['codigo_brecha'], r['tipo_dato']))
        reales4 = filas('\n'.join(partes(4)))
        assert sorted(reales4, key=lambda r: (r['fecha_notificacion'], r['codigo_brecha'],
                                              r['tipo_dato'])) == esperadas4
        assert [r['fecha_notificacion'] for r in reales4] == sorted(
            r['fecha_notificacion'] for r in reales4)
        assert not filas("SET @codigo_usuario = 'NO-EXISTE';\n" + '\n'.join(partes(4)))
        otro = next(r['codigo_usuario'] for r in sabana if r['codigo_usuario'] != codigo)
        assert len(filas(f"SET @codigo_usuario = '{otro}';\n" + '\n'.join(partes(4)))) == sum(
            r['codigo_usuario'] == otro for r in sabana)
        pruebas.append('Etapa 4: contraste independiente con CSV, orden cronologico, '
                       'usuario alternativo y codigo inexistente sin filas: OK')
        metadatos['etapas']['4'].update({'codigo_usuario': codigo,
                                        'brechas': len({r['codigo_brecha'] for r in esperadas4})})

        # Casos controlados: dos usuarios, uno con varios tipos de dato;
        # fechas en ambos extremos, fuera de rango y brecha sin dato critico.
        inicio3, consulta3 = partes(3)
        fixture = '''USE brechas_seguridad;
START TRANSACTION;
SET @org = (SELECT MIN(id_organizacion) FROM organizacion);
SET @critico = (SELECT MIN(id_tipo_dato) FROM tipo_dato WHERE categoria_sensibilidad = 'Critica');
SET @bajo = (SELECT MIN(id_tipo_dato) FROM tipo_dato WHERE categoria_sensibilidad = 'Baja');
SET @fin = (SELECT MAX(fecha_deteccion) FROM brecha);
SET @inicio = DATE_SUB(@fin, INTERVAL 12 MONTH);
INSERT INTO usuario (id_usuario,codigo_usuario,pseudonimo,email_hash,id_organizacion,pais_residencia,fecha_registro)
VALUES (900001,'ZZ-U00001','zz_fixture_1',MD5('zz_fixture_1'),@org,'Colombia',@inicio),
       (900002,'ZZ-U00002','zz_fixture_2',MD5('zz_fixture_2'),@org,'Colombia',@inicio);
INSERT INTO brecha (id_brecha,codigo_brecha,id_organizacion,vector_ataque,severidad,fecha_ocurrencia,fecha_deteccion,registros_afectados,costo_estimado)
VALUES (900001,'ZZ-B00001',@org,'Prueba','Alta',@inicio,@inicio,0,0),
       (900002,'ZZ-B00002',@org,'Prueba','Critica',@fin,@fin,0,0),
       (900003,'ZZ-B00003',@org,'Prueba','Alta',DATE_SUB(@inicio,INTERVAL 1 DAY),DATE_SUB(@inicio,INTERVAL 1 DAY),0,0),
       (900004,'ZZ-B00004',@org,'Prueba','Alta',@inicio,@inicio,0,0),
       (900005,'ZZ-B00005',@org,'Prueba','Media',@inicio,@inicio,0,0);
INSERT INTO exposicion_usuario VALUES
 (900001,900001,@critico,@inicio),(900001,900001,@bajo,@inicio),(900001,900002,@bajo,@inicio),
 (900002,900001,@critico,@fin),(900003,900001,@critico,@inicio),
 (900004,900001,@bajo,@inicio),(900005,900001,@critico,@inicio);
'''
        prueba_fixture = filas(fixture + inicio3 + '\n' + consulta3 + '\nROLLBACK;')
        seleccion = {r['codigo_brecha']: int(r['usuarios_afectados']) for r in prueba_fixture
                     if r['codigo_brecha'].startswith('ZZ-')}
        assert seleccion == {'ZZ-B00001': 2, 'ZZ-B00002': 1}, seleccion
        pruebas.append('Etapa 3: fixture transaccional de extremos inclusivos, fuera de rango, '
                       'sensibilidad, severidad y usuario con multiples tipos: OK; ROLLBACK aplicado')
        final = filas('USE brechas_seguridad;\n' + ' UNION ALL '.join(
            f"SELECT '{t}' AS tabla, COUNT(*) AS obtenido FROM {t}" for t in esperados) + ';')
        assert all(int(r['obtenido']) == esperados[r['tabla']] for r in final)
        assert filas('USE brechas_seguridad; SELECT MAX(fecha_deteccion) AS fecha FROM brecha;')[0]['fecha'] == str(ultimo)
        pruebas.append('Sin filas de prueba persistentes; conteos y MAX originales: OK')
    finally:
        visibles()
        restaurados = filas("SELECT DISTINCT TABLE_NAME, INDEX_NAME, IS_VISIBLE "
                           "FROM information_schema.STATISTICS WHERE TABLE_SCHEMA = "
                           "'brechas_seguridad' ORDER BY TABLE_NAME, INDEX_NAME;")
        guardar_csv(destino / 'indices_restaurados_Lifeng_Chen_000215708.csv', restaurados)
        assert all(r['IS_VISIBLE'] == 'YES' for r in restaurados)

    pruebas.append('Todos los indices visibles al terminar: OK')
    metadatos['pruebas'] = pruebas
    (destino / 'verificacion_Lifeng_Chen_000215708.json').write_text(
        json.dumps(metadatos, indent=2, ensure_ascii=False), encoding='utf-8')
    guardar_texto(destino / 'pruebas_Lifeng_Chen_000215708.txt', '\n'.join(pruebas) + '\n')
    print('\n'.join(pruebas))
    for etapa, info in metadatos['etapas'].items():
        print(f'Etapa {etapa}: {info["filas"]} filas, medianas ms {info["mediana_ms"]}, '
              f'costos {info["costos_estimados"]}')


if __name__ == '__main__':
    main()
