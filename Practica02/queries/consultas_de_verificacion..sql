CREATE DATABASE db_test;
USE db_test;

/* Verificar el total de tabla en mi base de datos*/
SHOW TABLES;

/*Verificar el total de triggers en mi base de datos*/
SHOW TRIGGERS FROM db_test;

/* Consultar los registros de los usuarios*/
SELECT * FROM tb_users;
/* Consultar los registros de la bitacora */
SELECT * FROM tb_logs;

/* Verifica los usuarios remotos creados en el servidor*/
SELECT user,host FROM mysql.user WHERE host="%";

/* Verificar los roles asignados a los usuarios remotos creados en el servidor*/
SELECT
	FROM_USER AS Rol,
    FROM_HOST AS Host_Rol,
    TO_USER AS Usuario,
    TO_HOST AS Host_Usuario
FROM mysql.role_edges
ORDER BY FROM_USER, TO_USER;
    