-- ============================================================================
-- SCRIPT DE PRUEBAS FUNCIONALES - BASE DE DATOS: db_test
-- ============================================================================
USE `db_test`;

-- Asegurar métodos de pago requeridos por los casos de prueba (Spin, SPEI, Cupón)
INSERT IGNORE INTO `tb_payment_methods` (`code`, `name`, `status`) VALUES
('digital_card_spin', 'Tarjeta Digital (Spin)', b'1'),
('spei_transfer', 'Transferencia SPEI', b'1'),
('gift_coupon', 'Cupón de Regalo', b'1');

-- ============================================================================
-- CASO DE PRUEBA 1: "Compra Exitosa, sin modificaciones"
-- ============================================================================
-- Nota de conexión: Si ejecutas conectado como 'AppWeb' o 'AppMobile', activa el rol:
-- SET ROLE 'user_not_registered';

-- 1. Registro de usuario nuevo y sus datos personales mediante SP existente
SET @cp1_user_id = 0;
SET @cp1_person_id = 0;

CALL `sp_register_new_user`(
    'carlos.mendoza.test1@gmail.com',
    'cmendoza_test1',
    'PassSegura2026!',
    'Ing.',
    'Carlos Alberto',
    'Mendoza Ruiz',
    '1995-06-15',
    1,
    'MX',
    '7761002030',
    @cp1_user_id,
    @cp1_person_id
);

-- Asegurar rol inicial de usuario recién registrado
UPDATE `tb_users` SET `role` = 'user_not_registered' WHERE `ID` = @cp1_user_id;

-- 2. Selección y verificación de estatus de 5 productos disponibles
SELECT `ID`, `SKU`, `name`, `current_price`, `current_stock`, `status`
FROM `tb_products`
WHERE `ID` IN (5001, 5002, 5003, 5004, 5005) AND `status` = b'1';

-- 3. Crear 1 carrito de compra
INSERT INTO `tb_carts` (`user_ID`) VALUES (@cp1_user_id);
SET @cp1_cart_id = LAST_INSERT_ID();

-- 4. Agregar 5 productos con diferentes cantidades al carrito
INSERT INTO `tbd_cart_items` (`cart_id`, `product_id`, `quantity`) VALUES
(@cp1_cart_id, 5001, 1),
(@cp1_cart_id, 5002, 2),
(@cp1_cart_id, 5003, 1),
(@cp1_cart_id, 5004, 3),
(@cp1_cart_id, 5005, 2);

-- 5. Realizar la orden de compra
SELECT @cp1_total := SUM(ci.quantity * p.current_price)
FROM `tbd_cart_items` ci
JOIN `tb_products` p ON p.ID = ci.product_id
WHERE ci.cart_id = @cp1_cart_id;

INSERT INTO `tb_orders` (`user_ID`, `total_amount`, `order_status`)
VALUES (@cp1_user_id, @cp1_total, 'Pending');
SET @cp1_order_id = LAST_INSERT_ID();

INSERT INTO `tbd_order_items` (`order_ID`, `product_offer_ID`, `quantity`, `unit_price`)
SELECT @cp1_order_id, ci.product_id, ci.quantity, p.current_price
FROM `tbd_cart_items` ci
JOIN `tb_products` p ON p.ID = ci.product_id
WHERE ci.cart_id = @cp1_cart_id;

-- Generar desglose en tb_buyer_orders (vendedor ID = 4)
INSERT INTO `tb_buyer_orders` (`order_ID`, `seller_ID`, `seller_order_status`, `subtotal`, `shipping_cost`, `discount_amount`)
VALUES (@cp1_order_id, 4, 'Pending', @cp1_total, 0.00, 0.00);

-- 6. Registrar domicilio para envío
INSERT INTO `tb_user_addresses` (`user_id`, `street`, `city`, `state`, `postal_code`, `country`)
VALUES (@cp1_user_id, 'Calle Juárez #45, Col. Centro', 'Xicotepec de Juárez', 'Puebla', '73080', 'MX');
SET @cp1_addr_id = LAST_INSERT_ID();

INSERT INTO `tbd_address_components` (`address_ID`, `value`, `component_type`, `status`, `creation_date`)
VALUES (@cp1_addr_id, 'Hogar', 'address_label', 1, NOW());

-- 7. Registrar método de pago: Tarjeta de débito (ID = 2) de 16 dígitos
INSERT INTO `tbd_user_payment_methods` (`user_id`, `payment_method_id`, `card_number`, `card_holder`, `card_expires`, `is_default`)
VALUES (@cp1_user_id, 2, '4152313456789012', 'CARLOS ALBERTO MENDOZA RUIZ', '08/2029', 1);
SET @cp1_user_pm_id = LAST_INSERT_ID();

-- 8. Registrar pago único y activar rol de 'buyer'
-- SET ROLE 'buyer';
UPDATE `tb_users` SET `role` = 'buyer' WHERE `ID` = @cp1_user_id;

INSERT INTO `tb_payments` (`order_ID`, `payment_method_ID`, `user_payment_method_ID`, `amount`, `currency`, `payment_status`, `transaction_reference`)
VALUES (@cp1_order_id, 2, @cp1_user_pm_id, @cp1_total, 'MXN', 'pending', CONCAT('TXN-CP1-', UUID()));
SET @cp1_payment_id = LAST_INSERT_ID();

-- 9. El sistema registra la transacción bancaria y la autoriza
CALL `sp_authorize_payment`(@cp1_payment_id);

-- 10. El sistema procesa la orden marcándola como atendida (descuenta stock)
CALL `sp_attend_order`(@cp1_order_id);

-- 11. El usuario recibe el producto en casa
CALL `sp_deliver_order`(@cp1_order_id);


-- ============================================================================
-- CASO DE PRUEBA 2: "Compra con detalles en el último pago, reclamación y reenvío"
-- ============================================================================
SET @cp2_user_id = 10; -- Usuario activo existente (kami)

-- 1. Crear carrito de compra con 10 productos aleatorios (cantidades entre 1 y 5)
DELETE FROM `tbd_cart_items` WHERE `cart_id` IN (SELECT `ID` FROM `tb_carts` WHERE `user_ID` = @cp2_user_id);
DELETE FROM `tb_carts` WHERE `user_ID` = @cp2_user_id;

INSERT INTO `tb_carts` (`user_ID`) VALUES (@cp2_user_id);
SET @cp2_cart_id = LAST_INSERT_ID();

INSERT INTO `tbd_cart_items` (`cart_id`, `product_id`, `quantity`)
SELECT @cp2_cart_id, `ID`, FLOOR(1 + RAND() * 5)
FROM `tb_products`
WHERE `status` = b'1' AND `current_stock` >= 10
ORDER BY RAND()
LIMIT 10;

-- 2. Realizar la orden de compra
SELECT @cp2_total := SUM(ci.quantity * p.current_price)
FROM `tbd_cart_items` ci
JOIN `tb_products` p ON p.ID = ci.product_id
WHERE ci.cart_id = @cp2_cart_id;

INSERT INTO `tb_orders` (`user_ID`, `total_amount`, `order_status`)
VALUES (@cp2_user_id, @cp2_total, 'Pending');
SET @cp2_order_id = LAST_INSERT_ID();

INSERT INTO `tbd_order_items` (`order_ID`, `product_offer_ID`, `quantity`, `unit_price`)
SELECT @cp2_order_id, ci.product_id, ci.quantity, p.current_price
FROM `tbd_cart_items` ci
JOIN `tb_products` p ON p.ID = ci.product_id
WHERE ci.cart_id = @cp2_cart_id;

INSERT INTO `tb_buyer_orders` (`order_ID`, `seller_ID`, `seller_order_status`, `subtotal`, `shipping_cost`, `discount_amount`)
VALUES (@cp2_order_id, 5, 'Pending', @cp2_total, 0.00, 0.00);
SET @cp2_seller_order_id = LAST_INSERT_ID();

-- 3. Registrar domicilio de envío alternativo (Trabajo)
INSERT INTO `tb_user_addresses` (`user_id`, `street`, `city`, `state`, `postal_code`, `country`)
VALUES (@cp2_user_id, 'Blvd. Atlixcáyotl #1499, Torre Ejecutiva Piso 4', 'Puebla', 'Puebla', '72810', 'MX');
SET @cp2_addr_id = LAST_INSERT_ID();

INSERT INTO `tbd_address_components` (`address_ID`, `value`, `component_type`, `status`, `creation_date`)
VALUES (@cp2_addr_id, 'Trabajo', 'address_label', 1, NOW());

-- 4. Registrar método de pago: Tarjeta de crédito (ID = 1) de 16 dígitos
INSERT INTO `tbd_user_payment_methods` (`user_id`, `payment_method_id`, `card_number`, `card_holder`, `card_expires`, `is_default`)
VALUES (@cp2_user_id, 1, '5412750012349876', 'FERNANDA KAMILA', '11/2029', 1);
SET @cp2_user_pm_id = LAST_INSERT_ID();

-- 5 y 6. Registrar 6 pagos mensuales: 5 autorizados y el 6to rechazado por "límite excedido de crédito"
-- SET ROLE 'buyer';
UPDATE `tb_users` SET `role` = 'buyer' WHERE `ID` = @cp2_user_id;

SET @cp2_monthly = ROUND(@cp2_total / 6, 2);
SET @cp2_last_monthly = @cp2_total - (@cp2_monthly * 5);

-- Mensualidades 1 a 5 (Autorizadas)
INSERT INTO `tb_payments` (`order_ID`, `payment_method_ID`, `user_payment_method_ID`, `amount`, `currency`, `payment_status`, `transaction_reference`)
VALUES (@cp2_order_id, 1, @cp2_user_pm_id, @cp2_monthly, 'MXN', 'pending', CONCAT('TXN-CP2-M1-', UUID()));
CALL `sp_authorize_payment`(LAST_INSERT_ID());

INSERT INTO `tb_payments` (`order_ID`, `payment_method_ID`, `user_payment_method_ID`, `amount`, `currency`, `payment_status`, `transaction_reference`)
VALUES (@cp2_order_id, 1, @cp2_user_pm_id, @cp2_monthly, 'MXN', 'pending', CONCAT('TXN-CP2-M2-', UUID()));
CALL `sp_authorize_payment`(LAST_INSERT_ID());

INSERT INTO `tb_payments` (`order_ID`, `payment_method_ID`, `user_payment_method_ID`, `amount`, `currency`, `payment_status`, `transaction_reference`)
VALUES (@cp2_order_id, 1, @cp2_user_pm_id, @cp2_monthly, 'MXN', 'pending', CONCAT('TXN-CP2-M3-', UUID()));
CALL `sp_authorize_payment`(LAST_INSERT_ID());

INSERT INTO `tb_payments` (`order_ID`, `payment_method_ID`, `user_payment_method_ID`, `amount`, `currency`, `payment_status`, `transaction_reference`)
VALUES (@cp2_order_id, 1, @cp2_user_pm_id, @cp2_monthly, 'MXN', 'pending', CONCAT('TXN-CP2-M4-', UUID()));
CALL `sp_authorize_payment`(LAST_INSERT_ID());

INSERT INTO `tb_payments` (`order_ID`, `payment_method_ID`, `user_payment_method_ID`, `amount`, `currency`, `payment_status`, `transaction_reference`)
VALUES (@cp2_order_id, 1, @cp2_user_pm_id, @cp2_monthly, 'MXN', 'pending', CONCAT('TXN-CP2-M5-', UUID()));
CALL `sp_authorize_payment`(LAST_INSERT_ID());

-- Mensualidad 6 (Rechazada por límite excedido de crédito)
INSERT INTO `tb_payments` (`order_ID`, `payment_method_ID`, `user_payment_method_ID`, `amount`, `currency`, `payment_status`, `transaction_reference`, `failure_reason`)
VALUES (@cp2_order_id, 1, @cp2_user_pm_id, @cp2_last_monthly, 'MXN', 'failed', CONCAT('TXN-CP2-M6-', UUID()), 'Límite excedido de crédito');
SET @cp2_failed_pay_id = LAST_INSERT_ID();

INSERT INTO `tb_payment_transaction` (`payment_id`, `transaction_reference`, `amount`, `status`)
VALUES (@cp2_failed_pay_id, CONCAT('BANK-DECLINED-', UUID()), @cp2_last_monthly, 'failed: limite excedido de credito');

-- 7. El sistema procesa la orden marcándola como atendida
CALL `sp_attend_order`(@cp2_order_id);

-- 8. El usuario recibe el pedido
CALL `sp_deliver_order`(@cp2_order_id);

-- 9. El usuario reclama la devolución de 1 producto que llegó dañado
SELECT `product_offer_ID` INTO @cp2_damaged_prod_id
FROM `tbd_order_items`
WHERE `order_ID` = @cp2_order_id
LIMIT 1;

INSERT INTO `tb_returns` (`order_ID`, `product_offer_ID`, `requested_by`, `quantity`, `return_reason`, `return_status`, `inspection_notes`)
VALUES (@cp2_order_id, @cp2_damaged_prod_id, @cp2_user_id, 1, 'Damaged', 'Authorized', 'Empaque aplastado y producto dañado reportado por cliente');
SET @cp2_return_id = LAST_INSERT_ID();

INSERT INTO `tbd_return_items` (`return_ID`, `order_item_ID`, `quantity`, `item_condition`, `disposition`, `approved_refund_amount`, `item_status`)
VALUES (@cp2_return_id, @cp2_damaged_prod_id, 1, 'Damaged', 'SupplierReturn', 0.00, 'Approved');

-- 10. El sistema realiza el reenvío del producto en buenas condiciones
UPDATE `tb_products` SET `current_stock` = `current_stock` - 1 WHERE `ID` = @cp2_damaged_prod_id;

INSERT INTO `tb_shipments` (`seller_order_ID`, `carrier`, `tracking_number`, `shipment_status`, `shipped_date`, `estimated_delivery_date`, `delivered_date`)
VALUES (@cp2_seller_order_id, 'DHL Express (Reenvío Garantía)', CONCAT('RPL', LPAD(@cp2_return_id, 8, '0')), 'Delivered', NOW(), NOW() + INTERVAL 2 DAY, NOW());

UPDATE `tb_returns`
SET `return_status` = 'Completed', `received_date` = NOW(), `completed_date` = NOW()
WHERE `return_ID` = @cp2_return_id;


-- ============================================================================
-- CASO DE PRUEBA 3: "Compra exitosa con cancelación parcial, ajuste y reembolso parcial"
-- ============================================================================
SET @cp3_user_id = 331; -- Usuario activo existente

-- 1. Crear carrito de 3 productos de la misma categoría (Categoría 1: Ropa) con cantidades entre 1 y 10
DELETE FROM `tbd_cart_items` WHERE `cart_id` IN (SELECT `ID` FROM `tb_carts` WHERE `user_ID` = @cp3_user_id);
DELETE FROM `tb_carts` WHERE `user_ID` = @cp3_user_id;

INSERT INTO `tb_carts` (`user_ID`) VALUES (@cp3_user_id);
SET @cp3_cart_id = LAST_INSERT_ID();

INSERT INTO `tbd_cart_items` (`cart_id`, `product_id`, `quantity`) VALUES
(@cp3_cart_id, 5001, 2),
(@cp3_cart_id, 5013, 4),
(@cp3_cart_id, 5037, 1);

-- 2. Realizar la orden de compra
SELECT @cp3_total := SUM(ci.quantity * p.current_price)
FROM `tbd_cart_items` ci
JOIN `tb_products` p ON p.ID = ci.product_id
WHERE ci.cart_id = @cp3_cart_id;

INSERT INTO `tb_orders` (`user_ID`, `total_amount`, `order_status`)
VALUES (@cp3_user_id, @cp3_total, 'Pending');
SET @cp3_order_id = LAST_INSERT_ID();

INSERT INTO `tbd_order_items` (`order_ID`, `product_offer_ID`, `quantity`, `unit_price`)
SELECT @cp3_order_id, ci.product_id, ci.quantity, p.current_price
FROM `tbd_cart_items` ci
JOIN `tb_products` p ON p.ID = ci.product_id
WHERE ci.cart_id = @cp3_cart_id;

INSERT INTO `tb_buyer_orders` (`order_ID`, `seller_ID`, `seller_order_status`, `subtotal`, `shipping_cost`, `discount_amount`)
VALUES (@cp3_order_id, 8, 'Pending', @cp3_total, 0.00, 0.00);
SET @cp3_seller_order_id = LAST_INSERT_ID();

-- 3. Registrar domicilio de envío con etiqueta "Casa Papas"
INSERT INTO `tb_user_addresses` (`user_id`, `street`, `city`, `state`, `postal_code`, `country`)
VALUES (@cp3_user_id, 'Av. Reforma #810, Col. La Paz', 'Puebla', 'Puebla', '72160', 'MX');
SET @cp3_addr_id = LAST_INSERT_ID();

INSERT INTO `tbd_address_components` (`address_ID`, `value`, `component_type`, `status`, `creation_date`)
VALUES (@cp3_addr_id, 'Casa Papas', 'address_label', 1, NOW());

-- 4. Registrar método de pago: Tarjeta digital (Spin) de 16 dígitos
SELECT `ID` INTO @pm_spin_id FROM `tb_payment_methods` WHERE `code` = 'digital_card_spin' LIMIT 1;

INSERT INTO `tbd_user_payment_methods` (`user_id`, `payment_method_id`, `card_number`, `card_holder`, `card_expires`, `is_default`)
VALUES (@cp3_user_id, @pm_spin_id, '4213160098765432', 'USUARIO SPIN TEST 3', '05/2030', 1);
SET @cp3_user_pm_id = LAST_INSERT_ID();

-- 5. Registrar un solo pago por el costo total de la compra
INSERT INTO `tb_payments` (`order_ID`, `payment_method_ID`, `user_payment_method_ID`, `amount`, `currency`, `payment_status`, `transaction_reference`)
VALUES (@cp3_order_id, @pm_spin_id, @cp3_user_pm_id, @cp3_total, 'MXN', 'pending', CONCAT('TXN-CP3-', UUID()));
SET @cp3_payment_id = LAST_INSERT_ID();

CALL `sp_authorize_payment`(@cp3_payment_id);

-- 6. El sistema procesa la orden marcándola como atendida
CALL `sp_attend_order`(@cp3_order_id);

-- 7. El usuario cancela un producto del pedido (Producto 5037)
SELECT `line_total`, `quantity` INTO @cp3_cancelled_amount, @cp3_cancelled_qty
FROM `tbd_order_items`
WHERE `order_ID` = @cp3_order_id AND `product_offer_ID` = 5001;

INSERT INTO `tb_order_cancellations` (`order_ID`, `seller_order_ID`, `product_offer_ID`, `requested_by`, `cancellation_reason`, `cancellation_status`, `resolved_date`)
VALUES (@cp3_order_id, @cp3_seller_order_id, 5001, @cp3_user_id, 'Cliente solicitó cancelación parcial de artículo antes de envío', 'Completed', NOW());
SET @cp3_cancel_id = LAST_INSERT_ID();

INSERT INTO `tbd_cancellation_items` (`cancellation_id`, `order_item_id`, `quantity`, `reason`)
VALUES (@cp3_cancel_id, 5001, @cp3_cancelled_qty, 'Cancelación parcial solicitada por cliente');

-- 8. El sistema actualiza la orden de compra y devuelve el inventario del producto cancelado
DELETE FROM `tbd_order_items` WHERE `order_ID` = @cp3_order_id AND `product_offer_ID` = 5001;

UPDATE `tb_products` SET `current_stock` = `current_stock` + @cp3_cancelled_qty WHERE `ID` = 5001;

UPDATE `tb_orders` SET `total_amount` = `total_amount` - @cp3_cancelled_amount WHERE `ID` = @cp3_order_id;
UPDATE `tb_buyer_orders` SET `subtotal` = `subtotal` - @cp3_cancelled_amount WHERE `ID` = @cp3_seller_order_id;

-- 9. El sistema realiza el reembolso parcial del monto cancelado
INSERT INTO `tb_refunds` (`payment_ID`, `cancellation_ID`, `amount`, `currency`, `refund_reason`, `refund_status`, `provider_reference`, `completed_date`)
VALUES (@cp3_payment_id, @cp3_cancel_id, @cp3_cancelled_amount, 'MXN', 'Reembolso parcial por cancelación de producto 5037', 'Completed', CONCAT('REF-CP3-', UUID()), NOW());

-- 10 y 11. El sistema realiza el envío y el cliente recibe el pedido
CALL `sp_deliver_order`(@cp3_order_id);


-- ============================================================================
-- CASO DE PRUEBA 4: "Compra exitosa del mismo proveedor con entrega en punto de recolección"
-- ============================================================================
SET @cp4_user_id = 100;     -- Comprador activo
SET @cp4_provider_id = 15; -- Proveedor único para los 3 productos

-- Vincular 3 productos activos al mismo proveedor en tbd_products_users_providers
INSERT IGNORE INTO `tbd_products_users_providers` (`user_ID`, `product_ID`, `type_ownership`, `status`, `available_date`) VALUES
(@cp4_provider_id, 5046, 'Seller', b'1', NOW()),
(@cp4_provider_id, 8007, 'Seller', b'1', NOW()),
(@cp4_provider_id, 4058, 'Seller', b'1', NOW());

-- 1. Crear carrito de 3 productos del mismo proveedor (cantidades entre 1 y 3)
DELETE FROM `tbd_cart_items` WHERE `cart_id` IN (SELECT `ID` FROM `tb_carts` WHERE `user_ID` = @cp4_user_id);
DELETE FROM `tb_carts` WHERE `user_ID` = @cp4_user_id;

INSERT INTO `tb_carts` (`user_ID`) VALUES (@cp4_user_id);
SET @cp4_cart_id = LAST_INSERT_ID();

INSERT INTO `tbd_cart_items` (`cart_id`, `product_id`, `quantity`) VALUES
(@cp4_cart_id, 5046, 1),
(@cp4_cart_id, 8007, 4),
(@cp4_cart_id, 4058, 3);

-- 2. Realizar la orden de compra
SELECT @cp4_total := SUM(ci.quantity * p.current_price)
FROM `tbd_cart_items` ci
JOIN `tb_products` p ON p.ID = ci.product_id
WHERE ci.cart_id = @cp4_cart_id;

INSERT INTO `tb_orders` (`user_ID`, `total_amount`, `order_status`)
VALUES (@cp4_user_id, @cp4_total, 'Pending');
SET @cp4_order_id = LAST_INSERT_ID();

INSERT INTO `tbd_order_items` (`order_ID`, `product_offer_ID`, `quantity`, `unit_price`)
SELECT @cp4_order_id, ci.product_id, ci.quantity, p.current_price
FROM `tbd_cart_items` ci
JOIN `tb_products` p ON p.ID = ci.product_id
WHERE ci.cart_id = @cp4_cart_id;

INSERT INTO `tb_buyer_orders` (`order_ID`, `seller_ID`, `seller_order_status`, `subtotal`, `shipping_cost`, `discount_amount`)
VALUES (@cp4_order_id, @cp4_provider_id, 'Pending', @cp4_total, 0.00, 0.00);
SET @cp4_seller_order_id = LAST_INSERT_ID();

-- 3. Registrar domicilio de hogar
INSERT INTO `tb_user_addresses` (`user_id`, `street`, `city`, `state`, `postal_code`, `country`)
VALUES (@cp4_user_id, 'Privada de los Pinos #12, Col. El Tabacal', 'Xicotepec de Juárez', 'Puebla', '73080', 'MX');
SET @cp4_addr_id = LAST_INSERT_ID();

INSERT INTO `tbd_address_components` (`address_ID`, `value`, `component_type`, `status`, `creation_date`)
VALUES (@cp4_addr_id, 'Hogar', 'address_label', 1, NOW());

-- 4. Registrar método de pago: Transferencia SPEI (referencia numérica de 16 dígitos)
SELECT `ID` INTO @pm_spei_id FROM `tb_payment_methods` WHERE `code` = 'spei_transfer' LIMIT 1;

INSERT INTO `tbd_user_payment_methods` (`user_id`, `payment_method_id`, `card_number`, `card_holder`, `card_expires`, `is_default`)
VALUES (@cp4_user_id, @pm_spei_id, '6461801104000001', 'CUENTA SPEI CLIENTE 4', '12/2030', 1);
SET @cp4_user_pm_id = LAST_INSERT_ID();

-- 5. Registrar pago único por el total
INSERT INTO `tb_payments` (`order_ID`, `payment_method_ID`, `user_payment_method_ID`, `amount`, `currency`, `payment_status`, `transaction_reference`)
VALUES (@cp4_order_id, @pm_spei_id, @cp4_user_pm_id, @cp4_total, 'MXN', 'pending', CONCAT('SPEI-CP4-', UUID()));
SET @cp4_payment_id = LAST_INSERT_ID();

CALL `sp_authorize_payment`(@cp4_payment_id);

-- 6. Procesar orden como atendida
CALL `sp_attend_order`(@cp4_order_id);

-- 7 y 8. Envío con intento fallido en domicilio y entrega en punto de recolección
INSERT INTO `tb_shipments` (`seller_order_ID`, `carrier`, `tracking_number`, `tracking_url`, `shipment_status`, `shipped_date`, `estimated_delivery_date`)
VALUES (@cp4_seller_order_id, 'Estafeta - Punto de Recolección Sucursal Centro', CONCAT('PKP', LPAD(@cp4_seller_order_id, 8, '0')), 'https://rastreo.ejemplo.mx/pickup', 'DeliveryFailed', NOW(), NOW() + INTERVAL 2 DAY);
SET @cp4_shipment_id = LAST_INSERT_ID();

-- Cliente recoge en punto de recolección
UPDATE `tb_shipments`
SET `shipment_status` = 'Delivered', `delivered_date` = NOW()
WHERE `shipment_ID` = @cp4_shipment_id;

UPDATE `tb_buyer_orders` SET `seller_order_status` = 'Delivered' WHERE `ID` = @cp4_seller_order_id;
UPDATE `tb_orders` SET `order_status` = 'Delivered' WHERE `ID` = @cp4_order_id;


-- ============================================================================
-- CASO DE PRUEBA 5: "Compra fallida por falta de inventario"
-- ============================================================================
SET @cp5_user_id = 20;
SET @cp5_prod_id = 6009;

-- Guardar stock original y simular disponibilidad insuficiente (solo 2 unidades disponibles vs 5 solicitadas)
SELECT `current_stock`, `current_price` INTO @cp5_orig_stock, @cp5_prod_price
FROM `tb_products` WHERE `ID` = @cp5_prod_id;

UPDATE `tb_products` SET `current_stock` = 2 WHERE `ID` = @cp5_prod_id;

-- 1. Crear carrito de 1 producto con 5 unidades
DELETE FROM `tbd_cart_items` WHERE `cart_id` IN (SELECT `ID` FROM `tb_carts` WHERE `user_ID` = @cp5_user_id);
DELETE FROM `tb_carts` WHERE `user_ID` = @cp5_user_id;

INSERT INTO `tb_carts` (`user_ID`) VALUES (@cp5_user_id);
SET @cp5_cart_id = LAST_INSERT_ID();

INSERT INTO `tbd_cart_items` (`cart_id`, `product_id`, `quantity`)
VALUES (@cp5_cart_id, @cp5_prod_id, 5);

-- 2. Realizar la orden de compra
SET @cp5_total = @cp5_prod_price * 5;

INSERT INTO `tb_orders` (`user_ID`, `total_amount`, `order_status`)
VALUES (@cp5_user_id, @cp5_total, 'Pending');
SET @cp5_order_id = LAST_INSERT_ID();

INSERT INTO `tbd_order_items` (`order_ID`, `product_offer_ID`, `quantity`, `unit_price`)
VALUES (@cp5_order_id, @cp5_prod_id, 5, @cp5_prod_price);

INSERT INTO `tb_buyer_orders` (`order_ID`, `seller_ID`, `seller_order_status`, `subtotal`, `shipping_cost`, `discount_amount`)
VALUES (@cp5_order_id, 12, 'Pending', @cp5_total, 0.00, 0.00);
SET @cp5_seller_order_id = LAST_INSERT_ID();

-- 3. Registrar domicilio de hogar
INSERT INTO `tb_user_addresses` (`user_id`, `street`, `city`, `state`, `postal_code`, `country`)
VALUES (@cp5_user_id, 'Calle Hidalgo #204, Col. Centro', 'Huauchinango', 'Puebla', '73160', 'MX');

-- 4. Registrar método de pago: Cupón de regalo (código de 16 dígitos)
SELECT `ID` INTO @pm_coupon_id FROM `tb_payment_methods` WHERE `code` = 'gift_coupon' LIMIT 1;

INSERT INTO `tbd_user_payment_methods` (`user_id`, `payment_method_id`, `card_number`, `card_holder`, `card_expires`, `is_default`)
VALUES (@cp5_user_id, @pm_coupon_id, '9900112233445566', 'CUPON REGALO #9900', '12/2026', 1);
SET @cp5_user_pm_id = LAST_INSERT_ID();

INSERT INTO `tb_payments` (`order_ID`, `payment_method_ID`, `user_payment_method_ID`, `amount`, `currency`, `payment_status`, `transaction_reference`)
VALUES (@cp5_order_id, @pm_coupon_id, @cp5_user_pm_id, @cp5_total, 'MXN', 'authorized', CONCAT('CPN-USED-', UUID()));
SET @cp5_payment_id = LAST_INSERT_ID();

-- 5 y 6. Validación de inventario: Orden no atendida por falta de stock, cancelación y reasignación de cupón
INSERT INTO `tb_order_cancellations` (`order_ID`, `seller_order_ID`, `product_offer_ID`, `requested_by`, `cancellation_reason`, `cancellation_status`, `resolved_date`)
VALUES (@cp5_order_id, @cp5_seller_order_id, @cp5_prod_id, @cp5_user_id, 'Orden no atendida: inventario insuficiente (solicitado: 5, disponible: 2)', 'Completed', NOW());
SET @cp5_cancel_id = LAST_INSERT_ID();

INSERT INTO `tbd_cancellation_items` (`cancellation_id`, `order_item_id`, `quantity`, `reason`)
VALUES (@cp5_cancel_id, @cp5_prod_id, 5, 'Falta de inventario en almacén');

-- Cancelar orden, orden de vendedor y liberar/reasignar cupón de regalo
UPDATE `tb_buyer_orders` SET `seller_order_status` = 'Cancelled' WHERE `ID` = @cp5_seller_order_id;
UPDATE `tb_orders` SET `order_status` = 'Cancelled' WHERE `ID` = @cp5_order_id;
UPDATE `tb_payments` SET `payment_status` = 'refunded', `failure_reason` = 'Cupón reasignado al usuario por falta de inventario' WHERE `ID` = @cp5_payment_id;

INSERT INTO `tb_refunds` (`payment_ID`, `cancellation_ID`, `amount`, `currency`, `refund_reason`, `refund_status`, `provider_reference`, `completed_date`)
VALUES (@cp5_payment_id, @cp5_cancel_id, @cp5_total, 'MXN', 'Reasignación automática de cupón de regalo 9900112233445566 por falta de inventario', 'Completed', CONCAT('CPN-REASSIGN-', UUID()), NOW());

-- Restaurar el stock original del producto 5009 para no alterar el catálogo base
UPDATE `tb_products` SET `current_stock` = @cp5_orig_stock WHERE `ID` = @cp5_prod_id;

-- ============================================================================
-- CONSULTA DE VERIFICACIÓN DE RESULTADOS Y AUDITORÍA (tb_logs)
-- ============================================================================
SELECT `ID`, `user_ID`, `total_amount`, `order_status`, `creation_date`
FROM `tb_orders`
WHERE `ID` IN (@cp1_order_id, @cp2_order_id, @cp3_order_id, @cp4_order_id, @cp5_order_id);

SELECT * FROM `tb_logs` ORDER BY `ID` DESC LIMIT 25;