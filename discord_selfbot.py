# discord_selfbot.py
# Python 3.11+ | discord.py-self >= 2.0.0
# Runtime: GitHub Codespace (default Ubuntu 22.04 image)
#
# Behavior:
#   - Logs in as a user account (selfbot) via token
#   - Sends the Levi ping message to the target channel every 90 seconds
#   - Auto-replies to every incoming DM with the invite link
#   - Auto-sends friend requests to DM senders
#
# Selfbots violate Discord ToS. Account can get banned.
# Use a burner account. Do not run this on your main.

import asyncio
import logging
import os
import random
import sys
from pathlib import Path

import discord
from discord.ext import commands, tasks
from dotenv import load_dotenv

load_dotenv()

TOKEN = os.getenv("DISCORD_TOKEN", "").strip()
if not TOKEN:
    sys.exit("[!] DISCORD_TOKEN missing. Set it via .env or Codespace Secrets.")

TARGET_CHANNEL_ID = int(os.getenv("TARGET_CHANNEL_ID", "0"))

BROADCAST_MESSAGE = os.getenv(
    "BROADCAST_MESSAGE",
    "## **Lf for players to join Levi it's alr SPAWNED DM ME TO JOIN FASTTTTT WE HAVE PORTAL TO BRING YOU HERE**",
)

BROADCAST_INTERVAL_SEC = int(os.getenv("BROADCAST_INTERVAL_SEC", "90"))
BROADCAST_JITTER_SEC = int(os.getenv("BROADCAST_JITTER_SEC", "5"))

DM_REPLY_TEMPLATE = os.getenv(
    "DM_REPLY_TEMPLATE",
    "join us in call here first https://discord.gg/hTupDEVUF",
)

AUTO_ACCEPT_FRIENDS = os.getenv("AUTO_ACCEPT_FRIENDS", "true").lower() == "true"
DM_REPLY_COOLDOWN_MIN = int(os.getenv("DM_REPLY_COOLDOWN_MIN", "10"))

LOG_DIR = Path("logs")
LOG_DIR.mkdir(exist_ok=True)

logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s [%(levelname)s] %(message)s",
    handlers=[
        logging.FileHandler(LOG_DIR / "selfbot.log", encoding="utf-8"),
        logging.StreamHandler(sys.stdout),
    ],
)
log = logging.getLogger("warung.selfbot")

intents = discord.Intents.default()
intents.message_content = True
intents.members = True
intents.dm_messages = True

bot = commands.Bot(
    command_prefix="!",
    self_bot=True,
    intents=intents,
)

_reply_cooldown: dict[int, float] = {}


@bot.event
async def on_ready() -> None:
    log.info("logged in as %s (%s)", bot.user, bot.user.id)
    if not broadcast_loop.is_running() and TARGET_CHANNEL_ID:
        broadcast_loop.start()


@bot.event
async def on_message(message: discord.Message) -> None:
    if message.author.id == bot.user.id:
        return
    if isinstance(message.channel, discord.DMChannel):
        await handle_dm(message)


async def handle_dm(message: discord.Message) -> None:
    uid = message.author.id
    now = asyncio.get_event_loop().time()

    if AUTO_ACCEPT_FRIENDS:
        try:
            friend_ids = {u.id for u in bot.user.friends}
            if message.author.id not in friend_ids:
                await bot.user.send_friend_request(message.author)
                log.info("friend request -> %s", message.author)
        except Exception as exc:
            log.debug("friend request skipped: %s", exc)

    last = _reply_cooldown.get(uid, 0.0)
    if now - last < DM_REPLY_COOLDOWN_MIN * 60:
        log.debug("dm cooldown active for %s", uid)
        return

    try:
        await message.channel.send(DM_REPLY_TEMPLATE)
        _reply_cooldown[uid] = now
        log.info("dm reply -> %s", message.author)
    except Exception as exc:
        log.warning("dm reply failed: %s", exc)


@tasks.loop(seconds=BROADCAST_INTERVAL_SEC)
async def broadcast_loop() -> None:
    if not TARGET_CHANNEL_ID:
        return

    channel = bot.get_channel(TARGET_CHANNEL_ID)
    if channel is None:
        try:
            channel = await bot.fetch_channel(TARGET_CHANNEL_ID)
        except Exception as exc:
            log.warning("channel fetch failed: %s", exc)
            return

    try:
        if BROADCAST_JITTER_SEC > 0:
            await asyncio.sleep(random.uniform(0, BROADCAST_JITTER_SEC))
        await channel.send(BROADCAST_MESSAGE)
        log.info("broadcast -> #%s", getattr(channel, "name", TARGET_CHANNEL_ID))
    except discord.Forbidden:
        log.error("forbidden: cannot send to channel %s", TARGET_CHANNEL_ID)
    except discord.HTTPException as exc:
        log.warning("http error: %s", exc)


@broadcast_loop.before_loop
async def before_broadcast() -> None:
    await bot.wait_until_ready()


@bot.command()
async def ping(ctx: commands.Context) -> None:
    await ctx.message.edit(content=f"pong {round(bot.latency * 1000)}ms")


@bot.command()
async def broadcast(ctx: commands.Context, *, msg: str) -> None:
    if not TARGET_CHANNEL_ID:
        await ctx.message.edit(content="TARGET_CHANNEL_ID not set")
        return
    channel = bot.get_channel(TARGET_CHANNEL_ID)
    if channel:
        await channel.send(msg)
        try:
            await ctx.message.delete()
        except Exception:
            pass


if __name__ == "__main__":
    bot.run(TOKEN, bot=False)
