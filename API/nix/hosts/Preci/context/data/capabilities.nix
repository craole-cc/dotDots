{
  lix,
  inputs,
  ...
}: let
  inherit (lix.attrsets) attrByPath;
  inherit (lix.lists) optional optionals;
  inherit (lix.trivial) isNotEmpty;

  resolveRust = user: let
    rust =
      attrByPath
      ["capabilities" "development" "languages" "rust"]
      null
      user;
    isDefined = isNotEmpty rust;

    channel =
      if isDefined
      then rust.channel or "stable"
      else null;

    extensions =
      optionals isDefined
      rust.components or (rust.extensions or []);
  in
    optional isDefined ((
      # TODO: Why are we using inputs here, should it rust-bin not already be in pkgs as an overlay?
      with inputs.nixpkgs.rust-bin;
        if channel == "nightly"
        then selectLatestNightlyWith (tc: tc.default)
        else stable.latest.default
    ).override {inherit extensions;});

  resolve = {user}: {
    home = {
      packages = resolveRust user;
    };
  };
in {inherit resolve;}
