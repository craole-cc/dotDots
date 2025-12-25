{
  templates = let
    root = ./Templates;
    rust = {
      path = root + "/rust/standard";
      description = "Rust development environment with nightly toolchain";
    };
    rustspace = {
      path = root + "/rust/workspace";
      description = "Rust workspace with multiple crates";
    };
  in {
    default = rust;
    inherit rust rustspace;
  };
}
