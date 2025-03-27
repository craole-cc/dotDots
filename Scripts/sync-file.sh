#!/bin/sh
set -eu

# File mapping in the format "source:destination"
sync_files() {
  # Create destination directory if it doesn't exist
  mkdir -p "$(dirname "$2")"

  if [ ! -f "$2" ] && [ -f "$1" ]; then
    cp "$1" "$2"
    echo "Created: $2"
    return
  fi

  if [ ! -f "$1" ] && [ -f "$2" ]; then
    cp "$2" "$1"
    echo "Created: $1"
    return
  fi

  if [ -f "$1" ] && [ -f "$2" ]; then
    # Using universal date format for comparison
    src_time=$(date -r "$1" +%s 2>/dev/null || stat -c %Y "$1")
    dst_time=$(date -r "$2" +%s 2>/dev/null || stat -c %Y "$2")

    if [ "${src_time}" -gt "${dst_time}" ]; then
      cp "$1" "$2"
      echo "Updated: $2 (source newer)"
    elif [ "${dst_time}" -gt "${src_time}" ]; then
      cp "$2" "$1"
      echo "Updated: $1 (destination newer)"
    fi
  fi
}

# Navigate to git root
root_dir=$(git rev-parse --show-toplevel)
if [ -d "${root_dir}" ]; then
  cd "${root_dir}"
else
  echo "This directory is not part of a git repository."
  echo "Please navigate to a valid git repository and try again."
  exit 1
fi

#| List of files to sync
sync_files ".dotsrc" "Configuration/Modules/init"
sync_files ".editorconfig" "Configuration/editorconfig/default.editorconfig"
sync_files ".envrc" "Configuration/nixos/.envrc"
sync_files ".gitignore" "Configuration/git/global/ignore"
sync_files ".treefmt.toml" "Configuration/treefmt/config.toml"
sync_files "README.md" "Documentation/README.md"
sync_files "LICENSE" "Documentation/LICENSE"
sync_files ".ignore" "Configuration/search/ignore"
sync_files ".shellcheckrc" "Configuration/shell/shellcheck"
sync_files ".sops.yaml" "Configuration/sops/config.yaml"
sync_files ".taplo.toml" "Configuration/toml/config.toml"
sync_files "codebook.toml" "Configuration/codebook/config.toml"
