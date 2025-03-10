{ pkgs ? import <nixpkgs> {} }:

pkgs.writeShellScriptBin "update-and-push" ''
  #!${pkgs.bash}/bin/bash
  set -euo pipefail

  # Update flake inputs first
  ${pkgs.nix}/bin/nix flake update

  # Pull repo changes
  pull_output=$(${pkgs.git}/bin/git pull --quiet --autostash 2>&1 || true)
  pull_ignore="Already up to date."

  case "$pull_output" in
    *"$pull_ignore"*) ;;
    *) printf "%s\n" "$pull_output" ;;
  esac

  # Stage all changes
  ${pkgs.git}/bin/git add --all :/

  # Commit and push if changes exist
  if ${pkgs.git}/bin/git status --porcelain | ${pkgs.coreutils}/bin/grep -q .; then
    msg="\${@:+\$@}" # Use all arguments if provided
    if [[ -z "$msg" ]]; then
      msg="General updates"
    fi
    ${pkgs.git}/bin/git commit --message "$msg" || true
    ${pkgs.git}/bin/git push
  fi
''
