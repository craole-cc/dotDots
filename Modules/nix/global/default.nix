{
  inputs,
  lib,
  lix,
  paths,
  pkgs,
  system,
  ...
}: let
  inherit (lib.lists) optionals;
  inherit (pkgs.stdenv) isLinux isDarwin;
  path = ./.;

  #> Toolchain policy from .config/toolchain.toml
  toolchain = builtins.fromTOML (builtins.readFile ../../../.config/toolchain.toml);

  #> Metadata & Dependency Injection
  dots = rec {
    #~@ Metadata
    name = "dotDots";
    version = "2.0.0";
    cache = ".cache";
    prefix = ".";
    toolchainSchema = toolchain.schema or 1;
    toolchainPolicy = toolchain;

    #~@ Imports
    inherit
      inputs
      lib
      lix
      optionals
      system
      ;
    inherit (paths) src;

    #~@ Packages
    inherit
      pkgs
      formatters
      isLinux
      isDarwin
      ;
    inherit (import ./minimal.nix {inherit dots;}) packages;
    inputPkgs = input: lix.sources.packages.fromInputs {inherit input inputs system;};
    pythonPkgs = pkgs.python312;

    #~@ Options
    allowAI = true;
  };

  #~@ Global formatting tools
  inherit (import ./fmt.nix {inherit dots;}) formatters formatter checks;

  #~@ Shell Logic Consolidation
  devShells = let
    inherit
      (lib.attrsets)
      filterAttrs
      mapAttrs
      mapAttrs'
      nameValuePair
      ;
    inherit (lib.filesystem) readDir;
    inherit (lib.lists) elem;
    inherit (lib.strings) hasSuffix hasPrefix removeSuffix;
    inherit (pkgs) mkShell;

    #> Filter out internal logic, archives, and formatting files
    filesFor = dir: let
      all = readDir dir;
    in
      filterAttrs (
        name: type:
          (type == "regular")
          && hasSuffix ".nix" name
          && !(elem name [
            "default.nix"
            "fmt.nix"
          ])
          && !(hasPrefix "archive" name)
          && !(hasPrefix "review" name)
      )
      all;

    #> Import the attrs from the validated files
    file-configs = mapAttrs' (
      file: _:
        nameValuePair
        (removeSuffix ".nix" file)
        (import (path + "/${file}") {inherit dots;})
    ) (filesFor path);

    configs =
      file-configs
      // {
        hermes = import ./ai/hermes {inherit dots;};
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
    toolchainMatches = with pkgs; [
      (bat.version == toolchain.tools.bat)
      (cargo.version == toolchain.tools.cargo)
      (direnv.version == toolchain.tools.direnv)
      (eza.version == toolchain.tools.eza)
      (fd.version == toolchain.tools.fd)
      (gcc.version == toolchain.tools.gcc)
      (jq.version == toolchain.tools.jq)
      (lsd.version == toolchain.tools.lsd)
      (mise.version == toolchain.tools.mise)
      (nushell.version == toolchain.tools.nushell)
      (pandoc.version == toolchain.tools.pandoc)
      (ripgrep.version == toolchain.tools.ripgrep)
      (rustc.version == toolchain.tools.rustc)
      (sd.version == toolchain.tools.sd)
      (starship.version == toolchain.tools.starship)
      (tldr.version == toolchain.tools.tldr)
      (typst.version == toolchain.tools.typst)
      (yazi.version == toolchain.tools.yazi)
      (zoxide.version == toolchain.tools.zoxide)
    ];
  in
    assert builtins.all (match: match) toolchainMatches;
    shells // {default = shells.minimal;};
in {inherit checks devShells formatter;}
