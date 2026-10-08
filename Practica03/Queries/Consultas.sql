/* 1. Conectarse como superadmin */
SELECT CURRENT_ROLE();

/* 2. Que usuarios existen?*/
SELECT * FROM tb_users;

/* 3. Desactiva a uno el que quieras*/
CALL sp_soft_delete_user(6);

/* 4. Como se que si lo registro la bitacora? */
SELECT * FROM tb_logs ORDER BY ID DESC LIMIT 10;
