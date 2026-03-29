{
  _,
  lib,
  ...
}: let
  inherit (_.lists.generators) mkEnum;
  inherit (_.trivial.tests) mkTest runTests;
  inherit (lib.attrsets) filterAttrs;

  __exports = {
    internal = {
      inherit all interactive system enums;
      inherit
        (all)
        elvish
        nushell
        pwsh
        tcsh
        bash
        dash
        zsh
        ksh
        sh
        fish
        ;
    };
    external = {};
  };

  all = {
    #~@ POSIX-compatible
    bash = {
      posix = true;
      interactive = true;
      system = true;
      base = "c";
    };
    dash = {
      posix = true;
      interactive = false;
      system = true;
      base = "c";
    };
    sh = {
      posix = true;
      interactive = false;
      system = true;
      base = "c";
    };
    ksh = {
      posix = true;
      interactive = true;
      system = true;
      base = "c";
    };
    zsh = {
      posix = true;
      interactive = true;
      system = true;
      base = "c";
    };

    #~@ Modern
    fish = {
      posix = false;
      interactive = true;
      system = false;
      base = "c";
    };
    nushell = {
      posix = false;
      interactive = true;
      system = false;
      base = "rust";
    };
    elvish = {
      posix = false;
      interactive = true;
      system = false;
      base = "go";
    };
    pwsh = {
      posix = false;
      interactive = true;
      system = false;
      base = "dotnet";
    };

    #~@ Legacy/niche
    tcsh = {
      posix = false;
      interactive = true;
      system = false;
      base = "c";
    };
  };

  system = filterAttrs (_: s: s.system) all;
  interactive = filterAttrs (_: s: s.interactive) all;

  enums = {
    all = mkEnum {
      values = all;
      nullable = true;
    };
    interactive = mkEnum {
      values = interactive;
      nullable = true;
    };
    system = mkEnum {
      values = system;
      nullable = true;
    };
  };
in
  __exports.internal
  // {
    _rootAliases = __exports.external;

    _tests = runTests {
      validatesBash = mkTest true (enums.all.validator.check "bash");
      validatesZsh = mkTest true (enums.all.validator.check "zsh");
      validatesFish = mkTest true (enums.all.validator.check "fish");
      caseInsensitive = mkTest true (enums.all.validator.check "NUSHELL");

      systemExcludesFish = mkTest false (enums.system.validator.check "fish");
      systemExcludesPwsh = mkTest false (enums.system.validator.check "pwsh");
      systemIncludesBash = mkTest true (enums.system.validator.check "bash");
      systemIncludesZsh = mkTest true (enums.system.validator.check "zsh");

      interactiveExcludesDash = mkTest false (enums.interactive.validator.check "dash");
      interactiveExcludesSh = mkTest false (enums.interactive.validator.check "sh");
      interactiveIncludesFish = mkTest true (enums.interactive.validator.check "fish");
      interactiveIncludesBash = mkTest true (enums.interactive.validator.check "bash");
    };
  }
