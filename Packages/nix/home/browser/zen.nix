{
  user,
  config,
  pkgs,
  tree,
  ...
}: let
  #~@ Universal Zen launcher
  #> Prefers twilight → beta → zen → $BROWSER
  script =
    pkgs.writeShellScript "zen.sh"
    (builtins.readFile (tree.lib.sh.local + "/packages/wrappers/zen.sh"));

  launcher = pkgs.writeShellScriptBin "zen" ''
    exec ${script} "$@"
  '';
in {
  home.packages = [launcher];

  programs.zen-browser = {
    # enable = true;
    profiles.default = {
      bookmarks = {
        force = true;
        settings = [
          {
            name = "For Nix";
            toolbar = true;
            bookmarks = [
              {
                name = "homepage";
                url = "https://nixos.org/";
              }
              {
                name = "wiki";
                tags = ["wiki" "nix"];
                url = "https://wiki.nixos.org/";
              }
            ];
          }
        ];
      };

      search = {
        default = "brave";
        privateDefault = "brave";
        engines = {
          bing = {
            name = "Bing";
            urls = [{template = "https://www.bing.com/search?q={searchTerms}";}];
            metaData.alias = "@mb";
          };
          brave = {
            name = "Brave";
            urls = [{template = "https://search.brave.com/search?q={searchTerms}";}];
            definedAliases = ["br" "@br"];
          };
          github = {
            name = "GitHub";
            urls = [{template = "https://github.com/search?q={searchTerms}";}];
            definedAliases = ["gh" "@gh"];
          };
          google.metaData.alias = "@g";
          google-images = {
            name = "Google Images";
            urls = [
              {
                template = "https://www.google.com/search";
                params = [
                  {
                    name = "tbm";
                    value = "isch";
                  }
                  {
                    name = "q";
                    value = "{searchTerms}";
                  }
                ];
              }
            ];
            definedAliases = ["gi" "@gimg"];
          };
          home-manager-options = {
            name = "Home Manager Options";
            iconMapObj."16" = "https://nix-community.github.io/nixos-facter-modules/latest/assets/images/logo.png";
            urls = [
              {
                template = "https://home-manager-options.extranix.com/";
                params = [
                  {
                    name = "release";
                    value = "master";
                  }
                  {
                    name = "query";
                    value = "{searchTerms}";
                  }
                ];
              }
            ];
            definedAliases = ["hm" "@hm"];
          };
          nix-packages = {
            name = "NixOS Packages";
            urls = [
              {
                template = "https://search.nixos.org/packages";
                params = [
                  {
                    name = "channel";
                    value = "unstable";
                  }
                  {
                    name = "query";
                    value = "{searchTerms}";
                  }
                ];
              }
            ];
            definedAliases = ["np" "@p"];
          };
          nixos-options = {
            name = "NixOS Options";
            urls = [
              {
                template = "https://search.nixos.org/";
                params = [
                  {
                    name = "channel";
                    value = "unstable";
                  }
                  {
                    name = "query";
                    value = "{searchTerms}";
                  }
                ];
              }
            ];
            definedAliases = ["no" "@o"];
          };
          nixos-wiki = {
            name = "NixOS Wiki";
            urls = [{template = "https://wiki.nixos.org/w/index.php?search={searchTerms}";}];
            iconMapObj."16" = "https://wiki.nixos.org/favicon.ico";
            definedAliases = ["nw" "@nw"];
          };
          noogle = {
            name = "Noogle Dev";
            urls = [
              {
                template = "https://noogle.dev/q";
                params = [
                  {
                    name = "term";
                    value = "{searchTerms}";
                  }
                ];
              }
            ];
            definedAliases = ["@l" "nl"];
          };
          perplexity = {
            name = "Perplexity";
            urls = [
              {
                template = "https://www.perplexity.ai/search";
                params = [
                  {
                    name = "q";
                    value = "{searchTerms}";
                  }
                ];
              }
            ];
            definedAliases = ["@px" "px"];
          };
          wikipedia = {
            name = "Wiktionary";
            urls = [
              {
                template = "https://en.wiktionary.org/wiki/Special:Search";
                params = [
                  {
                    name = "search";
                    value = "{searchTerms}";
                  }
                ];
              }
            ];
            definedAliases = ["@wp"];
          };
          wiktionary = {
            name = "Wiktionary";
            urls = [
              {template = "https://en.wiktionary.org/w/index.php?search={searchTerms}";}
              {
                template = "https://en.wiktionary.org/wiki/%s";
                params = [
                  {
                    name = "search_query";
                    value = "{searchTerms}";
                  }
                ];
              }
            ];
            definedAliases = ["@dict" "@wd"];
          };
          youtube = {
            name = "YouTube";
            urls = [
              {
                template = "https://www.youtube.com/results";
                params = [
                  {
                    name = "search_query";
                    value = "{searchTerms}";
                  }
                ];
              }
            ];
            definedAliases = ["@yt"];
          };
          youglish = {
            name = "YouGlish";
            urls = [{template = "https://youglish.com/pronounce/{searchTerms}/english";}];
            definedAliases = ["@yg"];
          };
        };
        order = [
          "google"
          "perplexity"
          "google-images"
          "nix-packages"
          "nixos-options"
          "home-manager-options"
          "bing"
          "brave"
          "nixos-wiki"
          "github"
          "wiktionary"
          "wikipedia"
          "youtube"
          "youglish"
        ];
      };

      settings = {
        "browser.profiles.enabled" = true;
        "browser.profiles.default" = "default";
        "privacy.trackingprotection.enabled" = true;
        "privacy.resistFingerprinting" = false;
        "privacy.donottrackheader.enabled" = true;
        "browser.urlbar.suggest.searches" = false;
        "browser.urlbar.suggest.history" = true;
        "browser.urlbar.suggest.bookmark" = true;
        "browser.urlbar.suggest.openpage" = true;
        "toolkit.tabbox.switchByScrolling" = true;
        "browser.tabs.loadInBackground" = true;
        "browser.tabs.warnOnClose" = false;
        "media.videocontrols.picture-in-picture.enabled" = true;
        "media.autoplay.default" = 0;
        "gfx.webrender.all" = true;
        "general.smoothScroll" = true;
        "mousewheel.default.delta_multiplier_y" = 100;
        "browser.download.useDownloadDir" = true;
        "browser.download.folderList" = 1;
        "zen.workspaces.continue-where-left-off" = true;
        "zen.workspaces.natural-scroll" = true;
        "zen.workspaces.swipe-actions" = true;
        "zen.view.compact.hide-tabbar" = true;
        "zen.view.compact.hide-toolbar" = true;
        "zen.view.compact.animate-sidebar" = false;
        "zen.welcome-screen.seen" = true;
        "zen.urlbar.behavior" = "float";
        "zen.theme.accent-color" = "#6366f1";
        "zen.theme.gradient" = true;
        "zen.theme.gradient.show-custom-colors" = false;
        "zen.view.gray-out-inactive-windows" = true;
        "zen.watermark.enabled" = true;
        "zen.tabs.rename-tabs" = true;
        "zen.tabs.dim-pending" = true;
        "zen.ctrlTab.show-pending-tabs" = true;
        "zen.mediacontrols.enabled" = true;
        "zen.mediacontrols.show-on-hover" = true;
        "zen.glance.enable-contextmenu-search" = true;
        "zen.glance.show-bookmarks" = true;
        "zen.glance.show-history" = true;
        "zen.tab-unloader.enabled" = true;
        "zen.tab-unloader.delay" = 300;
        "zen.tab-unloader.excluded-urls" = "https://meet.google.com,https://app.slack.com";
        "zen.view.experimental-rounded-view" = false;
        "zen.theme.content-element-separation" = 8;
      };
    };

    policies = {
      AutofillAddressEnabled = true;
      AutofillCreditCardEnabled = false;
      DefaultDownloadDirectory = user.paths.downloads or config.home.homeDirectory;
      DisableAppUpdate = true;
      DisableFeedbackCommands = true;
      DisableFirefoxStudies = true;
      DisablePocket = true;
      DisableTelemetry = true;
      DontCheckDefaultBrowser = true;
      OfferToSaveLogins = false;
      PictureInPicture = true;
      EnableTrackingProtection = {
        Value = true;
        Locked = true;
        Cryptomining = true;
        Fingerprinting = true;
      };
      SanitizeOnShutdown = {
        FormData = true;
        Cache = true;
      };
    };
  };
}
