{
  _,
  lib,
  src,
  __moduleRef,
  ...
}: let
  inherit (_.attrsets.predicates) valueOr;
  inherit (_.content.fallback) firstNonEmpty;
  inherit (_.content.empty) isNotEmpty;
  inherit (_.debug.assertions) mkTest mkTest';
  inherit (_.debug.module) mkModuleDebug;
  inherit (_.debug.runners) runTests;
  inherit (_.filesystem.paths) getFlakePath;
  inherit (_.hardware.systems) getSystems;
  inherit
    (lib.attrsets)
    attrByPath
    attrValues
    filterAttrs
    genAttrs
    hasAttrByPath
    listToAttrs
    optionalAttrs
    ;
  inherit (lib.debug) traceIf;
  inherit (lib.lists) filter findFirst head toList;
  inherit (builtins) getFlake tryEval;

  debug = mkModuleDebug __moduleRef;

  exports = rec {
    internal = {
      inherit
        byPaths
        flake
        getAttr
        host
        inputPackages
        inputSource
        nestedByPaths
        nixpkgs
        optional
        orDefault
        orNull
        package
        packages
        shellPackage
        ;
      flakeAttrs = flake;
      getAttrByPaths = byPaths;
      getAttrOrDefault = orDefault;
      getAttrOrNull = orNull;
      getFlake = flake;
      getHost = host;
      getNestedAttrByPaths = nestedByPaths;
      getPackage = package;
      getPkgs = packages;
      getShellPackage = shellPackage;
      mkInputPackages = inputPackages;
      mkInputSource = inputSource;
      optionalAttr = optional;
    };
    external = {
      inherit
        (internal)
        flakeAttrs
        getAttrByPaths
        getAttrOrDefault
        getAttrOrNull
        getFlake
        getHost
        getNestedAttrByPaths
        getPackage
        getPkgs
        getShellPackage
        mkInputPackages
        optionalAttr
        ;
    };
  };

  /**
  Get an attribute value, throwing if the key is absent.

  Use when the key is required and absence is a programming error.
  For optional keys use `orDefault` or `orNull`.

  # Type
  ```nix
  getAttr :: { attrs :: AttrSet, name :: string } -> a
  ```

  # Examples
  ```nix
  getAttr { attrs = { a = "hello"; }; name = "a"; }  # => "hello"
  getAttr { attrs = {};               name = "a"; }  # => throws
  getAttr { attrs = { a = ""; };      name = "a"; }  # => ""  (empty is valid)
  ```
  */
  getAttr = {
    attrs,
    name,
  }:
    if attrs ? ${name}
    then attrs.${name}
    else
      throw (debug.mkError {
        function = "getAttr";
        message = "attribute '${name}' is missing";
      });

  /**
  Get an attribute value, falling back to `default` if missing or empty.

  Unlike `attrs.key or default`, treats empty strings, empty lists, and
  empty attrsets as absent.

  # Type
  ```nix
  orDefault :: { attrs :: AttrSet, name :: string, default :: a } -> a
  ```

  # Examples
  ```nix
  orDefault { attrs = { a = "hello"; }; name = "a"; default = "fallback"; }  # => "hello"
  orDefault { attrs = { a = "";      }; name = "a"; default = "fallback"; }  # => "fallback"
  orDefault { attrs = {};               name = "a"; default = "fallback"; }  # => "fallback"
  orDefault { attrs = { a = 0;       }; name = "a"; default = 42;         }  # => 0
  orDefault { attrs = { a = false;   }; name = "a"; default = true;       }  # => false
  orDefault { attrs = { a = [];      }; name = "a"; default = [1 2];      }  # => [1 2]
  ```
  */
  orDefault = {
    attrs,
    name,
    default,
  }:
    if attrs ? ${name} && isNotEmpty attrs.${name}
    then attrs.${name}
    else default;

  /**
  Get an attribute value, falling back to `default` only if the key is absent.

  Unlike `orDefault`, preserves empty strings, empty lists, and empty attrsets.

  # Type
  ```nix
  orNull :: { attrs :: AttrSet, name :: string, default :: a } -> a
  ```

  # Examples
  ```nix
  orNull { attrs = { a = ""; };   name = "a"; default = "fallback"; }  # => ""
  orNull { attrs = { a = []; };   name = "a"; default = [1];         }  # => []
  orNull { attrs = {};             name = "a"; default = "fallback"; }  # => "fallback"
  orNull { attrs = { a = null; }; name = "a"; default = "fallback"; }  # => null
  ```
  */
  orNull = {
    attrs,
    name,
    default,
  }:
    if attrs ? ${name}
    then attrs.${name}
    else default;

  /**
  Resolve an attribute by trying multiple paths in order.

  Returns the value at the first matching path, or `default` if none exist.

  # Type
  ```nix
  byPaths :: { attrset :: AttrSet, paths :: [[string]], default :: a } -> a
  ```

  # Examples
  ```nix
  byPaths {
    attrset = { foo.bar = 1; baz.qux = 2; };
    paths   = [["missing"] ["foo" "bar"] ["baz" "qux"]];
    default = null;
  }
  # => 1  (first match: foo.bar)
  ```
  */
  byPaths = {
    attrset,
    paths,
    default ? {},
  }: let
    matched = filter (path: hasAttrByPath path attrset) paths;
  in
    if isNotEmpty matched
    then attrByPath (head matched) default attrset
    else default;

  /**
  Resolve a nested attribute under any of several possible parent names.

  # Type
  ```nix
  nestedByPaths :: { attrset :: AttrSet, parents :: string | [string], target :: string | [string], default :: a } -> a
  ```

  # Examples
  ```nix
  nestedByPaths {
    attrset = inputs;
    parents = ["zenBrowser" "zen-browser" "zen"];
    target  = "homeModules";
  }
  ```
  */
  nestedByPaths = {
    attrset,
    parents,
    target,
    default ? {},
  }:
    byPaths {
      inherit attrset default;
      paths = map (parent: [parent] ++ toList target) (toList parents);
    };

  /**
  Get `legacyPackages` from a nixpkgs flake for a given system.

  # Type
  ```nix
  packages :: { nixpkgs :: Flake?, system :: string?, priority :: [string]? } -> AttrSet
  ```
  */
  packages = {
    nixpkgs ? import <nixpkgs> {},
    system ? null,
    priority ? null,
  }: let
    targetSystem = system;
  in
    if priority != null
    then let
      sources = filterAttrs (_key: value: value != null) (genAttrs priority (name: nixpkgs.${name} or null));
    in
      (findFirst
        (nixpkgsSource: nixpkgsSource.legacyPackages.${targetSystem} or null != null)
        nixpkgs.legacyPackages
        (attrValues sources))
      .${
        targetSystem
      }
    else nixpkgs.legacyPackages.${targetSystem};

  /**
  Resolve a package from `pkgs` by trying one or more names in order.

  # Type
  ```nix
  package :: { pkgs :: AttrSet, target :: string | [string], default :: a } -> Derivation | a
  ```

  # Examples
  ```nix
  package { inherit pkgs; target = ["firefox-beta" "firefox-esr" "firefox"]; }
  ```
  */
  package = {
    pkgs,
    target,
    default ? null,
  }:
    byPaths {
      attrset = pkgs;
      paths = map (name: [name]) (toList target);
      inherit default;
    };

  /**
  Map a shell name to its nixpkgs package.

  Falls back to `pkgs.bashInteractive` for unknown names.

  # Type
  ```nix
  shellPackage :: { pkgs :: AttrSet, name :: string } -> Derivation
  ```

  # Examples
  ```nix
  shellPackage { inherit pkgs; name = "zsh"; }     # => pkgs.zsh
  shellPackage { inherit pkgs; name = "unknown"; } # => pkgs.bashInteractive
  ```
  */
  shellPackage = {
    pkgs,
    name,
  }:
    {
      "bash" = pkgs.bashInteractive;
      "fish" = pkgs.fish;
      "nushell" = pkgs.nushell;
      "powershell" = pkgs.powershell;
      "zsh" = pkgs.zsh;
    }
    .${
      name
    } or pkgs.bashInteractive;

  /**
  Build a name → packages attrset by resolving `inputs.<name>.<attr>` for
  each name in `names`.

  # Type
  ```nix
  mkPkgSet :: { attr :: string, names :: [string] } -> AttrSet
  ```
  */
  inputPackages = {
    inputs,
    attrs,
    names,
  }:
    listToAttrs (map (name: {
        inherit name;
        value = let
          input = valueOr {
            attrs = inputs;
            key = name;
            default = {};
          };
        in
          valueOr {
            attrs = input;
            key = attrs;
            default = {};
          };
      })
      names);

  /**
  Conditionally include a single attribute in an attrset merge.

  Returns `{ name = attrs.name; }` if the attribute exists and is non-empty,
  otherwise `{}`.

  # Type
  ```nix
  optional :: { attrs :: AttrSet, name :: string } -> AttrSet
  ```

  # Examples
  ```nix
  { inherit foo bar; }
  // optional { attrs = config; name = "baz"; }
  // optional { attrs = config; name = "qux"; }
  ```
  */
  optional = {
    attrs,
    name,
  }:
    if attrs ? name && isNotEmpty attrs.${name}
    then {${name} = attrs.${name};}
    else {};

  flake = {
    self ? {},
    path ? src,
  }: let
    normalizedPath = getFlakePath {inherit self path;};
    derived = optionalAttrs (normalizedPath != null) (getFlake normalizedPath);
    failureReason =
      if normalizedPath == null
      then "path normalization failed"
      else if derived == null
      then "getFlake returned null"
      else if (derived._type or null) != "flake"
      then "invalid flake type: ${derived._type or "null"}"
      else "unknown";
  in
    if self != {}
    then self
    else
      traceIf
      ((derived._type or null) != "flake")
      "❌ Flake load failed: ${toString path} (${failureReason})"
      (derived // {srcPath = path;});

  host = {
    nixosConfigurations ? optionalAttrs ((flake {}) ? nixosConfigurations) (flake {}).nixosConfigurations,
    system ? (getSystems {}).system,
  }: let
    derived =
      findFirst
      (hostConfig: (hostConfig.config.nixpkgs.hostPlatform.system or null) == system)
      null
      (attrValues nixosConfigurations);
  in
    traceIf
    ((derived.class or null) != "nixos")
    "❌ Failed to derive current host"
    (derived // {name = derived.config.networking.hostName;});

  /**
  Build the `nixpkgs` source attribute appropriate for the host class.

  Darwin uses `source`; NixOS uses `flake.source`. Resolves `root` from
  `inputs.nixpkgs` when not explicitly provided.

  # Type
  ```
  inputSource :: { host? :: AttrSet, root? :: any, inputs? :: AttrSet } -> AttrSet
  ```

  # Examples
  ```nix
  inputSource { host.class = "darwin"; inputs.nixpkgs = nixpkgs; }
  # => { source = nixpkgs; }

  inputSource { inputs.nixpkgs = nixpkgs; }
  # => { flake.source = nixpkgs; }
  ```
  */
  inputSource = {
    host ? {},
    root ? null,
    inputs ? {},
    ...
  }: let
    root' = firstNonEmpty [root (inputs.nixpkgs or null)];
  in
    if (host.class or "nixos") == "darwin"
    then {source = root';}
    else {flake.source = root';};

  nixpkgs = {
    system,
    config,
    overlays,
    inputs,
    ...
  }:
    {
      hostPlatform = system;
      inherit config overlays;
    }
    // (
      with inputs.nixpkgs; (
        if (host.class or "nixos") == "darwin"
        then {source = outPath;}
        else {flake.source = outPath;}
      )
    );

  __doc = ''
    Attribute set resolution and lookup utilities.

    Provides tools for navigating nested structures, handling missing attributes
    gracefully, and resolving values from multiple potential sources.
  '';
in
  exports.internal
  // {
    inherit __doc;
    _rootAliases = exports.external;
    _tests = runTests {
      getAttr = {
        returnsValueWhenPresent = mkTest {
          desired = "hello";
          outcome = getAttr {
            attrs = {a = "hello";};
            name = "a";
          };
          command = ''getAttr { attrs = { a = "hello"; }; name = "a"; }'';
        };
        preservesEmptyString = mkTest {
          desired = "";
          outcome = getAttr {
            attrs = {a = "";};
            name = "a";
          };
          command = ''getAttr { attrs = { a = ""; }; name = "a"; }'';
        };
        throwsWhenMissing = mkTest {
          desired = {
            success = false;
            value = false;
          };
          outcome = tryEval (getAttr {
            attrs = {};
            name = "a";
          });
          command = ''builtins.tryEval (getAttr { attrs = {}; name = "a"; })'';
        };
      };

      orDefault = {
        returnsValueWhenPresent = mkTest {
          desired = "hello";
          outcome = orDefault {
            attrs = {a = "hello";};
            name = "a";
            default = "fallback";
          };
          command = ''orDefault { attrs = { a = "hello"; }; name = "a"; default = "fallback"; }'';
        };
        fallsBackOnEmptyString = mkTest {
          desired = "fallback";
          outcome = orDefault {
            attrs = {a = "";};
            name = "a";
            default = "fallback";
          };
          command = ''orDefault { attrs = { a = ""; }; name = "a"; default = "fallback"; }'';
        };
        fallsBackOnMissing = mkTest {
          desired = "fallback";
          outcome = orDefault {
            attrs = {};
            name = "a";
            default = "fallback";
          };
          command = ''orDefault { attrs = {}; name = "a"; default = "fallback"; }'';
        };
        preservesZero = mkTest' 0 (orDefault {
          attrs = {a = 0;};
          name = "a";
          default = 42;
        });
        preservesFalse = mkTest' false (orDefault {
          attrs = {a = false;};
          name = "a";
          default = true;
        });
        fallsBackOnEmpty = mkTest' [1 2] (orDefault {
          attrs = {a = [];};
          name = "a";
          default = [1 2];
        });
      };

      orNull = {
        preservesEmptyString = mkTest {
          desired = "";
          outcome = orNull {
            attrs = {a = "";};
            name = "a";
            default = "fallback";
          };
          command = ''orNull { attrs = { a = ""; }; name = "a"; default = "fallback"; }'';
        };
        preservesEmptyList = mkTest {
          desired = [];
          outcome = orNull {
            attrs = {a = [];};
            name = "a";
            default = [1];
          };
          command = ''orNull { attrs = { a = []; }; name = "a"; default = [1]; }'';
        };
        fallsBackOnMissing = mkTest {
          desired = "fallback";
          outcome = orNull {
            attrs = {};
            name = "a";
            default = "fallback";
          };
          command = ''orNull { attrs = {}; name = "a"; default = "fallback"; }'';
        };
        preservesNull = mkTest' null (orNull {
          attrs = {a = null;};
          name = "a";
          default = "fallback";
        });
      };

      optional = {
        includesWhenPresent = mkTest {
          desired = {baz = "yes";};
          outcome = optional {
            attrs = {baz = "yes";};
            name = "baz";
          };
          command = ''optional { attrs = { baz = "yes"; }; name = "baz"; }'';
        };
        excludesWhenMissing = mkTest' {} (optional {
          attrs = {};
          name = "baz";
        });
        excludesWhenEmpty = mkTest' {} (optional {
          attrs = {baz = "";};
          name = "baz";
        });
      };

      byPaths = {
        returnsFirstMatch = mkTest {
          desired = 1;
          outcome = byPaths {
            attrset = {
              foo.bar = 1;
              baz.qux = 2;
            };
            paths = [["missing"] ["foo" "bar"] ["baz" "qux"]];
            default = null;
          };
          command = ''byPaths: first match is foo.bar'';
        };
        fallsBackToDefault = mkTest' null (byPaths {
          attrset = {};
          paths = [["missing"]];
          default = null;
        });
      };
    };
  }
