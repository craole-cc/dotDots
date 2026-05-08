/**
libraries/shells/build.nix

Shell finalization helpers for lib.shells.
*/
{lib}: let
  inherit (lib.attrsets) attrNames attrValues isDerivation mapAttrs;
  inherit (lib.packages) mkPkgsPerSystem mkPkgs;
  inherit (lib.lists) filter findFirst;
  inherit (lib.strings) isString concatStringsSep;
  inherit (lib.trivial) isNotEmpty;

  /**
  Turn a shell spec into a `pkgs.mkShell` derivation.

  # Type
  ```nix
  mkShell :: { pkgs :: AttrSet; args :: AttrSet; } -> derivation
  ```

  # Examples
  ```nix
  mkShell {
    pkgs = pkgs.x86_64-linux;
    args = {
      name = "demo";
      packages = [];
      env = {};
      shellHook = "";
    };
  }
  ```
  */
  mkShell = {
    args ? {},
    env ? {},
    inputs ? null,
    name ? "nix-dev",
    packages ? [],
    pkgs ? null,
    shell ? {},
    shellHook ? "",
    system ? null,
    ...
  }: let
    #? Performance note: We use null-check here because pkgs can be huge.
    #? isNotEmpty (nixpkgs) would force evaluation of all attribute names.
    pkgs' =
      if pkgs != null
      then pkgs
      else mkPkgs {inherit inputs system;};

    #> Recursively update or manual merge preserve data.
    args' =
      {inherit name packages;}
      // args
      // shell
      // {
        env = env // (args.env or {}) // (shell.env or {});
        #> Combine hooks rather than overwriting them
        #? Filtering out empty strings and joining with a newline.
        shellHook = concatStringsSep "\n" (
          filter isNotEmpty [
            (shell.shellHook or "")
            shellHook
          ]
        );
      };
  in
    pkgs'.mkShell args';

  mkShells = {
    default ? null,
    inputs ? {},
    shells ? {},
  }:
  #> Iterate over all systems, generating native pkgs for each (Linux & Mac compatibility)
    mapAttrs (
      system: pkgs: let
        #? Ensures each shell gets the correct pkgs and system context
        processShell = spec:
          if isDerivation spec
          then spec
          else
            mkShell {
              inherit pkgs inputs system;
              shell = spec.shell or spec;
            };

        processedShells = mapAttrs (_: processShell) shells;
      in
        processedShells
        // {
          default =
            if default == null
            then let
              found = findFirst isDerivation null (attrValues processedShells);
            in
              if found != null
              then found
              else throw "mkShells: no shells defined and no default provided."
            else if isString default
            then let
              error = throw ''
                mkShells: default shell '${default}' not found.
                Available: ${concatStringsSep ", " (attrNames processedShells)}
              '';
            in
              processedShells.${default} or error
            else processShell default;
        }
    ) (mkPkgsPerSystem {inherit inputs;});
in {inherit mkShell mkShells;}
