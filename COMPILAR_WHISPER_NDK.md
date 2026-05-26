# 📦 Compilar whisper.cpp para Android NDK

## Requisitos Previos

✅ **Instalados:**
- Android NDK (descargable desde Android Studio)
- CMake 3.14+
- Git
- PowerShell (para Windows)

## Opción 1: Script PowerShell (Windows - RECOMENDADO)

Crea un archivo `compilar_whisper.ps1` en la raíz del proyecto:

```powershell
# compilar_whisper.ps1
$NDK_PATH = "C:\Users\Fpl\AppData\Local\Android\Sdk\ndk\26.1.10909125"  # Ajusta la versión
$PROJECT_ROOT = Get-Location

Write-Host "🔨 Compilando whisper.cpp para Android NDK..." -ForegroundColor Green
Write-Host "NDK: $NDK_PATH" -ForegroundColor Yellow

# 1. Clonar/actualizar whisper.cpp
if (-not (Test-Path "whisper.cpp")) {
    Write-Host "📥 Clonando whisper.cpp..." -ForegroundColor Cyan
    git clone https://github.com/ggerganov/whisper.cpp.git
} else {
    Write-Host "📂 whisper.cpp ya existe, actualizando..." -ForegroundColor Cyan
    cd whisper.cpp
    git pull
    cd ..
}

cd whisper.cpp

# 2. Crear directorio de build
if (Test-Path "build-android") {
    Remove-Item -Recurse -Force build-android
}
mkdir build-android
cd build-android

# 3. Configurar con CMake
Write-Host "🔧 Configurando CMake..." -ForegroundColor Cyan

cmake `
  -DCMAKE_TOOLCHAIN_FILE="$NDK_PATH/build/cmake/android.toolchain.cmake" `
  -DANDROID_ABI=arm64-v8a `
  -DANDROID_PLATFORM=android-21 `
  -DCMAKE_BUILD_TYPE=Release `
  -DBUILD_SHARED_LIBS=ON `
  ..

# 4. Compilar
Write-Host "🚀 Compilando (esto puede tomar varios minutos)..." -ForegroundColor Green
cmake --build . -j$(Get-ComputerInfo).LogicalProcessorCount

# 5. Verificar resultado
if ($LASTEXITCODE -eq 0) {
    Write-Host "✅ Compilación exitosa!" -ForegroundColor Green
    Write-Host "📂 Archivos .so en: $(Get-Location)\android" -ForegroundColor Yellow
    
    # Crear directorio jniLibs si no existe
    $JNI_LIBS_PATH = "$PROJECT_ROOT\android\app\src\main\jniLibs\arm64-v8a"
    if (-not (Test-Path $JNI_LIBS_PATH)) {
        mkdir -p $JNI_LIBS_PATH
    }
    
    # Copiar archivos .so
    Write-Host "📋 Copiando libwhisper.so..." -ForegroundColor Cyan
    Copy-Item "android/arm64-v8a/libwhisper.so" "$JNI_LIBS_PATH/libwhisper.so" -Force
    
    Write-Host "✅ Archivo copiado a jniLibs" -ForegroundColor Green
} else {
    Write-Host "❌ Error durante la compilación" -ForegroundColor Red
    exit 1
}

Write-Host "`n✨ Compilación completada" -ForegroundColor Green
```

### Ejecutar Script:

```powershell
# En PowerShell (como Administrador)
cd D:\Topicos\app_flutter
Set-ExecutionPolicy -ExecutionPolicy Bypass -Scope Process
.\compilar_whisper.ps1
```

---

## Opción 2: Script Bash (macOS/Linux)

```bash
#!/bin/bash
set -e

# Configurar variables
NDK_PATH="$ANDROID_SDK_ROOT/ndk/26.1.10909125"  # Ajusta la versión
PROJECT_ROOT=$(pwd)
ARCH="arm64-v8a"
MIN_SDK="21"

echo "🔨 Compilando whisper.cpp para Android NDK..."
echo "NDK: $NDK_PATH"
echo "Arquitectura: $ARCH"

# 1. Clonar/actualizar whisper.cpp
if [ ! -d "whisper.cpp" ]; then
    echo "📥 Clonando whisper.cpp..."
    git clone https://github.com/ggerganov/whisper.cpp.git
else
    echo "📂 whisper.cpp ya existe, actualizando..."
    cd whisper.cpp
    git pull
    cd ..
fi

cd whisper.cpp

# 2. Crear directorio de build
rm -rf build-android
mkdir build-android
cd build-android

# 3. Configurar con CMake
echo "🔧 Configurando CMake..."

cmake \
  -DCMAKE_TOOLCHAIN_FILE="$NDK_PATH/build/cmake/android.toolchain.cmake" \
  -DANDROID_ABI=$ARCH \
  -DANDROID_PLATFORM=android-$MIN_SDK \
  -DCMAKE_BUILD_TYPE=Release \
  -DBUILD_SHARED_LIBS=ON \
  ..

# 4. Compilar
echo "🚀 Compilando..."
cmake --build . -j$(nproc)

# 5. Copiar archivos
if [ -f "android/$ARCH/libwhisper.so" ]; then
    echo "✅ Compilación exitosa"
    
    JNI_LIBS_PATH="$PROJECT_ROOT/android/app/src/main/jniLibs/$ARCH"
    mkdir -p "$JNI_LIBS_PATH"
    
    cp "android/$ARCH/libwhisper.so" "$JNI_LIBS_PATH/libwhisper.so"
    echo "✅ Archivo copiado a jniLibs"
else
    echo "❌ Error: libwhisper.so no encontrado"
    exit 1
fi

echo "✨ Compilación completada"
```

---

## Opción 3: Manual (Sin Scripts)

Si prefieres compilar paso a paso:

### 1. Clonar whisper.cpp:
```bash
cd D:\Topicos\app_flutter
git clone https://github.com/ggerganov/whisper.cpp.git
cd whisper.cpp
```

### 2. Crear directorio de build:
```bash
mkdir build-android
cd build-android
```

### 3. Configurar CMake:

**Encuentra tu NDK:**
- Abre Android Studio → SDK Manager
- Anota la ruta del NDK (ej: `C:\Users\...\Android\Sdk\ndk\26.1.10909125`)

**Ejecuta CMake:**
```bash
# Reemplaza NDK_PATH con tu ruta real
cmake `
  -DCMAKE_TOOLCHAIN_FILE="C:\Users\Fpl\AppData\Local\Android\Sdk\ndk\26.1.10909125\build\cmake\android.toolchain.cmake" `
  -DANDROID_ABI=arm64-v8a `
  -DANDROID_PLATFORM=android-21 `
  -DCMAKE_BUILD_TYPE=Release `
  -DBUILD_SHARED_LIBS=ON `
  ..
```

### 4. Compilar:
```bash
cmake --build . -j8
```

### 5. Copiar .so a jniLibs:
```bash
# Crear estructura de directorio
mkdir -p D:\Topicos\app_flutter\android\app\src\main\jniLibs\arm64-v8a

# Copiar archivo
copy build-android\android\arm64-v8a\libwhisper.so D:\Topicos\app_flutter\android\app\src\main\jniLibs\arm64-v8a\
```

---

## Verificar Compilación

Después de compilar, verifica que existe:

```
D:\Topicos\app_flutter\
└── android\
    └── app\
        └── src\
            └── main\
                └── jniLibs\
                    └── arm64-v8a\
                        └── libwhisper.so  ✅ DEBE EXISTIR
```

```powershell
# PowerShell: verificar
Test-Path "D:\Topicos\app_flutter\android\app\src\main\jniLibs\arm64-v8a\libwhisper.so"
# Resultado esperado: True
```

---

## Solución de Problemas

### ❌ Error: "NDK not found"
**Solución:** Verifica la ruta del NDK en Android Studio:
```
Tools → SDK Manager → SDK Tools → Android NDK (installed)
```
Copia la ruta exacta y úsala en el script.

### ❌ Error: "cmake not found"
**Solución:** Instala CMake:
```powershell
# Windows (via Chocolatey)
choco install cmake

# macOS
brew install cmake

# Linux
apt install cmake
```

### ❌ Error: "Compilation failed"
**Solución:**
1. Verifica que tienes espacio en disco (min 2GB)
2. Prueba con `cmake --build . -j4` (menos jobs)
3. Actualiza el NDK en Android Studio

### ❌ Error: "libwhisper.so not generated"
**Solución:**
1. Verifica que CMake finalizó exitosamente
2. Comprueba que usaste `-DBUILD_SHARED_LIBS=ON`
3. Intenta compilar con `-DCMAKE_BUILD_TYPE=Debug` primero para ver errores

---

## Arquitecturas Múltiples (Opcional)

Si necesitas compilar para múltiples arquitecturas:

```powershell
$ARCHITECTURES = @("arm64-v8a", "armeabi-v7a", "x86_64")

foreach ($ABI in $ARCHITECTURES) {
    Write-Host "Compilando para $ABI..."
    
    cmake `
      -DANDROID_ABI=$ABI `
      -DCMAKE_TOOLCHAIN_FILE="$NDK_PATH/build/cmake/android.toolchain.cmake" `
      ...
    
    cmake --build . -j8
    
    # Copiar cada .so a su directorio
    Copy-Item "android/$ABI/libwhisper.so" `
      "android/app/src/main/jniLibs/$ABI/libwhisper.so" -Force
}
```

---

## Próximos Pasos

Una vez compilado, tendrás:
```
✅ libwhisper.so en jniLibs/arm64-v8a/
✅ WhisperManager.kt en MainActivity
✅ MethodChannel para Whisper
```

Ahora puedes:
1. Abrir la app en Android Studio
2. Cargar el modelo Whisper
3. Grabar audio
4. Ver transcripción automática ✨

---

## 📚 Referencias

- whisper.cpp: https://github.com/ggerganov/whisper.cpp
- Android NDK: https://developer.android.com/ndk
- CMake en Android: https://developer.android.com/ndk/guides/cmake

