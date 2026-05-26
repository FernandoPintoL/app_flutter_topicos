#!/usr/bin/env pwsh
# Script para compilar whisper.cpp para Android NDK

param(
    [string]$ABI = "arm64-v8a",
    [string]$MinSdk = "21"
)

Write-Host "
╔════════════════════════════════════════════════╗
║  🔨 Compilador de Whisper.cpp para Android    ║
╚════════════════════════════════════════════════╝
" -ForegroundColor Cyan

# 1. Detectar NDK
Write-Host "📍 Detectando Android NDK..." -ForegroundColor Yellow

$ANDROID_SDK = "$env:USERPROFILE\AppData\Local\Android\Sdk"
$NDK_VERSIONS = @()

if (Test-Path "$ANDROID_SDK\ndk") {
    $NDK_VERSIONS = Get-ChildItem "$ANDROID_SDK\ndk" -Directory | Select-Object -ExpandProperty Name
}

if ($NDK_VERSIONS.Count -eq 0) {
    Write-Host "❌ No se encontró Android NDK" -ForegroundColor Red
    Write-Host "Instala NDK desde Android Studio: Tools → SDK Manager → SDK Tools" -ForegroundColor Yellow
    exit 1
}

$NDK_PATH = "$ANDROID_SDK\ndk\$($NDK_VERSIONS[0])"
Write-Host "✅ NDK encontrado: $NDK_PATH" -ForegroundColor Green

# 2. Verificar CMake
Write-Host "`n🔍 Verificando CMake..." -ForegroundColor Yellow
$CMAKE_PATH = (Get-Command cmake -ErrorAction SilentlyContinue).Source

if (-not $CMAKE_PATH) {
    Write-Host "❌ CMake no encontrado" -ForegroundColor Red
    Write-Host "Instálalo con: choco install cmake (requiere Chocolatey)" -ForegroundColor Yellow
    exit 1
}

Write-Host "✅ CMake encontrado: $CMAKE_PATH" -ForegroundColor Green

# 3. Clonar whisper.cpp
Write-Host "`n📥 Preparando whisper.cpp..." -ForegroundColor Yellow

if (-not (Test-Path "whisper.cpp")) {
    Write-Host "Clonando repositorio (esto puede tomar unos minutos)..." -ForegroundColor Cyan
    git clone https://github.com/ggerganov/whisper.cpp.git
    if ($LASTEXITCODE -ne 0) {
        Write-Host "❌ Error clonando repositorio" -ForegroundColor Red
        exit 1
    }
} else {
    Write-Host "📂 Actualizando whisper.cpp..." -ForegroundColor Cyan
    cd whisper.cpp
    git pull --quiet
    cd ..
}

Write-Host "✅ whisper.cpp listo" -ForegroundColor Green

# 4. Preparar directorio de build
Write-Host "`n🏗️ Preparando directorio de build..." -ForegroundColor Yellow

Push-Location whisper.cpp

if (Test-Path "build-android") {
    Remove-Item -Recurse -Force build-android | Out-Null
}

New-Item -ItemType Directory -Path "build-android" -Force | Out-Null
Set-Location build-android

# 5. CMake Configuration
Write-Host "`n⚙️ Configurando CMake para $ABI..." -ForegroundColor Yellow

$CMAKE_ARGS = @(
    "-DCMAKE_TOOLCHAIN_FILE=$NDK_PATH/build/cmake/android.toolchain.cmake",
    "-DANDROID_ABI=$ABI",
    "-DANDROID_PLATFORM=android-$MinSdk",
    "-DCMAKE_BUILD_TYPE=Release",
    "-DBUILD_SHARED_LIBS=ON",
    "-G", "Unix Makefiles",
    ".."
)

& cmake @CMAKE_ARGS

if ($LASTEXITCODE -ne 0) {
    Write-Host "❌ Error configurando CMake" -ForegroundColor Red
    Pop-Location
    Pop-Location
    exit 1
}

Write-Host "✅ CMake configurado exitosamente" -ForegroundColor Green

# 6. Compilar
Write-Host "`n🚀 Compilando whisper.cpp (esto puede tomar 5-15 minutos)..." -ForegroundColor Cyan
Write-Host "Tiempo estimado: depende del tamaño del archivo y velocidad del CPU" -ForegroundColor Gray

$StartTime = Get-Date
& cmake --build . -j 4

if ($LASTEXITCODE -ne 0) {
    Write-Host "❌ Error durante la compilación" -ForegroundColor Red
    Pop-Location
    Pop-Location
    exit 1
}

$EndTime = Get-Date
$Duration = ($EndTime - $StartTime).TotalSeconds
Write-Host "✅ Compilación completada en $([math]::Round($Duration, 2))s" -ForegroundColor Green

# 7. Verificar .so
Write-Host "`n🔍 Verificando libwhisper.so..." -ForegroundColor Yellow

if (Test-Path "android/$ABI/libwhisper.so") {
    $Size = (Get-Item "android/$ABI/libwhisper.so").Length / 1MB
    Write-Host "✅ libwhisper.so generado exitosamente ($([math]::Round($Size, 2)) MB)" -ForegroundColor Green
} else {
    Write-Host "❌ libwhisper.so no encontrado" -ForegroundColor Red
    Write-Host "Ruta buscada: $(Get-Location)\android\$ABI\libwhisper.so" -ForegroundColor Yellow
    Pop-Location
    Pop-Location
    exit 1
}

# 8. Copiar a jniLibs
Write-Host "`n📋 Copiando a jniLibs..." -ForegroundColor Yellow

Pop-Location  # whisper.cpp/build-android
Pop-Location  # whisper.cpp

$JNI_LIBS_PATH = "$pwd\android\app\src\main\jniLibs\$ABI"

if (-not (Test-Path $JNI_LIBS_PATH)) {
    New-Item -ItemType Directory -Path $JNI_LIBS_PATH -Force | Out-Null
    Write-Host "✅ Directorio jniLibs creado" -ForegroundColor Green
}

Copy-Item "whisper.cpp/build-android/android/$ABI/libwhisper.so" "$JNI_LIBS_PATH/libwhisper.so" -Force

if (Test-Path "$JNI_LIBS_PATH/libwhisper.so") {
    Write-Host "✅ libwhisper.so copiado a jniLibs" -ForegroundColor Green
    Write-Host "   Ubicación: $JNI_LIBS_PATH" -ForegroundColor Gray
} else {
    Write-Host "❌ Error copiando libwhisper.so" -ForegroundColor Red
    exit 1
}

# Resumen final
Write-Host "
╔════════════════════════════════════════════════╗
║  ✨ COMPILACIÓN COMPLETADA                    ║
╚════════════════════════════════════════════════╝
" -ForegroundColor Green

Write-Host "
📊 Resumen:
  • ABI: $ABI
  • Min SDK: $MinSdk
  • libwhisper.so: $(Test-Path "$JNI_LIBS_PATH/libwhisper.so" ? '✅' : '❌')
  • Ubicación: $JNI_LIBS_PATH

🎯 Próximos pasos:
  1. Abre el proyecto en Android Studio
  2. Ejecuta: flutter pub get
  3. Carga el modelo Whisper desde la app
  4. Prueba la grabación y transcripción

📚 Para más información:
  Ver: COMPILAR_WHISPER_NDK.md
" -ForegroundColor Cyan

Write-Host "✨ ¡Listo para compilar la app!" -ForegroundColor Green
