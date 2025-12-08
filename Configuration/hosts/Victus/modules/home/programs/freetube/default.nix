{ policies, ... }:
{
  programs.freetube.enable = policies.webMedia;
  imports = [ ./settings.nix ];
}
