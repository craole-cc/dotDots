"""Run with the built Hermes Python: real gates and transport, no providers/network."""

import json
import os
from pathlib import Path
import socket
import subprocess
import sys
import tempfile
import threading
from types import SimpleNamespace
import unittest
from unittest.mock import patch


def forbidden(*args, **kwargs):
    raise AssertionError("Network forbidden in handoff acceptance")


socket.socket.connect = forbidden
socket.socket.connect_ex = forbidden
socket.create_connection = forbidden

# Isolate import-time defaults as well as each individual test's state.
IMPORT_HOME = tempfile.TemporaryDirectory(prefix="hermes-handoff-import-")
os.environ["HERMES_HOME"] = IMPORT_HOME.name

from tools import bot_mode_dm as dm, bot_mode_probe as probe, team_handoff as team
from agent.system_prompt import _bot_mode_parts


class Handoff(unittest.TestCase):
    def setUp(self):
        temporary = tempfile.TemporaryDirectory()
        self.addCleanup(temporary.cleanup)
        self.root = Path(temporary.name)
        self.policy = {
            "version": 1, "enabled": True, "gateway_platforms": ["telegram"],
            "routes": {"default": ["coordinator"], "coordinator": ["auditor", "developer"],
                       "developer": ["scribe"], "auditor": [], "scribe": []},
        }
        self.write_policy()
        (self.root / "config.yaml").write_text("{}\n")
        for name in self.policy["routes"]:
            home = self.home(name)
            home.mkdir(parents=True, exist_ok=True)
            (home / "profile.yaml").write_text("ui_meta:\n  hermes-bots:\n    title: " + name + "\n")
        probe._reset_cache_for_tests()
        environment = patch.dict(os.environ, {"HERMES_HOME": str(self.root)})
        environment.start()
        self.addCleanup(environment.stop)

    def home(self, name):
        return self.root if name == "default" else self.root / "profiles" / name

    def write_policy(self):
        (self.root / "team-handoff.json").write_text(json.dumps(self.policy))

    def agent(self, profile="default", platform="telegram", title="Actual Telegram conversation"):
        return SimpleNamespace(
            _session_db=SimpleNamespace(db_path=str(self.home(profile) / "state.db")),
            session_id=f"fixture-{profile}-{platform}", platform=platform,
            _session_title_hint=title, _bot_mode_protocol=True, tools=[], valid_tool_names=set(),
        )

    def test_telegram_tool_and_protocol_without_renaming_session(self):
        agent = self.agent()
        self.assertTrue(dm.ensure_message_agent_tool(agent))
        self.assertTrue(dm.ensure_message_agent_tool(agent))
        self.assertEqual(len(agent.tools), 1)
        self.assertIn("message_agent", agent.valid_tool_names)
        self.assertIn('target="coordinator"', "\n".join(_bot_mode_parts(agent)))
        self.assertEqual(agent._session_title_hint, "Actual Telegram conversation")
        self.assertFalse(getattr(agent, "_bot_chat_timeless_prompt", False))

    def test_other_surfaces_and_named_telegram_sessions_stay_closed(self):
        for platform in ("cli", "api_server", "discord", None):
            self.assertFalse(dm.ensure_message_agent_tool(self.agent(platform=platform)))
        self.assertFalse(dm.ensure_message_agent_tool(self.agent(profile="coordinator")))
        agent = self.agent()
        agent._bot_mode_protocol = False
        self.assertFalse(dm.ensure_message_agent_tool(agent))
        agent = self.agent()
        agent._session_db = None
        self.assertFalse(dm.ensure_message_agent_tool(agent))

    def test_telegram_dispatch_uses_native_local_transport(self):
        with patch.object(dm, "_start_delivery", return_value=json.dumps({
            "status": "queued", "delivery_id": "fixture-delivery", "process_id": "fixture-process",
            "reply_delivery": "notification",
        })) as start:
            result = json.loads(dm.message_agent_tool(
                target="coordinator", message="Audit only; preserve current work",
                constraints="No implementation; return for owner approval",
                expecting="Auditor findings and revised plan", agent=self.agent(),
            ))
        self.assertEqual(result["delivery_id"], "fixture-delivery")
        self.assertEqual(result["reply_delivery"], "notification")
        args, kwargs = start.call_args
        self.assertEqual(args[0][-2:], ["-p", "coordinator"])
        self.assertIn("No implementation; return for owner approval", args[1])
        self.assertIn("Auditor findings and revised plan", args[1])
        self.assertEqual(kwargs["profile_home"], self.home("coordinator"))

    def test_wrong_role_remote_and_fanout_refused_before_transport(self):
        for target in ("auditor", "developer", "peer/coordinator", "coordinator@remote", "coordinator,auditor"):
            with self.subTest(target=target), patch.object(dm, "_start_delivery") as start:
                result = json.loads(dm.message_agent_tool(target=target, message="Audit", agent=self.agent()))
                self.assertIn("error", result)
                start.assert_not_called()

    def test_coordinator_can_commission_auditor_in_canonical_session(self):
        agent = self.agent(profile="coordinator", platform="cli", title="Bot Chat")
        with patch.object(dm, "_start_delivery", return_value='{"status":"queued"}') as start:
            result = json.loads(dm.message_agent_tool(target="auditor", message="Review only", agent=agent))
        self.assertEqual(result["status"], "queued")
        self.assertEqual(start.call_args.kwargs["profile_home"], self.home("auditor"))

    def test_leaf_cannot_initiate_another_commission(self):
        with patch.object(dm, "_start_delivery") as start:
            result = json.loads(dm.message_agent_tool(target="developer", message="Implement", agent=self.agent(
                profile="auditor", platform="cli", title="Bot Chat")))
        self.assertIn("error", result)
        start.assert_not_called()

    def test_missing_or_malformed_policy_does_not_open_telegram(self):
        file = self.root / "team-handoff.json"
        file.unlink()
        self.assertFalse(dm.ensure_message_agent_tool(self.agent()))
        file.write_text("invalid json")
        self.assertFalse(dm.ensure_message_agent_tool(self.agent()))
        sender = SimpleNamespace(roster_homes={"coordinator": self.home("coordinator")})
        self.assertIsNotNone(team.target_error(self.agent(), ["coordinator"], sender))

    def test_policy_without_managed_bots_does_not_advertise_handoff(self):
        for file in self.root.rglob("profile.yaml"):
            file.unlink()
        probe._reset_cache_for_tests()
        agent = self.agent()
        self.assertFalse(dm.ensure_message_agent_tool(agent))
        self.assertEqual(_bot_mode_parts(agent), [])

    def test_revoked_policy_refuses_a_leaked_tool_call(self):
        agent = self.agent()
        self.assertTrue(dm.ensure_message_agent_tool(agent))
        self.policy["enabled"] = False
        self.write_policy()
        with patch.object(dm, "_start_delivery") as start:
            result = json.loads(dm.message_agent_tool(target="coordinator", message="Audit", agent=agent))
        self.assertIn("error", result)
        start.assert_not_called()

    def test_native_ack_distinguishes_notification_poll_and_failure(self):
        for can_notify, expected in ((True, "notification"), (False, "poll")):
            with patch("tools.terminal_tool.terminal_tool", return_value=json.dumps({
                "session_id": "fixture-process", "notify_on_complete": can_notify,
            })):
                result = json.loads(dm._spawn_delivery("fixture", "@coordinator", delivery_id="fixture-id",
                                                      task_id=None, agent=self.agent()))
            self.assertEqual(result["reply_delivery"], expected)
            self.assertEqual(result["delivery_id"], "fixture-id")
        with patch("tools.terminal_tool.terminal_tool", return_value='{"error":"approval required"}'):
            result = json.loads(dm._spawn_delivery("fixture", "@coordinator", task_id=None, agent=self.agent()))
        self.assertIn("error", result)
        self.assertNotIn("status", result)

    def test_nested_commission_forces_poll_instead_of_an_early_final_reply(self):
        agent = self.agent(profile="coordinator", platform="cli", title="Bot Chat")
        with patch("tools.terminal_tool.terminal_tool", return_value=json.dumps({
            "session_id": "fixture-child", "notify_on_complete": False,
        })) as terminal:
            result = json.loads(dm._spawn_delivery("fixture", "@auditor", delivery_id="child-id",
                                                  task_id=None, agent=agent))
        self.assertFalse(terminal.call_args.kwargs["notify_on_complete"])
        self.assertEqual(result["reply_delivery"], "poll")
        self.assertIn("wait", result["detail"])

    def test_native_completion_persists_reply_only_to_owning_session(self):
        from tools.process_registry import process_registry

        agent = self.agent(profile="coordinator", platform="cli", title="Bot Chat")
        rows = []
        ready = threading.Event()

        def append(session_id, role, **fields):
            rows.append((session_id, role, fields))
            ready.set()

        agent._session_db.append_message = append
        payload = json.dumps({"status": "settled", "delivery_id": "audit-id", "reply": "Fixture audit result"})
        child = subprocess.Popen([sys.executable, "-c", f"print({payload!r})"],
                                 stdout=subprocess.PIPE, stderr=subprocess.STDOUT, text=True)
        process = process_registry.adopt_local(child, command="fixture-audit", cwd=str(self.root),
                                               notify_on_complete=False)
        self.assertTrue(dm._persist_reply_when_done(process.id, agent))
        self.assertTrue(ready.wait(10), "native process completion did not persist")
        child.wait(timeout=5)
        self.assertEqual(len(rows), 1)
        self.assertEqual(rows[0][:2], (agent.session_id, "user"))
        self.assertEqual(rows[0][2]["display_kind"], "process_complete")
        self.assertIn("Fixture audit result", rows[0][2]["content"])
        self.assertIn(process.id, rows[0][2]["content"])

    def test_gateway_completion_uses_persisted_origin_not_foreground_chat(self):
        from gateway.run_notifications import GatewayNotificationsMixin

        origin = SimpleNamespace(platform="telegram", chat_id="fixture-owner", user_id="fixture-user")
        entry = SimpleNamespace(origin=origin)
        restored = []

        def restore(current):
            restored.append(current)
            return current.origin

        gateway = SimpleNamespace(
            session_store=SimpleNamespace(_ensure_loaded=lambda: None, _entries={"fixture-session": entry}),
            _restored_source=restore,
        )
        result = GatewayNotificationsMixin._build_process_event_source(gateway, {
            "session_key": "fixture-session", "platform": "telegram", "chat_id": "wrong-foreground-chat",
        })
        self.assertIs(result, origin)
        self.assertEqual(restored, [entry])


if __name__ == "__main__":
    unittest.main()
