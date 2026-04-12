{
  _,
  __moduleDir,
  __moduleName,
  ...
}: let
  inherit (_.applications.primitives) toValue toName;
  inherit (_.applications.queries) mkEq mkMember;
  inherit (_.applications.selection) withFlag;
  inherit (_.attrsets.access) attrValues;
  inherit (_.attrsets.construction) genAttrs listToAttrs;
  inherit (_.attrsets.transformation) filterAttrs;
  inherit (_.lists.predicates) isIn;
  inherit (_.lists.selection) filter;
  inherit (_.lists.transformation) unique;
  default = _.applications.filters.groups;

  /**
  Partition an application set by the distinct values of the `maturity` field.
  Entries where `maturity` is absent or `null` are excluded.

  # Type
  ```nix
  mkMaturity :: { set :: AttrSet } -> { ${maturity} :: AttrSet }
  ```

  # Examples
  ```nix
  mkMaturity { set = { a = { maturity = "stable"; }; b = { maturity = "beta"; }; }; }
  # => { stable = { a = ...; }; beta = { b = ...; }; }
  ```
  */
  mkMaturity = {set}:
    mkEq {
      inherit set;
      field = "maturity";
    };

  /**
  Index an application set by members of the `protocol` list field.
  An entry appears under every protocol value it lists.

  # Type
  ```nix
  mkProtocol :: { set :: AttrSet } -> { ${protocol} :: AttrSet }
  ```

  # Examples
  ```nix
  mkProtocol {
    set = { a = { protocol = ["wayland" "xorg"]; }; b = { protocol = ["wayland"]; }; };
  }
  # => { wayland = { a = ...; b = ...; }; xorg = { a = ...; }; }
  ```
  */
  mkProtocol = {set}:
    mkMember {
      inherit set;
      field = "protocol";
    };

  /**
  Partition an application set by the distinct values of the `scope` field.
  Entries where `scope` is absent or `null` are excluded.

  # Type
  ```nix
  mkScope :: { set :: AttrSet } -> { ${scope} :: AttrSet }
  ```

  # Examples
  ```nix
  mkScope { set = { a = { scope = "user"; }; b = { scope = "system"; }; }; }
  # => { user = { a = ...; }; system = { b = ...; }; }
  ```
  */
  mkScope = {set}:
    mkEq {
      inherit set;
      field = "scope";
    };

  /**
  Build a capability map for an application set across a fixed set of
  boolean capability fields. Each key contains the subset of entries that
  have that capability set to true. Empty subsets are omitted.

  # Type
  ```nix
  mkCapability :: { set :: AttrSet } -> { ${capability} :: AttrSet }
  ```

  # Examples
  ```nix
  mkCapability {
    set = {
      a = { acceleration = true;  compositing = false; };
      b = { acceleration = true;  compositing = true;  };
    };
  }
  # => { acceleration = { a = ...; b = ...; }; compositing = { b = ...; }; }

  # Capabilities with no matching entries are omitted
  mkCapability { set = { a = { floating = false; }; }; }
  # => {}
  ```
  */
  mkCapability = {set}: let
    fields = [
      "acceleration"
      "compositing"
      "floating"
      "fuzzy"
      "history"
      "navigation"
      "remote"
      "stacking"
      "tiling"
    ];
  in
    filterAttrs (_: v: v != {}) (
      genAttrs fields (field: withFlag {inherit field set;})
    );

  /**
  Partition an application set by the value of `config.file`.
  Entries without `config` or with a null `config.file` are excluded.

  # Type
  ```nix
  mkConfig :: { set :: AttrSet } -> { ${configFile} :: AttrSet }
  ```

  # Examples
  ```nix
  mkConfig {
    set = {
      a = { config = { file = ".bashrc"; }; };
      b = { config = { file = ".zshrc";  }; };
      c = {};
    };
  }
  # => { ".bashrc" = { a = ...; }; ".zshrc" = { b = ...; }; }
  ```
  */
  mkConfig = {set}: let
    getFile = toValue {field = "config.file";};
    withCfg = filterAttrs (_: a: toValue {field = "config";} a != null) set;
    keys = unique (filter (v: v != null) (map getFile (attrValues withCfg)));
  in
    genAttrs keys (file: filterAttrs (_: a: getFile a == file) set);

  /**
  Build a combined grouping attrset from an application set, prefixed with
  `by`. Well-known fields (`maturity`, `protocol`, `config`, `capability`,
  `scope`) use their dedicated builders; unknown fields in `eq` use `mkEq`
  and unknown fields in `member` use `mkMember`.

  # Type
  ```nix
  mkStandard :: {
    set    :: AttrSet,
    eq     :: [string],  # optional, default []
    member :: [string],  # optional, default []
    fields :: [string],  # optional, default [] — well-known semantic fields
  } -> AttrSet
  ```

  # Examples
  ```nix
  mkStandard {
    set    = { ... };
    eq     = ["role"];
    member = ["engine"];
    fields = ["protocol" "maturity"];
  }
  # => { byRole = ...; byEngine = ...; byProtocol = ...; byMaturity = ...; }

  # Well-known fields use dedicated builders
  mkStandard { set = { ... }; fields = ["capability"]; }
  # => { byCapability = { acceleration = ...; compositing = ...; }; }
  ```
  */
  mkStandard = {
    set,
    eq ? [
      "compositor"
      "kind"
      "role"
      "scope"
      "surface"
      "toolkit"
    ],
    member ? [
      "config.lang"
      "engine"
      "greeters"
      "layouts"
      "panel"
      "shells"
    ],
    fields ? ["capability" "protocol" "maturity"],
  }: let
    perField = {
      maturity = mkMaturity {inherit set;};
      protocol = mkProtocol {inherit set;};
      config = mkConfig {inherit set;};
      capability = mkCapability {inherit set;};
      scope = mkScope {inherit set;};
    };
    allFields = unique (eq ++ member ++ fields);
  in
    filterAttrs (_: v: v != {}) (
      listToAttrs (map (field: {
          name = toName {
            inherit field;
            prefix = "by";
          };
          value =
            perField.${
              field
            } or (
              if isIn field eq
              then mkEq {inherit set field;}
              else mkMember {inherit set field;}
            );
        })
        allFields)
    );
in
  _.meta.mkModuleExports {
    directory = __moduleDir;
    filename = __moduleName;
    doc = ''
      Application group builders (Layer 3).

      Provides semantic grouping functions that partition an application set
      by well-known fields (maturity, protocol, scope, capability, config),
      and a composable standard grouping builder used by section constructors.
      All group keys are prefixed with "by" via mkNamed.

      Depends on: applications {queries, primitives, selection}.
    '';

    functions =
      default
      // {
        inherit
          mkCapability
          mkConfig
          mkMaturity
          mkProtocol
          mkScope
          mkStandard
          ;
        mk = mkStandard;
      };
  }
