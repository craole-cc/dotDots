{pkgs, ...}:
pkgs.runCommand "secrets-lint" {} ''
  echo "==> Scanning repository sources for leaked secret patterns..."

  source_root=${../..}

  # Patterns that must never appear in tracked sources.
  PATTERNS=(
    "BEGIN PRIVATE KEY"
    "BEGIN RSA PRIVATE KEY"
    "AKIA[A-Z0-9]{16}"
    "password[[:space:]]*=[[:space:]]*\"[^\"]+\""
  )

  FOUND=0
  while IFS= read -r -d "" file; do
    for pat in "''${PATTERNS[@]}"; do
      if grep -Eq "$pat" "$file"; then
        echo "FAIL: Found pattern: $pat in $file"
        FOUND=1
      fi
    done
  done < <(
    find "$source_root" -type f \
      ! -path "*/secrets/secrets.yaml.example" \
      ! -path "*/secrets/.sops.yaml.example" \
      ! -path "*/secrets/*.yaml.enc" \
      -print0
  )

  if [ "$FOUND" -eq 1 ]; then
    echo "secrets-lint: leaked secret pattern detected - aborting."
    exit 1
  fi

  echo "secrets-lint: no leaked secrets found."
  touch "$out"
''
