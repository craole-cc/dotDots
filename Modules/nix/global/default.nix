{
  inputs,
  lix,
  paths,
  pkgs,
  system,
  ...
}: let
  inherit (lix.filesystem.traversal) importAttrs;
  inherit (lix.lists.construction) optionals;
  inherit (lix.lists.predicates) all;
  inherit (lix.attrsets.transformation) mapAttrs;
  inherit (lix.filesystem.access) readFile;
  inherit (lix.sources.packages) fromInputs;
  inherit (pkgs) mkShell stdenv;
  inherit (stdenv) isLinux isDarwin;

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
    inherit (import ./shells/minimal {inherit dots;}) packages;
    inputPkgs = input: fromInputs {inherit input inputs system;};
    pythonPkgs = pkgs.python312;

    #~@ Options
    allowAI = true;
  };

  #~@ Global formatting tools — structurally different from a devshell,
  #~@ kept outside `shellsPath` so importAttrs never has to filter it out
  fmt = import ./fmt {inherit dots;};
  inherit (fmt) formatters formatter checks;

  #~@ Shell Logic Consolidation
  devShells = let
    #> Import every subdirectory under ./shells (minimal, ai, python, ...),
    #> each keyed by its folder name, using its default.nix
    configs = importAttrs ./shells;

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

      verify = section: name: let
        expected = toolchain.${section}.${name};
        actual = pkgs.${name}.version;
      in
        (actual == expected)
        || throw ''
          Version mismatch for '${name}':
            Expected: ${expected}
            Actual:   ${actual}
        '';

      tools = {
        general = [
          "bat"
          "direnv"
          "eza"
          "fd"
          "jq"
          "lsd"
          "pandoc"
          "ripgrep"
          "sd"
          "starship"
          "typst"
          "yazi"
          "zoxide"
        ];
        nix = [
          "cargo"
          "gcc"
          "mise"
          "nushell"
          "rustc"
          "tldr"
        ];
      };
    in
      (map (verify "general") tools.general)
      ++ (map (verify "nix") tools.nix);
  in
    assert all (valid: valid) versions;
      shells // {default = shells.minimal;};
in {inherit checks devShells formatter;}
