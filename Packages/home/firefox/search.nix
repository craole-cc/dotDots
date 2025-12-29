{
  icons,
  host,
  ...
}: let
  inherit (icons.nixos) snowflake;
  inherit (host) stateVersion;
  inherit (host.packages) allowUnstable;

  branch = unstable:
    if allowUnstable
    then unstable
    else stateVersion;

  core = {
    channel = branch "unstable";
    icon = icons.nixos.snowflake;
  };
  home = branch "master";
in {
  search = {
    default = "google";
    privateDefault = "brave";

    engines = {
      bing = {
        name = "Bing";
        urls = [
          {template = "https://www.bing.com/search?q={searchTerms}";}
        ];
        metaData = {
          alias = "@mb";
        };
      };

      brave = {
        name = "Brave";
        urls = [
          {template = "https://search.brave.com/search?q={searchTerms}";}
        ];
        definedAliases = ["b" "@b"];
      };

      github = {
        name = "GitHub";
        urls = [
          {template = "https://github.com/search?q={searchTerms}";}
        ];
        definedAliases = ["gh" "@gh"];
      };

      google = {
        metaData.alias = "@g";
      };

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
        urls = [
          {
            template = "https://home-manager-options.extranix.com/";
            params = [
              {
                name = "release";
                value = home;
              }
              {
                name = "query";
                value = "{searchTerms}";
              }
            ];
          }
        ];
        icon = snowflake;
        definedAliases = ["hm" "@hm"];
      };

      nix-packages = {
        inherit (core) icon;
        name = "NixOS Packages";
        urls = [
          {
            template = "https://search.nixos.org/packages";
            params = [
              {
                name = "channel";
                value = core.channel;
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
        inherit (core) icon;
        name = "NixOS Options";
        urls = [
          {
            template = "https://search.nixos.org/";
            params = [
              {
                name = "channel";
                value = core.channel;
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
        inherit (core) icon;
        name = "NixOS Wiki";
        urls = [{template = "https://wiki.nixos.org/w/index.php?search={searchTerms}";}];
        # iconMapObj."16" = "https://wiki.nixos.org/favicon.ico";
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
        definedAliases = ["@p"];
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
        definedAliases = [
          "@dict"
          "@wd"
        ];
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
      "perplexity"
      "google"
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
}
