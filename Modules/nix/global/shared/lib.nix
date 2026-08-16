args: let
  inherit (args) cfg pkgs lix inputs;
  inherit (args.lix.sources.packages) pkgOf pkgsFrom;
in
  args
  // {
    inherit (pkgs.stdenv.hostPlatform) system isLinux isDarwin;
    inherit (lix.lists.construction) optionals;
    inherit (pkgs) writeShellScriptBin writeShellApplication;

    src = {
      inherit args;
      name = cfg.names.src;
      path = cfg.paths.src.store;
    };

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
