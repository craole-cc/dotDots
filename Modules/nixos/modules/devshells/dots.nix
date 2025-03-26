{
  perSystem =
    {
      pkgsUnstable,
      flakePaths,
      ...
    }:
    let
      pkgs = pkgsUnstable;
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
        packages = with pkgs; [
          curl
          devenv
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
        ];
        commands = [
          {
            name = "rebuild";
            category = "Project Management";
            command = ''sudo nixos-rebuild --flake $PRJ_ROOT switch $@'';
            help = "Rebuild NixOS with the changes made to the flake";
          }
          {
            name = "clean";
            category = "Project Management";
            command = ''nix-collect-garbage --delete-old'';
            help = "Remove old nixos and home-manager generations";
          }
          {
            name = "repo";
            category = "Project Management";
            command = ''sync-repo.sh'';
            help = "Sync git repository";
          }
          {
            name = "flake";
            category = "Project Management";
            command = ''sync-flake.sh'';
            help = "Update flake inputs and sync git repository";
          }
          {
            category = "File/Environment Management";
            package = "bat";
          }
          {
            category = "File/Environment Management";
            package = "btop";
          }
          {
            category = "Interactive Shell & Scripting";
            package = "devenv";
          }
          {
            category = "Interactive Shell & Scripting";
            package = "direnv";
          }
          {
            category = "File/Environment Management";
            package = "eza";
            command = ''
              eza \
                --icons=always\
                --group-directories-first\
                --color=always \
                --color-scale \
                --all \
                --long \
                $@
            '';
          }
          {
            category = "File/Environment Management";
            package = "fd";
          }
          {
            category = "Interactive Shell & Scripting";
            package = "fish";
          }
          {
            category = "File/Environment Management";
            package = "fastfetch";
            help = "Display system information";
          }
          {
            category = "File/Environment Management";
            package = "fzf";
          }
          {
            category = "Project Management";
            package = "gitui";
          }
          {
            category = "Interactive Shell & Scripting";
            package = "just";
          }
          {
            category = "Interactive Shell & Scripting";
            name = "nu";
            package = "nushell";
          }
          {
            category = "Interactive Shell & Scripting";
            name = "pwsh";
            package = "powershell";
          }
          {
            category = "File/Environment Management";
            package = "rbw";
          }
          {
            category = "File/Environment Management";
            name = "rg";
            package = "ripgrep";
          }
          {
            category = "Project Management";
            package = "treefmt";
          }
          {
            category = "File/Environment Management";
            package = "yazi";
          }
          # {
          #   category = "Interactive Shell & Scripting";
          #   name = "zeditor";
          #   package = "zed-editor-fhs";
          #   command = ''
          #     if [ "$#" -gt 0 ]; then
          #       zeditor "$@"
          #     else
          #       zeditor "$PRJ_ROOT"
          #     fi
          #   '';
          #   help = ''High-performance Integrated Development Environment (IDE)'';
          # }
          {
            category = "File/Environment Management";
            package = "zoxide";
          }
          {
            category = "Interactive Shell & Scripting";
            package = "zsh";
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
