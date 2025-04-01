{ pkgs, config, ... }:
let
  inherit (config.dots.paths) DOTS QBXL;
in
{
  environment = {
    variables = {
      EDITOR = "hx";
      VISUAL = "code-insiders"; # TODO: Make this dynamic
      DOTS = DOTS.flake;
      QBXL = QBXL.flake;
    };
    systemPackages = with pkgs; [
      (writeScriptBin ".dots" ''
        exec "${DOTS.flake}/Bin/shellscript/project/.dots" "$@"
      '')
      (writeShellScriptBin "QBXL" (
        with QBXL;
        ''
          set -e
          printf "NixOS WSL Flake for QBXL [%s]\n/> Updating />\n" "${flake}"
            nix flake update --flake "${flake}"
          printf "/> Committing />\n"
            gitui || true
          printf "/> Rebuilding />\n"
            sudo nixos-rebuild switch --flake "${flake}" --show-trace --upgrade
        ''
      ))
      gitui
    ];
  };

  programs = {
    direnv = {
      enable = true;
      silent = true;
    };
    git = {
      enable = true;
      lfs.enable = true;
      prompt.enable = true;
      config = {
        init = {
          defaultBranch = "main";
        };
        url = {
          "https://github.com/" = {
            insteadOf = [
              "gh:"
              "github:"
            ];
          };
        };
      };
    };
    nix-ld.enable = true;
    starship.enable = true;
    vivid.enable = true;
    yazi.enable = true;
  };

  services = {
    atuin.enable = true;
  };
}
