# Prácticas de la asignatura Optativa I: Bases De Datos en la Nube
## Ing. en Tecnologías de la Información e Innovación Digital
### Docente: M.T.I Marco A. Ramrírez Hernandez
Periodo: Septiembre - Diciembre 2026

---
|ID|Numero de Práctica|Nombre de la Práctica|Potenciador|Estatus
|---|---|---|---|---|
| 1. | Práctica 02 | Conexión Remota en MYSQL | 42 | Concluida |
| 2. | Conexiones Remotas para Bases de Datos SQL | Crear y administrar usuarios y privilegios para conexiones desde internet o redes locales | 60 | Concluida |
| 3. | Práctica 03 | Manipulación de datos en conexiones remotas | 50 | Concluida |


# Práctica 02 - Base de Datos `db_test`

## 📋 Descripción General
Esta práctica consiste en el diseño, implementación, conexión remota y respaldo de la base de datos relacional **`db_test`** utilizando MySQL (versión 8.0.36). El proyecto incluye la gestión de usuarios, pruebas de operaciones colaborativas en red y un sistema automatizado de registro de auditoría (*logs*) mediante disparadores (*triggers*) para el seguimiento de cambios.

---

## 🗄️ Estructura de la Base de Datos

La base de datos contiene las siguientes tablas principales:

### 1. `tb_users`
Almacena la información de los usuarios registrados en el sistema.
* **`ID`**: Identificador único (Clave primaria, autoincrementable).
* **`email`**: Correo electrónico del usuario (Único, obligatorio).
* **`nickname`**: Nombre de usuario o apodo (Único, obligatorio).
* **`password`**: Contraseña cifrada del usuario.
* **`creation_date`**: Fecha y hora de creación del registro.
* **`last_update`**: Fecha y hora de la última modificación.
* **`last_login`**: Fecha y hora del último acceso.

### 2. `tb_logs`
Almacena el historial de auditoría de las acciones realizadas sobre la tabla de usuarios.
* **`ID`**: Identificador único del registro de log.
* **`table_name`**: Nombre de la tabla afectada (`tb_users`).
* **`operation`**: Tipo de operación realizada (`Create`, `Read`, `Update`, `Delete`).
* **`db_users`**: Usuario de la base de datos y host desde el que se ejecutó la acción.
* **`description`**: Detalle descriptivo del cambio o evento registrado.
* **`operation_date`**: Marca de tiempo exacta de cuándo ocurrió el evento.
* **`operation_status`**: Estado de la operación (Bit lógico).

---

## 🌐 Conexión Colaborativa y Pruebas Remotas
Durante el desarrollo de la práctica, se realizaron conexiones hacia instancias de bases de datos de compañeros de equipo mediante comandos y configuración de red para simular un entorno distribuido:
* **Conexión remota**: Se establecieron enlaces mediante IP/host para acceder de manera concurrente al servidor de base de datos de la estación de trabajo de un compañero.
* **Ejecución de operaciones CRUD**: Se realizaron pruebas de inserción (`INSERT`), actualización (`UPDATE`) y eliminación (`DELETE`) de registros de manera remota.
* **Trazabilidad en Logs**: Gracias a los registros almacenados en `tb_logs`, se pudo comprobar qué usuario y desde qué equipo (*host*) se efectuaron modificaciones específicas (por ejemplo, cambios de correos electrónicos y bajas de registros).

---

## ⚙️ Automatización (Triggers)
Para garantizar la integridad y trazabilidad de las acciones colaborativas, se implementaron tres triggers en la tabla `tb_users`:
1. **`trg_users_after_insert`**: Registra automáticamente en `tb_logs` cada vez que se crea un nuevo usuario.
2. **`trg_users_after_update`**: Detecta cambios específicos en campos como `email` o `nickname` y guarda los valores anteriores y nuevos en el log.
3. **`trg_users_after_delete`**: Almacena un registro de auditoría cuando un usuario es eliminado del sistema.