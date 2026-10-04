@echo off
setlocal enabledelayedexpansion

echo ================================================
echo Discord Bot - Fix AttributeError: 'Intents'
echo ================================================
echo.

REM Uninstall wrong packages
echo [1/4] Uninstalling discord packages...
python -m pip uninstall -y discord discord.py
if errorlevel 1 (
    echo Warning: Could not uninstall packages, continuing anyway...
)
echo.

REM Install correct discord.py
echo [2/4] Installing discord.py...
python -m pip install -U discord.py
if errorlevel 1 (
    echo Error: Failed to install discord.py
    pause
    exit /b 1
)
echo.

REM Verify installation
echo [3/4] Verifying discord.py installation...
python -c "import discord; print('Discord version:', discord.__version__); print('Has Intents:', hasattr(discord, 'Intents'))"
if errorlevel 1 (
    echo Error: Verification failed
    pause
    exit /b 1
)
echo.

REM Check for conflicting files
echo [4/4] Checking for conflicting discord.py files...
if exist "discord.py" (
    echo Warning: Found discord.py in current directory - this will shadow the installed package!
    echo Please rename or delete it.
)
if exist "discord\" (
    echo Warning: Found discord\ folder in current directory - this will shadow the installed package!
    echo Please rename or delete it.
)
echo.

echo ================================================
echo Fix complete! Your bot should now work.
echo ================================================
echo.
pause
