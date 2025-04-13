let
  inherit (builtins) mapAttrs isAttrs;

  flake = {
    store = ../.;
    local = "/home/craole/.dots";
  };

  parts = rec {
    flake = "";
    administration = {
      base = "/Admin";
      host = administration.base + "/host.nix";
      modules = administration.base + "/modules.nix";
      packages = administration.base + "/packages.nix";
      paths = administration.base + "/paths.nix";
    };
    binaries = {
      base = "/Bin";
      cmd = binaries.base + "/cmd";
      nix = binaries.base + "/nix";
      rs = binaries.base + "/rust";
      sh = binaries.base + "/shellscript";
      gyt = binaries.sh + "/projects/git/gyt";
      eda = binaries.sh + "/packages/alias/edita";
      dev = binaries.sh + "/projects/nix/devnix";
    };
    configuration = {
      base = "/Configuration";
      hosts = configuration.base + "/hosts";
      users = configuration.base + "/users";
    };
    documentation = {
      base = "/Documentation";
    };
    environment = {
      base = "/Environment";
    };
    libraries = {
      base = "/Libraries";
      core = libraries.base + "/core";
    };
    modules = {
      base = "/Modules";
      env = modules.base + "/environment.nix";
      nix = modules.base + "/nix.nix";
    };
    packages = {
      base = "/Packages";
      core = packages.base + "/core";
      custom = packages.base + "/custom";
      overlays = packages.base + "/overlays";
      home = packages.base + "/home";
    };
  };

  mkPathSet =
    root: set: mapAttrs (name: value: if isAttrs value then mkPathSet root value else root + value) set;

  initialPaths = {
    store = mkPathSet flake.store parts;
    local = mkPathSet flake.local parts;
    passwords = "/var/lib/dots/passwords";
  };

  updateLocalPaths =
    local:
    initialPaths
    // {
      local = mkPathSet (if local == null then flake.local else local) parts;
    };
in
{
  inherit updateLocalPaths;
}
// initialPaths
