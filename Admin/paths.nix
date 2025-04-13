let
  inherit (builtins) mapAttrs isAttrs;

  base = {
    store = ../.;
    local = "/home/craole/.dots";
  };

  parts = rec {
    administration = {
      base = "/Admin";
      host = administration.base + "/host.nix";
      modules = administration.base + "/modules.nix";
      packages = administration.base + "/packages.nix";
      paths = administration.base + "/paths.nix";
    };
    binaries = {
      base = "/Binaries";
      cmd = binaries.base + "/cmd";
      nix = binaries.base + "/nix";
      rs = binaries.base + "/rs";
      sh = binaries.base + "/sh";
      gyt = binaries.base.sh + "/projects/git/gyt";
      eda = binaries.base.sh + "/packages/alias/edita";
      dev = binaries.base.sh + "/projects/nix/devnix";
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
    store = mkPathSet base.store parts;
    local = mkPathSet base.local parts;
    passwords = "/var/lib/dots/passwords";
  };

  updateLocalPaths =
    local:
    initialPaths
    // {
      local = mkPathSet (if local == null then base.local else local) parts;
    };
in
{
  inherit updateLocalPaths;
}
// initialPaths
