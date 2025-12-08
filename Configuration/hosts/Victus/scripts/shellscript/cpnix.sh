#!/usr/bin/env sh
#~@ Backup NixOS configuration to /etc/nixos

set -eu

#~@ Use existing environment variable
HOSTNAME_VAR="$(hostname | tr '[:lower:]' '[:upper:]')_CONFIG"
SOURCE=$(eval echo "\$$HOSTNAME_VAR")
BACKUP="/etc/nixos"
ARCHIVE="/archive/etc/nixos"

#~@ Validate source exists
if [ -z "$SOURCE" ] || [ ! -d "$SOURCE" ]; then
	printf "Error: Configuration directory not found at %s\n" "$SOURCE" >&2
	printf "Expected environment variable: %s\n" "$HOSTNAME_VAR" >&2
	exit 1
fi

#~@ Check for rsync
if ! command -v rsync >/dev/null 2>&1; then
	printf "Error: rsync is not installed\n" >&2
	exit 1
fi

#~@ Archive existing /etc/nixos if it exists
if [ -d "$BACKUP" ]; then
	printf "Archiving existing /etc/nixos...\n"

	#~@ Create archive directory
	sudo mkdir -p "$ARCHIVE"

	#~@ Get next backup number
	LATEST=$(find "$ARCHIVE" -maxdepth 1 -type d -name "backup.*" 2>/dev/null |
		sed 's/.*backup\.//' |
		sort -n |
		tail -1)
	NEXT=$((${LATEST:-0} + 1))
	ARCHIVE_DIR="$ARCHIVE/backup.$NEXT"

	#~@ Move existing /etc/nixos to archive
	sudo mv "$BACKUP" "$ARCHIVE_DIR"
	printf "✓ Archived to: %s\n" "$ARCHIVE_DIR"
fi

#~@ Copy configuration to /etc/nixos
printf "Copying configuration to /etc/nixos...\n"
sudo rsync -av --exclude='.git' "$SOURCE/" "$BACKUP/"
printf "✓ Configuration copied to /etc/nixos\n"

#~@ Update nixPath in /etc/nixos/mod/system.nix (not source!)
SYSTEM_NIX="$BACKUP/mod/system.nix"

if [ -f "$SYSTEM_NIX" ]; then
	printf "Updating nixPath in /etc/nixos/mod/system.nix...\n"

	#~@ Create temp file for sed (POSIX compatible)
	TEMP_FILE=$(mktemp)

	#~@ Remove any existing nixos-config lines and add the new one
	sed '/nixos-config=/d' "$SYSTEM_NIX" |
		sed 's|^\(      "nixpkgs=.*"\)$|\1\n      "nixos-config=/etc/nixos/configuration.nix"|' \
			>"$TEMP_FILE"

	#~@ Replace original file in BACKUP location
	sudo cp "$TEMP_FILE" "$SYSTEM_NIX"
	rm "$TEMP_FILE"

	printf "✓ Updated nixPath to use /etc/nixos/configuration.nix\n"
else
	printf "Warning: %s not found\n" "$SYSTEM_NIX" >&2
fi

printf "\n✓ Backup complete!\n"
printf "  Configuration: /etc/nixos\n"
if [ -n "${ARCHIVE_DIR:-}" ]; then
	printf "  Previous backup: %s\n" "$ARCHIVE_DIR"
fi
