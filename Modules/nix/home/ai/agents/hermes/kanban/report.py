"""Read-only task/run usage report. Session counters are estimates, not billing."""
import argparse
from contextlib import contextmanager
import json
import sqlite3
from pathlib import Path


@contextmanager
def read_db(path):
    conn = sqlite3.connect(f'file:{path}?mode=ro', uri=True)
    conn.row_factory = sqlite3.Row
    try:
        yield conn
    finally:
        conn.close()


def report(home, board):
    path = home / 'kanban.db' if board == 'default' else home / 'kanban' / 'boards' / board / 'kanban.db'
    with read_db(path) as conn:
        tasks = [dict(row) for row in conn.execute('SELECT id,title,status,assignee FROM tasks ORDER BY created_at')]
        for task in tasks:
            runs = [dict(row) for row in conn.execute('SELECT id,profile,started_at,ended_at,outcome,metadata FROM task_runs WHERE task_id=? ORDER BY id', (task['id'],))]
            for run in runs:
                metadata = json.loads(run.pop('metadata') or '{}')
                sid = metadata.get('worker_session_id')
                run['worker_session_id'] = sid
                run['usage'] = None
                profile = run['profile']
                if profile and profile not in ('.', '..') and '/' not in profile and sid:
                    state = (home if profile == 'default' else home / 'profiles' / profile) / 'state.db'
                    if state.exists():
                        with read_db(state) as sessions:
                            row = sessions.execute('SELECT model,billing_provider,api_call_count,input_tokens,output_tokens,cache_read_tokens,reasoning_tokens FROM sessions WHERE id=?', (sid,)).fetchone()
                            run['usage'] = dict(row) if row else None
            task['runs'] = runs
            task['correction_requests'] = conn.execute("SELECT COUNT(*) FROM task_events WHERE task_id=? AND kind='changes_requested'", (task['id'],)).fetchone()[0]
    return {'board': board, 'tasks': tasks, 'accounting': 'Local session estimates; missing usage is null. Reused session IDs must not be summed twice. Auxiliary calls, retries and route switches may be incomplete. Not provider billing or Plus allowance.'}


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--home', required=True, type=Path)
    parser.add_argument('--board', default='default')
    args = parser.parse_args()
    if not args.board or any(c not in 'abcdefghijklmnopqrstuvwxyz0123456789_-' for c in args.board):
        parser.error('Expected a native board slug')
    print(json.dumps(report(args.home.resolve(), args.board), indent=2))


if __name__ == '__main__':
    main()
