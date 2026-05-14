{ _, ... }:
let
  meta =
    let
      doc = ''
        Application runtime operations (Layer 5).

        Provides execution-oriented helpers that consume normalized registry
        data and produce runtime-facing artifacts such as wrapped exec strings
        and package-enriched app records.

        Depends on: applications.registry applications.primitives.
      '';
      functions = { inherit resolveExec mkApps; };
      exports = {
        local = functions;
        alias = functions;
      };
    in
    {
      inherit doc exports functions;
    };

  inherit (_.applications.registry) all;
  inherit (_.applications.primitives) toValue;
  inherit (_.attrsets.transformation) mapAttrs;

  /**
    Resolve executable command string for a given TTY wrapper.

    Wraps `needsTerminal = true` apps with the provided terminal launcher.

    # Type
    ```nix
    resolveExec :: TtyRecord -> AppRecord -> string
    ```
  */
  resolveExec =
    tty: app:
    if
      toValue {
        field = "needsTerminal";
        default = false;
      } app
    then
      "${tty.names.command}"
      + " ${tty.wrap.titleFlag} ${app.names.title or app.names.command}"
      + " ${tty.wrap.execFlag} ${app.exec}"
    else
      app.exec;

  /**
    Enrich the registry with package lookups and versions.

    Maps over the normalized registry, injecting `pkg` and `version`
    from `pkgs.${app.names.package}` where available.

    # Type
    ```nix
    mkApps :: Pkgs -> AttrSet
    ```
  */
  mkApps =
    pkgs:
    mapAttrs (
      _: app:
      let
        pkg = pkgs.${app.names.package} or null;
      in
      app // { inherit pkg; } // (if pkg != null then { inherit (pkg) version; } else { })
    ) all;
in
meta.exports.local
// {
  __docs = meta.doc;
  __rootAliases = meta.exports.alias;
}
