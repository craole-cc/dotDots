{
  mkExtensionSettings,
  mkExtensionEntry,
  ...
}: {
  ExtensionSettings = mkExtensionSettings {
    "{446900e4-71c2-419f-a6a7-df9c091e268b}" = mkExtensionEntry {
      id = "bitwarden-password-manager";
      pinned = true;
    };
    "addon@darkreader.org" = mkExtensionEntry {
      id = "darkreader";
      pinned = true;
    };
    "wappalyzer@crunchlabz.com" = mkExtensionEntry {
      id = "wappalyzer";
      pinned = true;
    };
    "uBlock0@raymondhill.net" = mkExtensionEntry {
      id = "ublock-origin";
      pinned = true;
    };
    "{a4c4eda4-fb84-4a84-b4a1-f7c1cbf2a1ad}" = "refined-github-";
    "{85860b32-02a8-431a-b2b1-40fbd64c9c69}" = "github-file-icons";
    "{762f9885-5a13-4abd-9c77-433dcd38b8fd}" = "return-youtube-dislikes";
    "{74145f27-f039-47ce-a470-a662b129930a}" = "clearurls";
    "github-no-more@ihatereality.space" = "github-no-more";
    "github-repository-size@pranavmangal" = "gh-repo-size";
    "firefox-extension@steamdb.info" = "steam-database";
    "@searchengineadremover" = "searchengineadremover";
    "jid1-BoFifL9Vbdl2zQ@jetpack" = "decentraleyes";
    "trackmenot@mrl.nyu.edu" = "trackmenot";
    "{861a3982-bb3b-49c6-bc17-4f50de104da1}" = "custom-user-agent-revived";
    "{3579f63b-d8ee-424f-bbb6-6d0ce3285e6a}" = "chameleon-ext";
  };
}
