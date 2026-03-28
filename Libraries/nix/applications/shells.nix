{
  _,
  lib,
  ...
}: let
  inherit (lib.attrsets) attrNames;
  inherit (_.lists.generators) mkEnum;
  inherit (_.trivial.tests) mkTest runTests;

  shells = {
    # POSIX-compatible
    bash = {
      posix = true;
      interactive = true;
      login = true;
      base = "c";
    };
    dash = {
      posix = true;
      interactive = false;
      login = true;
      base = "c";
    };
    sh = {
      posix = true;
      interactive = false;
      login = true;
      base = "c";
    };
    ksh = {
      posix = true;
      interactive = true;
      login = true;
      base = "c";
    };
    zsh = {
      posix = true;
      interactive = true;
      login = true;
      base = "c";
    };

    # Modern
    fish = {
      posix = false;
      interactive = true;
      login = true;
      base = "c";
    };
    nushell = {
      posix = false;
      interactive = true;
      login = true;
      base = "rust";
    };
    elvish = {
      posix = false;
      interactive = true;
      login = true;
      base = "go";
    };
    pwsh = {
      posix = false;
      interactive = true;
      login = true;
      base = "dotnet";
    };

    # Legacy/niche
    tcsh = {
      posix = false;
      interactive = true;
      login = true;
      base = "c";
    };
  };

  enum = mkEnum (attrNames shells);
in {
  inherit shells;

  _rootAliases = {
    shellsList = enum;
    shells = shells;
  };

  _tests = runTests {
    shells = {
      validatesBash = mkTest true (enum.validator.check "bash");
      validatesZsh = mkTest true (enum.validator.check "zsh");
      validatesFish = mkTest true (enum.validator.check "fish");
      caseInsensitive = mkTest true (enum.validator.check "NUSHELL");
    };
  };
}
