args: let
  inherit (args) flake pkgs lix inputs paths;
  inherit (args.lix.sources.packages) pkgOf pkgsFrom;
  inherit (lix.modules.core.software) mkFetch;
  inherit (pkgs.stdenv.hostPlatform) system isLinux isDarwin;
  inherit (lix.lists.construction) optionals;
  inherit (pkgs) writeShellScriptBin writeShellApplication;
in
  args
  // {
    inherit system isLinux isDarwin optionals writeShellScriptBin writeShellApplication;

    fetch = mkFetch {
      inherit pkgs paths;
      inherit (flake) name;
    };

    cmdExists = writeShellScriptBin "cmd-exists" ''
      command -v "$@" >/dev/null 2>&1
    '';

    mkName = name: "${flake.name}-${name}";

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
