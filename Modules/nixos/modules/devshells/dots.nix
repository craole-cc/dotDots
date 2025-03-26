{
  perSystem =
    {
      pkgsUnstable,
      flakePaths,
      ...
    }:
    let
      # pkgs = pkgsUnstable;
      dots = {
        name = "dotDots";
        env = [
          {
            name = "PRJ_BIN";
            prefix =
              let
                inherit (flakePaths.parts) bin;
                shellscript = "$PRJ_ROOT" + bin.shellscript;
                rust = "$PRJ_ROOT" + bin.rust;
                dots = "$PRJ_ROOT" + bin.scripts.dots;
                mods = "$PRJ_ROOT" + bin.scripts.mods;
              in
              ''
                ${shellscript}:${rust}:${dots}:${mods}
              '';
          }
          {
            name = "PATH";
            prefix = "$PRJ_BIN";
          }
          {
            name = "PRJ_CACHE";
            eval = "$PRJ_ROOT/.cache";
          }
          {
            name = "PRJ_CONFIG";
            eval = "$PRJ_ROOT/.config";
          }
          {
            name = "FLAKE";
            eval = "$PRJ_ROOT";
          }
        ];
        packages = with pkgsUnstable; [
          bat
          btop
          curl
          devenv
          fastfetch
          fd
          fzf
          gitui
          helix
          jq
          nerd-fonts.victor-mono
          nil
          nixd
          nix-index
          nixfmt-rfc-style
          ripgrep
          sd
          shfmt
          shellcheck
          tldr
          tokei
          undollar
          wget
          yazi
          # zed-editor-fhs
        ];
        commands = [
          {
            category = "Flake Management";
            name = "Flick";
            #TODO: Update sync-fkake to rebuid
            command = ''gitui; sudo nixos-rebuild switch --flake "$PRJ_ROOT" "$@"'';
            help = "Rebuild NixOS with the changes made to the flake";
          }
          {
            category = "Flake Management";
            help = "Remove old nixos and home-manager generations";
            command = ''nix-collect-garbage --delete-old'';
            name = "Flush";
          }
          {
            category = "Flake Management";
            help = "Sync git repository";
            command = ''sync-repo.sh'';
            name = "Flux";
          }
          {
            category = "Flake Management";
            help = "Update flake inputs and sync git repository";
            command = ''sync-flake.sh'';
            name = "Fly";
          }
          {
            category = "Flake Management";
            help = "Lint and format the entire project tree";
            command = ''nix fmt "$@"'';
            name = "Format";
          }
          {
            category = "File/Environment Management";
            help = "List files in the current directory";
            command = ''list-files.sh'';
            name = "fl";
          }
          {
            category = "File/Environment Management";
            help = "Navigate the file tree";
            # command = ''list-files.sh --tree --git-ignore "$@"'';
            command = ''yazi'';
            name = "ft";
          }
          {
            category = "File/Environment Management";
            help = "Display system information";
            command = ''fastfetch.sh "$@"'';
            name = "ff";
          }
          {
            category = "Flake Management";
            help = "Manage development environments";
            command = ''devenv'';
            name = "Flex";
          }
          {
            category = "Flake Management";
            help = ''Edit the flake'';
            command = ''
              if [ "$#" -gt 0 ]; then
                "$EDITOR" "$@"
              else
                "$EDITOR" "$PRJ_ROOT"
              fi
            '';
            name = "Flare";
          }
        ];
      };
    in
    {
      devshells = {
        default = dots;
        inherit dots;
      };
    };
}
