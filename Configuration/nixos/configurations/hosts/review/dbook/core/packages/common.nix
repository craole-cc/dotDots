{
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (lib.lists) elem;
  inherit (lib.options) mkOption;
  inherit (lib.types)
    listOf
    either
    package
    path
    ;

  inherit (config) DOTS;
  inherit (DOTS.interface) manager;

  base = "environment";
  mod = "systemPackages";
  cfg = DOTS.${base}.${mod};
in
{
  options.DOTS.${base}.${mod} = mkOption {
    description = "The {{base}} {{mod}}at the system level";
    default =
      let
        tui = with pkgs; [
          #| System Information
          btop
          hyperfine
          macchina
          neofetch
          cpufetch
          procs

          #| Help
          tealdeer
          cod

          #| Development
          helix
          nixd
          nixfmt-rfc-style
          alejandra
          nil
          tokei
          kondo
          shellcheck
          shfmt
          treefmt2

          # | Network
          bandwhich
          speedtest-go

          #| Utility
          bat
          ripgrep
          fd
          brightnessctl
          jq
          eza
          lsd
          libsixel
          lsix
          bc
          grex
          fend

          #| Web
          wget
          curl
        ];
        gui = with pkgs; [
          #| Development
          vscode-fhs
          warp-terminal

          #| Utility
          pavucontrol
          easyeffects
          qjackctl

          #| Web
          brave
          freetube
        ];
      in
      tui ++ (if (manager == "none" || manager == null) then [ ] else gui);
    # ++ (
    #   if
    #     (elem manager [
    #       "none"
    #       null
    #     ])
    #   then
    #     [ ]
    #   else
    #     gui
    # );
    type = listOf (either package path);
  };

  config.${base}.${mod} = cfg;
}
