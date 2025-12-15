{ policies, ... }:
{
  programs.fastfetch.enable = policies.dev;
  imports = [ ./settings.nix ];
}
