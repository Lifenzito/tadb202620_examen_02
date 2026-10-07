-- Estudiantes: Lifeng Chen - 000215708
--              Santiago Lopez - 000229668
-- Implementacion para MySQL 8.4

CREATE DATABASE IF NOT EXISTS brechas_seguridad
    CHARACTER SET utf8mb4
    COLLATE utf8mb4_0900_ai_ci;

USE brechas_seguridad;

DROP VIEW IF EXISTS v_exposicion_detalle;

SET FOREIGN_KEY_CHECKS = 0;
DROP TABLE IF EXISTS exposicion_usuario;
DROP TABLE IF EXISTS brecha;
DROP TABLE IF EXISTS usuario;
DROP TABLE IF EXISTS tipo_dato;
DROP TABLE IF EXISTS organizacion;
DROP TABLE IF EXISTS stg_sabana;
SET FOREIGN_KEY_CHECKS = 1;

CREATE TABLE organizacion (
    id_organizacion   INT AUTO_INCREMENT,
    nombre            VARCHAR(100) NOT NULL,
    sector            VARCHAR(40)  NOT NULL,
    pais              VARCHAR(40)  NOT NULL,
    tamano_empleados  INT          NOT NULL,
    CONSTRAINT pk_organizacion PRIMARY KEY (id_organizacion),
    CONSTRAINT uq_organizacion_nombre UNIQUE (nombre),
    CONSTRAINT ck_organizacion_tamano CHECK (tamano_empleados > 0)
) ENGINE = InnoDB;

CREATE TABLE tipo_dato (
    id_tipo_dato            INT AUTO_INCREMENT,
    nombre                  VARCHAR(40) NOT NULL,
    categoria_sensibilidad  VARCHAR(10) NOT NULL,
    CONSTRAINT pk_tipo_dato PRIMARY KEY (id_tipo_dato),
    CONSTRAINT uq_tipo_dato_nombre UNIQUE (nombre),
    CONSTRAINT ck_tipo_dato_sensibilidad
        CHECK (categoria_sensibilidad IN ('Baja', 'Media', 'Alta', 'Critica'))
) ENGINE = InnoDB;

CREATE TABLE brecha (
    id_brecha            INT AUTO_INCREMENT,
    codigo_brecha        VARCHAR(10) NOT NULL,
    id_organizacion      INT         NOT NULL,
    vector_ataque        VARCHAR(60) NOT NULL,
    severidad            VARCHAR(10) NOT NULL,
    fecha_ocurrencia     DATE        NOT NULL,
    fecha_deteccion      DATE        NOT NULL,
    registros_afectados  INT         NOT NULL,
    costo_estimado       DECIMAL(14,2) NOT NULL,
    CONSTRAINT pk_brecha PRIMARY KEY (id_brecha),
    CONSTRAINT uq_brecha_codigo UNIQUE (codigo_brecha),
    CONSTRAINT fk_brecha_organizacion
        FOREIGN KEY (id_organizacion)
        REFERENCES organizacion (id_organizacion),
    CONSTRAINT ck_brecha_severidad
        CHECK (severidad IN ('Baja', 'Media', 'Alta', 'Critica')),
    CONSTRAINT ck_brecha_fechas
        CHECK (fecha_deteccion >= fecha_ocurrencia),
    CONSTRAINT ck_brecha_registros
        CHECK (registros_afectados >= 0),
    CONSTRAINT ck_brecha_costo
        CHECK (costo_estimado >= 0)
) ENGINE = InnoDB;

CREATE TABLE usuario (
    id_usuario       INT AUTO_INCREMENT,
    codigo_usuario   VARCHAR(10) NOT NULL,
    pseudonimo       VARCHAR(40) NOT NULL,
    email_hash       CHAR(32)    NOT NULL,
    id_organizacion  INT         NOT NULL,
    pais_residencia  VARCHAR(40) NOT NULL,
    fecha_registro   DATE        NOT NULL,
    CONSTRAINT pk_usuario PRIMARY KEY (id_usuario),
    CONSTRAINT uq_usuario_codigo UNIQUE (codigo_usuario),
    CONSTRAINT uq_usuario_pseudonimo UNIQUE (pseudonimo),
    CONSTRAINT uq_usuario_email_hash UNIQUE (email_hash),
    CONSTRAINT fk_usuario_organizacion
        FOREIGN KEY (id_organizacion)
        REFERENCES organizacion (id_organizacion)
) ENGINE = InnoDB;

CREATE TABLE exposicion_usuario (
    id_brecha           INT  NOT NULL,
    id_usuario          INT  NOT NULL,
    id_tipo_dato        INT  NOT NULL,
    fecha_notificacion  DATE NOT NULL,
    CONSTRAINT pk_exposicion_usuario
        PRIMARY KEY (id_brecha, id_usuario, id_tipo_dato),
    CONSTRAINT fk_exposicion_brecha
        FOREIGN KEY (id_brecha)
        REFERENCES brecha (id_brecha),
    CONSTRAINT fk_exposicion_usuario
        FOREIGN KEY (id_usuario)
        REFERENCES usuario (id_usuario),
    CONSTRAINT fk_exposicion_tipo_dato
        FOREIGN KEY (id_tipo_dato)
        REFERENCES tipo_dato (id_tipo_dato)
) ENGINE = InnoDB;

CREATE TABLE stg_sabana (
    nombre_organizacion             TEXT,
    sector_organizacion             TEXT,
    pais_organizacion               TEXT,
    tamano_empleados_organizacion   TEXT,
    codigo_brecha                   TEXT,
    fecha_ocurrencia                TEXT,
    fecha_deteccion                 TEXT,
    vector_ataque                   TEXT,
    severidad_incidente             TEXT,
    registros_afectados_total       TEXT,
    costo_estimado_total            TEXT,
    codigo_usuario                  TEXT,
    pseudonimo_usuario              TEXT,
    email_hash_usuario              TEXT,
    pais_residencia_usuario         TEXT,
    fecha_registro_usuario          TEXT,
    tipo_dato_expuesto              TEXT,
    categoria_sensibilidad_dato     TEXT,
    fecha_notificacion_usuario      TEXT
) ENGINE = InnoDB;

