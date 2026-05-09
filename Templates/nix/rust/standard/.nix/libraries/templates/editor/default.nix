let
  mkSource = group: name: ./. + "/${group}/${name}";
  mkEntry = group: name: {
    source = mkSource group name;
    target = ".${group}/${name}";
  };
in {
  editorconfig = {
    base = {
      source = ./common/editorconfig;
      target = ".editorconfig";
    };
  };

  vscode = {
    settings = mkEntry "vscode" "settings.json";
    extensions = mkEntry "vscode" "extensions.json";
    tasks = mkEntry "vscode" "tasks.json";
    launch = mkEntry "vscode" "launch.json";
  };

  helix = {
    config = mkEntry "helix" "config.toml";
    languages = mkEntry "helix" "languages.toml";
  };

  zed = {
    settings = mkEntry "zed" "settings.json";
    tasks = mkEntry "zed" "tasks.json";
  };

  rust-rover = {
    rust = mkEntry "idea" "rust.xml";
    misc = mkEntry "idea" "misc.xml";
    cargo-run = mkEntry "idea" "runConfigurations/cargo.xml";
    cargo-test = mkEntry "idea" "runConfigurations/tests.xml";
  };

  neovim = {
    neoconf = {
      source = mkSource "neovim" "neoconf.json";
      target = ".neoconf.json";
    };
    config = {
      source = mkSource "neovim" "nvim.lua";
      target = ".nvim.lua";
    };
  };
}
