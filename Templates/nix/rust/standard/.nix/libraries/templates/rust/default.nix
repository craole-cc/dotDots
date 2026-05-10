{lib, ...}: let
  inherit (lib.attrsets) optionalAttrs;

  mkRust = set:
    optionalAttrs (set != null) (
      {
        cargo = {
          source = ./cargo.toml;
          target = ".cargo/config.toml";
        };

        rust-analyzer = {
          source = ./rust-analyzer.toml;
          target = [".rust-analyzer.toml" "rust-analyzer.toml"];
        };

        rustfmt = {
          source = ./rustfmt.toml;
          target = [".rustfmt.toml" "rustfmt.toml"];
        };
      }
      // optionalAttrs (set.includeToolchain or false) {
        toolchain = {
          source = ./rust-toolchain.toml;
          target = ["rust-toolchain.toml" "rust-toolchain"];
        };
      }
    );
in {
  inherit mkRust;
}
