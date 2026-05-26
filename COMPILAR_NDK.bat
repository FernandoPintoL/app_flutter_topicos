@echo off
REM Script para compilar NDK code de llama.cpp en Android

setlocal enabledelayedexpansion

cd /d "%~dp0"

echo.
echo ===================================================
echo COMPILAR NDK PARA LLAMA.CPP EN FLUTTER
echo ===================================================
echo.

REM Detectar Android NDK
if defined ANDROID_NDK (
    echo ✅ ANDROID_NDK detectado: %ANDROID_NDK%
) else (
    echo ❌ ANDROID_NDK no está configurado
    echo.
    echo Configúralo con:
    echo   set ANDROID_NDK=C:\Android\ndk\27.0.11793014
    echo.
    exit /b 1
)

REM Detectar Flutter SDK
if defined FLUTTER_SDK (
    echo ✅ FLUTTER_SDK detectado: %FLUTTER_SDK%
) else (
    echo ⚠️  FLUTTER_SDK no definido, buscando flutter en PATH...
    for /f "delims=" %%i in ('where flutter 2^>nul') do set "FLUTTER_SDK=%%i\..\..\"
    if defined FLUTTER_SDK (
        echo ✅ Encontrado: !FLUTTER_SDK!
    ) else (
        echo ❌ No se pudo encontrar Flutter
        exit /b 1
    )
)

REM Cambiar a directorio del proyecto
echo.
echo Directorio del proyecto: %cd%

REM Compilar con gradle
echo.
echo ===================================================
echo COMPILANDO CON GRADLE + CMAKE + NDK
echo ===================================================
echo.

call gradlew.bat assembleDebug

if errorlevel 1 (
    echo.
    echo ❌ ERROR EN COMPILACIÓN
    echo.
    echo Posibles soluciones:
    echo 1. Asegúrate que llama.cpp está en: android\app\src\main\cpp\llama.cpp
    echo 2. Verifica que el modelo está en: assets\models\qwen2.5-3b-instruct-q4_k_m.gguf
    echo 3. Intenta: gradlew.bat clean assembleDebug
    echo 4. Revisa los logs en: android\app\build\
    exit /b 1
)

echo.
echo ===================================================
echo ✅ COMPILACIÓN EXITOSA
echo ===================================================
echo.
echo APK generado en:
echo   android\app\build\outputs\apk\debug\app-debug.apk
echo.
echo Próximos pasos:
echo 1. Conecta un dispositivo Android o inicia un emulador
echo 2. Ejecuta: flutter run
echo 3. O instala directamente: flutter install
echo.
pause
