{lix, inputs, ...}: let
  inherit (lix.attrsets) attrByPath;

  resolveRust = user: let
    rust = attrByPath ["capabilities" "development" "languages" "rust"] null user;
    channel = if rust == null then null else rust.channel or "stable";
    extensions = if rust == null then [] else rust.components or [];
    toolchain =
      if channel == "nightly"
      then inputs.nixpkgs.rust-bin.nightly.latest.default
      else inputs.nixpkgs.rust-bin.stable.latest.default;
  in
    if rust == null
    then []
    else [
      (toolchain.override {inherit extensions;})
    ];

  resolve = {user}: {
    home = {
      packages = resolveRust user;
    };
  };
in {
  inherit resolve;
}
