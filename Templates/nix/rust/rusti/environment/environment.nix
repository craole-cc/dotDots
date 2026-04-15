{
  lib,
  ai ? {},
  rust ? {},
}: let
  inherit (lib.attrsets) toEnv;

  defaults = {
    # RUST_LOG = "info";
    # RUST_BACKTRACE = "full";
    # CARGO_INCREMENTAL = "1";
    VISUAL = "rust-rover";
    EDITOR = "helix";
  };
in
  #? Precedence: defaults < rust < ai
  toEnv (defaults // rust // ai)
