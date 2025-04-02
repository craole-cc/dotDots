{
  pkgs,
  paths,
  ...
}:
pkgs.inputs.developmentShell.mkShell {
  name = "dotDots";
  env = [
    {
      name = "PRJ_BIN";
      prefix =
        let
          inherit (paths.parts) bin;
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
    # {
    #   name = "TREEFMT_CONFIG";
    #   eval = treefmt.configFile;
    # }
  ];
  packages =
    with pkgs;
    [
      bat
      btop
      coreutils
      gnused
      curl
      devenv
      diffutils
      eza
      dust
      fastfetch
      fd
      fd
      findutils
      fzf
      gawk
      getent
      gitui
      gnused
      helix
      jq
      nerd-fonts.victor-mono
      nil
      nix-index
      nixd
      nixfmt-rfc-style
      onefetch
      ripgrep
      rsync
      sd
      shellcheck
      shfmt
      tldr
      tokei
      trashy
      treefmt
      undollar
      wget
      yazi
      # zed-editor-fhs
      zig

      # TODO: add formatters
    ]
    ++ [
      # |Formatters
      # alejandra
      # biome
      deadnix
      deno
      markdownlint-cli2
      mdsh
      nodePackages.prettier
      ruff
      shellcheck
      shfmt
      taplo
      taplo
      treefmt
      yamlfmt
    ];
  commands = [
    {
      category = "Flake Management";
      name = "Flick";
      #TODO: Update sync-fkake to rebuild
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
      name = "Fmt";
    }
    {
      category = "Flake Management";
      help = "Load the flake in the REPL";
      command = ''repl-flake.sh'';
      name = "Flake";
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
      help = "Display flake information";
      command = ''tokei && onefetch --no-title --no-color-palette --disabled-fields url'';
      name = "fo";
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
      help = ''Edit the flake the default editor'';
      command = ''
        if [ "$#" -gt 0 ]; then
          "$EDITOR" "$@"
        else
          "$EDITOR" "$PRJ_ROOT"
        fi
      '';
      name = "Flow";
    }
    {
      category = "Flake Management";
      help = ''Edit the flake in the default GUI editor'';
      command = ''
        if [ "$#" -gt 0 ]; then
          "$VISUAL" "$@"
        else
          "$VISUAL" "$PRJ_ROOT"
        fi
      '';
      name = "Flare";
    }
  ];
}
