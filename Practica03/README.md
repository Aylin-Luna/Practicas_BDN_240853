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

* 📖 **[Diccionario de Datos Interactivo (HTML)](https://aylin-luna.github.io/Practicas_BDN_240853/)** *(Estructura detallada de 25 tablas, tipos de datos, restricciones y llaves PK/FK)*
* 🗺️ **[Modelo Entidad-Relación Extendido (MERE / EER)](https://aylin-luna.github.io/Practicas_BDN_240853/)** *(Diagrama relacional completo con la arquitectura lógica del E-Commerce)*

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