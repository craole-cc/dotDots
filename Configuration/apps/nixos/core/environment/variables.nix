{ paths, host,... }:
with paths;
{
  DOTS = flake.local;
  DOTS_RC = flake.local + "/.dotsrc";
  DOTS_BIN = scripts.local;
  DOTS_NIX = modules.local;
  NIXOS_FLAKE = flake.local;
  NIXOS_CONFIG = with paths; modules.local + parts.hosts + "/${host}";
}
