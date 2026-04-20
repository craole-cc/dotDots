/**
libraries/shells/build.nix

Shell finalization helpers for lib.shells.
*/
{lib}: let
  inherit (lib.attrsets) attrNames attrValues isDerivation mapAttrs optionalAttrs;
  inherit (lib.packages) currentSystem mkPkgsPerSystem mkPkgs;
  inherit (lib.lists) filter findFirst optionals;
  inherit (lib.strings) isString concatStringsSep;
  inherit (lib.trivial) isNotEmpty;

  /**
  Turn a shell spec into a `pkgs.mkShell` derivation.

  # Type
  ```nix
  mkShell :: { pkgs :: AttrSet; spec :: AttrSet; } -> derivation
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
    pkgs ? null,
    inputs ? {},
    system ? currentSystem,
    shell ? {},
    name ? "",
    packages ? [],
    env ? {},
    shellHook ? "",
    ...
  }: let
    #? Performance note: We use null-check here because pkgs can be huge.
    #? isNotEmpty (nixpkgs) would force evaluation of all attribute names.
    pkgs' =
      if pkgs != null
      then pkgs
      else mkPkgs {inherit inputs system;};

    #> Recursively update or manual merge preserve data.
    args =
      shell
      // {
        name =
          if isNotEmpty name
          then name
          else (shell.name or "nix-dev");

        packages =
          (shell.packages or [])
          ++ (optionals (isNotEmpty packages) packages);

        env =
          (shell.env or {})
          // (optionalAttrs (isNotEmpty env) env);

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
    pkgs'.mkShell args;

  mkShells = {
    inputs ? {},
    shells ? {},
    default ? null,
  }:
  #> Iterate over all systems, generating native pkgs for each (Linux & Mac compatibility)
    mapAttrs (
      system: pkgs: let
        # This helper ensures every shell gets the correct pkgs and system context
        processShell = shellSpec:
          if isDerivation shellSpec
          then shellSpec
          else
            mkShell {
              inherit pkgs inputs system;
              shell = shellSpec;
            };

        processedShells = mapAttrs (_: processShell) shells;

        resolvedDefault =
          if default == null
          then let
            found = findFirst isDerivation null (attrValues processedShells);
          in
            if found == null
            then throw "mkShells: no shells defined and no default provided."
            else found
          else if isString default
          then
            processedShells.${
              default
            } or (throw ''
              mkShells: default shell '${default}' not found.
              Available: ${concatStringsSep ", " (attrNames processedShells)}'')
          else processShell default;
      in
        processedShells // {default = resolvedDefault;}
    ) (mkPkgsPerSystem {inherit inputs;});
in {inherit mkShell mkShells;}
