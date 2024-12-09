{ specialArgs, ... }:
{
  environment = {
    variables = import ./variables.nix { inherit (specialArgs) paths host; };
    shellAliases = import ./aliases.nix { inherit (specialArgs) paths; };
    extraInit = ''[ -f "$DOTS_RC" ] && . "$DOTS_RC"'';
  };
}
