{pkgs}:
pkgs.runCommand "secrets-lint" {} ''
  echo "==> Scanning Nix store path for leaked secret patterns..."

  # Patterns that must never appear in any tracked store path.
  PATTERNS=(
    "BEGIN PRIVATE KEY"
    "BEGIN RSA PRIVATE KEY"
    "AKIA[A-Z0-9]\{16\}"
    "password[[:space:]]*=[[:space:]]*\"[^\"]\\+\""
  )

  FOUND=0
  for pat in "''${PATTERNS[@]}"; do
    if grep -rq "$pat" ${pkgs.path} 2>/dev/null; then
      echo "FAIL: Found pattern: $pat"
      FOUND=1
    fi
  done

  if [ "$FOUND" -eq 1 ]; then
    echo "secrets-lint: leaked secret pattern detected — aborting."
    exit 1
  fi

  echo "secrets-lint: no leaked secrets found."
  touch "$out"
''
