{lib}: let
  inherit (lib.shells) mergeShellSpecs mkShells rust ai;

  mkSpec = {
    pkgs ? null,
    channel ? null,
    targets ? null,
    extensions ? null,
    includeEditor ? true,
    preset ? null,
    includeAnalytics ? true,
    includeWorkflow ? false,
    minimal ? false,
  }: let
    specs = {
      rust = rust.mkShell {inherit pkgs channel targets extensions includeEditor minimal;};
      ai = ai.mkShell {inherit pkgs preset includeAnalytics includeWorkflow minimal;};
      merged = mergeShellSpecs specs.rust specs.ai;
    };
  in
    mergeShellSpecs specs.merged {
      __meta.kind = "combined";
      shell.name = "${specs.rust.shell.name}-${specs.ai.shell.name}";
    };

  mkSuite = {
    inputs,
    pkgs,
  }: let
    mk = args: mkSpec ({inherit pkgs;} // args);
    suites = {
      rust = rust.mkSuite {inherit pkgs;};
      ai = ai.mkSuite {inherit pkgs;};
      combined = {
        default = mk {};
        stable = mk {channel = "stable";};
        full = mk {
          preset = "full";
          includeWorkflow = true;
        };
        minimal = mk {
          preset = "minimal";
          includeAnalytics = false;
          includeEditor = false;
          minimal = true;
        };
      };
    };
  in {
    devShells = mkShells {
      inherit inputs;
      inherit (suites.combined) default;
      shells = suites.rust // suites.ai // suites.combined;
    };
  };
in {
  inherit mkSpec mkSuite;
  mkDevShells = mkSuite;
}
