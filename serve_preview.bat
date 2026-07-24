@echo off
setlocal
cd /d "%~dp0"
set "PORT=41828"

if not exist "build\web\index.html" (
  echo Release web build was not found in build\web.
  echo Build it with:
  echo flutter build web --release --dart-define=SOURCEARENA_TOKEN=YOUR_TOKEN
  pause
  exit /b 1
)

where py >nul 2>nul
if not errorlevel 1 (
  set "PYTHON=py"
) else (
  where python >nul 2>nul
  if errorlevel 1 (
    echo Python 3 is required. Install it and enable "Add Python to PATH".
    pause
    exit /b 1
  )
  set "PYTHON=python"
)

echo Starting Ravand at http://127.0.0.1:%PORT%
start "" powershell -NoProfile -WindowStyle Hidden -Command "Start-Sleep -Seconds 1; Start-Process 'http://127.0.0.1:%PORT%'"
%PYTHON% preview_server.py %PORT%

endlocal
