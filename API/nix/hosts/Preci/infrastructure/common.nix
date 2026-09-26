{host, inputs, lix, ...}: let
  inherit (lix.attrsets) listToAttrs;
  inherit (lix.lists) map;

  capabilities = import ./capabilities.nix {inherit lix;};
  packages = import ./packages.nix {inherit lix;};
  packageResolver = packages // {
    pkgs = inputs.nixpkgs;
  };
  functionalities = import ./functionalities.nix {inherit lix;};
  principal = import ./principal.nix {
    inherit capabilities;
    packages = packageResolver;
  };

  resolveRust = user: let
    rust = user.capabilities.development.languages.rust or null;
    channel = if rust == null then null else rust.channel or "stable";
    extensions = if rust == null then [] else rust.components or [];
  in
    if rust == null then []
    else [
      (
        if channel == "nightly"
        then inputs.nixpkgs.rust-bin.nightly.latest.default
        else inputs.nixpkgs.rust-bin.stable.latest.default
      ).override {inherit extensions;}
    ];

  principals = listToAttrs (map
    (declaration: let
      resolved = principal.resolve {
        inherit host;
        user = declaration;
      };
    in {
      name = declaration.name;
      value = resolved // {
        packages = resolved.packages // {
          packages = resolved.packages.packages ++ resolveRust declaration;
        };
      };
    })
    host.principals.all);
in {
  inherit functionalities principals;

  packages = packages.resolveHost {
    inherit host;
    pkgs = packageResolver.pkgs;
  };
}
