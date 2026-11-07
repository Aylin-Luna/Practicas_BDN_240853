# Práctica 03: Manipulación de Datos, Relaciones, Procedimientos, Funciones y Eventos en Conexiones Remotas
## Ing. en Tecnologías de la Información e Innovación Digital
### Docente: M.T.I Marco A. Ramírez Hernández
Periodo: Septiembre - Diciembre 2026

## 📌 Descripción del Proyecto
Este repositorio contiene la implementación, administración remota en un Servidor Privado Virtual (VPS) y documentación técnica integral correspondiente a la **Práctica 03: Bases de Datos en la Nube**. 

En este proyecto se consolidan 25 tablas relacionales de un sistema de **E-Commerce**, incorporando mecanismos avanzados de auditoría (72 triggers en `tb_logs`), 25 vistas de trazabilidad y negocio, control de acceso mediante 7 roles MySQL, funciones y procedimientos almacenados parametrizables para simulación masiva (7,500 usuarios y 7,000 productos), automatización con eventos programados, respaldos progresivos y documentación actualizada mediante **Archify**.

---

## 🌐 Enlaces Rápidos (GitHub Pages)

Consulta la documentación técnica interactiva del sistema desplegada a través de GitHub Pages:

* 📖 **[Diccionario de Datos Interactivo (HTML)]([https://aylin-luna.github.io/Practicas_BDN_240853/])** *(Estructura detallada de 25 tablas, tipos de datos, restricciones y llaves PK/FK)*
* 🗺️ **[Modelo Entidad-Relación Extendido (MERE / EER)]([https://aylin-luna.github.io/Practicas_BDN_240853/])** *(Diagrama relacional completo con la arquitectura lógica del E-Commerce)*

---

## 🛠️ Estructura del Repositorio

```text
├── docs/
│   ├── diccionario_datos.html      # Diccionario de datos interactivo generado con Archify
│   └── imagenes/
│       └── MERE_Practica03.png      # Exportación en alta resolución del esquema EER
├── scripts/
│   ├── 01_schema_25_tablas.sql     # DDL de creación e integridad referencial (25 tablas)
│   ├── 02_triggers_auditoria.sql   # Implementación de los 72 triggers de bitácora
│   ├── 03_vistas_trazabilidad.sql  # Vistas de auditoría (24) y Productos por Categoría (1)
│   ├── 04_roles_y_usuarios.sql     # Script de seguridad, 7 roles y privilegios de acceso remoto
│   ├── 05_rutinas_y_eventos.sql    # Procedimiento general de simulación, funciones y eventos SQL
│   ├── 06_poblacion_usuarios.sql   # Ejecución de Test 1, Test 2 y Test 3 (7,500 usuarios)
│   ├── 07_poblacion_productos.sql  # Inserción masiva remota de 7,000 productos (seller1 y seller2)
│   └── 08_consultas_validacion.sql # Consultas de verificación, auditoría e integridad
├── backups/
│   ├── backup_sesion1_inicial.sql   # Respaldo de estructura base y seguridad
│   ├── backup_sesion2_rutinas.sql   # Respaldo con triggers, vistas y procedimientos
│   └── backup_sesion3_final.sql     # Respaldo completo con 14,500+ registros generados
└── README.md                        # Documentación general y reporte de evidencias

```

---

## 📐 Modelo Entidad-Relación Extendido (MERE / EER)

A continuación se presenta la arquitectura visual del sistema de E-Commerce (25 tablas):

*Para explorar el diagrama navegable o consultar detalles de relaciones específicas, visita el [Modelo EER en GitHub Pages]([https://aylin-luna.github.io/Practicas_BDN_240853/]).*

---

## 📊 Resumen de la Arquitectura del Sistema

### 1. Estructura y Seguridad (25 Tablas y 7 Roles)

* **Tablas Operativas (24):** `tb_users`, `tb_people`, `tb_products`, `tb_categories`, `tb_subcategories`, `tb_suppliers`, `tb_carts`, `tb_cart_items`, `tb_orders`, `tb_order_items`, `tb_payments`, `tb_transactions`, `tb_shipments`, `tb_addresses`, `tb_countries`, `tb_states`, `tb_cities`, `tb_reviews`, `tb_coupons`, `tb_wishlists`, `tb_inventory`, `tb_roles`, `tb_user_roles`, `tb_permissions`.
* **Bitácora (1):** `tb_logs` (recolecta cambios de `INSERT`, `UPDATE` y `DELETE`).
* **Matriz de Seguridad:** Roles `superadmin`, `admin`, `support`, `seller`, `buyer`, `common_user` y `user_not_registered` configurados con asignaciones y roles por defecto.

### 2. Auditoría y Trazabilidad (72 Triggers y 25 Vistas)

* Cada una de las 24 tablas operativas cuenta con 3 triggers (`AFTER INSERT`, `AFTER UPDATE`, `AFTER DELETE`) que alimentan `tb_logs` registrando usuario remoto, fecha, tabla y detalle del cambio.
* 24 vistas cruzan la información operativa con la bitácora para auditoría remota, complementadas con la vista **`vw_products_by_category`** (clasificación por categoría, subcategoría y disponibilidad).

### 3. Rutinas y Simulación Masiva

* **Procedimiento Generador:** `sp_generate_users(p_qty, p_gender, p_country_id, p_min_age, p_max_age, p_prob_active)`
* **Población de Usuarios (7,500 total):**
* **Test 1:** 500 usuarios masculinos de Estados Unidos.
* **Test 2:** 2,000 usuarios multinacionales (rango de edad 19-35 años).
* **Test 3:** 5,000 usuarios con regla probabilística (80% activos `b'1'`, 20% inactivos `b'0'`).


* **Población de Productos (7,000 total):**
* **`seller1`:** 5,000 productos asignados.
* **`seller2`:** 2,000 productos asignados.
* *Garantía:* Mínimo 5 productos por categoría/subcategoría e inclusión de productos descontinuados (`status = b'0'`).



---

## 📚 Diccionario de Datos y Documentación (Archify)

El Diccionario de Datos ha sido compilado y exportado mediante **Archify** para reflejar fielmente la base de datos desplegada en el VPS:

* Especificación de claves primarias ($PK$) y foráneas ($FK$).
* Tipos de datos, longitudes, valores por defecto y nulabilidad.
* Restricciones de integridad ($UNIQUE$, $CHECK$, dominios de estado binario).

Accede a la versión interactiva completa en el [Diccionario de Datos en GitHub Pages](https://aylin-luna.github.io/Practicas_BDN_240853/).

---

## ⚡ Guía de Instalación y Replicación

Sigue estos pasos para desplegar la práctica en tu entorno MySQL remoto o local:

1. **Clonar el repositorio:**
```bash
git clone [https://github.com/Aylin-Luna/Practicas_BDN_240853.git]
cd Practicas_BDN_240853

```


2. **Ejecutar scripts de construcción en el servidor MySQL:**
```bash
# 1. Crear estructura de tablas
mysql -u root -p -h TU_IP_VPS < scripts/01_schema_25_tablas.sql

# 2. Implementar triggers de auditoría y vistas
mysql -u root -p -h TU_IP_VPS < scripts/02_triggers_auditoria.sql
mysql -u root -p -h TU_IP_VPS < scripts/03_vistas_trazabilidad.sql

# 3. Configurar seguridad y roles
mysql -u root -p -h TU_IP_VPS < scripts/04_roles_y_usuarios.sql

# 4. Cargar rutinas, funciones y eventos
mysql -u root -p -h TU_IP_VPS < scripts/05_rutinas_y_eventos.sql

```


3. **Ejecutar simulaciones de carga:**
```bash
mysql -u superadmin -p -h TU_IP_VPS < scripts/06_poblacion_usuarios.sql
mysql -u seller1 -p -h TU_IP_VPS < scripts/07_poblacion_productos.sql

```


4. **Validación de resultados:**
```bash
mysql -u superadmin -p -h TU_IP_VPS < scripts/08_consultas_validacion.sql

```



---

## 👥 Integrantes y Roles

* **Aylin Esteban Luna** - *Administradora de Base de Datos / Desarrollo SQL*

```

```