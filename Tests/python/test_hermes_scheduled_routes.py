"""Offline schedule and live-agent routing tests; provider calls are forbidden."""
import importlib.util
import json
from datetime import datetime, timezone
from pathlib import Path
import sys
import tempfile
from types import SimpleNamespace, ModuleType
import unittest
from unittest.mock import patch

ROOT = Path(__file__).resolve().parents[2]
SPEC = importlib.util.spec_from_file_location("scheduled_routes", ROOT / "Modules/nix/home/ai/agents/hermes/routing/scheduled_routes.py")
ROUTES = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(ROUTES)
CALENDAR = json.loads((ROOT / "API/nix/ai/routing/calendar.json").read_text())


def instant(value):
    return datetime.fromisoformat(value).replace(tzinfo=timezone.utc)


class ScheduledRoutes(unittest.TestCase):
    def setUp(self):
        self.network = patch("socket.socket", side_effect=AssertionError("Network forbidden"))
        self.network.start()
        self.addCleanup(self.network.stop)
        self.policy = {
            "version": 1, "date_convention": "UTC",
            "calendar": CALENDAR,
            "utc_windows": [[240, 360], [600, 1500]],
            "profiles": {"developer": {
                "otherwise": {"provider": "openai-codex", "model": "gpt-6.1-sol"},
                "off_peak": {"provider": "deepseek", "model": "deepseek-flash"},
            }},
        }

    def test_weekday_boundaries(self):
        for clock, expected in [("00:59:59", True), ("01:00:00", False),
                                ("03:59:59", False), ("04:00:00", True),
                                ("05:59:59", True), ("06:00:00", False),
                                ("09:59:59", False), ("10:00:00", True),
                                ("23:59:59", True)]:
            with self.subTest(clock=clock):
                self.assertEqual(ROUTES.off_peak(self.policy, instant("2026-11-09T" + clock)), expected)

    def test_weekends_and_calendar_exceptions(self):
        self.assertTrue(ROUTES.off_peak(self.policy, instant("2026-11-07T02:00:00")))
        self.assertTrue(ROUTES.off_peak(self.policy, instant("2026-10-01T02:00:00")))
        self.assertFalse(ROUTES.off_peak(self.policy, instant("2026-10-10T02:00:00")))

    def test_timezone_normalization(self):
        self.assertFalse(ROUTES.off_peak(self.policy, datetime.fromisoformat("2026-11-08T20:00:00-05:00")))

    def test_unknown_time_or_expired_calendar_uses_codex(self):
        for now in [datetime(2026, 11, 7), instant("2027-01-02T02:00:00")]:
            with self.subTest(now=now):
                self.assertEqual(ROUTES.choose_route(self.policy, "developer", now)["provider"], "openai-codex")

    def test_malformed_calendar_and_windows_use_codex(self):
        for key, value in [("calendar", {}), ("utc_windows", []), ("utc_windows", [[600, 400]])]:
            policy = {**self.policy, key: value}
            self.assertEqual(ROUTES.choose_route(policy, "developer", instant("2026-11-07T02:00:00"))["provider"], "openai-codex")

    def agent_fixture(self):
        temp = tempfile.TemporaryDirectory()
        self.addCleanup(temp.cleanup)
        file = Path(temp.name) / "policy.json"
        file.write_text(json.dumps(self.policy))
        agent = SimpleNamespace(
            _scheduled_routes={"enabled": True, "policy_file": str(file)},
            _scheduled_home=Path(temp.name) / "developer",
            _primary_runtime={"provider": "openai-codex", "model": "gpt-6.1-sol"},
            provider="openai-codex", model="gpt-6.1-sol",
        )
        return agent, file

    def bind(self, agent, entry, provider, model):
        old = (agent.model, agent.provider)
        agent.provider, agent.model = provider, model
        return old

    def binder(self, function):
        module = ModuleType("agent.route_binding")
        module.bind_route_entry = function
        return patch.dict(sys.modules, {"agent.route_binding": module})

    def test_rechecks_time_on_each_request_and_switches_back(self):
        agent, _ = self.agent_fixture()
        with self.binder(self.bind):
            self.assertTrue(ROUTES.ensure_route(agent, instant("2026-11-09T00:59:59")))
            self.assertEqual(agent.provider, "deepseek")
            self.assertFalse(ROUTES.ensure_route(agent, instant("2026-11-09T00:59:59")))
            self.assertTrue(ROUTES.ensure_route(agent, instant("2026-11-09T01:00:00")))
            self.assertEqual((agent.provider, agent.model), ("openai-codex", "gpt-6.1-sol"))

    def test_disabled_schedule_keeps_routine_route_at_peak_and_off_peak(self):
        agent, _ = self.agent_fixture()
        agent._scheduled_routes["enabled"] = False
        agent.provider, agent.model = "deepseek", "deepseek-flash"
        agent._primary_runtime = {"provider": "deepseek", "model": "deepseek-flash"}
        with self.binder(lambda *args: self.fail("Disabled schedule must not bind a route")):
            for clock in ["00:59:59", "01:00:00", "06:00:00", "10:00:00"]:
                with self.subTest(clock=clock):
                    self.assertFalse(ROUTES.ensure_route(agent, instant("2026-11-09T" + clock)))
                    self.assertEqual((agent.provider, agent.model), ("deepseek", "deepseek-flash"))

    def test_off_peak_fallback_refuses_peak_and_unknown_calendar(self):
        _, file = self.agent_fixture()
        entry = {"off_peak_policy_file": str(file)}
        self.assertTrue(ROUTES.fallback_allowed(entry, instant("2026-11-09T00:59:59")))
        self.assertFalse(ROUTES.fallback_allowed(entry, instant("2026-11-09T01:00:00")))
        self.assertFalse(ROUTES.fallback_allowed(entry, instant("2027-01-02T12:00:00")))
        file.unlink()
        self.assertFalse(ROUTES.fallback_allowed(entry, instant("2026-11-09T12:00:00")))

    def test_fallback_reverts_at_peak_even_without_primary_schedule(self):
        agent, file = self.agent_fixture()
        agent._scheduled_routes["enabled"] = False
        agent.provider, agent.model = "deepseek", "deepseek-flash"
        agent._off_peak_fallback_entry = {"off_peak_policy_file": str(file)}
        with self.binder(self.bind):
            ROUTES.ensure_route(agent, instant("2026-11-09T01:00:00"))
        self.assertEqual((agent.provider, agent.model), ("openai-codex", "gpt-6.1-sol"))
        self.assertIsNone(agent._off_peak_fallback_entry)

    def test_startup_fallback_is_also_reverted_at_peak(self):
        agent, file = self.agent_fixture()
        with patch.dict(sys.modules, {"hermes_constants": SimpleNamespace(get_hermes_home=lambda: file.parent)}):
            ROUTES.initialise(agent, {
                "model": {"provider": "openai-codex", "default": "gpt-6.1-sol"},
                "fallback_providers": [{"provider": "deepseek", "model": "deepseek-flash", "off_peak_policy_file": str(file)}],
            })
        agent.provider, agent.model = "deepseek", "deepseek-flash"
        agent._primary_runtime = {"provider": "deepseek", "model": "deepseek-flash"}
        with self.binder(self.bind):
            ROUTES.ensure_route(agent, instant("2026-11-09T01:00:00"))
        self.assertEqual((agent.provider, agent.model), ("openai-codex", "gpt-6.1-sol"))

    def test_missing_policy_restores_safe_route(self):
        agent, file = self.agent_fixture()
        agent.provider, agent.model = "deepseek", "deepseek-flash"
        file.unlink()
        with self.binder(self.bind):
            self.assertTrue(ROUTES.ensure_route(agent))
            self.assertEqual(agent.provider, "openai-codex")

    def test_missing_credentials_falls_back_and_stays_safe_this_turn(self):
        agent, _ = self.agent_fixture()
        def bind(agent, entry, provider, model):
            return None if provider == "deepseek" else self.bind(agent, entry, provider, model)
        with self.binder(bind):
            ROUTES.ensure_route(agent, instant("2026-11-07T02:00:00"))
            self.assertEqual(agent.provider, "openai-codex")
            self.assertTrue(agent._provider_fallback_active)

    def test_unavailable_safe_route_stops_request(self):
        agent, _ = self.agent_fixture()
        with self.binder(lambda *args: None):
            with self.assertRaises(RuntimeError):
                ROUTES.ensure_route(agent, instant("2026-11-07T02:00:00"))

    def test_initialization_uses_session_profile_home(self):
        module = ModuleType("hermes_constants")
        module.get_hermes_home = lambda: Path("/root-home")
        agent = SimpleNamespace(_session_db=SimpleNamespace(db_path="/profiles/developer/state.db"))
        with patch.dict(sys.modules, {"hermes_constants": module}):
            ROUTES.initialise(agent, {"scheduled_routes": {"enabled": True}})
        self.assertEqual(agent._scheduled_home, Path("/profiles/developer"))
        self.assertTrue(agent._scheduled_routes["enabled"])

    def test_unknown_policy_version_uses_codex(self):
        self.policy["version"] = 2
        self.assertEqual(ROUTES.choose_route(self.policy, "developer", instant("2026-11-07T02:00:00"))["provider"], "openai-codex")

    def test_other_profiles_are_opt_in(self):
        agent = SimpleNamespace()
        self.assertFalse(ROUTES.ensure_route(agent))


if __name__ == "__main__":
    unittest.main()
