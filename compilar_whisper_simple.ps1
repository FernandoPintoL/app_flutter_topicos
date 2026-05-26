#!/usr/bin/env pwsh
# Script para compilar whisper.cpp para Android NDK - Version simple

Write-Host "Compilador de Whisper.cpp para Android" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan

# 1. Detectar NDK
Write-Host "Detectando Android NDK..." -ForegroundColor Yellow

$ANDROID_SDK = "$env:USERPROFILE\AppData\Local\Android\Sdk"
$NDK_VERSIONS = @()

if (Test-Path "$ANDROID_SDK\ndk") {
    $NDK_VERSIONS = Get-ChildItem "$ANDROID_SDK\ndk" -Directory | Select-Object -ExpandProperty Name
}

if ($NDK_VERSIONS.Count -eq 0) {
    Write-Host "ERROR: No se encontro Android NDK" -ForegroundColor Red
    Write-Host "Instala NDK desde Android Studio" -ForegroundColor Yellow
    exit 1
}

$NDK_PATH = "$ANDROID_SDK\ndk\$($NDK_VERSIONS[0])"
Write-Host "OK: NDK encontrado: $NDK_PATH" -ForegroundColor Green

# 2. Verificar CMake
Write-Host "Verificando CMake..." -ForegroundColor Yellow
$CMAKE_PATH = (Get-Command cmake -ErrorAction SilentlyContinue).Source

if (-not $CMAKE_PATH) {
    Write-Host "ERROR: CMake no encontrado" -ForegroundColor Red
    exit 1
}

Write-Host "OK: CMake encontrado" -ForegroundColor Green

# 3. Clonar whisper.cpp
Write-Host "Preparando whisper.cpp..." -ForegroundColor Yellow

if (-not (Test-Path "whisper.cpp")) {
    Write-Host "Clonando repositorio..." -ForegroundColor Cyan
    git clone https://github.com/ggerganov/whisper.cpp.git
    if ($LASTEXITCODE -ne 0) {
        Write-Host "ERROR: No se pudo clonar" -ForegroundColor Red
        exit 1
    }
} else {
    Write-Host "whisper.cpp ya existe, actualizando..." -ForegroundColor Cyan
    cd whisper.cpp
    git pull --quiet
    cd ..
}

Write-Host "OK: whisper.cpp listo" -ForegroundColor Green

# 4. Preparar directorio de build
Write-Host "Preparando directorio de build..." -ForegroundColor Yellow

Push-Location whisper.cpp

if (Test-Path "build-android") {
    Remove-Item -Recurse -Force build-android | Out-Null
}

New-Item -ItemType Directory -Path "build-android" -Force | Out-Null
Set-Location build-android

# 5. CMake Configuration
Write-Host "Configurando CMake para arm64-v8a..." -ForegroundColor Yellow

$CMAKE_ARGS = @(
    "-DCMAKE_TOOLCHAIN_FILE=$NDK_PATH/build/cmake/android.toolchain.cmake",
    "-DANDROID_ABI=arm64-v8a",
    "-DANDROID_PLATFORM=android-21",
    "-DCMAKE_BUILD_TYPE=Release",
    "-DBUILD_SHARED_LIBS=ON",
    "-G", "Unix Makefiles",
    ".."
)

& cmake @CMAKE_ARGS

if ($LASTEXITCODE -ne 0) {
    Write-Host "ERROR: CMake configuration fallo" -ForegroundColor Red
    Pop-Location
    Pop-Location
    exit 1
}

Write-Host "OK: CMake configurado" -ForegroundColor Green

# 6. Compilar
Write-Host "Compilando whisper.cpp (esto puede tomar 10-15 minutos)..." -ForegroundColor Cyan

$StartTime = Get-Date
& cmake --build . -j 4

if ($LASTEXITCODE -ne 0) {
    Write-Host "ERROR: Compilacion fallo" -ForegroundColor Red
    Pop-Location
    Pop-Location
    exit 1
}

$EndTime = Get-Date
$Duration = ($EndTime - $StartTime).TotalSeconds
Write-Host "OK: Compilacion completada en $([math]::Round($Duration, 2))s" -ForegroundColor Green

# 7. Verificar .so
Write-Host "Verificando libwhisper.so..." -ForegroundColor Yellow

if (Test-Path "android/arm64-v8a/libwhisper.so") {
    $Size = (Get-Item "android/arm64-v8a/libwhisper.so").Length / 1MB
    Write-Host "OK: libwhisper.so generado ($([math]::Round($Size, 2)) MB)" -ForegroundColor Green
} else {
    Write-Host "ERROR: libwhisper.so no encontrado" -ForegroundColor Red
    Pop-Location
    Pop-Location
    exit 1
}

# 8. Copiar a jniLibs
Write-Host "Copiando a jniLibs..." -ForegroundColor Yellow

Pop-Location
Pop-Location

$JNI_LIBS_PATH = "$pwd\android\app\src\main\jniLibs\arm64-v8a"

if (-not (Test-Path $JNI_LIBS_PATH)) {
    New-Item -ItemType Directory -Path $JNI_LIBS_PATH -Force | Out-Null
}

Copy-Item "whisper.cpp/build-android/android/arm64-v8a/libwhisper.so" "$JNI_LIBS_PATH/libwhisper.so" -Force

if (Test-Path "$JNI_LIBS_PATH/libwhisper.so") {
    Write-Host "OK: libwhisper.so copiado a jniLibs" -ForegroundColor Green
} else {
    Write-Host "ERROR: No se pudo copiar libwhisper.so" -ForegroundColor Red
    exit 1
}

# Resumen final
Write-Host ""
Write-Host "COMPILACION EXITOSA!" -ForegroundColor Green
Write-Host "Ubicacion: $JNI_LIBS_PATH" -ForegroundColor Gray
Write-Host ""
Write-Host "Proximos pasos:" -ForegroundColor Cyan
Write-Host "1. flutter clean" -ForegroundColor White
Write-Host "2. flutter pub get" -ForegroundColor White
Write-Host "3. flutter build apk --debug" -ForegroundColor White
Write-Host ""
