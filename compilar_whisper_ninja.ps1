#!/usr/bin/env pwsh
# Script para compilar whisper.cpp con Ninja

Write-Host "Compilador Whisper.cpp - Ninja" -ForegroundColor Cyan
Write-Host "===============================" -ForegroundColor Cyan

# Variables
$ANDROID_SDK = "$env:USERPROFILE\AppData\Local\Android\Sdk"
$NDK_PATH = "$ANDROID_SDK\ndk\25.1.8937393"
$ABI = "arm64-v8a"

Write-Host "Usando NDK: $NDK_PATH" -ForegroundColor Yellow

# Verificar Ninja
$NINJA_PATH = (Get-Command ninja -ErrorAction SilentlyContinue).Source
if (-not $NINJA_PATH) {
    Write-Host "ERROR: Ninja no encontrado" -ForegroundColor Red
    Write-Host "Instala con: choco install ninja" -ForegroundColor Yellow
    exit 1
}

Write-Host "OK: Ninja encontrado" -ForegroundColor Green

# Preparar directorio
Push-Location whisper.cpp

if (Test-Path "build-android") {
    Write-Host "Limpiando build anterior..." -ForegroundColor Yellow
    Remove-Item -Recurse -Force build-android
}

mkdir build-android
cd build-android

# CMake con Ninja
Write-Host "Configurando con Ninja..." -ForegroundColor Yellow

cmake -G Ninja `
  "-DCMAKE_TOOLCHAIN_FILE=$NDK_PATH/build/cmake/android.toolchain.cmake" `
  "-DANDROID_ABI=$ABI" `
  "-DANDROID_PLATFORM=android-21" `
  "-DCMAKE_BUILD_TYPE=Release" `
  "-DBUILD_SHARED_LIBS=ON" `
  ..

if ($LASTEXITCODE -ne 0) {
    Write-Host "ERROR: CMake fallo" -ForegroundColor Red
    Pop-Location
    exit 1
}

Write-Host "OK: CMake configurado" -ForegroundColor Green

# Compilar
Write-Host "Compilando (10-15 minutos)..." -ForegroundColor Cyan
& ninja

if ($LASTEXITCODE -ne 0) {
    Write-Host "ERROR: Compilacion fallo" -ForegroundColor Red
    Pop-Location
    exit 1
}

Write-Host "OK: Compilacion exitosa" -ForegroundColor Green

# Copiar
Pop-Location

$JNI_PATH = "$pwd\android\app\src\main\jniLibs\$ABI"
mkdir -p $JNI_PATH -Force | Out-Null

Copy-Item "whisper.cpp/build-android/android/$ABI/libwhisper.so" "$JNI_PATH/" -Force

if (Test-Path "$JNI_PATH/libwhisper.so") {
    Write-Host "OK: libwhisper.so copiado" -ForegroundColor Green
    Write-Host "Ubicacion: $JNI_PATH" -ForegroundColor Gray
} else {
    Write-Host "ERROR: No se copió" -ForegroundColor Red
    exit 1
}

Write-Host ""
Write-Host "COMPLETADO!" -ForegroundColor Green
Write-Host "Ahora ejecuta:" -ForegroundColor Cyan
Write-Host "  flutter clean" -ForegroundColor White
Write-Host "  flutter pub get" -ForegroundColor White
Write-Host "  flutter build apk --debug" -ForegroundColor White
