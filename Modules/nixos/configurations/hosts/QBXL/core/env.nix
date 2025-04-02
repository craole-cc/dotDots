{ pkgs, dots, ... }:
{
  environment = {
    inherit (dots) variables;

    systemPackages = with pkgs; [
      # (writeScriptBin ".dots" ''
      #   exec "${DOTS.flake}/Bin/shellscript/project/.dots" "$@"
      # '')
      # (writeShellScriptBin "QBXL" (
      #   with QBXL;
      #   ''
      #     set -e
      #     printf "NixOS WSL Flake for QBXL [%s]\n/> Updating />\n" "${flake}"
      #       nix flake update --flake "${flake}"
      #     printf "/> Committing />\n"
      #       gitui || true
      #     printf "/> Rebuilding />\n"
      #       sudo nixos-rebuild switch --flake "${flake}" --show-trace --upgrade
      #   ''
      # ))
      gitui
      nixd
      nixfmt-rfc-style
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
