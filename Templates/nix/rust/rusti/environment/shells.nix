/**
modules/shells/default.nix

Expose final devShell derivations using lib.shells.
All shell composition logic lives in modules/libraries/shells.
*/
{
  lib,
  pkgs,
  mkTools,
  mkEnvironment,
  mkTemplates,
  mkWelcome,
}: let
  inherit (lib.shells.config) mkRustSpec mkAiSpec mkCombinedSpec;
  inherit (lib.shells.build) mkShell;
  rust = {
    nightly = mkShell (mkRustSpec {
      inherit pkgs mkTools mkEnvironment mkTemplates mkWelcome;
      channel = "nightly";
    });
    stable = mkShell (mkRustSpec {
      inherit pkgs mkTools mkEnvironment mkTemplates mkWelcome;
      channel = "stable";
    });
    beta = mkShell (mkRustSpec {
      inherit pkgs mkTools mkEnvironment mkTemplates mkWelcome;
      channel = "beta";
    });
  };

  ai = mkShell (mkAiSpec {inherit pkgs lib;});

  full = mkShell (mkCombinedSpec {
    inherit lib pkgs mkTools mkEnvironment mkTemplates mkWelcome;
    channel = "nightly";
  });
in {
  inherit rust ai full;
  default = full;
}
