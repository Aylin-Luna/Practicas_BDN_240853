/* Como vendedor necesioto desactivar
el producto 16 */

/*Opcion 1: Desactivsrlo mediante un update*/
UPDATE tb_products SET status=b'0'
WHERE id = 16;

/* Opcion 2: Implementar un procedimiento general
para la desactivacion de productos*/
CALL sp_soft_delete("tb_products", 16);

/* 3. */
SELECT *
FROM vwtotal_products_by_category
ORDER BY category_id is null;

/*4. */
SHOW PROCEDURE STATUS WHERE Db = 'db_test';