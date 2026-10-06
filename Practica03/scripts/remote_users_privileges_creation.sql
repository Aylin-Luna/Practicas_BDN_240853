-- ==========================================
-- 1. CREACION DE USUARIOS REMOTOS Y LOCALES
-- ==========================================
-- Usuarios para cualquier host (%)
CREATE USER IF NOT EXISTS 'aylin.luna'@'%' IDENTIFIED BY '240853';
CREATE USER IF NOT EXISTS 'marco.ramirez'@'%' IDENTIFIED BY 'qwerty123';
CREATE USER IF NOT EXISTS 'yazmin.esquivel'@'%' IDENTIFIED BY '240235';
CREATE USER IF NOT EXISTS 'natalia.carrasco'@'%' IDENTIFIED BY '240537';
CREATE USER IF NOT EXISTS 'luis.cazarez'@'%' IDENTIFIED BY '240343';
CREATE USER IF NOT EXISTS 'saul.barrios'@'%' IDENTIFIED BY '240196';
CREATE USER IF NOT EXISTS 'uriel.valenzuela'@'%' IDENTIFIED BY '240485';

-- Usuarios específicos por host de equipo (ej. PC-05)
CREATE USER IF NOT EXISTS 'luis.cazarez'@'PC-05' IDENTIFIED BY '240343';

-- ==========================================
-- 2. CREACION DE ROLES PARA ECOMMERCE
-- ==========================================
CREATE ROLE IF NOT EXISTS 'superadmin';
CREATE ROLE IF NOT EXISTS 'admin';
CREATE ROLE IF NOT EXISTS 'seller';
CREATE ROLE IF NOT EXISTS 'buyer';
CREATE ROLE IF NOT EXISTS 'common_user';
CREATE ROLE IF NOT EXISTS 'user_not_registered';
CREATE ROLE IF NOT EXISTS 'support';

-- ==========================================
-- 3. ASIGNACION DE PRIVILEGIOS A LOS ROLES
-- ==========================================
-- Asegurar acceso básico de conexión
GRANT USAGE ON *.* TO 'support';

-- Privilegios de Superadmin
GRANT ALL PRIVILEGES ON *.* TO 'superadmin' WITH GRANT OPTION;

-- Privilegios de Admin
GRANT ALL PRIVILEGES ON db_test.* TO 'admin';

-- Privilegios de Support
GRANT SELECT, INSERT, UPDATE ON db_test.tb_users TO 'support';
GRANT SELECT, UPDATE ON db_test.tb_products TO 'support';
GRANT SELECT, INSERT, UPDATE ON db_test.tbc_categories TO 'support';
GRANT SELECT, INSERT, UPDATE ON db_test.tbd_products_categories TO 'support';
GRANT SELECT ON db_test.tb_logs TO 'support';
GRANT SELECT ON mysql.role_edges TO 'support';

-- Privilegios de Seller (Gestionar productos y cargar categorías)
GRANT SELECT, INSERT, UPDATE ON db_test.tb_products TO 'seller';
GRANT SELECT, INSERT, UPDATE ON db_test.tbc_categories TO 'seller'; -- Corrección: Se agregó INSERT para LOAD DATA

-- Privilegios de Common User
GRANT SELECT, INSERT ON db_test.tb_users TO 'common_user';

-- ==========================================
-- 4. ASIGNACION DE ROLES A LOS USUARIOS
-- ==========================================
GRANT 'superadmin' TO 'aylin.luna'@'%';
GRANT 'admin' TO 'marco.ramirez'@'%';
GRANT 'support' TO 'yazmin.esquivel'@'%';
GRANT 'seller' TO 'natalia.carrasco'@'%';
GRANT 'seller' TO 'luis.cazarez'@'%';
GRANT 'seller' TO 'luis.cazarez'@'PC-05'; -- Asignación explícita para PC-05
GRANT 'common_user' TO 'saul.barrios'@'%';
GRANT 'common_user' TO 'uriel.valenzuela'@'%';

-- ==========================================
-- 5. ACTIVACION AUTOMATICA DE ROLES
-- ==========================================
SET DEFAULT ROLE ALL TO 
  'aylin.luna'@'%',
  'marco.ramirez'@'%',
  'yazmin.esquivel'@'%',
  'natalia.carrasco'@'%',
  'luis.cazarez'@'%',
  'luis.cazarez'@'PC-05',
  'saul.barrios'@'%',
  'uriel.valenzuela'@'%';

-- ==========================================
-- 6. REFRESCAR PRIVILEGIOS
-- ==========================================
FLUSH PRIVILEGES;

SELECT "Los usuarios y privilegios han sido creados correctamente" AS mensaje;