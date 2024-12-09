{ specialArgs, ... }:
let
  variables = import ./variables.nix { inherit (specialArgs) paths host; };
  aliases = import ./aliases.nix { inherit (specialArgs) paths; };
in
{
  environment = {
    inherit variables aliases;
    extraInit = ''[ -f "$DOTS_RC" ] && . "$DOTS_RC"'';
  };
}
