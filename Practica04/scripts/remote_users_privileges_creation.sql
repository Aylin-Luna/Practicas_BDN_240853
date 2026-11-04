-- ==========================================
-- 1. CREACION DE USUARIOS REMOTOS Y LOCALES
-- ==========================================
CREATE USER IF NOT EXISTS 'aylin.luna'@'%' IDENTIFIED BY '240853';
CREATE USER IF NOT EXISTS 'marco.ramirez'@'%' IDENTIFIED BY 'qwerty123';
CREATE USER IF NOT EXISTS 'yazmin.esquivel'@'%' IDENTIFIED BY '240235';
CREATE USER IF NOT EXISTS 'natalia.carrasco'@'%' IDENTIFIED BY '240537';
CREATE USER IF NOT EXISTS 'luis.cazarez'@'%' IDENTIFIED BY '240343';
CREATE USER IF NOT EXISTS 'saul.barrios'@'%' IDENTIFIED BY '240196';
CREATE USER IF NOT EXISTS 'uriel.valenzuela'@'%' IDENTIFIED BY '240485';
CREATE USER IF NOT EXISTS 'app_web'@'%' IDENTIFIED BY 'Web123';
CREATE USER IF NOT EXISTS 'app_movil'@'%' IDENTIFIED BY 'Mobile890';

-- Usuario específico por host
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
GRANT USAGE ON *.* TO 'support';

-- Superadmin
GRANT ALL PRIVILEGES ON *.* TO 'superadmin' WITH GRANT OPTION;

-- Admin
GRANT ALL PRIVILEGES ON db_test.* TO 'admin';

-- Support
GRANT SELECT, INSERT, UPDATE ON db_test.tb_users TO 'support';
GRANT SELECT, UPDATE ON db_test.tb_products TO 'support';
GRANT SELECT, INSERT, UPDATE ON db_test.tbc_categories TO 'support';
GRANT SELECT, INSERT, UPDATE ON db_test.tbd_products_categories TO 'support';
GRANT SELECT ON db_test.tb_logs TO 'support';
GRANT SELECT ON mysql.role_edges TO 'support';
GRANT EXECUTE ON PROCEDURE db_test.sp_soft_delete_user TO 'support';

-- Seller
GRANT SELECT, INSERT, UPDATE ON db_test.tb_products TO 'seller';
GRANT SELECT, INSERT, UPDATE ON db_test.tbc_categories TO 'seller';

-- Common User
GRANT SELECT, INSERT ON db_test.tb_users TO 'common_user';
GRANT SELECT ON db_test.tb_products TO 'common_user';


-- User Not Registered (Permisos completos para registro de nuevos usuarios)
GRANT SELECT, INSERT ON db_test.tb_users TO 'user_not_registered';
GRANT SELECT, INSERT ON db_test.tb_people TO 'user_not_registered';
GRANT EXECUTE ON PROCEDURE db_test.sp_register_new_user TO 'user_not_registered';

GRANT 'user_not_registered', 'common_user', 'buyer' TO 'app_web'@'%';
GRANT 'user_not_registered', 'common_user', 'buyer' TO 'app_movil'@'%';
GRANT INSERT ON db_test.tb_user_addresses TO 'app_web'@'192.168.1.24';

-- ==========================================
-- 4. ASIGNACION DE ROLES A LOS USUARIOS
-- ==========================================
GRANT 'superadmin' TO 'aylin.luna'@'%';
GRANT 'admin' TO 'marco.ramirez'@'%';
GRANT 'support' TO 'yazmin.esquivel'@'%';
GRANT 'seller' TO 'natalia.carrasco'@'%';
GRANT 'seller' TO 'luis.cazarez'@'%';
GRANT 'seller' TO 'luis.cazarez'@'PC-05';
GRANT 'common_user' TO 'saul.barrios'@'%';
GRANT 'common_user' TO 'uriel.valenzuela'@'%';
GRANT 'user_not_registered' TO 'app_web'@'%';
GRANT 'user_not_registered' TO 'app_movil'@'%';

-- ==========================================
-- 5. ACTIVACION AUTOMATICA DE ROLES (Corregido)
-- ==========================================
SET DEFAULT ROLE ALL TO 
  'aylin.luna'@'%',
  'marco.ramirez'@'%',
  'yazmin.esquivel'@'%',
  'natalia.carrasco'@'%',
  'luis.cazarez'@'%',
  'luis.cazarez'@'PC-05',
  'saul.barrios'@'%',
  'uriel.valenzuela'@'%',
  'app_web'@'%',
  'app_movil'@'%';

-- ==========================================
-- 6. REFRESCAR PRIVILEGIOS
-- ==========================================
FLUSH PRIVILEGES;

SELECT "Los usuarios y privilegios han sido creados correctamente" AS mensaje;

-- =====================================================================
-- 01_setup_practica04.sql
-- Usuarios, roles, privilegios y procedimientos del sistema para que
-- app_web / app_movil puedan ejecutar el Caso de Prueba 1 de forma remota.
-- Ejecutar UNA VEZ como root/superadmin sobre db_test.
-- =====================================================================
USE db_test;

-- ==========================================
-- 1. USUARIOS
-- ==========================================
CREATE USER IF NOT EXISTS 'aylin.luna'@'%'        IDENTIFIED BY '240853';
CREATE USER IF NOT EXISTS 'marco.ramirez'@'%'     IDENTIFIED BY 'qwerty123';
CREATE USER IF NOT EXISTS 'yazmin.esquivel'@'%'   IDENTIFIED BY '240235';
CREATE USER IF NOT EXISTS 'natalia.carrasco'@'%'  IDENTIFIED BY '240537';
CREATE USER IF NOT EXISTS 'luis.cazarez'@'%'      IDENTIFIED BY '240343';
CREATE USER IF NOT EXISTS 'luis.cazarez'@'PC-05'  IDENTIFIED BY '240343';
CREATE USER IF NOT EXISTS 'saul.barrios'@'%'      IDENTIFIED BY '240196';
CREATE USER IF NOT EXISTS 'uriel.valenzuela'@'%'  IDENTIFIED BY '240485';
CREATE USER IF NOT EXISTS 'app_web'@'%'           IDENTIFIED BY 'Web123';
CREATE USER IF NOT EXISTS 'app_movil'@'%'         IDENTIFIED BY 'Mobile890';

-- ==========================================
-- 2. ROLES
-- ==========================================
CREATE ROLE IF NOT EXISTS 'superadmin', 'admin', 'seller', 'buyer',
                          'common_user', 'user_not_registered', 'support';

-- ==========================================
-- 3. PRIVILEGIOS POR ROL
-- ==========================================
GRANT USAGE ON *.* TO 'support';

-- superadmin / admin
GRANT ALL PRIVILEGES ON *.*      TO 'superadmin' WITH GRANT OPTION;
GRANT ALL PRIVILEGES ON db_test.* TO 'admin';

-- support
GRANT SELECT, INSERT, UPDATE ON db_test.tb_users                TO 'support';
GRANT SELECT, UPDATE         ON db_test.tb_products             TO 'support';
GRANT SELECT, INSERT, UPDATE ON db_test.tbc_categories          TO 'support';
GRANT SELECT, INSERT, UPDATE ON db_test.tbd_products_categories TO 'support';
GRANT SELECT                 ON db_test.tb_logs                 TO 'support';
GRANT SELECT                 ON mysql.role_edges                TO 'support';
GRANT EXECUTE ON PROCEDURE db_test.sp_soft_delete_user          TO 'support';

-- seller
GRANT SELECT, INSERT, UPDATE ON db_test.tb_products    TO 'seller';
GRANT SELECT, INSERT, UPDATE ON db_test.tbc_categories TO 'seller';

-- user_not_registered: solo registrarse (el SP corre como DEFINER; no se
-- da SELECT sobre tb_users para no exponer hashes de contraseña)
GRANT EXECUTE ON PROCEDURE db_test.sp_register_new_user TO 'user_not_registered';
GRANT INSERT ON db_test.tb_users  TO 'user_not_registered';
GRANT INSERT ON db_test.tb_people TO 'user_not_registered';

-- common_user: catálogo, favoritos, carrito, orden, domicilio, método de pago
GRANT SELECT (ID, email, nick, status) ON db_test.tb_users TO 'common_user';
GRANT SELECT ON db_test.tb_products                  TO 'common_user';
GRANT SELECT ON db_test.tbc_categories               TO 'common_user';
GRANT SELECT ON db_test.tbd_products_categories      TO 'common_user';
GRANT SELECT ON db_test.tbd_products_users_providers TO 'common_user';
GRANT SELECT ON db_test.tb_payment_methods           TO 'common_user';

GRANT SELECT, INSERT, UPDATE, DELETE ON db_test.tbd_users_wishlist_products TO 'common_user';
GRANT SELECT, INSERT, UPDATE, DELETE ON db_test.tb_carts       TO 'common_user';
GRANT SELECT, INSERT, UPDATE, DELETE ON db_test.tbd_cart_items TO 'common_user';
GRANT SELECT, INSERT ON db_test.tb_orders        TO 'common_user';
GRANT SELECT, INSERT ON db_test.tbd_order_items  TO 'common_user';
GRANT SELECT, INSERT ON db_test.tb_buyer_orders  TO 'common_user';
GRANT SELECT, INSERT, UPDATE ON db_test.tb_user_addresses        TO 'common_user';
GRANT SELECT, INSERT, UPDATE ON db_test.tbd_address_components   TO 'common_user';
GRANT SELECT, INSERT, UPDATE ON db_test.tbd_user_payment_methods TO 'common_user';

-- buyer: pagar y consultar su compra; los pasos 9-11 los hace el sistema (SPs)
GRANT SELECT, INSERT ON db_test.tb_payments            TO 'buyer';
GRANT SELECT ON db_test.tb_payment_transaction         TO 'buyer';
GRANT SELECT ON db_test.tb_payment_methods             TO 'buyer';
GRANT SELECT ON db_test.tbd_user_payment_methods       TO 'buyer';
GRANT SELECT ON db_test.tb_orders                      TO 'buyer';
GRANT SELECT ON db_test.tbd_order_items                TO 'buyer';
GRANT SELECT ON db_test.tb_buyer_orders                TO 'buyer';
GRANT SELECT ON db_test.tb_shipments                   TO 'buyer';
GRANT EXECUTE ON PROCEDURE db_test.sp_authorize_payment TO 'buyer';
GRANT EXECUTE ON PROCEDURE db_test.sp_attend_order      TO 'buyer';
GRANT EXECUTE ON PROCEDURE db_test.sp_deliver_order     TO 'buyer';

-- ==========================================
-- 6. ASIGNACIÓN DE ROLES A USUARIOS
-- ==========================================
GRANT 'superadmin'   TO 'aylin.luna'@'%';
GRANT 'admin'        TO 'marco.ramirez'@'%';
GRANT 'support'      TO 'yazmin.esquivel'@'%';
GRANT 'seller'       TO 'natalia.carrasco'@'%';
GRANT 'seller'       TO 'luis.cazarez'@'%', 'luis.cazarez'@'PC-05';
GRANT 'common_user'  TO 'saul.barrios'@'%', 'uriel.valenzuela'@'%';

GRANT 'user_not_registered', 'common_user', 'buyer' TO 'app_web'@'%', 'app_movil'@'%';

-- ==========================================
-- 7. ROLES POR DEFECTO
--    app_web / app_movil inician como user_not_registered (como pide el
--    caso) y cambian con SET ROLE durante la práctica.
-- ==========================================
SET DEFAULT ROLE ALL TO
  'aylin.luna'@'%', 'marco.ramirez'@'%', 'yazmin.esquivel'@'%',
  'natalia.carrasco'@'%', 'luis.cazarez'@'%', 'luis.cazarez'@'PC-05',
  'saul.barrios'@'%', 'uriel.valenzuela'@'%';
SET DEFAULT ROLE 'user_not_registered' TO 'app_web'@'%', 'app_movil'@'%';

FLUSH PRIVILEGES;

SELECT 'Usuarios, roles, privilegios y procedimientos creados correctamente' AS mensaje;