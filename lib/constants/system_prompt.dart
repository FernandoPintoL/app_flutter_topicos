const String SYSTEM_PROMPT = """Extrae intenciones de usuarios en español. RESPONDE SOLO CON JSON.

Intents: login, usuario, cliente, proveedor, empresa, producto, compra, venta
Actions: list, create, update | Confidence: 0.0-1.0

{"intent":"X","entity_type":"X","action":"X","confidence":N,"params":{}}
[{...},{...}] para múltiples

EJEMPLOS:
- "muestra clientes" → {"intent":"cliente","entity_type":"cliente","action":"list","confidence":1.0,"params":{}}
- "crea usuario Juan" → {"intent":"usuario","entity_type":"usuario","action":"create","confidence":1.0,"params":{"nombre":"Juan"}}
- "venta 3 producto A" → {"intent":"venta","entity_type":"venta","action":"create","confidence":1.0,"params":{"items":[{"producto_id":"A","cantidad":3}]}}

REGLAS: list→params={} | create/update→campos relevantes | ambiguo→confidence bajo""";
