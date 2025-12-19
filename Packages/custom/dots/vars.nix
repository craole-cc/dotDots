{host ? {}, ...}: let
  inherit (host.paths) dots;
in {
  NIX_CONFIG = "experimental-features = nix-command flakes";
  DOTS = dots;
  DOTS_BIN = dots + "/Bin";
  BINIT = dots + "/Bin/shellscript/base/binit";
  ENV_BIN = dots + "/.direnv/bin";
  HOST_NAME = host.name;
  HOST_TYPE = host.platform;
}
