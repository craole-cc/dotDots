"""Run with the built Hermes venv: offline hooks and native provider binding."""
from contextlib import ExitStack
from datetime import datetime, timezone
import inspect
import json
from pathlib import Path
import socket
import tempfile
from types import SimpleNamespace
from unittest.mock import patch


def forbidden(*args, **kwargs):
    raise AssertionError("Network forbidden during runtime acceptance")

socket.socket.connect = forbidden
socket.socket.connect_ex = forbidden
socket.create_connection = forbidden

import agent.scheduled_routes as routes
import agent.agent_init as init
import agent.turn_api_request as requests

assert "initialise(agent, _agent_cfg)" in inspect.getsource(init.init_agent)
source = inspect.getsource(requests.build_request_payload)
assert source.index("ensure_route(agent)") < source.index("agent._reapply_reasoning_echo_for_provider")
assert source.index("ensure_route(agent)") < source.index("api_kwargs = agent._build_api_kwargs")
assert routes.__file__.startswith("/nix/store/")

# Keep Hermes's real route binder, replacing only provider/credential endpoints
# and its external collaborators. No real tokens or provider calls are used.
agent = SimpleNamespace(
    provider="openai-codex", requested_provider="openai-codex", model="gpt-6.1-sol",
    base_url="https://chatgpt.com/backend-api/codex", api_mode="codex_responses",
    _primary_runtime={"provider": "openai-codex", "model": "gpt-6.1-sol"},
    _transport_cache={"old-client": object()},
    _is_azure_openai_url=lambda base: False,
    _is_direct_openai_url=lambda base: False,
    _provider_model_requires_responses_api=lambda *args, **kwargs: False,
    _anthropic_prompt_cache_policy=lambda **kwargs: (False, False),
    _ensure_lmstudio_runtime_loaded=lambda: None,
)

def resolve(provider, **kwargs):
    client = SimpleNamespace(
        base_url="https://api.deepseek.com/v1" if provider == "deepseek" else "https://chatgpt.com/backend-api/codex",
        api_key="fixture-deepseek" if provider == "deepseek" else "fixture-oauth",
    )
    return client, kwargs["model"]


def swap(agent, client, provider, model, base_url, api_mode):
    agent.client, agent.api_key = client, client.api_key

with tempfile.TemporaryDirectory() as directory, ExitStack() as mocks:
    policy = {
        "version": 1, "date_convention": "UTC", "utc_windows": [[240, 360], [600, 1500]],
        "calendar": {"start": "2026-01-01", "end": "2026-12-31", "holidays": [], "makeup_workdays": []},
        "profiles": {"developer": {
            "otherwise": {"provider": "openai-codex", "model": "gpt-6.1-sol"},
            "off_peak": {"provider": "deepseek", "model": "deepseek-flash"},
        }},
    }
    file = Path(directory) / "policy.json"
    file.write_text(json.dumps(policy))
    agent._scheduled_routes = {"enabled": True, "policy_file": str(file)}
    agent._scheduled_home = Path(directory) / "developer"
    mocks.enter_context(patch("agent.auxiliary_client.resolve_provider_client", side_effect=resolve))
    mocks.enter_context(patch("hermes_cli.fallback_config.resolve_entry_api_key", return_value=None))
    mocks.enter_context(patch("hermes_cli.model_normalize.normalize_model_for_provider", side_effect=lambda model, provider: model))
    mocks.enter_context(patch("agent.client_lifecycle._swap_fallback_clients", side_effect=swap))
    mocks.enter_context(patch("agent.chat_completion_helpers._fallback_api_mode_hint", return_value=(False, "chat_completions")))
    for target in [
        "agent.chat_completion_helpers._rebind_fallback_credential_pool",
        "agent.chat_completion_helpers._update_fallback_context_compressor",
        "agent.chat_completion_helpers._reresolve_fallback_reasoning_config",
        "agent.chat_completion_helpers._rescope_fallback_extra_body",
        "agent.turn_recovery_codex.reset_codex_reasoning_replay",
        "agent.agent_runtime_helpers.sync_credential_pool_entry_id",
    ]:
        mocks.enter_context(patch(target))
    assert routes.ensure_route(agent, datetime(2026, 11, 9, 0, 59, tzinfo=timezone.utc))
    assert (agent.provider, agent.model) == ("deepseek", "deepseek-flash")
    assert agent.base_url == "https://api.deepseek.com/v1"
    assert agent.api_key == "fixture-deepseek"
    assert agent.api_mode == "chat_completions"
    assert agent._transport_cache == {}
    assert routes.ensure_route(agent, datetime(2026, 11, 9, 1, 0, tzinfo=timezone.utc))
    assert (agent.provider, agent.model) == ("openai-codex", "gpt-6.1-sol")
    assert agent.base_url == "https://chatgpt.com/backend-api/codex"
    assert agent.api_key == "fixture-oauth"
    assert agent.api_mode == "codex_responses"
print("PASS: installed hooks, real native binder, endpoints, credentials and transport reset; network forbidden")
