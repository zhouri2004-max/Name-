@echo off
setlocal enabledelayedexpansion
title warung selfbot
cd /d "%~dp0"

echo.
echo ============================================
echo   warung selfbot installer
echo ============================================
echo.

REM ---- check python ----
python --version >nul 2>&1
if errorlevel 1 (
  echo [!] Python not found.
  echo.
  echo     Install Python 3.12 first:
  echo     https://www.python.org/downloads/release/python-3129/
  echo.
  echo     IMPORTANT: check "Add python.exe to PATH" during install.
  echo.
  pause
  exit /b 1
)

for /f "tokens=2" %%v in ('python --version 2^>^&1') do set PYVER=%%v
echo [+] Python %PYVER% found

REM ---- check git ----
git --version >nul 2>&1
if errorlevel 1 (
  echo [!] Git not found. Installing via winget...
  winget install --id Git.Git -e --source winget --accept-package-agreements --accept-source-agreements
  if errorlevel 1 (
    echo [!] winget install failed. Install Git manually:
    echo     https://git-scm.com/download/win
    pause
    exit /b 1
  )
  echo [+] Git installed. Restart this script.
  pause
  exit /b 0
)
echo [+] Git found

REM ---- venv ----
if not exist .venv (
  echo [*] Creating virtual environment...
  python -m venv .venv
  if errorlevel 1 (
    echo [!] venv creation failed.
    pause
    exit /b 1
  )
  echo [+] .venv created
) else (
  echo [+] .venv exists
)

call .venv\Scripts\activate.bat

REM ---- install deps ----
python -c "import discord; assert hasattr(discord,'Intents')" >nul 2>&1
if errorlevel 1 (
  echo [*] Installing dependencies... this takes ~1 min
  python -m pip install --upgrade pip setuptools wheel --quiet
  pip install --no-cache-dir --no-build-isolation "git+https://github.com/dolfies/discord.py-self.git@master" --quiet
  pip install --no-cache-dir python-dotenv --quiet
  echo [+] Dependencies installed
) else (
  echo [+] Dependencies already installed
)

REM ---- bot script ----
if not exist discord_selfbot.py (
  echo [*] Writing discord_selfbot.py...
  > discord_selfbot.py (
    echo import asyncio
    echo import logging
    echo import os
    echo import random
    echo import sys
    echo from pathlib import Path
    echo import discord
    echo from discord.ext import commands, tasks
    echo from dotenv import load_dotenv
    echo load_dotenv^(^)
    echo TOKEN = os.getenv^("DISCORD_TOKEN",""^).strip^(^)
    echo if not TOKEN:
    echo     sys.exit^("[!] DISCORD_TOKEN missing in .env"^)
    echo TARGET_CHANNEL_ID = int^(os.getenv^("TARGET_CHANNEL_ID","0"^)^)
    echo BROADCAST_MESSAGE = os.getenv^("BROADCAST_MESSAGE", "## **Lf for players to join Levi it's alr SPAWNED DM ME TO JOIN FASTTTTT WE HAVE PORTAL TO BRING YOU HERE**"^)
    echo BROADCAST_INTERVAL_SEC = int^(os.getenv^("BROADCAST_INTERVAL_SEC","90"^)^)
    echo BROADCAST_JITTER_SEC = int^(os.getenv^("BROADCAST_JITTER_SEC","5"^)^)
    echo DM_REPLY_TEMPLATE = os.getenv^("DM_REPLY_TEMPLATE", "join us in call here first https://discord.gg/hTupDEVUF"^)
    echo AUTO_ACCEPT_FRIENDS = os.getenv^("AUTO_ACCEPT_FRIENDS","true"^).lower^(^) == "true"
    echo DM_REPLY_COOLDOWN_MIN = int^(os.getenv^("DM_REPLY_COOLDOWN_MIN","10"^)^)
    echo LOG_DIR = Path^("logs"^)
    echo LOG_DIR.mkdir^(exist_ok=True^)
    echo logging.basicConfig^(level=logging.INFO, format="%%^(asctime^)s [%%^(levelname^)s] %%^(message^)s", handlers=[logging.FileHandler^(LOG_DIR/"selfbot.log", encoding="utf-8"^), logging.StreamHandler^(sys.stdout^)]^)
    echo log = logging.getLogger^("warung.selfbot"^)
    echo intents = discord.Intents.default^(^)
    echo intents.message_content = True
    echo intents.members = True
    echo intents.dm_messages = True
    echo bot = commands.Bot^(command_prefix="!", self_bot=True, intents=intents^)
    echo _reply_cooldown = {}
    echo @bot.event
    echo async def on_ready^(^):
    echo     log.info^("logged in as %%s ^(%%s^)", bot.user, bot.user.id^)
    echo     if not broadcast_loop.is_running^(^) and TARGET_CHANNEL_ID:
    echo         broadcast_loop.start^(^)
    echo @bot.event
    echo async def on_message^(message^):
    echo     if message.author.id == bot.user.id:
    echo         return
    echo     if isinstance^(message.channel, discord.DMChannel^):
    echo         await handle_dm^(message^)
    echo async def handle_dm^(message^):
    echo     uid = message.author.id
    echo     now = asyncio.get_event_loop^(^).time^(^)
    echo     if AUTO_ACCEPT_FRIENDS:
    echo         try:
    echo             friend_ids = {u.id for u in bot.user.friends}
    echo             if message.author.id not in friend_ids:
    echo                 await bot.user.send_friend_request^(message.author^)
    echo                 log.info^("friend request -^> %%s", message.author^)
    echo         except Exception as exc:
    echo             log.debug^("friend req skipped: %%s", exc^)
    echo     last = _reply_cooldown.get^(uid, 0.0^)
    echo     if now - last ^< DM_REPLY_COOLDOWN_MIN * 60:
    echo         return
    echo     try:
    echo         await message.channel.send^(DM_REPLY_TEMPLATE^)
    echo         _reply_cooldown[uid] = now
    echo         log.info^("dm reply -^> %%s", message.author^)
    echo     except Exception as exc:
    echo         log.warning^("dm reply failed: %%s", exc^)
    echo @tasks.loop^(seconds=BROADCAST_INTERVAL_SEC^)
    echo async def broadcast_loop^(^):
    echo     if not TARGET_CHANNEL_ID:
    echo         return
    echo     channel = bot.get_channel^(TARGET_CHANNEL_ID^)
    echo     if channel is None:
    echo         try:
    echo             channel = await bot.fetch_channel^(TARGET_CHANNEL_ID^)
    echo         except Exception as exc:
    echo             log.warning^("channel fetch failed: %%s", exc^)
    echo             return
    echo     try:
    echo         if BROADCAST_JITTER_SEC ^> 0:
    echo             await asyncio.sleep^(random.uniform^(0, BROADCAST_JITTER_SEC^)^)
    echo         await channel.send^(BROADCAST_MESSAGE^)
    echo         log.info^("broadcast -^> #%%s", getattr^(channel, "name", TARGET_CHANNEL_ID^)^)
    echo     except discord.Forbidden:
    echo         log.error^("forbidden channel %%s", TARGET_CHANNEL_ID^)
    echo     except discord.HTTPException as exc:
    echo         log.warning^("http error: %%s", exc^)
    echo @broadcast_loop.before_loop
    echo async def before_broadcast^(^):
    echo     await bot.wait_until_ready^(^)
    echo if __name__ == "__main__":
    echo     bot.run^(TOKEN, bot=False^)
  )
  echo [+] discord_selfbot.py written
) else (
  echo [+] discord_selfbot.py exists
)

REM ---- .env ----
if not exist .env (
  echo.
  echo ============================================
  echo   Setup - fill in your details
  echo ============================================
  echo.
  echo Get your token: Discord web ^> F12 ^> Network ^> filter "science" ^> click request ^> Headers ^> find "authorization:"
  echo.
  set /p TK="Paste Discord user token: "
  echo.
  echo Get channel ID: Discord ^> Settings ^> Advanced ^> Developer Mode ON ^> right-click channel ^> Copy Channel ID
  echo.
  set /p CH="Paste channel ID: "
  echo.
  > .env (
    echo DISCORD_TOKEN=!TK!
    echo TARGET_CHANNEL_ID=!CH!
    echo BROADCAST_MESSAGE=## **Lf for players to join Levi it's alr SPAWNED DM ME TO JOIN FASTTTTT WE HAVE PORTAL TO BRING YOU HERE**
    echo BROADCAST_INTERVAL_SEC=90
    echo BROADCAST_JITTER_SEC=5
    echo DM_REPLY_TEMPLATE=join us in call here first https://discord.gg/hTupDEVUF
    echo AUTO_ACCEPT_FRIENDS=true
    echo DM_REPLY_COOLDOWN_MIN=10
  )
  echo [+] .env created
) else (
  echo [+] .env exists - using existing values
)

REM ---- run ----
echo.
echo ============================================
echo   Starting bot... press Ctrl+C to stop
echo ============================================
echo.
python discord_selfbot.py

echo.
echo Bot stopped.
pause