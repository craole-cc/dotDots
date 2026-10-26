{
  lix ? (import ../.. {}).libraries.default,
  pkgs ? import <nixpkgs> {},
  inputs ? {},
}: let
  inherit (lix) lib;
  inherit (lix.applications.editors) flattenVSCodeSetting mkVSCodeSetting mkVSCodeSubFeature normalizeSettings;
  inherit (lix.modules.construction) mkForce mkIf mkMerge;
  inherit (lix.options.construction) mkEnable;
  toolkit = lix.sources.packages.mkToolkit {inherit pkgs inputs;};
  context = {
    dom = "editor";
    sub = null;
    mod = "vscode";
    wantsDmsShell.condition = false;
  };
  entryArgs = {
    inherit lix context mkEnable;
    requires = _name: true;
  };

  baseline = builtins.fromJSON (builtins.readFile ../../Configuration/vscode/settings.json);
  settingNames = builtins.attrNames baseline;
  flatten = flattenVSCodeSetting {inherit settingNames;};
  entry = path:
    (mkVSCodeSubFeature ((import path entryArgs)
      // {
        enable = true;
        inherit settingNames;
      })).effectiveSettings;
  nixSettings = entry ../../Modules/nix/home/editor/vscode/settings/lang/nix.nix;
  javascript = entry ../../Modules/nix/home/editor/vscode/settings/lang/web.nix;
  python = entry ../../Modules/nix/home/editor/vscode/settings/lang/python.nix;
  resolveProfileWithImports = importJSON: features: let
    args =
      entryArgs
      // {
        inherit pkgs inputs toolkit;
        cfg = evaluated.config // {inherit importJSON;};
        requires = names: builtins.any (name: builtins.elem name ["rust" "python" "zig" "nix" "shell"]) (lib.toList names);
        fonts.families = {
          monospace = "monospace";
          sansSerif = "sans-serif";
        };
        style = {
          catppuccin = true;
          mode = "dark";
          opacity.editor.dark = 0.9;
        };
        user = {
          git.identities = [];
          firewall.tcp.ports = [];
        };
        host.access.remote = {
          ssh.enable = false;
          tailscale.enable = false;
        };
        paths.store.cfg.default = ../../Configuration;
      };
    settings = import ../../Modules/nix/home/editor/vscode/settings args;
    evaluated = lib.evalModules {
      modules = [
        {inherit (settings) options;}
        {config.features = features;}
      ];
    };
  in
    settings.output // {features = evaluated.config.features;};
  resolveProfile = resolveProfileWithImports false;
  enabledProfile = resolveProfile {};
  disabledFeatures = lib.genAttrs ["ai" "app" "dev" "doc" "ui"] (_name: {enable = false;});
  disabledProfile = resolveProfile disabledFeatures;
  importedProfile = resolveProfileWithImports true {};
  customCatppuccin = (pkgs.vscode-extensions.catppuccin.catppuccin-vsc).overrideAttrs (_previous: {
    version = "99.0.0";
    __intentionallyOverridingVersion = true;
  });
  customProfile = resolveProfile {ui.catppuccin.package = customCatppuccin;};
  noCatppuccinProfile = resolveProfile {ui.catppuccin.enable = false;};
  profile = enabledProfile.userSettings;
  terminalBinding = {
    key = "ctrl+alt+`";
    command = "workbench.action.terminal.kill";
  };
  evaluate = value:
    (lib.evalModules {
      modules = [
        {
          options.settings = lib.mkOption {type = toolkit.types.json;};
          config.settings = value;
        }
      ];
    }).config.settings;

  checks = {
    toolkitFormatTypesAndWritersAreAvailable = builtins.all (
      name:
        lib.isFunction toolkit.types.${name}.check && builtins.isFunction toolkit.write.${name}
    ) ["json" "toml" "yaml" "ini"];
    toolkitOptionConstructorsAreAvailable = (toolkit.options.mkEnable {condition = false;}).default == false;
    structuredFeatureExposesPackage = enabledProfile.features.ui.catppuccin.package.version != "";
    simpleFeaturesRemainBooleans = builtins.isBool enabledProfile.features.ui.dms && builtins.isBool enabledProfile.features.dev.web;
    customPackageIsInstalled = builtins.elem customCatppuccin customProfile.extensions;
    schemaVersionFollowsPackage = customProfile.userSettings."json.schemaDownload.trustedDomains" ? "https://raw.githubusercontent.com/catppuccin/vscode/catppuccin-vsc-v99.0.0/packages/catppuccin-vsc/schemas/colorOverrides.schema.json";
    disabledCatppuccinIsNotInstalled = !(builtins.any (extension: extension.vscodeExtUniqueId == enabledProfile.features.ui.catppuccin.package.vscodeExtUniqueId) noCatppuccinProfile.extensions);
    disabledCatppuccinChangesTheme = noCatppuccinProfile.userSettings."workbench.colorTheme" == "Dark 2026";
    toolkitJSONTypeMergesObjects =
      evaluate (mkMerge [{nested.left = true;} {nested.right = false;}])
      == {
        nested = {
          left = true;
          right = false;
        };
      };
    webCategoryIsLoaded = profile."vs-browser.url" == "http://127.0.0.1:3000";
    webObjectValuesRemainObjects = profile."vs-browser.favourites.list"."http://localhost" == "http://localhost";
    rustSnippetObjectsArePreserved =
      profile."rust-analyzer.completion.snippets.custom"."Arc::new".body
      == "Arc::new(\${receiver})"
      && !(profile ? "rust-analyzer.completion.snippets.custom.Arc::new.body");
    rustSourceFileMapIsPreserved = profile."rust-analyzer.debug.sourceFileMap" == "auto";
    rustStatusBarObjectIsPreserved = profile."rust-analyzer.statusBar.showStatusBar" ? documentSelector;
    explicitObjectValueNeedsNoCatalogue =
      flattenVSCodeSetting "" {
        extension.custom = mkVSCodeSetting {nested.value = true;};
      }
      == {"extension.custom".nested.value = true;};
    markedKnownSettingIsUnwrapped =
      flatten {
        editor.tokenColorCustomizations = mkVSCodeSetting {textMateRules = [];};
      }
      == {"editor.tokenColorCustomizations".textMateRules = [];};
    markedValuePreservesPriority =
      evaluate (flatten {
        editor.tokenColorCustomizations = mkForce (mkVSCodeSetting {textMateRules = [];});
      })
      == {"editor.tokenColorCustomizations".textMateRules = [];};
    JSONFallbackDisabledByDefault = builtins.all (name: !(builtins.hasAttr name profile)) [
      "direnv.restart.automatic"
    ];
    disabledGroupsProduceEmptySettingsWithoutImports = disabledProfile.userSettings == {};
    javascriptColourRuleIsDefinedOnce =
      builtins.length (builtins.filter
        (rule: (rule.scope or null) == (builtins.head javascript."editor.tokenColorCustomizations".textMateRules).scope)
        profile."editor.tokenColorCustomizations".textMateRules)
      == 1;
    nestedExecutorMapUsesSharedObjectBoundary =
      profile."code-runner.executorMap".zig
      == "cd $dir && zig build run"
      && profile."code-runner.executorMap" ? rust
      && !(profile ? "code-runner.executorMap.zig");
    disabledEntriesDoNotFallBackToJSON = builtins.all (name: !(builtins.hasAttr name profile)) [
      "harper.dialect"
      "codeium.enableSearch"
      "continue.enableTabAutocomplete"
      "geminicodeassist.inlineSuggestions.enableAuto"
      "rubyLsp.enableExperimentalFeatures"
      "terminal.integrated.profiles.windows"
    ];
    disabledGroupsDoNotFallBackToJSON = builtins.all (name: !(builtins.hasAttr name disabledProfile.userSettings)) [
      "[nix]"
      "nix.serverSettings"
      "workbench.iconTheme"
      "github.copilot.enable"
      "harper.dialect"
    ];
    JSONFallbackCanBeEnabled = importedProfile.userSettings."direnv.restart.automatic" == baseline."direnv.restart.automatic";
    enabledEntryKeybindingIsNotDuplicated =
      builtins.length (builtins.filter (binding: binding == terminalBinding) enabledProfile.keybindings) == 1;
    disabledGroupKeybindingsDoNotFallBackToJSON = !(builtins.elem terminalBinding disabledProfile.keybindings);
    disabledGroupsHaveNoKeybindings = disabledProfile.keybindings == [];
    profilePassesSettingNamesToEntries =
      profile."nix.serverSettings"
      == nixSettings."nix.serverSettings"
      && profile."[nix]" == nixSettings."[nix]"
      && profile."lintRunner.tools" ? statix
      && profile."lintRunner.tools" ? shellcheck;
    profilePreservesMergedColourRules =
      builtins.length profile."editor.tokenColorCustomizations".textMateRules
      > builtins.length javascript."editor.tokenColorCustomizations".textMateRules;
    nixServerSettingsRemainObjects =
      nixSettings."nix.serverSettings"
      == {
        nixd = {
          formatting.command = ["alejandra" "-q" "-"];
          diagnostic.suppress = ["sema-primop-overridden"];
        };
      };
    lintToolsRemainObjects =
      nixSettings."lintRunner.tools".statix.command
      == "statix"
      && nixSettings."lintRunner.tools".statix.parser.flags == "gm";
    languageOverridesRemainObjects =
      builtins.isAttrs nixSettings."[nix]"
      && nixSettings."[nix]"."editor.defaultFormatter" == "jnoortheen.nix-ide"
      && !(nixSettings ? "[nix].editor.defaultFormatter");
    javascriptRulesRemainInsideObject = javascript."editor.tokenColorCustomizations" ? textMateRules;
    pythonRulesRemainInsideObject = python."editor.tokenColorCustomizations" ? textMateRules;
    colourRulesMergeAcrossEntries = let
      merged = evaluate (mkMerge [javascript python]);
    in
      merged."editor.tokenColorCustomizations".textMateRules
      == javascript."editor.tokenColorCustomizations".textMateRules
      ++ python."editor.tokenColorCustomizations".textMateRules;
    explicitObjectSettingPreserved =
      flatten {"extension.object".nested.value = true;}
      == {
        "extension.object".nested.value = true;
      };
    nestedLanguageSettingsFlattened =
      flatten {"[nix]".editor.formatOnSave = true;}
      == {
        "[nix]"."editor.formatOnSave" = true;
      };
    emptySettingsRemainEmpty = flatten {} == {};
    emptySettingObjectPreserved = flatten {"extension.object" = {};} == {"extension.object" = {};};
    deeplyNestedScalarSetting =
      flatten {"rust-analyzer".diagnostics.enable = true;}
      == {
        "rust-analyzer.diagnostics.enable" = true;
      };
    legacyPrefixSupported =
      flattenVSCodeSetting "extension" {enabled = true;}
      == {
        "extension.enabled" = true;
      };
    aliasesMergeAfterFlattening =
      normalizeSettings {
        userSettings."editor.formatOnSave" = false;
        settings.editor.formatOnSave = true;
      }
      == {"editor.formatOnSave" = true;};
    moduleMergePreserved =
      evaluate (flatten (mkMerge [
        {editor.formatOnSave = false;}
        (mkIf true {editor.formatOnSave = mkForce true;})
      ]))
      == {"editor.formatOnSave" = true;};
    namespacePriorityPreserved =
      evaluate (flatten (mkForce {editor.formatOnSave = true;}))
      == {
        "editor.formatOnSave" = true;
      };
  };
in {
  total = builtins.length (builtins.attrNames checks);
  failures = builtins.filter (name: !checks.${name}) (builtins.attrNames checks);
}
