{
  envrc = {
    source = ./envrc;
    target = ".envrc";
  };
  gitignore = {
    source = ./gitignore;
    target = ".gitignore";
  };
  mise = {
    source = ./mise.toml;
    target = [".mise.toml" "mise.toml"];
  };
  shellcheck = {
    source = ./shellcheckrc;
    target = [".shellcheckrc" "shellcheckrc"];
  };
  markdownlint = {
    source = ./markdownlint-cli2.yaml;
    target = [".markdownlint-cli2.yaml" "markdownlint-cli2.yaml"];
  };
  treefmt = {
    source = ./treefmt.toml;
    target = [".treefmt.toml" "treefmt.toml"];
  };
}
