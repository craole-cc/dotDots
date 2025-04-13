let
  #@ Define the flake paths
  store = ../.;
  local = "/home/craole/.dots";

  #@ Create a function for creating paths
  mkPaths = base: {
    inherit base;
    bin = base + "/Bin";
    conf = base + "/Configuration";
    docs = base + "/Documentation";
    env = base + "/Environment";
    libs = base + "/Libraries";
    mods = base + "/Modules";
    opts = base + "/Options";
    pkgs = base + "/Packages";
  };

  #@ Generate flake paths
  storePaths = mkPaths store;
  localPaths = mkPaths local;

  #@ Define all paths upfront to avoid recursive references
  flakePaths = {
    store = store;
    local = local;
  };

  confPaths = {
    base = localPaths.conf;
    hosts = localPaths.conf + "/hosts";
    users = localPaths.conf + "/users";
  };

  libPaths = {
    base = storePaths.libs;
    admin = storePaths.libs + "/admin";
    core = storePaths.libs + "/core";
    mkHost = storePaths.libs + "/admin/mkHost.nix";
    mkModules = storePaths.libs + "/admin/mkModules.nix";
    mkPackages = storePaths.libs + "/admin/mkPackages.nix";
  };

  pkgPaths = {
    base = storePaths.pkgs;
    core = storePaths.pkgs + "/core";
    custom = storePaths.pkgs + "/custom";
    home = storePaths.pkgs + "/home";
    overlays = storePaths.pkgs + "/overlays";
  };

  binPaths = {
    base = localPaths.bin;
    cmd = localPaths.bin + "/cmd";
    nix = localPaths.bin + "/nix";
    rust = localPaths.bin + "/rust";
    shellscript = localPaths.bin + "/shellscript";
    gyt = localPaths.bin + "/projects/git/gyt";
    eda = localPaths.bin + "/packages/alias/edita";
    dev = localPaths.bin + "/projects/nix/devnix";
  };

  modPaths = {
    base = storePaths.mods;
    nixos = storePaths.mods + "/nixos";
    home = storePaths.mods + "/home";
  };
in
{
  flake = flakePaths;
  conf = confPaths;
  libs = libPaths;
  pkgs = pkgPaths;
  bins = binPaths;
  mods = modPaths;

  # Other paths
  documentation = storePaths.docs;
  environment = storePaths.env;
  modules = modPaths.base;
  options = storePaths.opts;
  binaries = binPaths.base;
  passwords = "/var/lib/dots/passwords";
}
