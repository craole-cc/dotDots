{
  inputs,
  lix,
  paths,
  pkgs,
  system,
  ...
}: let
  inherit (lix.attrsets.construction) nameValuePair;
  inherit (lix.attrsets.transformation) filterAttrs mapAttrs mapAttrs';
  inherit (lix.filesystem.access) readFile readDir;
  inherit (lix.lists.construction) optionals;
  inherit (lix.lists.predicates) all elem;
  inherit (lix.sources.packages) fromInputs;
  inherit (lix.strings.predicates) hasSuffix hasPrefix;
  inherit (lix.strings.transformation) removeSuffix;
  inherit (pkgs) mkShell stdenv;
  inherit (stdenv) isLinux isDarwin;
  path = ./.;

  #> Metadata & Dependency Injection
  dots = rec {
    #~@ Metadata
    name = "dotDots";
    version = "2.0.0";
    cache = ".cache";
    prefix = ".";

    #~@ Imports
    inherit inputs lix optionals system;
    inherit (paths) src;

    #~@ Packages
    inherit formatters isDarwin isLinux pkgs;
    inherit (import ./minimal.nix {inherit dots;}) packages;
    inputPkgs = input: fromInputs {inherit input inputs system;};
    pythonPkgs = pkgs.python312;

    #~@ Options
    allowAI = true;
  };

  #~@ Global formatting tools
  fmt = import ./fmt.nix {inherit dots;};
  inherit (fmt) formatters formatter checks;

  #~@ Shell Logic Consolidation
  devShells = let
    #> Filter out internal logic, archives, and formatting files
    filesFor = dir:
      filterAttrs (
        name: type:
          (type == "regular")
          && hasSuffix ".nix" name
          && !(elem name ["default.nix" "fmt.nix"])
          && !(hasPrefix "archive" name)
          && !(hasPrefix "review" name)
      )
      (readDir dir);

    #> Import the attrs from the validated files
    configs =
      (mapAttrs' (
        file: _:
          nameValuePair
          (removeSuffix ".nix" file)
          (import (path + "/${file}") {inherit dots;})
      ) (filesFor path))
      // {
        ai = import ./ai {inherit dots;};
      };

    #> Build the final derivations
    shells =
      mapAttrs (
        name: cfg:
          mkShell {
            name = "${dots.name}-${name}";
            env = cfg.env or {};
            shellHook = cfg.shellHook or "";
            packages = dots.packages ++ (cfg.packages or []);
          }
      )
      configs;

    versions = let
      toolchain = fromTOML (readFile (paths.src + "/toolchain.toml"));
    in [
      (pkgs.bat.version == toolchain.general.bat)
      (pkgs.cargo.version == toolchain.nix.cargo)
      (pkgs.direnv.version == toolchain.general.direnv)
      (pkgs.eza.version == toolchain.general.eza)
      (pkgs.fd.version == toolchain.general.fd)
      (pkgs.gcc.version == toolchain.nix.gcc)
      (pkgs.jq.version == toolchain.general.jq)
      (pkgs.lsd.version == toolchain.general.lsd)
      (pkgs.mise.version == toolchain.nix.mise)
      (pkgs.nushell.version == toolchain.nix.nushell)
      (pkgs.pandoc.version == toolchain.general.pandoc)
      (pkgs.ripgrep.version == toolchain.general.ripgrep)
      (pkgs.rustc.version == toolchain.nix.rustc)
      (pkgs.sd.version == toolchain.general.sd)
      (pkgs.starship.version == toolchain.general.starship)
      (pkgs.tldr.version == toolchain.nix.tldr)
      (pkgs.typst.version == toolchain.general.typst)
      (pkgs.yazi.version == toolchain.general.yazi)
      (pkgs.zoxide.version == toolchain.general.zoxide)
    ];
  in
    assert all (version: version) versions;
      shells // {default = shells.minimal;};
in {inherit checks devShells formatter;}
