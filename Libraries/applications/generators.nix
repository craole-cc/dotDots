{
  _,
  lib,
  ...
}: let
  inherit (lib.attrsets) optionalAttrs;
  inherit (lib.lists) filter head unique;
  inherit (lib.meta) getExe';
  inherit (lib.modules) mkMerge;
  inherit (lib.trivial) warn boolToString;
  inherit (lib.strings) concatStringsSep optionalString toUpper;
  inherit (lib.generators) toPretty;
  inherit (_.lists.predicates) isIn;

  /**
      Create an application configuration object with role-based classification,
      environment variable generation, and platform compatibility checks.

      This function analyzes user configuration to determine if an application
      should be enabled, what role it plays (primary, secondary, or explicitly
      requested), and whether the required platform/environment is available.
      It generates appropriate environment variables following Unix conventions
      (EDITOR/VISUAL for editors) and custom conventions for other application types.

      # Inputs

      `user`

      : User configuration attrset containing application preferences.
        Expected structure:
  ```nix
        {
          applications = {
            <kind> = {
              primary = "<name>";
              secondary = "<name>";
              # OR for categorized types like editors:
              <category> = {
                primary = "<name>";
                secondary = "<name>";
              };
            };
            allowed = [ "<name>" ... ];
          };
        }
  ```

      `pkgs`

      : Nixpkgs package set used for package resolution.

      `config` (optional, default: `{}`)

      : System/home-manager configuration for platform checks.
        Used to verify Wayland availability, X11 status, etc.

      `name`

      : Application identifier (e.g., "helix", "foot", "zed-editor").
        Used as the default package name and in identifiers.

      `kind`

      : Application category (e.g., "editor", "terminal", "browser").
        Used for role classification and environment variable naming.

      `category` (optional, default: `null`)

      : Subcategory within `kind` (e.g., "tty" or "gui" for editors).
        When provided, looks up role in `user.applications.<kind>.<category>`.
        When `null`, looks up directly in `user.applications.<kind>`.

      `resolutionHints` (optional, default: `[name]`)

      : List of package name candidates to try during resolution.
        Useful when the application has aliases or alternative package names.
        Example: `["hx" "helix" "helix-editor"]`

      `customPackage` (optional, default: `null`)

      : Explicit package derivation to use instead of automatic resolution.
        Useful when you need to wrap or modify the base package.

      `customCommand` (optional, default: `null`)

      : Override the command name instead of deriving from package binary.
        Useful for wrapper scripts with different names than the base package.

      `requiresWayland` (optional, default: `false`)

      : Boolean indicating if this application requires Wayland.
        When true, checks if Wayland is available via config and user.interface.

      `requiresX11` (optional, default: `false`)

      : Boolean indicating if this application requires X11.
        When true, checks if X11 is available via config.

      # Output

      Attribute set containing:

      `name`

      : The application name (passthrough of input).

      `kind`

      : The application kind (passthrough of input).

      `category`

      : The application category (passthrough of input).

      `package`

      : Resolved package derivation.

      `command`

      : The command name to execute (binary name or custom override).

      `identifiers`

      : List of all possible identifiers for this application, including:
        - name
        - command
        - resolutionHints
        - "${name}-${kind}"
        - "${command}-${kind}"

      `isPrimary`

      : Boolean indicating if this is the user's primary choice for this kind/category.

      `isSecondary`

      : Boolean indicating if this is the user's secondary choice for this kind/category.

      `isRequested`

      : Boolean indicating if this application is in the user's allowed list.

      `isPlatformCompatible`

      : Boolean indicating if platform requirements (Wayland/X11) are satisfied.

      `isAllowed`

      : Boolean indicating if this application should be enabled.
        True only if (isPrimary OR isSecondary OR isRequested) AND isPlatformCompatible.

      `sessionVariables`

      : Attribute set of environment variables to export.
        For editors:
        - tty primary: `EDITOR`, `EDITOR_NAME`
        - tty secondary: `EDITOR_SEC`, `EDITOR_SEC_NAME`
        - gui primary: `VISUAL`, `VISUAL_NAME`
        - gui secondary: `VISUAL_SEC`, `VISUAL_SEC_NAME`

        For other kinds:
        - primary: `<KIND>`, `<KIND>_NAME`
        - secondary: `<KIND>_SEC`, `<KIND>_SEC_NAME`

      # Examples

      :::{.example}
      ## Create a TUI editor configuration
  ```nix
      app = application {
        inherit user pkgs;
        name = "helix";
        kind = "editor";
        category = "tty";
        resolutionHints = ["hx" "helix"];
      }
      # => {
      #   name = "helix";
      #   kind = "editor";
      #   category = "tty";
      #   package = <derivation helix-...>;
      #   command = "hx";
      #   isPrimary = true;
      #   isPlatformCompatible = true;  # no platform requirements
      #   isAllowed = true;
      #   sessionVariables = { EDITOR = "hx"; EDITOR_NAME = "helix"; };
      #   ...
      # }
  ```
      :::

      :::{.example}
      ## Wayland-only terminal
  ```nix
      app = application {
        inherit user pkgs config;
        name = "foot";
        kind = "terminal";
        requiresWayland = true;
        customCommand = "feet";
      }
      # => {
      #   name = "foot";
      #   isPlatformCompatible = true;  # only if Wayland is available
      #   isAllowed = true;  # only if wayland check passes
      #   ...
      # }
  ```
      :::

      :::{.example}
      ## X11-only application
  ```nix
      app = application {
        inherit user pkgs config;
        name = "xterm";
        kind = "terminal";
        requiresX11 = true;
      }
  ```
      :::

      # Type
  ```
      application :: {
        user :: AttrSet,
        pkgs :: AttrSet,
        config :: AttrSet,
        name :: String,
        kind :: String,
        category :: String | Null,
        resolutionHints :: [String],
        customPackage :: Derivation | Null,
        customCommand :: String | Null,
        requiresWayland :: Bool,
        requiresX11 :: Bool,
      } -> {
        name :: String,
        kind :: String,
        category :: String | Null,
        package :: Derivation,
        command :: String,
        identifiers :: [String],
        isPrimary :: Bool,
        isSecondary :: Bool,
        isRequested :: Bool,
        isPlatformCompatible :: Bool,
        isAllowed :: Bool,
        sessionVariables :: AttrSet,
      }
  ```
  */
  userApplication = {
    user,
    pkgs,
    config ? {},
    name,
    kind,
    category ? null,
    # modules ? {},
    extraPackages ? [],
    resolutionHints ? [name],
    customPackage ? null,
    customCommand ? null,
    requiresWayland ? false,
    requiresX11 ? false,
    debug ? false,
    ...
  }: let
    #~@ Package Resolution
    package =
      if customPackage != null
      then customPackage
      else
        _.attrsets.resolution.package {
          inherit pkgs;
          target = resolutionHints;
        };

    #> Check if package was found
    packageFound = package != null;

    #~@ Runtime Identity
    command =
      if customCommand != null
      then customCommand
      else if packageFound
      then let
        #> Try to get the binary from resolutionHints first, then fallback to name
        binaryName =
          if package ? meta.mainProgram
          then package.meta.mainProgram
          else head resolutionHints;
      in
        getExe' package binaryName
      else null; #> Return null if package not found

    basename =
      if command != null
      then baseNameOf command
      else null;

    #~@ Complete Identifiers - FILTER OUT NULL VALUES
    identifiers = unique (
      filter (x: x != null) ([
          name
          basename
        ]
        ++ resolutionHints ++ ["${name}-${kind}"])
    );

    #~@ Role Classification
    default =
      if category != null
      then user.applications.${kind}.${category} or null
      else user.applications.${kind} or null;
    isPrimary = isIn (default.primary or null) identifiers;
    isSecondary = isIn (default.secondary or null) identifiers;
    isRequested = isIn identifiers (user.applications.allowed or []);

    #~@ Platform Compatibility
    checkPlatform = requiresWayland || requiresX11;
    isWaylandAvailable =
      if requiresWayland
      then
        _.attrsets.predicates.waylandEnabled {
          inherit config;
          interface = user.interface or {};
        }
      else true;

    isX11Available =
      if requiresX11
      then config.services.xserver.enable or false # TODO: This check could fail if we're querying the home-mamager config
      else true;

    isPlatformCompatible = isWaylandAvailable && isX11Available;

    #~@ Final Allow Check
    #? Cannot allow if package wasn't found
    isAllowed = packageFound && (isPrimary || isSecondary || isRequested) && isPlatformCompatible;

    #~@ Environment
    var = toUpper kind;
    varWithCategory =
      if category != null
      then "${var}_${toUpper category}"
      else var;
    shellAliases = {}; #TODO: Add something here
    sessionVariables =
      optionalAttrs
      (kind != "editor")
      (
        if isPrimary
        then {
          "${varWithCategory}_PRI" = command;
          "${varWithCategory}_PRI_NAME" = name;
        }
        else if isSecondary
        then {
          "${varWithCategory}_SEC" = command;
          "${varWithCategory}_SEC_NAME" = name;
        }
        else {}
      )
      // optionalAttrs
      (kind == "editor" && category == "tty")
      (
        if isPrimary
        then {
          EDITOR_PRI = command;
          EDITOR_PRI_NAME = basename;
        }
        else if isSecondary
        then {
          EDITOR_SEC = command;
          EDITOR_SEC_NAME = basename;
        }
        else {}
      )
      // (
        optionalAttrs (kind == "editor" && category == "gui")
        (
          if isPrimary
          then {
            VISUAL_PRI = command;
            VISUAL_PRI_NAME = basename;
          }
          else if isSecondary
          then {
            VISUAL_SEC = command;
            VISUAL_SEC_NAME = basename;
          }
          else {}
        )
      );

    packages = [package] ++ extraPackages;

    export = {
      inherit
        basename
        category
        command
        config
        identifiers
        isAllowed
        isPlatformCompatible
        isPrimary
        isRequested
        isSecondary
        kind
        name
        package
        packages
        sessionVariables
        shellAliases
        debug
        ;
    };

    output = rec {
      role =
        optionalString
        isAllowed (
          if isPrimary
          then "Primary"
          else if isSecondary
          then "Secondary"
          else "Requested"
        );

      status =
        if isAllowed
        then "✓ ALLOWED {${role}}"
        else "✗ BLOCKED";

      variablesWithPlatform = ''
        │  Compatible: ${boolToString isPlatformCompatible}
        ${
          if requiresWayland
          then "│     Wayland: ${boolToString isWaylandAvailable}"
          else "│"
        }
        ${
          if requiresWayland
          then "│         X11: ${boolToString isX11Available}"
          else "│"
        }
        ${variables}'';

      variables =
        if sessionVariables == {}
        then "│   Variables: none"
        else toPretty {} sessionVariables;

      debug = ''
        ╭─ mkApplication ${name} ────│ ${status} │
        │        Kind: ${kind}${optionalString (category != null) " (${category})"}
        │     Command: ${
          if command != null
          then command
          else "null (package not found)"
        }
        │ Identifiers: [${concatStringsSep ", " identifiers}]
        │     Package: ${
          if packageFound
          then package.name or package
          else "not found"
        }
        ${
          if checkPlatform
          then variablesWithPlatform
          else variables
        }
        ╰──────────────────────────────
      '';
    };
    #~@ Debug Output
  in
    if debug
    then warn output.debug export
    else export;

  /**
      Generate a home-manager module configuration for an application.

      This is a convenience function that creates the standard structure for
      a home-manager program configuration with session variables and packages.
      It does NOT handle conditional logic - callers should wrap with `mkIf`
      or other module system functions as needed.

      # Inputs

      `name`

      : Application name, used as the key in `programs.<name>`.

      `package`

      : Package derivation to install.

      `extraConfig` (optional, default: `{}`)

      : Program-specific configuration to merge into `programs.<name>`.
        This is merged after the base `{ enable = true; package = ...; }`,
        allowing you to add or override any program settings.

      `sessionVariables` (optional, default: `{}`)

      : Environment variables to set in `home.sessionVariables`.

      `extraPackages` (optional, default: `[]`)

      : Additional packages to install in `home.packages`.
        Useful for wrapper scripts or companion tools.

      # Output

      Returns an attribute set with:
  ```nix
      {
        programs.<name> = {
          enable = true;
          package = <package>;
        } // <extraConfig>;

        home = {
          sessionVariables = <sessionVariables>;
          packages = <extraPackages>;
        };
      }
  ```

      # Examples

      :::{.example}
      ## Basic program configuration
  ```nix
      program {
        name = "helix";
        package = pkgs.helix;
        sessionVariables = { EDITOR = "hx"; };
      }
      # => {
      #   programs.helix = {
      #     enable = true;
      #     package = <derivation helix-...>;
      #   };
      #   home.sessionVariables = { EDITOR = "hx"; };
      # }
  ```
      :::

      :::{.example}
      ## With conditional logic (caller's responsibility)
  ```nix
      let
        app = application { ... };
      in {
        config = mkIf app.isAllowed (program {
          inherit (app) name package sessionVariables;
          extraConfig = {
            defaultEditor = app.isPrimary;
          };
        });
      }
  ```
      :::

      :::{.example}
      ## Program with additional configuration
  ```nix
      program {
        name = "foot";
        package = pkgs.foot;
        sessionVariables = { TERMINAL = "feet"; };
        extraPackages = [ feetWrapper ];
        extraConfig = {
          server.enable = true;
          settings = {
            main = {
              font = "monospace:size=12";
            };
          };
        };
      }
      # => {
      #   programs.foot = {
      #     enable = true;
      #     package = <derivation foot-...>;
      #     server.enable = true;
      #     settings = { main = { ... }; };
      #   };
      #   home = {
      #     sessionVariables = { TERMINAL = "feet"; };
      #     packages = [ <derivation feet-wrapper> ];
      #   };
      # }
  ```
      :::

      :::{.example}
      ## Merging multiple configuration sources
  ```nix
      program {
        name = "helix";
        package = pkgs.helix;
        sessionVariables = { EDITOR = "hx"; };
        extraConfig =
          { defaultEditor = true; }
          // import ./editor.nix
          // import ./keybindings.nix
          // import ./languages.nix
          // {};
      }
  ```
      :::

      # Type
  ```
      program :: {
        name :: String,
        package :: Derivation,
        extraConfig :: AttrSet,
        sessionVariables :: AttrSet,
        extraPackages :: [Derivation],
      } -> AttrSet
  ```
  */
  program = {
    config,
    isAllowed,
    name,
    package,
    extraConfig ? {},
    sessionVariables ? {},
    extraPackages ? [],
    ...
  }: let
    programs =
      optionalAttrs (config.programs ? name)
      {
        ${name} =
          {
            enable = true;
            inherit package;
          }
          // extraConfig;
      };
    home = {
      inherit sessionVariables;
      packages = [package] ++ extraPackages;
    };
    exports = {
      inherit programs home;
      # inherit config;
    };
  in
    exports;

  userApplicationConfig = {
    app ? {},
    config ? app.config or {},
    user ? app.user or {},
    pkgs ? app.pkgs or {},
    name ? app.name or null,
    kind ? app.kind or null,
    category ? app.category or null,
    requiresWayland ? app.requiresWayland or false,
    requiresX11 ? app.requiresX11 or false,
    debug ? app.debug or false,
    resolutionHints ? app.resolutionHints or [name],
    customPackage ? null,
    customCommand ? null,
    extraPackages ? [],
    extraProgramConfig ? {},
    extraVariables ? {},
    extraAliases ? {},
    ...
  }: let
    res =
      if app != {}
      then app
      else
        userApplication {
          inherit
            config
            user
            pkgs
            name
            kind
            category
            resolutionHints
            customPackage
            customCommand
            requiresWayland
            requiresX11
            debug
            ;
        };

    moduleName = res.name;
    hasHome = res.config?home;
    hasModule = res.config?programs.${moduleName};
    programModule = res.config.programs.${moduleName} or null;
    hasProgramPackage = hasModule && programModule?package;

    testVariables = optionalAttrs res.debug {
      "__${moduleName}" =
        (
          if hasHome
          then "${moduleName} is a home config"
          else "${moduleName} is a core config"
        )
        + (
          if hasModule
          then " with an existing programs module"
          else " without a programs module"
        )
        + (
          if enable
          then ". It should be enabled"
          else ". It should not be enabled"
        );
    };

    sessionVariables = res.sessionVariables // extraVariables // testVariables;
    shellAliases = res.shellAliases // extraAliases;

    inherit (res) package;
    enable = res.isAllowed;
    packages = res.packages ++ extraPackages;

    home =
      optionalAttrs hasHome
      {inherit sessionVariables shellAliases packages;};

    environment = optionalAttrs (!hasHome) {
      systemPackages = packages;
      inherit sessionVariables shellAliases;
    };

    programs = optionalAttrs hasModule {
      ${moduleName} = mkMerge [
        {inherit enable;}
        (optionalAttrs hasProgramPackage {inherit (res) package;})
        extraProgramConfig
      ];
    };

    exports = {inherit environment home programs enable;} // res;
  in
    exports;
in {
  inherit userApplication userApplicationConfig program;
  _rootAliases = {
    mkUserApplication = userApplicationConfig;
    mkProgram = program;
  };
}
