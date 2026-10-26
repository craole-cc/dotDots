{
  lix,
  user,
  cfg,
  ...
}: let
  inherit (lix.attrsets.construction) optionalAttrs;
  inherit (lix.lists.access) head;
  ids = user.git.identities or [];
  licence = optionalAttrs (ids != []) ((head ids).license or {});
in {
  name = "admin";
  description = "Administration & Secuirity";
  enable = true;
  extensions = [
    "jbro.vscode-default-keybindings"
    "ultram4rine.vscode-choosealicense"
    #? Justfile syntax highlighting
    # "nefrob.vscode-just-syntax"
    #? mise version manager integration
    # "hverlin.mise-vscode"
    #? Reload window command
    "natqe.reload"
  ];
  keybindings = [
    {
      key = "ctrl+alt+l";
      command = "license.addDefaultLicense";
    }
    {
      key = "ctrl+shift+l";
      command = "license.chooseLicense";
    }
    {
      key = "ctrl+alr+l";
      command = "license.chooseMultipleLicenses";
    }
  ];

  settings = {
    #~@ Choose a License
    license = {
      #> Author for licenses.
      author = licence.author or "Craig 'Craole' Cole";

      #> Default license.
      default = licence.default or "mit";

      #> License file extension.
      #? - "": Create licenses without extension
      #? - .md: Create licenses with .md extension
      #? - .txt: Create licenses with .txt extension
      extension = "";

      #> License filename.
      filename = "LICENSE";

      #> Token for api access.
      token = "";

      #> Year for licenses.
      #? Set 'auto' for automatic year detection.
      year = "auto";
    };

    #~@ Update
    update = {
      #> Configure whether you receive automatic updates. The updates are fetched from a Microsoft online service.
      #? - none: Disable updates.
      #? - manual: Disable automatic background update checks. Updates will be available if you manually check for updates.
      #? - start: Check for updates only on startup. Disable automatic background update checks.
      #? - default: Enable automatic update checks. Code will check for updates automatically and periodically.
      mode = "manual";

      #> Show a post-install update tooltip in the title bar
      #? Alternative to opening the release notes editor.
      showPostInstallInfo = true;

      #> Show Release Notes after an update.
      #? The Release Notes are fetched from a Microsoft online service.
      showReleaseNotes = true;

      #> Show the update indicator in the title bar.
      titleBar = true;
    };

    #~@ Extensions
    # The extension directory is declared by Nix. Letting the editor update
    # extensions installs `<id>-<version>` copies that the next activation
    # prunes, which leaves the editor cache pointing at missing paths.
    extensions = {
      #> Disable automatic extension updates.
      autoUpdate = false;

      #> Disable automatic extension update checks.
      autoCheckUpdates = false;
    };

    #~@ Security
    security = {
      #> Confirm before a local file or workspace opens through a protocol handler.
      promptForLocalFileProtocolHandling = true;

      #> Confirm before a remote file or workspace opens through a protocol handler.
      promptForRemoteFileProtocolHandling = true;

      workspace.trust = {
        #> Controls when the restricted mode banner is shown.
        #? - always: Show the banner every time an untrusted workspace is open.
        #? - untilDismissed: Show the banner when an untrusted workspace is opened until dismissed.
        #? - never: Do not show the banner when an untrusted workspace is open.
        banner = "untilDismissed";

        #> Controls whether or not the empty window is trusted by default within VS Code.
        #? When used with `security.workspace.trust.untrustedFiles`, you can enable the full functionality of VS Code without prompting in an empty window.
        emptyWindow = true;

        #> Controls whether or not Workspace Trust is enabled within VS Code.
        enabled = true;

        #> Controls when the startup prompt to trust a workspace is shown.
        #? - always: Ask for trust every time an untrusted workspace is opened.
        #? - once: Ask for trust the first time an untrusted workspace is opened.
        #? - never: Do not ask for trust when an untrusted workspace is opened.
        startupPrompt = "never";

        #> Controls how to handle opening untrusted files in a trusted workspace.
        #? This setting also applies to opening files in an empty window which is trusted via `security.workspace.trust.emptyWindow`.
        #? - prompt: Ask how to handle untrusted files for each workspace. Once untrusted files are introduced to a trusted workspace, you will not be prompted again.
        #? - open: Always allow untrusted files to be introduced to a trusted workspace without prompting.
        #? - newWindow: Always open untrusted files in a separate window in restricted mode without prompting.
        untrustedFiles = "open";
      };
    };

    #~@ VSCode Default Keybindings
    vscode-default-keybindings = {
      #> Enable default Windows VSCode keybindings
      windowsKeybindings = true;

      #> Enable default Linux VSCode keybindings
      linuxKeybindings = false;

      #> Enable default MacOS default VSCode keybindings
      macOSKeybindings = false;

      #> Remove OS default VSCode keybindings
      removeOSKeybindings = false;
    };

    json.schemaDownload = {
      enable = true;
      trustedDomains = let
        mkCatppuccinStr = schema: let
          version = cfg.features.ui.catppuccin.package.version;
        in "https://raw.githubusercontent.com/catppuccin/vscode/catppuccin-vsc-v${version}/packages/catppuccin-vsc/schemas/${schema}.schema.json";
      in {
        "https://developer.microsoft.com/json-schemas/" = true;
        "https://json-schema.org/" = true;
        "https://json.schemastore.org/" = true;

        #~@ Formatters
        "https://biomejs.dev" = true;
        "https://dprint.dev" = true;

        #~@ Themes
        "${mkCatppuccinStr "colorOverrides"}" = true;
        "${mkCatppuccinStr "customUIColors"}" = true;
        "https://raw.githubusercontent.com/devcontainers/spec/" = true;
        "https://raw.githubusercontent.com/microsoft/vscode/" = true;
        "https://schemastore.azurewebsites.net/" = true;
        "https://www.schemastore.org/" = true;
      };
    };
  };
}
