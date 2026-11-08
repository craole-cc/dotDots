"""Opt-in named-team access to Hermes's native Bot Mode delivery transport.

Identity comes from the agent's session database and runtime platform, never
message text. The root policy is declarative data, not a tool-call argument.
"""

import json
from pathlib import Path


def policy_for(agent):
    from tools.bot_mode_dm import _agent_home
    from tools.bot_mode_probe import _hermes_root, _profile_name

    # Require a real session owner: ambient HERMES_HOME is insufficient here.
    database = getattr(getattr(agent, "_session_db", None), "db_path", None)
    if not isinstance(database, (str, Path)) or not getattr(agent, "session_id", None):
        return None, None
    home = Path(_agent_home(agent))
    file = _hermes_root(home) / "team-handoff.json"
    if not file.exists():
        return None, _profile_name(home)
    try:
        policy = json.loads(file.read_text())
        if policy.get("version") != 1 or policy.get("enabled") is not True:
            raise ValueError("disabled or unsupported policy")
        routes = policy["routes"]
        if not isinstance(routes, dict) or not all(
            isinstance(name, str) and isinstance(targets, list)
            and all(isinstance(target, str) for target in targets)
            for name, targets in routes.items()
        ):
            raise ValueError("invalid routes")
        return policy, _profile_name(home)
    except (OSError, ValueError, TypeError, KeyError, AttributeError):
        return {"routes": {}}, _profile_name(home)  # malformed means deny


def gateway_authorized(agent):
    if not getattr(agent, "_bot_mode_protocol", True):
        return False
    policy, profile = policy_for(agent)
    if not policy or profile != "default":
        return False
    from tools.bot_mode_dm import _agent_home
    from tools.bot_mode_probe import is_bot_mode_managed

    return (
        getattr(agent, "platform", None) == "telegram"
        and is_bot_mode_managed(_agent_home(agent))
        and policy.get("gateway_platforms") == ["telegram"]
        and policy["routes"].get("default") == ["coordinator"]
    )


def target_error(agent, targets, sender):
    policy, profile = policy_for(agent)
    if policy is None:
        return None  # preserve upstream behaviour for unconfigured installs
    if len(targets) != 1:
        return "Team handoff requires exactly one named local recipient; nothing was sent."
    target = targets[0].strip().removeprefix("@")
    if target not in policy["routes"].get(profile, []) or target not in sender.roster_homes:
        return "Recipient is outside this role's named-team route; nothing was sent."
    return None


def requires_poll(agent):
    """A commissioned owner must collect children before its own final reply."""
    policy, profile = policy_for(agent)
    return policy is not None and profile != "default"


def gateway_prompt(agent):
    return """## Named team handoff
You are Hermes, the Telegram Receptionist. For coordinated work use
message_agent(target="coordinator", message=..., constraints=..., expecting=...).
Only Coordinator is permitted from this session; do not use generic delegation
or shell commands to bypass that route. Preserve the authorised objective,
approval gates, source paths and expected deliverables in the brief.
The native transport returns a dispatch acknowledgement, not completion.
Retain delivery_id and process_id. If reply_delivery is notification, finish
your turn and relay the completion outcome back in THIS Telegram conversation.
If reply_delivery is poll, follow the returned process-wait instructions before
ending your turn. Report refusals, unavailable tools, approval waits and delivery
failures accurately. Never resend an uncertain delivery without reconciliation.
Do not use send_message to guess another destination or pretend a task ran.
Coordinator's response must include any commissioned specialist's result and
verification, or explicitly identify unfinished work. Return the result for the
owner's approval where the assignment requires it.
"""
