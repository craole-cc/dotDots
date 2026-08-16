{
  pkgs,
  openclaw,
  ...
}: let
  inherit (pkgs) lib;
in
  pkgs.symlinkJoin {
    name = "openclaw-wrapped-${openclaw.version}";

    paths = [openclaw];

    nativeBuildInputs = [pkgs.makeWrapper];

    postBuild = ''
      wrapProgram "$out/bin/openclaw" \
        --prefix PATH : ${
        lib.makeBinPath [
          pkgs.coreutils
          pkgs.curl
        ]
      } \
        --set OPENCLAW_DATA_DIR "/var/lib/openclaw" \
        --set OPENCLAW_LOG_LEVEL "info"
    '';

    meta =
      openclaw.meta
      // {
        description = "openclaw (wrapped with runtime PATH and defaults)";
      };
  }
