{
  templates = let
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
    inherit rust rustspace;
  };
}
