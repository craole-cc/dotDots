{ ... }:

{
  environment.sessionVariables = rec {
    #> STORAGE
    DATA_STORE = "\${HOME}";

    #> DOWNLOADS
    DOWNLOADS = "\${DATA_STORE}/Downloads";
    MUSIC = "\${DOWNLOADS}/Music";
    MOVIES = "\${DOWNLOADS}/Videos";
    TUTORIALS = "\${DOWNLOADS}/Tutorials";
    BOOKS = "\${DOWNLOADS}/Books";
    WALLPAPER = "\${DOWNLOADS}/Wallpapers";
    DOTFILES = "\${DOWNLOADS}/Dotfiles";

    #> DOTS
    DOTS = "\${DATA_STORE}/DOTS";
    DOTS_CFG = "\${DOTS}/Config";
    DOTS_APP = "\${DOTS_CFG}/apps";
    DOTS_TOOL = "\${DOTS_CFG}/tools";
    DOTS_CLI = "\${DOTS_CFG}/cli";
    DOTS_ENV = "$\{DOTS}/Environment";
    DOTS_CTX = "$\{DOTS_ENV}/context";
    DOTS_BIN = "$\{DOTS}/Bin";

    #> PROJECTS
    PROJECTS = "\${DATA_STORE}/Projects";

    #> PICTURES
    PICTURES = "\${DATA_STORE}/Pictures";
  };
}
