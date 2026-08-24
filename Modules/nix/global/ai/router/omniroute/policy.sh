#!/bin/sh
# Keep upstream connections with known protocol incompatibilities out of
# OmniRoute's dynamic reasoning channel. This is idempotent and preserves
# every other channel and connection.
set -eu

data_dir="${OMNIROUTE_DATA_DIR:-$HOME/.local/share/omniroute}"
database="$data_dir/storage.sqlite"

# OmniRoute initializes the database on first start. Defer reconciliation
# until its schema exists.
[ -f "$database" ] || exit 0

sqlite3 "$database" <<'SQL'
INSERT INTO auto_candidate_overrides (
  id,
  api_key_id,
  auto_channel,
  connection_id,
  excluded,
  created_at
)
SELECT
  lower(hex(randomblob(16))),
  api_keys.id,
  'best-reasoning',
  provider_connections.id,
  1,
  strftime('%Y-%m-%dT%H:%M:%fZ', 'now')
FROM api_keys
CROSS JOIN provider_connections
WHERE api_keys.is_active = 1
  AND provider_connections.is_active = 1
  AND provider_connections.provider = 'codex'
ON CONFLICT(api_key_id, auto_channel, connection_id)
DO UPDATE SET excluded = excluded.excluded;
SQL
