"""Preview by default; --create uses native idempotent board setup after approval."""
import argparse
import json
import os
from pathlib import Path


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--home', required=True, type=Path)
    parser.add_argument('--repo', required=True, type=Path)
    parser.add_argument('--create', action='store_true')
    args = parser.parse_args()
    home, repo = args.home.resolve(), args.repo.resolve()
    if not (home / 'config.yaml').is_file() or not (repo / '.git').exists():
        parser.error('Expected an existing Hermes home and Git checkout')
    os.environ['HERMES_HOME'] = str(home)
    slug = 'hermes-acceptance'
    path = home / 'kanban' / 'boards' / slug / 'kanban.db'
    result = {'home': str(home), 'board': slug, 'repo': str(repo), 'exists': path.exists(), 'dispatch': 'unchanged'}
    if args.create:
        from hermes_cli.kanban_db_boards import create_board, read_board_metadata
        if path.exists():
            metadata = read_board_metadata(slug)
            if metadata.get('archived') or metadata.get('default_workdir') != str(repo):
                parser.error('Existing board differs; inspect it rather than changing its identity')
        else:
            create_board(slug, name='Hermes acceptance', description='Bounded owner-approved acceptance only', default_workdir=str(repo))
        result['exists'] = True
    print(json.dumps(result, indent=2))


if __name__ == '__main__':
    main()
