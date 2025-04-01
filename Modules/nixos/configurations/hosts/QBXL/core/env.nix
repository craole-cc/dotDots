{ pkgs, config, ... }:
let
  inherit (config.dots.paths) DOTS QBXL;
in
{
  environment = {
    variables = {
      EDITOR = "hx";
      VISUAL = "code";
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
          #@ Exit immediately if any command fails
          set -e

          printf "NixOS WSL Flake for QBXL [%s]\n" "${flake}"

          printf "/> Updating />\n"
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
    # bat.enable = true;
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
