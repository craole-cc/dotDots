let
  mkSrc = name: ./. + name;
in {
  cargo = {
    source = mkSrc "cargo.toml";
    target = ".cargo/config.toml";
  };
  rust-analyzer = {
    source = mkSrc "rust-analyzer.toml";
    target = [".rust-analyzer.toml" "rust-analyzer.toml"];
  };
  rust-toolchain = {
    source = mkSrc "rust-toolchain.toml";
    target = "rust-toolchain.toml";
  };
  rustfmt = {
    source = mkSrc "rustfmt.toml";
    target = [".rustfmt.toml" "rustfmt.toml"];
  };
}
