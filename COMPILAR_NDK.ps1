# Script PowerShell para compilar NDK code de llama.cpp en Android

Write-Host ""
Write-Host "===================================================" -ForegroundColor Cyan
Write-Host "COMPILAR NDK PARA LLAMA.CPP EN FLUTTER" -ForegroundColor Cyan
Write-Host "===================================================" -ForegroundColor Cyan
Write-Host ""

# Verificar directorios críticos
$llamaCppPath = "D:\Topicos\app_flutter\android\app\src\main\cpp\llama.cpp"
$modelPath = "D:\Topicos\app_flutter\assets\models\qwen2.5-3b-instruct-q4_k_m.gguf"

if (Test-Path $llamaCppPath) {
    Write-Host "✅ llama.cpp encontrado" -ForegroundColor Green
} else {
    Write-Host "❌ llama.cpp NO encontrado en: $llamaCppPath" -ForegroundColor Red
    exit 1
}

if (Test-Path $modelPath) {
    $size = (Get-Item $modelPath).Length / 1GB
    Write-Host "✅ Modelo GGUF encontrado ($('{0:N2}' -f $size) GB)" -ForegroundColor Green
} else {
    Write-Host "❌ Modelo GGUF NO encontrado en: $modelPath" -ForegroundColor Red
    exit 1
}

# Verificar Android NDK
if ($env:ANDROID_NDK) {
    Write-Host "✅ ANDROID_NDK: $($env:ANDROID_NDK)" -ForegroundColor Green
} else {
    Write-Host "❌ ANDROID_NDK no está configurado" -ForegroundColor Red
    Write-Host ""
    Write-Host "Configúralo con:" -ForegroundColor Yellow
    Write-Host '  $env:ANDROID_NDK = "C:\Android\ndk\27.0.11793014"' -ForegroundColor Yellow
    exit 1
}

Write-Host ""
Write-Host "===================================================" -ForegroundColor Cyan
Write-Host "COMPILANDO CON GRADLE + CMAKE + NDK" -ForegroundColor Cyan
Write-Host "===================================================" -ForegroundColor Cyan
Write-Host ""

# Cambiar al directorio del proyecto
Set-Location "D:\Topicos\app_flutter"

# Ejecutar gradle build
Write-Host "Ejecutando: gradle assembleDebug" -ForegroundColor Yellow
Write-Host ""

$processInfo = New-Object System.Diagnostics.ProcessStartInfo
$processInfo.FileName = "cmd.exe"
$processInfo.Arguments = "/c gradlew.bat assembleDebug"
$processInfo.RedirectStandardOutput = $false
$processInfo.UseShellExecute = $true
$processInfo.WorkingDirectory = "D:\Topicos\app_flutter"

$process = [System.Diagnostics.Process]::Start($processInfo)
$process.WaitForExit()

if ($process.ExitCode -eq 0) {
    Write-Host ""
    Write-Host "===================================================" -ForegroundColor Green
    Write-Host "✅ COMPILACIÓN EXITOSA" -ForegroundColor Green
    Write-Host "===================================================" -ForegroundColor Green
    Write-Host ""
    Write-Host "APK generado en:" -ForegroundColor Cyan
    Write-Host "  android\app\build\outputs\apk\debug\app-debug.apk" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "Próximos pasos:" -ForegroundColor Cyan
    Write-Host "  1. flutter run" -ForegroundColor Yellow
    Write-Host "  2. o: flutter install" -ForegroundColor Yellow
} else {
    Write-Host ""
    Write-Host "===================================================" -ForegroundColor Red
    Write-Host "❌ ERROR EN COMPILACIÓN" -ForegroundColor Red
    Write-Host "===================================================" -ForegroundColor Red
    Write-Host ""
    Write-Host "Posibles soluciones:" -ForegroundColor Yellow
    Write-Host "  1. Verifica que llama.cpp está en:" -ForegroundColor Yellow
    Write-Host "     android\app\src\main\cpp\llama.cpp" -ForegroundColor Yellow
    Write-Host "  2. Intenta: gradlew.bat clean assembleDebug" -ForegroundColor Yellow
    Write-Host "  3. Revisa los logs en: android\app\build\" -ForegroundColor Yellow
}
