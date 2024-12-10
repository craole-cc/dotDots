{ specialArgs, ... }:
let
  inherit (specialArgs) paths host;
in
{
  environment = {
    variables = with paths; {
      DOTS = flake.local;
      DOTS_RC = flake.local + "/.dotsrc";
      DOTS_BIN = scripts.local;
      DOTS_NIX = modules.local;
      NIXOS_FLAKE = flake.local;
      NIXOS_CONFIG = modules.local + parts.hosts + "/${host.name}";
    };
    extraInit = ''[ -f "$DOTS_RC" ] && . "$DOTS_RC"'';
  };
}
