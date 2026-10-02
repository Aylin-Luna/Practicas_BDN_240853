-- Practica: Base de datos db_test, usuarios, logs y trigger
-- MySQL 8.0

CREATE DATABASE IF NOT EXISTS db_test;
USE db_test;

-- Usuario para acceso remoto
CREATE USER IF NOT EXISTS 'yazmin.esquivel'@'%' IDENTIFIED BY '240235';

-- Tabla de usuarios
CREATE TABLE IF NOT EXISTS tb_users (
    ID INT NOT NULL AUTO_INCREMENT PRIMARY KEY,
    email VARCHAR(80) NOT NULL UNIQUE,
    nickname VARCHAR(100) NOT NULL UNIQUE,
    password VARCHAR(255) NOT NULL,
    creation_date DATETIME NOT NULL DEFAULT NOW(),
    last_login DATETIME
);

-- Tabla de bitácora
CREATE TABLE IF NOT EXISTS tb_logs (
    ID INT NOT NULL AUTO_INCREMENT PRIMARY KEY,
    table_name VARCHAR(100) NOT NULL,
    operation ENUM('Create','Read','Update','Delete') NOT NULL,
    db_user VARCHAR(80) NOT NULL,
    description TEXT NOT NULL,
    operation_date DATETIME NOT NULL DEFAULT NOW(),
    operation_status BIT DEFAULT b'1'
);

-- Trigger para registrar altas de usuarios
DROP TRIGGER IF EXISTS trg_users_after_insert;

DELIMITER $$

CREATE TRIGGER trg_users_after_insert
AFTER INSERT ON tb_users
FOR EACH ROW
BEGIN
    INSERT INTO tb_logs (
        table_name,
        operation,
        db_user,
        description,
        operation_date,
        operation_status
    )
    VALUES (
        'tb_users',
        'Create',
        USER(),
        CONCAT(
            'Usuario creado. ID=', NEW.ID,
            ', email=', NEW.email,
            ', nickname=', NEW.nickname
        ),
        CURRENT_TIMESTAMP,
        b'1'
    );
END$$

DELIMITER ;

-- Datos de prueba
INSERT INTO tb_users
VALUES (DEFAULT, 'aylin.esteban@utxicotepec.edu.mx', 'Aylin', MD5('12345'), DEFAULT, NULL);

INSERT INTO tb_users
VALUES (DEFAULT, 'yazmin.esquivel@utxicotepec.edu.mx', 'Yazmin', MD5('12345'), DEFAULT, NULL);

INSERT INTO tb_users
VALUES (DEFAULT, 'luis.mejia@utxicotepec.edu.mx', 'Luis', MD5('12345'), DEFAULT, NULL);

-- Permisos para Yazmin
GRANT INSERT ON db_test.tb_users TO 'yazmin.esquivel'@'%';
GRANT INSERT ON db_test.tb_logs TO 'yazmin.esquivel'@'%';
GRANT SELECT ON db_test.tb_logs TO 'yazmin.esquivel'@'%';
GRANT SELECT ON db_test.tb_users TO 'yazmin.esquivel'@'%';

-- Consultas de comprobación
SELECT * FROM tb_users;
SELECT * FROM tb_logs;
DESCRIBE tb_users;
DESCRIBE tb_logs;
