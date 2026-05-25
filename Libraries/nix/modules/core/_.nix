{_, ...}: let
  meta = {
    doc = ''
      Build the host-specific core module list used during system evaluation.

      Produces the base module stack for a host by combining low-level hardware,
      networking, environment, services, programs, users, and home-manager glue.
      The result is returned as a module list suitable for `evalModules`.

      # Args:
      host: The enriched host definition.
      nixpkgs: The resolved nixpkgs source/configuration attrset.
      inputs: Canonically resolved flake inputs.
      modules: Resolved input-provided module sets.
      specialArgs: Extra arguments forwarded into module evaluation.

      # Returns:
      A list of modules for the target host, including any host-local imports.
    '';

    exports = {
      internal = let
        functions = {inherit mkModules;};
        aliases = {mkCore = mkModules;};
      in
        {inherit functions aliases;}
        // functions // aliases;
      external = {mkCoreModules = mkModules;};
    };
  };

  inherit (_.modules.construction) mkHome;

  /**
  Build the host-specific core module list used during system evaluation.

  Produces the base module stack for a host by combining low-level hardware,
  networking, environment, services, programs, users, and home-manager glue.
  The result is returned as a module list suitable for `evalModules`.

  # Args:
    host: The enriched host definition.
    nixpkgs: The resolved nixpkgs source/configuration attrset.
    inputs: Canonically resolved flake inputs.
    modules: Resolved input-provided module sets.
    specialArgs: Extra arguments forwarded into module evaluation.

  # Returns:
    A list of modules for the target host, including any host-local imports.
  */
  mkModules = {
    host,
    nixpkgs,
    inputs,
    modules,
    specialArgs,
    tree,
  }: [
    {inherit nixpkgs;}
    (mkHome {
      inherit host specialArgs tree inputs;
      modules = modules.home;
    })
  ];
in
  with meta.exports;
    internal
    // {
      __doc = meta.doc;
      __rootAliases = external;
    }
