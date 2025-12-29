{
  pkgs,
  lib,
  lix,
  user,
  config,
  ...
}: let
  inherit (lib.lists) optionals;
  inherit (lix.attrsets.predicates) waylandEnabled;
in
  with pkgs.obs-studio-plugins; {
    plugins =
      [
        droidcam-obs
        looking-glass-obs
        obs-advanced-masks
        obs-aitum-multistream
        obs-backgroundremoval
        # obs-color-monitor #? Broken
        obs-composite-blur
        obs-dir-watch-media
        obs-browser-transition
        obs-freeze-filter
        obs-livesplit-one
        obs-media-controls
        obs-move-transition
        obs-multi-rtmp
        obs-mute-filter
        obs-replay-source
        obs-retro-effects
        obs-rgb-levels
        obs-scale-to-sound
        obs-source-record
        obs-source-switcher
        obs-transition-table
        obs-tuna
        # obs-vertical-canvas  #? Broken
        obs-vintage-filter
        waveform
      ]
      ++ optionals (
        waylandEnabled {
          inherit config;
          interface = user.interface or {};
        }
      ) [wlrobs];
  }
