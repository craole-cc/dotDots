"""Admission limits at the native atomic claim boundary; no second scheduler."""
import json
from pathlib import Path
import yaml


def configured_limits(conn):
    path = next((row[2] for row in conn.execute("PRAGMA database_list") if row[1] == "main"), "")
    if not path:
        return {}
    # Boards live below the effective home. Stop at its first configuration.
    for parent in Path(path).resolve().parents:
        config = parent / "config.yaml"
        if config.is_file():
            value = yaml.safe_load(config.read_text()) or {}
            return (value.get("kanban") or {}).get("execution_limits") or {}
    return {}


def admission_reason(conn, task_id, limits):
    if not limits.get("enabled"):
        return None
    runs = conn.execute("SELECT COUNT(*) FROM task_runs WHERE task_id = ?", (task_id,)).fetchone()[0]
    changes = conn.execute("SELECT COUNT(*) FROM task_events WHERE task_id = ? AND kind = 'changes_requested'", (task_id,)).fetchone()[0]
    if runs >= int(limits.get("max_runs", 8)):
        return "Task run budget exhausted; review existing artifacts before authorising more work"
    if changes > int(limits.get("max_correction_rounds", 2)):
        return "Correction budget exhausted; retain findings and request a scope decision"
    row = conn.execute("SELECT goal_mode FROM tasks WHERE id = ?", (task_id,)).fetchone()
    if row and row[0]:
        return "Goal-judge loops are disabled for this bounded workflow"
    return None


def completion_allowed(conn, task_id, limits):
    if not limits.get("enabled") or not limits.get("require_independent_review"):
        return True
    row = conn.execute("SELECT current_run_id, assignee FROM tasks WHERE id=?", (task_id,)).fetchone()
    if not row:
        return False
    review = conn.execute("SELECT payload FROM task_events WHERE task_id=? AND kind='review_requested' ORDER BY id DESC LIMIT 1", (task_id,)).fetchone()
    if not review and row[1] not in limits.get('review_profiles', ['developer', 'architect', 'scribe']):
        return True
    if row[0] is None:
        return False
    claim = conn.execute("SELECT payload FROM task_events WHERE task_id=? AND kind='claimed' AND run_id=? ORDER BY id DESC LIMIT 1", (task_id, row[0])).fetchone()
    if not claim or not review:
        return False
    implementer = json.loads(review[0] or '{}').get('implementer')
    return bool(implementer and implementer != row[1] and json.loads(claim[0] or '{}').get('source_status') == 'review')
