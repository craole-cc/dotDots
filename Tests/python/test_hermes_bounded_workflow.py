"""Run with patched Hermes source on PYTHONPATH and its venv; never uses real state."""
import os
import importlib.util
import io
from contextlib import closing, redirect_stdout
import socket
import sqlite3
import tempfile
import unittest
from pathlib import Path
from unittest.mock import patch

# The source may import profile/config helpers; isolate them before importing Hermes.
HOME = tempfile.TemporaryDirectory()
os.environ['HERMES_HOME'] = HOME.name


def forbidden(*args, **kwargs):
    raise AssertionError('Network forbidden')


socket.create_connection = forbidden
socket.socket.connect = forbidden
socket.socket.connect_ex = forbidden
from hermes_cli import kanban_db as kb
from hermes_cli.execution_limits import admission_reason
from agent import skill_utils
from toolsets import resolve_toolset


class BoundedWorkflow(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory()
        self.addCleanup(self.temp.cleanup)
        self.root = Path(self.temp.name)
        self.db = self.root / 'kanban.db'
        kb.init_db(self.db)
        self.conn = sqlite3.connect(self.db, isolation_level=None)
        self.conn.row_factory = sqlite3.Row
        self.addCleanup(self.conn.close)
        (self.root / 'config.yaml').write_text('kanban:\n  execution_limits:\n    enabled: true\n    max_runs: 2\n    max_correction_rounds: 1\n    require_independent_review: true\n')

    def card(self, **extra):
        tid = kb.create_task(self.conn, title='fixture', assignee=extra.pop('assignee', 'scribe'), initial_status='blocked', **extra)
        self.assertTrue(kb.promote_task(self.conn, tid, actor='fixture')[0])
        return tid

    def test_claim_is_atomic_and_run_budget_survives_reopen(self):
        tid = self.card()
        self.assertIsNotNone(kb.claim_task(self.conn, tid))
        self.assertIsNone(kb.claim_task(self.conn, tid))
        # Model a persisted earlier run ending and operator reopening; the run row remains.
        self.conn.execute("UPDATE task_runs SET status='failed', ended_at=1 WHERE task_id=?", (tid,))
        self.conn.execute("UPDATE tasks SET status='ready', claim_lock=NULL, current_run_id=NULL WHERE id=?", (tid,))
        self.assertIsNotNone(kb.claim_task(self.conn, tid))
        self.conn.execute("UPDATE task_runs SET status='failed', ended_at=2 WHERE task_id=?", (tid,))
        self.conn.execute("UPDATE tasks SET status='ready', claim_lock=NULL, current_run_id=NULL WHERE id=?", (tid,))
        self.assertIsNone(kb.claim_task(self.conn, tid))
        self.assertEqual(kb.get_task(self.conn, tid).status, 'blocked')
        self.assertEqual(self.conn.execute('SELECT COUNT(*) FROM task_runs WHERE task_id=?', (tid,)).fetchone()[0], 2)

    def test_corrections_and_goal_loops_block_before_spawning(self):
        tid = self.card()
        for _ in range(2):
            self.conn.execute("INSERT INTO task_events(task_id,kind,payload,created_at) VALUES (?, 'changes_requested', '{}', 1)", (tid,))
        self.assertIsNone(kb.claim_task(self.conn, tid))
        self.assertEqual(kb.get_task(self.conn, tid).status, 'blocked')
        goal = self.card(goal_mode=True)
        self.assertIsNone(kb.claim_task(self.conn, goal))

    def test_allowlist_blocks_unrelated_and_keeps_essential_skills(self):
        with patch.object(skill_utils, '_skills_cfg', return_value={'allowed': ['nix-style']}):
            self.assertFalse(skill_utils.is_disabled_entry({'name': 'nix-style'}, set()))
            self.assertTrue(skill_utils.is_disabled_entry({'name': 'songwriting-and-ai-music'}, set()))
            self.assertFalse(skill_utils.is_disabled_entry({'name': 'hermes-agent'}, set()))
            self.assertTrue(skill_utils.is_disabled_entry({'name': 'nix-style'}, {'nix-style'}))

    def test_actual_skill_catalog_filters_unrelated_skills(self):
        from tools import skills_tool
        root = Path(HOME.name) / 'skills'
        for name in ['fixture-allowed', 'fixture-unrelated']:
            folder = root / name
            folder.mkdir(parents=True, exist_ok=True)
            (folder / 'SKILL.md').write_text(f'---\nname: {name}\ndescription: fixture\n---\nFixture body.\n')
        skills_tool.clear_skills_cache()
        with patch.object(skill_utils, '_skills_cfg', return_value={'allowed': ['fixture-allowed']}):
            names = {entry['name'] for entry in skills_tool.find_all_skills()}
        self.assertIn('fixture-allowed', names)
        self.assertNotIn('fixture-unrelated', names)
        skills_tool.clear_skills_cache()

    def test_peak_gate_applies_to_startup_fallback_normalization(self):
        from hermes_cli.fallback_config import get_fallback_chain
        entry = {'provider': 'deepseek', 'model': 'deepseek-flash', 'off_peak_policy_file': '/fixture'}
        with patch('agent.scheduled_routes.fallback_allowed', return_value=False):
            self.assertEqual(get_fallback_chain({'fallback_providers': [entry]}), [])
        with patch('agent.scheduled_routes.fallback_allowed', return_value=True):
            self.assertEqual(len(get_fallback_chain({'fallback_providers': [entry]})), 1)

    def test_completion_subscription_is_passive(self):
        from tools import kanban_tools
        values = {'HERMES_SESSION_PLATFORM': 'telegram', 'HERMES_SESSION_CHAT_ID': 'fixture', 'HERMES_SESSION_PROFILE': 'default'}
        def env(key, default=None):
            return values.get(key, default)
        with patch('gateway.session_context.get_session_env', side_effect=env), patch.object(kanban_tools, 'load_config', return_value={'kanban': {'completion_delivery_mode': 'notify'}}):
            target = kanban_tools._resolve_notify_target()
        self.assertIsNotNone(target)
        self.assertEqual(target['delivery_mode'], 'notify')

    def test_board_preparation_is_preview_first_and_idempotent(self):
        script = Path(__file__).resolve().parents[2] / 'Modules/nix/home/ai/agents/hermes/kanban/prepare_acceptance.py'
        spec = importlib.util.spec_from_file_location('prepare_acceptance_fixture', script)
        module = importlib.util.module_from_spec(spec)
        spec.loader.exec_module(module)
        repo = self.root / 'repo'
        (repo / '.git').mkdir(parents=True)
        args = ['prepare', '--home', str(self.root), '--repo', str(repo)]
        board = self.root / 'kanban/boards/hermes-acceptance/kanban.db'
        with patch.dict(os.environ), redirect_stdout(io.StringIO()):
            with patch('sys.argv', args):
                module.main()
            self.assertFalse(board.exists())
            for _ in range(2):
                with patch('sys.argv', args + ['--create']):
                    module.main()
            self.assertTrue(board.exists())
            with closing(sqlite3.connect(board)) as db:
                self.assertEqual(db.execute('SELECT COUNT(*) FROM tasks').fetchone()[0], 0)

    def test_architect_toolset_cannot_edit_or_execute(self):
        tools = set(resolve_toolset('repository_read'))
        self.assertEqual(tools, {'read_file', 'search_files'})

    def test_bounded_support_evidence_does_not_force_extra_review(self):
        tid = self.card(assignee='intern')
        run = kb.claim_task(self.conn, tid)
        self.assertTrue(kb.complete_task(self.conn, tid, summary='Bounded inventory evidence', expected_run_id=run.current_run_id))

    def test_implementer_cannot_accept_own_review(self):
        tid = self.card()
        run = kb.claim_task(self.conn, tid)
        self.assertTrue(kb.request_review(self.conn, tid, summary='Full plan', reviewer='scribe', expected_run_id=run.current_run_id))
        review = kb.claim_review_task(self.conn, tid)
        self.assertFalse(kb.complete_task(self.conn, tid, summary='Self acceptance', expected_run_id=review.current_run_id))

    def test_independent_reviewer_can_complete(self):
        tid = self.card()
        run = kb.claim_task(self.conn, tid)
        self.assertTrue(kb.request_review(self.conn, tid, summary='Full plan', reviewer='auditor', expected_run_id=run.current_run_id))
        review = kb.claim_review_task(self.conn, tid)
        self.assertTrue(kb.complete_task(self.conn, tid, summary='Accepted plan', expected_run_id=review.current_run_id))

    def test_same_card_review_returns_to_original_implementer(self):
        tid = self.card()
        run = kb.claim_task(self.conn, tid)
        self.assertFalse(kb.complete_task(self.conn, tid, summary='Must not bypass review', expected_run_id=run.current_run_id))
        self.assertTrue(kb.request_review(self.conn, tid, summary='Full bounded plan', reviewer='auditor', expected_run_id=run.current_run_id))
        review = kb.claim_review_task(self.conn, tid)
        self.assertIsNotNone(review)
        ok, owner = kb.request_changes(self.conn, tid, reason='Add acceptance criteria', expected_run_id=review.current_run_id)
        self.assertTrue(ok)
        self.assertEqual(owner, 'scribe')
        self.assertEqual(kb.get_task(self.conn, tid).assignee, 'scribe')


if __name__ == '__main__':
    unittest.main()
