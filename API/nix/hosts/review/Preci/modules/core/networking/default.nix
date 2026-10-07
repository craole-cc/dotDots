#? Networking, nixpkgs construction and the flake registry wiring.
#?
#? `functionalities` is the resolved name list, so membership is tested with
#? `elem` against that list rather than read as an attribute.
{
  context,
  host,
  lix,
  ...
}: let
  inherit (lix.attrsets) recursiveUpdate;
  inherit (lix.lists) elem optional;

  inherit (lix) inputs overlays;

  #? `context.functionalities` is the module's own record -- `{names, set,
  #? resolved}` -- where `names` is the *shape-reading function*, not a list.
  #? `.resolved` is the list of names, so membership is tested against that.
  functionalities = context.functionalities.resolved;
in {
  networking = {
    hostName = host.name;
    hostId = host.id;
    networkmanager.enable = elem "network" functionalities;
  };

  nix = {
    settings = {
      experimental-features = [
        "nix-command"
        "flakes"
      ];
    };

    nixPath = [
      "nixos-config=${host.paths.roots.build}"
      "nixpkgs=${inputs.nixpkgs.path}"
    ];
  };

  #? `lix.inputs` entries are resolved source records, so nixpkgs is read
  #? through its `.path` rather than being treated as the path itself.
  nixpkgs.pkgs = import inputs.nixpkgs.path {
    inherit (host) system;

    config =
      recursiveUpdate {allowUnfree = false;}
      (host.config.nixpkgs or {});

    #? `lix.overlays.rust-overlay` is the overlay itself (a lambda), not a
    #? path to import. It is pulled in when the host asks for rust support.
    overlays =
      optional
      (elem "rust" functionalities)
      overlays.rust-overlay;
  };
}
