{
  __moduleRef,
  _,
  ...
}: let
  inherit (_.attrsets.transformation) listToAttrs;
  inherit (_.debug.assertions) mkTest;
  inherit (_.debug.module) mkModuleDebug mkFn;
  inherit (_.debug.runners) runTests;
  inherit (_.debug.tracing) id;
  inherit (_.strings.access) getEnv;
  inherit (_.strings.construction) asString;
  inherit (_.strings.transformation) toUpper;
  inherit (_.types.predicates) isList;

  __debug = mkModuleDebug __moduleRef;

  /**
    Create a single name-value environment pair, checking getEnv for live overrides.

    # Type
    ```nix
    mkEnvVar :: { name :: string, default :: a, uppercase :: bool, fn :: (string -> string) } -> { name :: string, value :: a }

  ```
  */
  mkEnvVar = {
    name,
    value ? null,
    default ? "",
    uppercase ? true,
    fn ? null,
  }: let
    transformKey =
      if fn != null
      then fn
      else if uppercase
      then toUpper
      else id;

    key = transformKey (asString name);
    existing = getEnv key;
    explicit = value;
    fallback = default;
  in {
    name = key;
    value = asString (
      if explicit != null
      then explicit
      else if existing != "" && existing != null
      then existing
      else fallback
    );
  };

  /**
  Transform a list of option sets into a list or attribute set of environment variables.

  # Type

  ```nix
  mkEnvVars :: { vars :: [ AttrSet ], type :: "list" | "set" } -> [ { name :: string, value :: a } ] | AttrSet

  ```
  */
  mkEnvVars = {
    vars,
    type ? "list",
    uppercase ? true,
    fn ? null,
  }:
    if !isList vars
    then
      throw (
        __debug.withLoc {
          function = mkFn {
            name = "mkEnvVars";
            fn = mkEnvVars;
          };
          message = "vars must be a list";
          input = vars;
        }
      )
    else let
      # Merge global defaults (uppercase, fn) with per-item options
      pairs = map (env: mkEnvVar ({inherit uppercase fn;} // env)) vars;
    in
      if type == "set"
      then listToAttrs pairs
      else pairs;
in {
  inherit mkEnvVar mkEnvVars;

  __rootAliases = {
    inherit mkEnvVar mkEnvVars;
  };

  __tests = runTests {
    mkEnvVar = {
      defaultFallback = mkTest {
        desired = {
          name = "NON_EXISTENT_VAR";
          value = "/fallback/path";
        };
        command = ''mkEnvVar { name = "NON_EXISTENT_VAR"; default = "/fallback/path"; }'';
        outcome = mkEnvVar {
          name = "NON_EXISTENT_VAR";
          default = "/fallback/path";
        };
      };
    };

    mkEnvVars = {
      asSet = mkTest {
        desired = {
          HOME = "/fallback/home";
          DOTS_TOP = "_";
        };
        command = ''
          mkEnvVars {
            type = "set";
            vars = [
              { name = "home"; default = "/fallback/home"; uppercase = true; }
              { name = "dots_top"; default = "_"; uppercase = true; }
            ];
          }
        '';
        outcome = mkEnvVars {
          type = "set";
          vars = [
            {
              name = "home";
              default = "/fallback/home";
              uppercase = true;
            }
            {
              name = "dots_top";
              default = "_";
              uppercase = true;
            }
          ];
        };
      };
    };
  };
}
