# TODO: Add docs
{
  __moduleRef,
  _,
  ...
}: let
  inherit (_.debug.assertions) mkTest;
  inherit (_.debug.module) mkModuleDebug mkFn;
  inherit (_.debug.runners) runTests;
  inherit (_.debug.tracing) id;
  inherit (_.strings.transformation) toUpper;
  debug = mkModuleDebug __moduleRef;

  mkEnvPair = {
    name,
    default ? null,
    uppercase ? false,
    fn ? null,
  }: let
    transformKey =
      if fn != null
      then fn
      else if uppercase
      then toUpper
      else id;

    envName = transformKey name;
    current = builtins.getEnv envName;
  in {
    name = envName;
    value =
      if current != "" && current != null
      then current
      else default;
  };

  mkEnvPairs = map mkEnvPair;
in {
  inherit mkEnvPair mkEnvPairs;
  __rootAliases = {inherit mkEnvPair mkEnvPairs;};

  __tests = runTests {
    mkEnvPair = {
      defaultFallback = mkTest {
        desired = {
          name = "NON_EXISTENT_VAR";
          value = "/fallback/path";
        };
        command = ''mkEnvPair { name = "NON_EXISTENT_VAR"; default = "/fallback/path"; }'';
        outcome = mkEnvPair {
          name = "NON_EXISTENT_VAR";
          default = "/fallback/path";
        };
      };

      uppercaseKey = mkTest {
        desired = {
          name = "NON_EXISTENT_VAR";
          value = "default_value";
        };
        command = ''mkEnvPair { name = "non_existent_var"; default = "default_value"; uppercase = true; }'';
        outcome = mkEnvPair {
          name = "non_existent_var";
          default = "default_value";
          uppercase = true;
        };
      };

      customFn = mkTest {
        desired = {
          name = "PREFIX_FOO";
          value = "bar";
        };
        command = ''mkEnvPair { name = "foo"; default = "bar"; fn = k: "PREFIX_" + toUpper k; }'';
        outcome = mkEnvPair {
          name = "foo";
          default = "bar";
          fn = k: "PREFIX_" + toUpper k;
        };
      };
    };

    mkEnvPairs = {
      multiplePairs = mkTest {
        desired = [
          {
            name = "HOME";
            value = "/fallback/home";
          }
          {
            name = "DOTS_TOP";
            value = "_";
          }
        ];
        command = ''
          mkEnvPairs [
            { name = "home"; default = "/fallback/home"; uppercase = true; }
            { name = "dots_top"; default = "_"; uppercase = true; }
          ]
        '';
        outcome = mkEnvPairs [
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
}
