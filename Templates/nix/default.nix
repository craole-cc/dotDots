{
  templates = let
    devShell = {
      path = ./common;
      description = "Common development utilities";
    };
    dev = {
      path = ./dev;
      description = "Common development utilities";
    };
    media = {
      path = ./media;
      description = "Comprehensive Media Environment";
    };
    rust = {
      path = ./rust/standard;
      description = "Rust development environment with nightly toolchain";
    };
    rustspace = {
      path = ./rust/workspace;
      description = "Rust workspace with multiple crates";
    };
  in {
    default = rust;
    inherit devShell dev media rust rustspace;
  };
}
