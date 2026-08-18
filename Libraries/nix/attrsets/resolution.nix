{
  _,
  lib,
  src,
  __moduleRef,
  ...
}: let
  # TODO: We need to improve meta management
  __meta = {
    doc = ''
      Attribute set resolution and lookup utilities.

      Provides tools for navigating nested structures, handling missing attributes
      gracefully, and resolving values from multiple potential sources.
    '';

    exports = let
      internal = let
        functions = {
          inherit
            byPaths
            flakeAttrs # TODO: Move to sources.inputs or sources.modules
            getAttr
            hostAttrs # TODO: Move to sources.inputs or sources.modules
            inputPackages # TODO: Move to sources.packages
            inputSource # TODO: Move to sources.inputs
            nestedByPaths
            withPath
            nixpkgs # TODO: Move to sources.inputs or sources.packages
            optional
            orDefault
            orNull
            package # TODO: Move to sources.packages or applications.registry
            packages # TODO: Move to sources.packages
            shellPackage # TODO: Move to sources.packages or applications.registry
            parseVscodeExt # TODO: Move to applications.vscode or applications.registry
            vscodePackage # TODO: Move to applications.vscode or applications.registry
            vscodePackages # TODO: Move to applications.vscode or applications.registry
            normalizePath
            ;
        };
        aliases = {
          getAttrWithPath = withPath;
          normalizeAttrPath = normalizePath;
          getAttrByPaths = byPaths;
          getAttrOrDefault = orDefault;
          getAttrOrNull = orNull;
          getFlake = flakeAttrs;
          getHost = hostAttrs;
          getNestedAttrByPaths = nestedByPaths;
          getPackage = package;
          getPackages = packages;
          getPkgs = packages;
          mkPkgs = packages;
          getShellPackage = shellPackage;
          mkInputPackages = inputPackages;
          mkInputSource = inputSource;
          optionalAttr = optional;
        };
      in
        {inherit functions aliases;} // functions // aliases;
      external = internal.aliases;
    in {inherit internal external;};
  };

  # __exports = {
  #   inherit
  #     byPaths
  #     flakeAttrs # TODO: Move to sources.inputs or sources.modules
  #     getAttr
  #     hostAttrs # TODO: Move to sources.inputs or sources.modules
  #     inputPackages # TODO: Move to sources.packages
  #     inputSource # TODO: Move to sources.inputs
  #     nestedByPaths
  #     withPath
  #     nixpkgs # TODO: Move to sources.inputs or sources.packages
  #     optional
  #     orDefault
  #     orNull
  #     package # TODO: Move to sources.packages or applications.registry
  #     packages # TODO: Move to sources.packages
  #     shellPackage # TODO: Move to sources.packages or applications.registry
  #     parseVscodeExt # TODO: Move to applications.vscode or applications.registry
  #     vscodePackage # TODO: Move to applications.vscode or applications.registry
  #     vscodePackages # TODO: Move to applications.vscode or applications.registry
  #     normalizePath
  #     ;
  #   getAttrWithPath = withPath;
  #   normalizeAttrPath = normalizePath;
  #   getAttrByPaths = byPaths;
  #   getAttrOrDefault = orDefault;
  #   getAttrOrNull = orNull;
  #   getFlake = flakeAttrs;
  #   getHost = hostAttrs;
  #   getNestedAttrByPaths = nestedByPaths;
  #   getPackage = package;
  #   getPackages = packages;
  #   getPkgs = packages;
  #   mkPkgs = packages;
  #   getShellPackage = shellPackage;
  #   mkInputPackages = inputPackages;
  #   mkInputSource = inputSource;
  #   optionalAttr = optional;
  # };

  # __rootAliases = {
  #   inherit
  #     (__exports)
  #     flakeAttrs
  #     getAttrByPaths
  #     getAttrOrDefault
  #     getAttrOrNull
  #     getFlake
  #     getHost
  #     getNestedAttrByPaths
  #     getPackage
  #     getPackages
  #     getPkgs
  #     getShellPackage
  #     optionalAttr
  #     ;
  #   mkPkgs = packages;
  #   mkInputPackages = inputPackages;
  #   mkVSCodePackages = vscodePackages; # TODO: Move to applications.vscode or applications.registry
  #   mkVSCodePackage = vscodePackage; # TODO: Move to applications.vscode or applications.registry
  # };

  inherit (_.attrsets.access) attrByPath attrValues;
  inherit (_.attrsets.predicates) hasAttrByPath;
  inherit (_.attrsets.construction) listToAttrs optionalAttrs;
  inherit (_.attrsets.predicates) hasAttr isAttrs;
  inherit (_.content.emptiness) isNotEmpty;
  inherit (_.content.fallback) firstNonEmpty;
  inherit (_.debug.assertions) withContext mkTest mkTest';
  inherit (_.debug.module) mkModuleDebug;
  inherit (_.debug.runners) runTests;
  inherit (_.debug.tracing) addErrorContext traceIf;
  inherit (_.filesystem.resolution) getFlakePath;
  inherit (_.hardware.system) getSystems getSystemOrDefault;
  inherit (_.lists.predicates) all elem isList;
  inherit (_.lists.access) head findFirst;
  inherit (_.lists.construction) optionals toList;
  inherit (_.lists.transformation) filter;
  inherit (_.strings.construction) concatStringsSep optionalString;
  inherit (_.strings.predicates) isString;
  inherit (_.strings.transformation) splitStringBy;
  inherit (_.types.predicates) isDerivation;
  inherit (builtins) getFlake tryEval;

  debug = mkModuleDebug __moduleRef;

  normalizePath = path: let
    fn = {
      name = "normalizePath";
      context = "normalizing attribute path";
    };

    stems =
      if isList path
      then path
      else
        assert withContext {
          inherit (fn) name context;
          assertion = isString path;
          message = "`path` must be a string or list of strings";
        };
          splitStringBy (_: sep: elem sep ["." "/"]) false path;

    validated = assert withContext {
      inherit (fn) name context;
      assertion = isList stems;
      message = "normalized path must be a list of path segments";
    };
    assert withContext {
      inherit (fn) name context;
      assertion = all isString stems;
      message = "each path segment must be a string";
    };
    assert withContext {
      inherit (fn) name context;
      assertion = all (stem: stem != "") stems;
      message = "path segments must not be empty";
    }; stems;
  in {
    path = validated;
    reference =
      optionalString
      (isNotEmpty validated)
      (concatStringsSep "." validated);
  };

  withPath = {
    base,
    path ? [],
  }: let
    fn = {
      name = "getAttrWithName";
      context = "resolving config reference";
    };

    validated = {
      base = assert withContext {
        inherit (fn) name context;
        assertion = isAttrs base;
        message = "`base` must be an attrset like { name, value; }";
      };
      assert withContext {
        inherit (fn) name context;
        assertion = hasAttr "name" base;
        message = "`base` is missing required attribute `name`";
      };
      assert withContext {
        inherit (fn) name context;
        assertion = hasAttr "value" base;
        message = "`base` is missing required attribute `value`";
      };
      assert withContext {
        inherit (fn) name context;
        assertion = isString base.name;
        message = "`base.name` must be a string";
      };
      assert withContext {
        inherit (fn) name context;
        assertion = base.name != "";
        message = "`base.name` must not be empty";
      };
      assert withContext {
        inherit (fn) name context;
        assertion = isAttrs base.value;
        message = "`base.value` must be an attrset";
      }; base;

      inherit
        ((
          assert withContext {
            inherit (fn) name context;
            assertion = isString path || isList path;
            message = "`path` must be a string or list";
          };
            normalizePath path
        ))
        path
        ;
    };

    inherit (validated.base) name value;
    stems = validated.path;
  in
    addErrorContext
    "while resolving `${name}`"
    {
      inherit name;
      path = (normalizePath ([name] ++ stems)).reference;
      value = attrByPath stems {} value;
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
    attrs.${
      name
    } or (throw (
      debug.mkError {
        function = "getAttr";
        message = "attribute '${name}' is missing";
      }
    ));

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
    attrs.${name} or default;

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

  # /**
  # Get `legacyPackages` from a nixpkgs flake for a given system.

  # # Type
  # ```nix
  # packages :: { nixpkgs :: Flake?, system :: string?, priority :: [string]? } -> AttrSet
  # ```
  # */
  # packages = {
  #   # nixpkgs ? import <nixpkgs> {},
  #   # system ? null,
  #   flake ? {},
  #   inputs ? {},
  #   nixpkgs ? {},
  #   legacyPackages ? {},
  #   system ? null,
  #   priority ? null,
  # }: let
  #   targetSystem = getSystemOrDefault {
  #     inherit flake inputs nixpkgs legacyPackages system;
  #   };
  # in
  #   if priority != null
  #   then let
  #     sources = filterAttrs (_key: value: value != null) (genAttrs priority (name: nixpkgs.${name} or null));
  #   in
  #     (findFirst
  #       (nixpkgsSource: nixpkgsSource.legacyPackages.${targetSystem} or null != null)
  #       nixpkgs.legacyPackages (
  #         attrValues sources
  #       )).${
  #       targetSystem
  #     }
  #   else nixpkgs.legacyPackages.${targetSystem};

  /**
  Resolve a package from `pkgs` by trying one or more names in order.
  If target is already a package derivation, returns it directly.

  # Input
  `pkgs`
  : the nixpkgs attrset to search for packages.

  `target`
  : a string or list of strings representing the package name(s) to search for.
    If a list is provided, the first matching package will be returned.

  `default`
  : a fallback value to return if none of the specified package names are found.
    If not provided, defaults to `null`.

  # Type
  > package :: { pkgs :: AttrSet, target :: Derivation | string | [string], default :: a } -> Derivation | a

  # Examples
  - package { inherit pkgs; target = ["firefox-non-existent" "firefox-beta" "firefox-esr" "firefox"]; }

  ```nix
  «derivation /nix/store/zqgjbxc3f3yaxhvpvhgkf8ik7k5cbig9-firefox-beta-151.0b9.drv»
  ```
  - package { inherit pkgs; target = "bluez"; }

  ```nix
  «derivation /nix/store/f4468gjcb7dsp0i9vha9gyrfx5lj2cxx-bluez-5.86.drv»
  ```

  - package { inherit pkgs; target = pkgs.bluez; }

  ```nix
  «derivation /nix/store/f4468gjcb7dsp0i9vha9gyrfx5lj2cxx-bluez-5.86.drv»
  ```
  */
  package = {
    pkgs,
    target,
    default ? null,
  }:
    if isDerivation target
    then target
    else
      byPaths {
        attrset = pkgs;
        paths = map (name: [name]) (toList target);
        inherit default;
      };

  /**
  Resolve package attribute sets or individual package derivations.

  Modes:
  1. _System Package Set Resolution (when `targets` is null/omitted)_. Extracts and returns the `legacyPackages.${system}` attribute set from flake inputs or nixpkgs.

  2. _Target Package List Resolution (when `targets` is provided)_. Resolves a list of strings, preference fallback lists, or package derivations into concrete derivations.

  # Input
  `pkgs`
  : Optional nixpkgs attrset. If omitted when resolving targets, it will be automatically resolved using flake/inputs/system parameters.

  `targets`
  : Optional list of package names, fallback lists, or derivations to resolve.

  `flake` / `inputs` / `nixpkgs` / `legacyPackages` / `system`
  : Flake resolution context arguments (used to compute `pkgs` if `pkgs` is not explicitly passed).

  `priority`
  : Optional string or list of strings naming input keys (e.g., `["nixPackagesUnstable" "nixPackages"]`) to prioritize when searching for a package set.

  `default`
  : Fallback value if a target package is not found. Defaults to `null`.

  `filterNulls`
  : Optional boolean. If `true`, removes `null` values from the resolved targets list. Defaults to `false`.

  # Type
  > packages :: AttrSet -> (AttrSet | [ (Derivation | a) ])

  # Examples
  - Resolving a system `pkgs` set from flake context with input priority:
  > packages { inherit flake system; priority = [ "nixPackagesUnstable" "nixPackages" ]; }

  - Resolving target package derivations directly from flake inputs:
  > packages { inherit flake; system = "x86_64-linux"; targets = [ "bluez" "git" ]; }

  - Resolving target package derivations from an explicit `pkgs` set:
  > packages { inherit pkgs; targets = [ "bluez" ["firefox-non-existent" "firefox-beta" "firefox-esr" "firefox"] pkgs.git ]; }

  - Filtering unresolved packages (`filterNulls`):
  > packages { inherit pkgs; targets = [ "bluez" pkgs.git "non-existent-package" ]; filterNulls = true; }
  */
  packages = {
    #? System package set context options
    flake ? {},
    inputs ? {},
    nixpkgs ? {},
    legacyPackages ? {},
    system ? null,
    priority ? null,
    #? Package target resolution options
    pkgs ? null,
    targets ? null,
    default ? null,
    filterNulls ? false,
  }: let
    __ctx = "attrsets.resolution.packages";

    resolved = {
      system = getSystemOrDefault {
        inherit flake inputs nixpkgs legacyPackages system;
      };

      sources = {
        priority = optionals (priority != null) (map (
          name:
            inputs.${name}
            or (flake.inputs.${name} or (nixpkgs.${name} or null))
        ) (toList priority));

        candidate = filter (src: src != {} && src != null) (
          resolved.sources.priority
          ++ [
            pkgs
            nixpkgs
            (inputs.nixPackages or null)
            (inputs.nixPackagesUnstable or null)
            (inputs.nixpkgs or null)
            (flake.inputs.nixPackages or null)
            (flake.inputs.nixPackagesUnstable or null)
            (flake.inputs.nixpkgs or null)
            flake
          ]
        );
      };

      findPkgsSet = src:
        src.legacyPackages.${
          resolved.system
        } or (src.packages.${
            resolved.system
          } or (
            if src ? system && src.system == resolved.system
            then src
            else null
          ));

      pkgs =
        if pkgs != null && pkgs ? system
        then pkgs
        else
          findFirst (pkg: pkg != null) (
            throw "${__ctx}: Unable to resolve a valid pkgs set for system '${resolved.system}'"
          ) (map resolved.findPkgsSet resolved.sources.candidate);

      targets = map (
        target:
          package {
            inherit (resolved) pkgs;
            inherit target default;
          }
      ) (toList targets);
    };
  in
    if targets != null
    then
      if filterNulls
      then filter (pkg: pkg != null) resolved.targets
      else resolved.targets
    else resolved.pkgs;

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
    listToAttrs (
      map (name: {
        inherit name;
        value = inputs.${name}.${attrs} or {};
      })
      names
    );

  /**
  Parse a VSCode extension identifier into { publisher, name }.

  Accepts either "publisher.name" string or { publisher; name; } attrset.

  # Type
  ```nix
  parseVscodeExt :: string | { publisher :: string, name :: string }
                -> { publisher :: string, name :: string }
  ```
  */
  parseVscodeExt = entry:
    if lib.strings.isString entry
    then let
      parts = lib.strings.splitString "." entry;
    in {
      publisher = lib.lists.elemAt parts 0;
      name = lib.lists.elemAt parts 1;
    }
    else entry;

  /**
  Resolve a single VSCode extension, trying nixpkgs first then marketplace.

  # Type
  ```nix
  vscodePackage :: {
    pkgs    :: AttrSet,
    inputs  :: AttrSet,
    system  :: string,
    entry   :: string | { publisher :: string, name :: string },
    default :: a?
  } -> Derivation | a
  ```
  */
  vscodePackage = {
    pkgs,
    inputs,
    system ? pkgs.stdenv.hostPlatform.system,
    entry,
    default ? null,
  }: let
    e = parseVscodeExt entry;
  in
    byPaths {
      attrset =
        {
          nixpkgs = pkgs.vscode-extensions;
        }
        // optionalAttrs (
          inputs ? nix-vscode-extensions
          && inputs.nix-vscode-extensions ? extensions
          && hasAttrByPath [system "vscode-marketplace"] inputs.nix-vscode-extensions.extensions
        ) {
          market = inputs.nix-vscode-extensions.extensions.${system}.vscode-marketplace;
        };
      paths = [
        [
          "nixpkgs"
          e.publisher
          e.name
        ]
        [
          "market"
          e.publisher
          e.name
        ]
      ];
      inherit default;
    };

  /**
  Resolve a list of VSCode extensions, silently dropping any not found.

  # Type
  ```nix
  vscodePackages :: {
    pkgs   :: AttrSet,
    inputs :: AttrSet,
    system :: string?,
    entries :: [string | { publisher :: string, name :: string }]
  } -> [Derivation]
  ```
  */
  vscodePackages = {
    pkgs,
    inputs,
    system ? pkgs.stdenv.hostPlatform.system,
    entries,
  }:
    lib.lists.filter (x: x != null) (
      map (
        entry:
          vscodePackage {
            inherit
              pkgs
              inputs
              system
              entry
              ;
          }
      )
      entries
    );

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

  flakeAttrs = {
    flake ? {},
    self ? {},
    path ? src,
  }: let
    normalizedPath = getFlakePath {
      inherit path;
      flake =
        if isNotEmpty flake
        then flake
        else self;
    };
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
      traceIf ((derived._type or null) != "flake") "❌ Flake load failed: ${toString path} (${failureReason})" (
        derived // {srcPath = path;}
      );

  hostAttrs = {
    self ? {},
    path ? src,
    hosts ? {},
    flake ? {},
    nixosConfigurations ? {},
    system ? null,
  }: let
    derived =
      findFirst
      (
        hostConfig:
          (hostConfig.config.nixpkgs.hostPlatform.system or null)
          == (
            if system != null
            then system
            else (getSystems {inherit hosts;}).system
          )
      )
      null
      (
        attrValues (
          if nixosConfigurations != {}
          then nixosConfigurations
          else (flake.nixosConfigurations or (flakeAttrs {inherit self path;}).nixosConfigurations or {})
        )
      );
  in
    traceIf ((derived.class or null) != "nixos") "❌ Failed to derive current host" (
      derived // {name = derived.config.networking.hostName;}
    );

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
    root' = firstNonEmpty [
      root
      (inputs.nixpkgs or null)
    ];
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
in
  with __meta;
    exports.internal
    // {
      __doc = doc;
      __rootAliases = exports.external;
      __tests = runTests {
        getAttr = {
          returnsValueWhenPresent = mkTest {
            desired = "hello";
            outcome = getAttr {
              attrs = {
                a = "hello";
              };
              name = "a";
            };
            command = ''getAttr { attrs = { a = "hello"; }; name = "a"; }'';
          };
          preservesEmptyString = mkTest {
            desired = "";
            outcome = getAttr {
              attrs = {
                a = "";
              };
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
              attrs = {
                a = "hello";
              };
              name = "a";
              default = "fallback";
            };
            command = ''orDefault { attrs = { a = "hello"; }; name = "a"; default = "fallback"; }'';
          };
          fallsBackOnEmptyString = mkTest {
            desired = "fallback";
            outcome = orDefault {
              attrs = {
                a = "";
              };
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
            attrs = {
              a = 0;
            };
            name = "a";
            default = 42;
          });
          preservesFalse = mkTest' false (orDefault {
            attrs = {
              a = false;
            };
            name = "a";
            default = true;
          });
          fallsBackOnEmpty = mkTest' [1 2] (orDefault {
            attrs = {
              a = [];
            };
            name = "a";
            default = [
              1
              2
            ];
          });
        };

        orNull = {
          preservesEmptyString = mkTest {
            desired = "";
            outcome = orNull {
              attrs = {
                a = "";
              };
              name = "a";
              default = "fallback";
            };
            command = ''orNull { attrs = { a = ""; }; name = "a"; default = "fallback"; }'';
          };
          preservesEmptyList = mkTest {
            desired = [];
            outcome = orNull {
              attrs = {
                a = [];
              };
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
            attrs = {
              a = null;
            };
            name = "a";
            default = "fallback";
          });
        };

        optional = {
          includesWhenPresent = mkTest {
            desired = {
              baz = "yes";
            };
            outcome = optional {
              attrs = {
                baz = "yes";
              };
              name = "baz";
            };
            command = ''optional { attrs = { baz = "yes"; }; name = "baz"; }'';
          };
          excludesWhenMissing = mkTest' {} (optional {
            attrs = {};
            name = "baz";
          });
          excludesWhenEmpty = mkTest' {} (optional {
            attrs = {
              baz = "";
            };
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
              paths = [
                ["missing"]
                [
                  "foo"
                  "bar"
                ]
                [
                  "baz"
                  "qux"
                ]
              ];
              default = null;
            };
            command = "byPaths: first match is foo.bar";
          };
          fallsBackToDefault = mkTest' null (byPaths {
            attrset = {};
            paths = [["missing"]];
            default = null;
          });
        };
      };
    }
