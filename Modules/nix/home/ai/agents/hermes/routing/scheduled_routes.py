"""Opt-in, fail-closed scheduled primary routing. Never alters conversation history."""
from __future__ import annotations

import json
import logging
from datetime import date, datetime, timezone
from pathlib import Path

logger = logging.getLogger(__name__)


def off_peak(policy: dict, now: datetime) -> bool:
    """Calendar dates and windows use UTC; unknown dates are never eligible."""
    if policy.get("version") != 1 or policy.get("date_convention") != "UTC":
        return False
    if now.tzinfo is None or now.utcoffset() is None:
        return False
    now = now.astimezone(timezone.utc)
    calendar = policy["calendar"]
    day = now.date()
    start, end = date.fromisoformat(calendar["start"]), date.fromisoformat(calendar["end"])
    holidays = {date.fromisoformat(value) for value in calendar["holidays"]}
    working = {date.fromisoformat(value) for value in calendar["makeup_workdays"]}
    if start > end or holidays & working or not start <= day <= end:
        return False
    if any(not start <= value <= end for value in holidays | working):
        return False
    windows = policy["utc_windows"]
    if not windows or any(len(w) != 2 or not 0 <= w[0] < w[1] <= 2880 for w in windows):
        return False
    if day in holidays or (day.weekday() >= 5 and day not in working):
        return True
    minute = now.hour * 60 + now.minute
    return any(a <= minute < b or (b > 1440 and minute < b - 1440) for a, b in windows)


def choose_route(policy: dict, profile: str, now: datetime) -> dict:
    routes = policy["profiles"][profile]
    if routes["otherwise"].get("provider") != "openai-codex" or routes["off_peak"].get("provider") != "deepseek":
        raise ValueError("Scheduled routes must have a Codex safe route and DeepSeek off-peak route")
    try:
        eligible = off_peak(policy, now)
    except (KeyError, TypeError, ValueError):
        eligible = False
    desired = dict(routes["off_peak" if eligible else "otherwise"])
    if desired.get("provider") not in {"deepseek", "openai-codex"} or not isinstance(desired.get("model"), str) or not desired["model"]:
        raise ValueError("Invalid scheduled provider route")
    return desired


def initialise(agent, config: dict) -> None:
    from hermes_constants import get_hermes_home

    agent._scheduled_routes = dict(config.get("scheduled_routes") or {})
    db = getattr(agent, "_session_db", None)
    agent._scheduled_home = Path(db.db_path).parent if db is not None else get_hermes_home()


def ensure_route(agent, now: datetime | None = None) -> bool:
    """Run before attempt decoration. Native provider failover remains sticky this turn."""
    config = getattr(agent, "_scheduled_routes", {})
    if not config.get("enabled"):
        return False
    from agent.route_binding import bind_route_entry

    desired = None
    try:
        policy = json.loads(Path(config["policy_file"]).read_text(encoding="utf-8-sig"))
        desired = choose_route(policy, agent._scheduled_home.name, now or datetime.now(timezone.utc))
        if getattr(agent, "_provider_fallback_active", False):
            desired = policy["profiles"][agent._scheduled_home.name]["otherwise"]
    except (OSError, KeyError, TypeError, ValueError):
        logger.warning("Scheduled route unavailable; retaining/restoring safe primary")
    primary = getattr(agent, "_primary_runtime", {})
    safe = {"provider": primary.get("provider"), "model": primary.get("model")}
    if safe["provider"] != "openai-codex":
        raise RuntimeError("Scheduled routes require a safe openai-codex primary")
    if desired is None:
        desired = safe
    provider, model = desired["provider"], desired["model"]
    if (agent.provider, agent.model) == (provider, model):
        return False
    try:
        if bind_route_entry(agent, desired, provider, model) is not None:
            return True
    except Exception:  # health: allow BLE001 -- safe primary restored if provider binding fails
        logger.warning("Scheduled provider binding failed; restoring Codex")
    if bind_route_entry(agent, safe, safe["provider"], safe["model"]) is None:
        raise RuntimeError("Safe scheduled fallback unavailable; request stopped")
    agent._provider_fallback_active = True
    return True
