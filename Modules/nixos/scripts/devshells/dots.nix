{
  commands = [
    {
      name = "Rebuild";
      category = "Flake/System Management";
      command = "sudo nixos-rebuild --flake $DOTS switch $@";
      help = "rebuild current NixOS";
    }
    {
      name = "Clean";
      category = "Flake/System Management";
      command = "nix-collect-garbage --delete-old";
      help = "rebuild current NixOS";
    }
    {
      name = "Update";
      category = "Flake/System Management";
      command = ''
        #!/bin/sh

        #@ Ensure strict mode and exit on error
        set -euo pipefail

        #@ Pull repo changes, capturing output
        PULL_OUTPUT=$(git pull --quiet --autostash 2>&1)
        PULL_IGNORE="Already up to date."
        case "$PULL_OUTPUT" in *"$PULL_IGNORE"*) ;;
          *) printf "%s\n" "$PULL_OUTPUT" ;;
        esac

        #@ Update flake inputs
        nix flake update

        #@ Sync repo and push changes
        git add --all :/
        if git status --porcelain | grep -q .; then
          msg="General updates"
          [ $# -gt 0 ] && msg="$*"
          git commit --message "$msg" || true
          git push
        fi
      '';
      help = "Update flake inputs, sync repo, and push changes";
    }
  ];
}
