# Comandos para Probar la App

## Clientes

### Crear Cliente
```
Crea un cliente llamado Juan con cedula 12345678
```
**Respuesta esperada**: Cliente creado con ID en result

### Crear Cliente con Teléfono
```
Crea un cliente llamado Maria Garcia con cedula 98765432 y teléfono 04121234567
```

### Listar Clientes
```
Muéstrame todos los clientes
```
**Respuesta esperada**: Array de clientes en result

### Listar Clientes (alternativo)
```
Lista de clientes
```

## Usuarios

### Crear Usuario
```
Crea un usuario llamado carlos con usuario carlos y contraseña seg123
```

### Listar Usuarios
```
Muéstrame los usuarios
```

## Productos

### Crear Producto
```
Crea un producto llamado Laptop con precio 1500
```

### Crear Categoría
```
Crea una categoría de productos llamada Electrónica
```

### Listar Productos
```
Muéstrame todos los productos
```

## Ventas

### Crear Venta
```
Registra una venta al cliente 1 de 2 unidades del producto 4 a 850 cada una
```

### Listar Ventas
```
Muéstrame todas las ventas
```

## Proveedores

### Crear Proveedor
```
Crea un proveedor llamado Tech Solutions con email tech@example.com
```

### Listar Proveedores
```
Muéstrame todos los proveedores
```

## Compras

### Crear Compra
```
Registra una compra al proveedor 1 de 10 unidades del producto 2 a 500 cada una
```

### Listar Compras
```
Muéstrame todas las compras
```

## Empresa

### Crear Empresa
```
Crea una empresa llamada Mi Empresa SRL con RIF 12345678
```

### Listar Empresas
```
Muéstrame todas las empresas
```

## Notas Importantes

- ✅ Los comandos funcionan en **Español**
- ✅ **Sin acentos** preferiblemente (aunque pueden funcionar)
- ✅ **Sin tildes especiales** (@, #, $) en los nombres
- ✅ Respeta el **formato de números de cédula/RIF**
- ✅ Los **IDs existentes** deben usarse para relacionar (cliente 1, producto 4, etc)

## Secuencia de Prueba Recomendada

1. **Crear cliente**
   - "Crea un cliente llamado Pedro con cedula 11111111"

2. **Listar clientes**
   - "Muéstrame todos los clientes"

3. **Crear producto**
   - "Crea un producto llamado Mouse con precio 25"

4. **Crear venta**
   - "Registra una venta al cliente 1 de 5 unidades del producto 1 a 25 cada una"

5. **Listar ventas**
   - "Muéstrame todas las ventas"

## Interpretar Respuesta JSON

```json
{
  "success": true,           // Operación exitosa
  "input": "...",            // Comando que ingresaste
  "type": "text",            // Tipo de input
  "intent": null,            // Intención detectada (null ahora)
  "entity_type": null,       // Tipo de entidad (null ahora)
  "action": null,            // Acción (null ahora)
  "confidence": null,        // Confianza (null ahora)
  "result": {...},           // Datos retornados
  "message": "...",          // Mensaje amigable
  "error": null              // Error si hubiera
}
```

**Si `success: false`**, ver campo `error` para detalles.

---

¡A probar la app! 🚀
