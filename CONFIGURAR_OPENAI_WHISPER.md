# 🎤 Configurar OpenAI Whisper API

## 1️⃣ Obtener API Key de OpenAI

### Paso 1: Crear cuenta en OpenAI
1. Ve a: https://platform.openai.com/signup
2. Registrate o inicia sesión
3. Completa la verificación de email

### Paso 2: Generar API Key
1. Ve a: https://platform.openai.com/account/api-keys
2. Click en **"Create new secret key"**
3. **COPIA la clave** (solo aparece una vez)
4. Guárdala en un lugar seguro

### Paso 3: Configurar Billing
1. Ve a: https://platform.openai.com/account/billing/overview
2. Agrega un método de pago
3. Establece un límite de gasto (recomendado: $5-10/mes)

---

## 2️⃣ Guardar API Key en la App

### Opción A: Desde UI (MÁS FÁCIL)

1. **Abre la app**
2. En la pantalla principal, verás: **"Configura OpenAI Whisper"**
3. Ingresa tu API Key (comienza con `sk-`)
4. Click en **"Guardar"**
5. ¡Listo! 

La app guardará la clave y podrás grabar audio inmediatamente.

### Opción B: Desde .env (RECOMENDADO)

1. Abre el archivo `.env` en la raíz del proyecto:
   ```
   D:\Topicos\app_flutter\.env
   ```

2. Agrega esta línea:
   ```
   OPENAI_API_KEY=sk-your-api-key-here
   ```

3. Reemplaza `sk-your-api-key-here` con tu API Key real

4. Reinicia la app

**Ventaja:** La app cargará automáticamente la clave sin que tengas que ingresarla manualmente.

---

## 3️⃣ Probar Whisper

### Flujo de Uso

1. **Carga Qwen** → Click "Seleccionar modelo" → `.gguf`
2. **Configura OpenAI** → Ingresa API Key (o ya está en `.env`)
3. **Graba audio** → Click "Audio" → Habla → Click "Detener"
4. **Automático:**
   - OpenAI Whisper transcribe el audio
   - El texto aparece en el TextController
   - Qwen procesa el comando
   - Ves el resultado JSON

---

## 💰 Costos de OpenAI Whisper

**Muy económico:**
- Whisper API: **$0.02 por minuto de audio**
- Ejemplo: 1 minuto de audio = $0.02 USD
- 100 minutos/mes = $2 USD
- 1000 minutos/mes = $20 USD

**Para desarrollo/pruebas:** 
- Gasta menos de $1/mes fácilmente
- Establece alerta de gasto en OpenAI dashboard

---

## 🔒 Seguridad

⚠️ **IMPORTANTE:**
- ❌ NO compartas tu API Key con nadie
- ❌ NO la publiques en GitHub/redes sociales
- ❌ NO la metas en código (usa .env)
- ✅ Guarda la clave en `.env` (ya está en `.gitignore`)

Si comprometes una clave:
1. Ve a https://platform.openai.com/account/api-keys
2. Click en el botón "Delete" al lado de la clave comprometida
3. Genera una nueva clave

---

## 🧪 Verificar que Funciona

### Prueba en la App

1. Abre la app
2. Verifica que dice: **"OpenAI Whisper: Configurado ✓"**
3. Graba un audio pequeño (5 segundos)
4. Detén la grabación
5. Si ves el texto transcrito → ✅ Funciona

### Solucionar Problemas

**Error: "API Key no configurada"**
- Verifica que ingresaste la clave correctamente
- Asegúrate que comienza con `sk-`
- Recarga la app

**Error: "Error en transcripción"**
- Verifica que tienes conexión a internet
- Verifica que tu API Key es válida
- Chequea el billing en OpenAI (sin deuda)

**Error: "401 Unauthorized"**
- Tu API Key es inválida o expiró
- Genera una nueva clave en OpenAI dashboard

**Error: "429 Too Many Requests"**
- Estás haciendo demasiadas peticiones
- Espera 1 minuto antes de intentar de nuevo
- Considera aumentar el límite en OpenAI

---

## 📊 Monitorear Uso

### Verificar Gastos

1. Ve a: https://platform.openai.com/account/usage/overview
2. Verás:
   - Tokens usados
   - Costo acumulado
   - Proyección mensual

### Establecer Límite de Gasto

1. Ve a: https://platform.openai.com/account/billing/limits
2. Establece un **"Hard limit"** (ej: $10/mes)
3. OpenAI detiene la API si alcanza el límite

---

## 🚀 Flujo Completo

```
1. Obtener API Key
   ↓
2. Guardar en .env o UI
   ↓
3. Cargar modelo Qwen
   ↓
4. Grabar audio
   ↓
5. OpenAI Whisper transcribe
   ↓
6. Qwen procesa
   ↓
7. Resultado JSON
```

---

## 📚 Referencias

- OpenAI Whisper: https://platform.openai.com/docs/guides/speech-to-text
- OpenAI Pricing: https://openai.com/pricing
- OpenAI Dashboard: https://platform.openai.com/account

---

## ✅ Checklist de Configuración

- [ ] Cuenta OpenAI creada
- [ ] API Key generada
- [ ] Método de pago agregado
- [ ] API Key guardada en `.env` o app
- [ ] App reiniciada
- [ ] Whisper muestra "Configurado ✓"
- [ ] Audio grabado y transcrito correctamente
- [ ] Qwen procesó el comando exitosamente

