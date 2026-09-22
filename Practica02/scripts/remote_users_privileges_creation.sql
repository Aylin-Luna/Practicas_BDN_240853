/* CREACION DE USUARIOS REMOTOS */

CREATE USER IF NOT EXISTS 'aylin.luna'@'%' IDENTIFIED BY '240853';
CREATE USER IF NOT EXISTS 'marco.ramirez'@'%' IDENTIFIED BY 'qwerty123';
CREATE USER IF NOT EXISTS 'yazmin.esquivel'@'%' IDENTIFIED BY '240235';
CREATE USER IF NOT EXISTS 'natalia.carrasco'@'%' IDENTIFIED BY '240537';
CREATE USER IF NOT EXISTS 'luis.cazarez'@'%' IDENTIFIED BY '240343';
CREATE USER IF NOT EXISTS 'saul.barrios'@'%' IDENTIFIED BY '240196';
CREATE USER IF NOT EXISTS 'uriel.valenzuela'@'%' IDENTIFIED BY '240485';


/* ASIGNACION DE PRIVILEGIOS DEL SUPER USUARIO  - IMPORTANTE: SOLO USTEDES */
GRANT ALL PRIVILEGES ON *.* TO 'aylin.luna'@'%' WITH GRANT OPTION;

GRANT SELECT, INSERT, UPDATE , DELETE ON db_test.* TO 'yazmin.esquivel'@'%';

/*CREACION DE ROLES PARA LOS USUARIOS DE LA PLATAFORMA DE ECOMMERCE */
CREATE ROLE IF NOT EXISTS 'superadmin';
CREATE ROLE IF NOT EXISTS 'admin';
CREATE ROLE IF NOT EXISTS 'seller';
CREATE ROLE IF NOT EXISTS 'buyer';
CREATE ROLE IF NOT EXISTS 'common_user';
CREATE ROLE IF NOT EXISTS 'user_not_registered';
CREATE ROLE IF NOT EXISTS 'support';

/* ASIGNACION DE PRIVILEGIOS A LOS ROLES DE LA PLATAFORMA DE ECOMMERCE */
GRANT ALL PRIVILEGES ON *.* TO 'superadmin';
-- ADMIN
GRANT ALL PRIVILEGES ON db_test.* TO 'admin';
-- SUPPORT
GRANT SELECT, INSERT, UPDATE ON db_test.tb_users TO 'support';
GRANT SELECT, INSERT, UPDATE ON db_test.tb_products TO 'support';
-- SELLER
GRANT SELECT, INSERT, UPDATE ON db_test.tb_products TO 'seller';

/* ASIGNAR EL ROL AL USUARIO*/
GRANT 'superadmin' TO 'aylin.luna'@'%';
GRANT 'admin' TO 'marco.ramirez'@'%';
GRANT 'support' TO 'yazmin.esquivel'@'%';
GRANT 'seller' To 'natalia.carrasco'@'%';
GRANT 'seller' To 'luis.cazarez'@'%';

SET DEFAULT ROLE 'superadmin' TO 'aylin.luna'@'%';
SET DEFAULT ROLE 'admin' TO 'marco.ramirez'@'%';
SET DEFAULT ROLE 'support' TO 'yazmin.esquivel'@'%';
SET DEFAULT ROLE 'seller' To 'natalia.carrasco'@'%';
SET DEFAULT ROLE 'seller' To 'luis.cazarez'@'%';

-- MENSAJE DE CONFIRMACION
SELECT "Los usuarios y privilegios han sido creados correctamente" AS mensaje;
