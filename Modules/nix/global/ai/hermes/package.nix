{
  description,
  dots,
  env,
  ...
}: let
  inherit (dots) pkgs lib inputPkgs pythonPkgs;
  inherit (lib.attrsets) attrValues;

  apps = {
    common = {inherit (pkgs) coreutils gum procps curl jq;};
    api = {inherit (pkgs) curl jq;};
    hermes = {
      agent = (inputPkgs "hermes-agent").default;
      telegram = pythonPkgs.withPackages (pkg: [pkg.python-telegram-bot]);
      inherit (pkgs) openai nodejs_22 jq;
    };
    ollama = {inherit (pkgs) ollama;};
  };

  paths = {
    hermes = apps.hermes.agent.outPath;
    telegram = "${apps.hermes.telegram}/lib/python3.12/site-packages";
  };

  runtimes = let
    common = attrValues apps.common;
    api = attrValues apps.api;
    ollama = attrValues apps.ollama;
    hermes = attrValues apps.hermes;
    default = common;
    all = default ++ ollama ++ hermes;
  in {
    inherit common api ollama hermes default all;
  };

  derived = import ./commands {
    inherit apps description dots paths runtimes;
  };
in {
  inherit apps paths runtimes;
  exports = derived ++ runtimes.all;
}
