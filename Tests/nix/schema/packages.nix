{lix ? (import ../../.. {}).libraries.default}: let
  inherit (lix) lib;
  inherit (builtins) deepSeq tryEval;
  inherit (lix.attrsets.access) attrNames;
  inherit (lix.lists.access) length;
  inherit (lix.schema.packages) merge normalize resolve toApplications;

  browsers = ["chromium" "zen-twilight" "brave"];
  base.packages.browser = browsers;
  priority.packages.browser.primary = "zen-twilight";
  browserOf = record: (resolve {inherit record;}).browser;
  legacyOf = record:
    toApplications {
      inherit (normalize {inherit record;}) packages;
      legacy = record.applications or {};
    };
  rejects = record: !(tryEval (deepSeq (resolve {inherit record;}) true)).success;
  terminals = ["foot" "ghostty" "kitty" "warp-terminal" "alacritty" "wezterm"];
  resolvedTerminals = lix.schema.applications.mkApplications {
    host = {};
    user.packages.terminal = terminals;
  };
  manyNames = map (index: "tool-${toString index}") (lib.range 1 30);
  manyApps = lix.applications.resolution.mkApp {
    appMap = lib.genAttrs manyNames (name: {
      pkg = name;
      cmd = name;
      inputPath = null;
    });
  };
  agentNames = ["hermes-desktop" "chatgpt" "claude-desktop" "claude-code" "codex" "ollama"];
  zenUser = {
    name = "demo";
    packages.browser = ["chromium" "brave" "firefox" "vivaldi" "floorp" "zen-twilight"];
  };
  zenModule = user:
    import ../../../Modules/nix/home/browser/zen {
      inherit lix lib user;
      config = {};
      host = {};
      paths = {};
      style = {};
    };
  chatgptModule = user:
    import ../../../Modules/nix/home/ai/agents/codex/packages/app {
      inherit lix user;
      cfg = {};
      tools = {};
      host.type = "laptop";
    };

  api = {
    paths = {
      roots = {};
      stems = {};
    };
    users.demo = base;
    hosts.demo = {
      system = "x86_64-linux";
      paths.roots.repo = "/tmp/package-schema";
      packages.kernel = "linuxPackages_latest";
      principals = [
        {
          name = "demo";
          enable = true;
          autoLogin = false;
          role = "administrator";
          applications.browser.primary = "zen-twilight";
        }
      ];
    };
  };
  schema = lix.schema.construction.mkSchema {inherit api;};
  hostGroups =
    (lix.schema.construction.mkSchema {
      api = lib.recursiveUpdate api {hosts.demo.packages.browser.primary = "brave";};
    }).hosts.demo;
  tests = {
    testString = {
      expr = browserOf {packages.browser = "brave";};
      expected = ["brave"];
    };
    testListOrder = {
      expr = browserOf base;
      expected = browsers;
    };
    testRoles = {
      expr = browserOf {
        packages.browser = {
          tertiary = "brave";
          primary = "zen-twilight";
          secondary = "chromium";
        };
      };
      expected = ["zen-twilight" "chromium" "brave"];
    };
    testSparseRole = {
      expr = browserOf {packages.browser.tertiary = "brave";};
      expected = ["brave"];
    };
    testPromotion = {
      expr = browserOf (merge base priority);
      expected = ["zen-twilight" "chromium" "brave"];
    };
    testPrioritySurvivesLaterList = {
      expr = browserOf (merge priority base);
      expected = ["zen-twilight" "chromium" "brave"];
    };
    testPrioritySurvivesLaterString = {
      expr = browserOf (merge priority {packages.browser = "brave";});
      expected = ["zen-twilight" "brave"];
    };
    testLaterRoleWins = {
      expr = browserOf (merge (merge base priority) {packages.browser.primary = "brave";});
      expected = ["brave" "chromium" "zen-twilight"];
    };
    testLaterListReplacesOrdinaryList = {
      expr = browserOf (merge base {packages.browser = "brave";});
      expected = ["brave"];
    };
    testNullClearsRole = {
      expr = browserOf (merge priority {packages.browser.primary = null;});
      expected = [];
    };
    testEmptyList = {
      expr = browserOf {packages.browser = [];};
      expected = [];
    };
    testNormalisationIsIdempotent = {
      expr = let
        once = normalize {record = base;};
      in
        normalize {record = once;} == once;
      expected = true;
    };
    testCanonicalSchemaDoesNotEmitLegacyInput = {
      expr = (normalize {record.applications.browser.primary = "brave";}) ? applications;
      expected = false;
    };
    testCanonicalListCanBeReplacedWithoutSyntheticRoles = {
      expr = let
        once = normalize {record = base;};
      in
        (normalize {record = once // {packages.browser = ["firefox"];};}).packages.browser;
      expected = ["firefox"];
    };
    testLegacyUtilityNormalisationIsIdempotent = {
      expr = let
        once = normalize {
          record.applications.utilities = {
            btop.enable = true;
            tmux.enable = false;
          };
        };
      in
        normalize {record = once;} == once;
      expected = true;
    };
    testDuplicateRemoval = {
      expr = browserOf {packages.browser = ["brave" "chromium" "brave"];};
      expected = ["brave" "chromium"];
    };
    testLegacyName = {
      expr = browserOf {applications.browser = "brave";};
      expected = ["brave"];
    };
    testLegacyRolePromotesNewList = {
      expr = browserOf (base // {applications.browser.primary = "zen-twilight";});
      expected = ["zen-twilight" "chromium" "brave"];
    };
    testNewRoleOverridesLegacyRole = {
      expr = browserOf {
        applications.browser.primary = "chromium";
        packages.browser.primary = "brave";
      };
      expected = ["brave"];
    };
    testLegacyEditors = {
      expr = resolve {
        record.applications.editor = {
          tty.primary = "helix";
          gui.primary = "zed";
        };
      };
      expected = {
        editor = ["helix"];
        ide = ["zed"];
      };
    };
    testLegacyEditorMetadataDoesNotSuppressDefaults = {
      expr =
        (lix.schema.applications.mkApplications {
          host = {};
          user.applications.editor.gui.visual = "code";
        }).legacy.raw.editor.gui.primary;
      expected = "vscode";
    };
    testAgentGroupAlias = {
      expr = resolve {record.applications.ai.primary = "codex";};
      expected.ai-agent = ["codex"];
    };
    testArbitraryGroups = {
      expr = resolve {
        record.packages = {
          research = "tool";
          media = ["mpv" "imv"];
        };
      };
      expected = {
        research = ["tool"];
        media = ["mpv" "imv"];
      };
    };
    testLegacyUtilities = {
      expr =
        (normalize {
          record.applications.utilities = {
            btop.enable = true;
            tmux.enable = false;
          };
        }).packages.utilities;
      expected = ["btop"];
    };
    testNewUtilitiesProjectFlags = {
      expr =
        (legacyOf {
          applications.utilities.btop.enable = true;
          packages.utilities = ["tmux"];
        }).utilities;
      expected = {
        btop.enable = false;
        tmux.enable = true;
      };
    };
    testLegacyUtilitiesList = {
      expr = (legacyOf {applications.utilities = ["tmux"];}).utilities;
      expected.tmux.enable = true;
    };
    testLegacyUtilitiesMergeByKey = {
      expr =
        (normalize {
          record = merge {
            applications.utilities = {
              btop.enable = true;
              tmux.enable = true;
            };
          } {applications.utilities.tmux.enable = false;};
        }).packages.utilities;
      expected = ["btop"];
    };
    testLegacyUtilitiesSurviveIdentityLayer = {
      expr =
        (normalize {
          record = merge (merge {} {applications.utilities.btop.enable = true;}) (merge {} {applications.utilities.tmux.enable = true;});
        }).packages.utilities;
      expected = ["btop" "tmux"];
    };
    testHostPolicyFields = {
      expr = resolve {
        record.packages = {
          kernel = "linuxPackages_latest";
          allowUnfree = false;
          browser = "brave";
        };
      };
      expected = {
        kernel = "linuxPackages_latest";
        allowUnfree = false;
        browser = ["brave"];
      };
    };
    testProtocolOverride = {
      expr =
        (resolve {
          record = merge base {packages.browser.wayland.primary = "zen-twilight";};
          protocol = "wayland";
        }).browser;
      expected = ["zen-twilight" "chromium" "brave"];
    };
    testOtherProtocolDoesNotApply = {
      expr =
        (resolve {
          record = merge base {packages.browser.wayland.primary = "zen-twilight";};
          protocol = "xorg";
        }).browser;
      expected = browsers;
    };
    testProtocolBranchesDoNotReachConsumers = {
      expr =
        (lix.schema.applications.mkApplications {
          host = {};
          user = {
            applications.browser.wayland.primary = "brave";
            interface.displayProtocol = "wayland";
          };
        }).legacy.raw.browser ? wayland;
      expected = false;
    };
    testLegacyEditorProtocolOverride = {
      expr = resolve {
        record.applications.editor = {
          tty.primary = "helix";
          gui.primary = "vscode";
          wayland.tty.primary = "neovim";
        };
        protocol = "wayland";
      };
      expected = {
        editor = ["neovim"];
        ide = ["vscode"];
      };
    };
    testFourthSelectionRemainsAvailable = {
      expr = (legacyOf {packages.browser = browsers ++ ["firefox"];}).allowed;
      expected = browsers ++ ["firefox"];
    };
    testResolvedApplicationsRetainEveryEntry = {
      expr = map (entry: entry.name) resolvedTerminals.terminal;
      expected = terminals;
    };
    testSixthApplicationHasCommandMetadata = {
      expr = (lib.elemAt resolvedTerminals.terminal 5).command;
      expected = "wezterm";
    };
    testRolePromotionRetainsFullResolvedList = {
      expr =
        map (entry: entry.name)
        (lix.schema.applications.mkApplications {
          host.packages.terminal = terminals;
          user.packages.terminal.primary = "wezterm";
        }).terminal;
      expected = ["wezterm" "foot" "ghostty" "kitty" "warp-terminal" "alacritty"];
    };
    testThirtyApplicationsRetainMetadata = {
      expr =
        map (entry: entry.command)
        (lix.schema.applications.mkApplications {
          host = {};
          user.packages.research = manyNames;
        }).research;
      expected = manyNames;
    };
    testPackageResolutionRetainsThirtyApplications = {
      expr = manyApps.packages {
        pkgs = {};
        config = manyNames;
      };
      expected = manyNames;
    };
    testCommandResolutionRetainsThirtyApplications = {
      expr =
        (manyApps.commands {
          pkgs = {};
          config = manyNames;
        }).all;
      expected = manyNames;
    };
    testFifthSelectionEnablesApplicationDirectly = {
      expr =
        (lix.applications.generators.userApplication {
          user.packages.research = manyNames;
          pkgs = {};
          name = "tool-5";
          kind = "research";
          customPackage = {
            type = "derivation";
            outPath = "/nix/store/00000000000000000000000000000000-tool-5";
            meta.mainProgram = "tool-5";
          };
        }).isAllowed;
      expected = true;
    };
    testSessionVariableForSixthApplication = {
      expr =
        (import ../../../Modules/nix/home {
          inherit lix;
          apps = resolvedTerminals;
          top = "dotDots";
        }).config.home.sessionVariables.TERMINAL_6.content;
      expected = "wezterm";
    };
    testEditorResolutionRetainsEverySelection = {
      expr = lix.applications.resolution.editors.packages {
        pkgs = lib.genAttrs ["helix" "neovim" "vim" "nano" "emacs" "vscode-fhs" "vscodium" "zed-editor-fhs" "sublime4"] (name: name);
        config = {
          tty = ["helix" "neovim" "vim" "nano" "emacs"];
          gui = ["vscode" "vscodium" "zed" "sublime"];
        };
      };
      expected = ["helix" "neovim" "vim" "nano" "emacs" "vscode-fhs" "vscodium" "zed-editor-fhs" "sublime4"];
    };
    testEmptyEditorCommands = {
      expr = lix.applications.resolution.editors.commands {
        pkgs = {};
        config = {
          tty = [];
          gui = [];
        };
      };
      expected = {
        editor = null;
        visual = null;
      };
    };
    testGuiOnlyEditorCommands = {
      expr = lix.applications.resolution.editors.commands {
        pkgs = {};
        config = {
          tty = [];
          gui = ["vscode"];
        };
      };
      expected = {
        editor = null;
        visual = "code";
      };
    };
    testEmptyGroupsDoNotEmitNullSystemVariables = {
      expr =
        (import ../../../Modules/nix/core/environment/variables.nix {
          inherit lix;
          config = {};
          inputs = {};
          names.src = "dots";
          pkgs.stdenv.hostPlatform.system = "x86_64-linux";
          paths = {
            roots.repo = "/tmp/package-schema";
            variablesByRoot.home.WALLPAPERS = "$HOME/Pictures/Wallpapers";
          };
          host = {
            paths.roots.repo = "/tmp/package-schema";
            users.data.primary.packages = {
              browser = [];
              editor = [];
              ide = ["vscode"];
              terminal = [];
              launcher = [];
              bar = [];
            };
          };
        }).options._.resolved.environment.variables.explicit.default.default;
      expected = {
        DOTS = "/tmp/package-schema";
        VISUAL = "code";
        WALLPAPERS = "$HOME/Pictures/Wallpapers";
      };
    };
    testUnknownBrowserStillHasMetadata = {
      expr =
        map (entry: entry.command)
        (lix.schema.applications.mkApplications {
          host = {};
          user.packages.browser = manyNames;
        }).browser;
      expected = manyNames;
    };
    testAllSelectedAgentsHaveMetadata = {
      expr =
        map (entry: entry.command)
        (lix.schema.applications.mkApplications {
          host = {};
          user.packages.ai-agent = agentNames;
        }).ai-agent;
      expected = ["hermes-desktop" "chatgpt" "claude-desktop" "claude" "codex" "ollama"];
    };
    testOllamaEnabledAtSixthPosition = {
      expr =
        (import ../../../Modules/nix/core/ai/agents/ollama {
          inherit lix;
          config = {};
          pkgs = {};
          host.users.data.primary.packages.ai-agent = agentNames;
        }).options._.resolved.ai.agents.ollama.explicit.enable.default;
      expected = true;
    };
    testUnselectedOllamaStaysDisabled = {
      expr =
        (import ../../../Modules/nix/core/ai/agents/ollama {
          inherit lix;
          config = {};
          pkgs = {};
          host.users.data.primary.packages.ai-agent = ["codex"];
        }).options._.resolved.ai.agents.ollama.explicit.enable.default;
      expected = false;
    };
    testHermesEnabledAtFifthPosition = {
      expr =
        (import ../../../Modules/nix/core/ai/agents/hermes {
          inherit lix;
          config = {};
          host.users.data.primary.packages.ai-agent = ["one" "two" "three" "four" "hermes-desktop"];
        }).options._.resolved.ai.agents.hermes-agent.explicit.enable.default;
      expected = true;
    };
    testChatgptEnabledAtSixthPosition = {
      expr = (chatgptModule {packages.ai-agent = ["one" "two" "three" "four" "codex" "chatgpt"];}).options.app.enable.default;
      expected = true;
    };
    testCodexSelectionDoesNotSelectDesktop = {
      expr = (chatgptModule {packages.ai-agent = ["one" "two" "three" "codex"];}).options.app.enable.default;
      expected = false;
    };
    testZenEnabledAtSixthPosition = {
      expr = (zenModule zenUser).options._.resolved.browser.zen.explicit.enable.default;
      expected = true;
    };
    testEmptyBrowserSelectionDisablesZen = {
      expr =
        (zenModule {
          name = "demo";
          packages.browser = [];
        }).options._.resolved.browser.zen.explicit.enable.default;
      expected = false;
    };
    testSixthBrowserImportsZenModule = {
      expr =
        (lix.modules.home.programs.mkApps {
          user = zenUser;
          inputs = {};
          modules = {};
        }).zen-browser.isAllowed;
      expected = true;
    };
    testFourthPanelImportsDmsModule = {
      expr =
        (lix.modules.home.programs.mkApps {
          user.packages.bar = ["custom-panel" "waybar" "caelestia" "dms-shell"];
          inputs = {};
          modules = {};
        }).dms-shell.isAllowed;
      expected = true;
    };
    testCanonicalSelectionFeedsApplicationRoles = {
      expr =
        (lix.schema.applications.mkApplications {
          host = {};
          user = base;
        }).legacy.raw.browser;
      expected = {
        primary = "chromium";
        secondary = "zen-twilight";
        tertiary = "brave";
      };
    };
    testEmptySelectionDoesNotResolveNullApp = {
      expr =
        (lix.schema.applications.mkApplications {
          host = {};
          user.packages.browser = [];
        }).browser;
      expected = [];
    };
    testSchemaNormalisesGlobalUser = {
      expr = schema.users.demo.packages.browser;
      expected = browsers;
    };
    testPrincipalLegacyRolePromotesGlobalList = {
      expr = schema.hosts.demo.users.data.primary.packages.browser;
      expected = ["zen-twilight" "chromium" "brave"];
    };
    testGlobalRoleSurvivesPrincipalList = {
      expr =
        (lix.schema.construction.mkSchema {
          api = lib.recursiveUpdate api {
            users.demo = priority;
            hosts.demo.principals = [
              {
                name = "demo";
                enable = true;
                autoLogin = false;
                role = "administrator";
                packages.browser = "brave";
              }
            ];
          };
        }).hosts.demo.users.data.primary.packages.browser;
      expected = ["zen-twilight" "brave"];
    };
    testHostKernelSurvivesConstruction = {
      expr = schema.hosts.demo.packages.kernel;
      expected = "linuxPackages_latest";
    };
    testHostPolicyDoesNotBecomeUserGroup = {
      expr = schema.hosts.demo.users.data.primary.packages ? kernel;
      expected = false;
    };
    testHostPackageSettingsDoNotExposeStagingRecords = {
      expr = hostGroups.settings.pkg.browser;
      expected = ["brave"];
    };
    testHostPackageSettingsAliasesAgree = {
      expr = hostGroups.settings.packages == hostGroups.packages;
      expected = true;
    };
    testHostRequirementsSurviveUserPreferences = {
      expr =
        (lix.schema.applications.mkApplications {
          host.packages = {
            terminal = ["ghostty"];
            editor = ["nano"];
            coding = ["nix"];
            kernel = "cachyos";
            core = ["nixpkgs"];
            home = ["home-manager"];
          };
          user.packages.terminal = ["foot"];
        }).requiredPackages;
      expected = ["nano" "ghostty"];
    };
    testApplicationNeededAcrossGroups = {
      expr = map (group:
        (lix.schema.applications.mkApplications {
          host = {};
          user.packages = {
            explorer = [];
            ${group} = ["yazi"];
          };
        }).needs "yazi") ["extra" "utilities" "custom"];
      expected = [true true true];
    };
    testApplicationNotSelected = {
      expr = (lix.schema.applications.mkApplications {
        host = {};
        user.packages.explorer = [];
      }).needs "yazi";
      expected = false;
    };
    testApplicationNeededByHost = {
      expr = (lix.schema.applications.mkApplications {
        host.packages.explorer = ["yazi"];
        user.packages.explorer = [];
      }).needs "yazi";
      expected = true;
    };
    testInvalidElement = {
      expr = rejects {packages.browser = ["brave" 1];};
      expected = true;
    };
    testInvalidRole = {
      expr = rejects {packages.browser.primary = ["brave"];};
      expected = true;
    };
    testUnknownRoleField = {
      expr = rejects {packages.browser.primray = "brave";};
      expected = true;
    };
    testUnknownUtilityRoleField = {
      expr = rejects {packages.utilities.primray = "btop";};
      expected = true;
    };
  };
in {
  total = length (attrNames tests);
  failures = lib.runTests tests;
}
