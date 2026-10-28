let
  git = [
    {
      id = "craole-cc";
      name = "craole-cc";
      email = "134658831+craole-cc@users.noreply.github.com";
      root = "craole-cc";
      licence = {
        name = "Craig 'Craole' Cole";
        type = "mit";
      };
    }
    {
      id = "craole";
      name = "Craole";
      email = "32288735+Craole@users.noreply.github.com";
      root = "Craole";
      licence = {
        name = "Craig 'Craole' Cole";
        type = "mit";
      };
    }
  ];
  writing = {};
  conferencing = {};
  development = {
    languages.rust = {
      channel = "nightly";
      components = ["rust-src" "rust-analyzer" "rustfmt" "clippy"];
    };
  };
  creation = {};
  analysis = {};
  management = {};
  gaming = {};
  multimedia = {};
  skills = {inherit writing conferencing development creation analysis management gaming multimedia;};
in {
  #TODO: Rename to skills downstream
  capabilities = skills;
  inherit skills git;
}
