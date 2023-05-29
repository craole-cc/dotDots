{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.zfs-root.Home.craole.modules.firefox;
  inherit (lib) mkOption types mkIf;
in {
  options.zfs-root.Home.craole.modules.firefox = {
    enable = mkOption {
      type = types.bool;
      default = config.zfs-root.Home.craole.enable;
    };
  };
  config = mkIf cfg.enable {
    programs.firefox = {
      enable = true;
      package = pkgs.firefox-esr;
      policies = {
        "3rdparty" = {
          Extensions = {
            "uBlock0@raymondhill.net" = {
              adminSettings = {
                userSettings = {
                  advancedUserEnabled = true;
                  popupPanelSections = 31;
                };
                dynamicFilteringString = ''
                  * * * block
                  * * image block
                  * * inline-script block
                  * * 1p-script block
                  * * 3p block
                  * * 3p-script block
                  * * 3p-frame block'';
                hostnameSwitchesString = ''
                  no-cosmetic-filtering: * true
                  no-remote-fonts: * true
                  no-csp-reports: * true
                  no-scripting: * true
                '';
              };
            };
          };
        };
        # captive portal enabled for connecting to free wifi
        CaptivePortal = true;
        DisableBuiltinPDFViewer = true;
        DisableFirefoxAccounts = true;
        DisableFirefoxStudies = true;
        DisableFormHistory = true;
        DisablePocket = true;
        DisableTelemetry = true;
        DisplayMenuBar = "never";
        DNSOverHTTPS = {Enabled = false;};
        EncryptedMediaExtensions = {Enabled = false;};
        ExtensionSettings = {
          "uBlock0@raymondhill.net" = {
            installation_mode = "force_installed";
            install_url = "https://addons.mozilla.org/firefox/downloads/latest/ublock-origin/latest.xpi";
          };
        };
        FirefoxHome = {
          SponsoredTopSites = false;
          Pocket = false;
          SponsoredPocket = false;
        };
        HardwareAcceleration = true;
        Homepage = {StartPage = "none";};
        NetworkPrediction = false;
        NewTabPage = false;
        NoDefaultBookmarks = false;
        OfferToSaveLogins = false;
        OfferToSaveLoginsDefault = false;
        OverrideFirstRunPage = "";
        OverridePostUpdatePage = "";
        PasswordManagerEnabled = false;
        PDFjs = {Enabled = false;};
        Permissions = {
          Location = {BlockNewRequests = true;};
          Notifications = {BlockNewRequests = true;};
        };
        PictureInPicture = {Enabled = false;};
        PopupBlocking = {Default = false;};
        PromptForDownloadLocation = true;
        SanitizeOnShutdown = true;
        SearchSuggestEnabled = false;
        ShowHomeButton = true;
        UserMessaging = {
          WhatsNew = false;
          SkipOnboarding = true;
        };
      };
    };
  };
}
