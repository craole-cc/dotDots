{host ? {}, ...}: let
  inherit (host.paths) dots;
in {
  DOTS = dots;
  DOTS_BIN = dots + "/Bin";
  BINIT = dots + "/Bin/shellscript/base/binit";
  ENV_BIN = dots + "/.direnv/bin";
  HOST = host.name;
}
