args: let
  inherit (args) cfg pkgs lix inputs paths;
  inherit (args.lix.sources.packages) pkgOf pkgsFrom;
  inherit (lix.modules.core.software) mkFetch;
  inherit (pkgs.stdenv.hostPlatform) system isLinux isDarwin;
  inherit (lix.lists.construction) optionals;
  inherit (pkgs) writeShellScriptBin writeShellApplication;

  src = {
    inherit args;
    name = cfg.names.src;
    path = cfg.paths.src.store;
  };
in
  args
  // {
    inherit system isLinux isDarwin optionals writeShellScriptBin writeShellApplication;

    fetch = mkFetch {
      inherit pkgs paths;
      inherit (src) name;
    };

    cmdExists = writeShellScriptBin "cmd-exists" ''
      command -v "$@" >/dev/null 2>&1
    '';

    mkName = name: "${cfg.names.src}-${name}";

    pkgFor = {
      input,
      target ? null,
      required ? true,
    }:
      pkgOf {inherit input inputs pkgs required target;};

    pkgsFor = {
      sources,
      required ? true,
      exclude ? [],
    }:
      pkgsFrom {inherit inputs pkgs required sources exclude;};
  }
