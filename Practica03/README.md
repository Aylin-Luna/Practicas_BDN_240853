# Modelo EER interactivo

Abre `index.html` en un navegador moderno. La página funciona localmente y lleva el esquema del respaldo integrado; no requiere servidor ni dependencias de JavaScript.

- El lienzo permite mover tarjetas, desplazarse y hacer zoom. Usa **Fit to view** para encuadrar el esquema.
- Busca tablas o columnas desde el campo superior. Selecciona una columna o una FK para consultar sus detalles y resaltar la relación.
- Las seis vistas incluyen su definición SQL extraída del dump.
- `schema-data.json` contiene el esquema procesado en formato JSON, incluidas columnas, restricciones, vistas y conteos de filas insertadas.

Los conteos representan filas explícitas en sentencias `INSERT` del respaldo `backups/141026.sql`; no son conteos consultados en una instancia activa de MySQL.

## Interacciones del lienzo

- Pasa sobre una tabla o columna para iluminar las relaciones implicadas y atenuar el resto; las FK y columnas referenciadas quedan marcadas. Haz clic en un campo para ver tipo, defaults, restricciones y referencias.
- Arrastra tarjetas; el trazado de relaciones se actualiza durante el movimiento. Pan en el fondo y zoom con rueda o controles. Fit to view reencuadra con transici?n.
- La barra flotante combina b?squeda por tabla/campo con filtros de cardinalidad y volumen de filas.
