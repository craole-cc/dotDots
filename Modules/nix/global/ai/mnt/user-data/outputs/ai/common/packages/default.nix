{
  description,
  dots,
  env,
  ...
}: let
  inherit (dots) pkgs lib;
  inherit (lib.attrsets) attrValues recursiveUpdate;

  apps = {
    common = {
      inherit
        (pkgs)
        coreutils
        gum
        procps
        curl
        jq
        ;
    };
    api = {inherit (pkgs) curl jq;};
    ollama = {inherit (pkgs) ollama;};
    # hermes's own runtime packages (agent CLI, telegram bindings) are
    # resolved inside agents/hermes/default.nix itself via env.pkgsFor,
    # not here - common no longer knows agent-specific package names.
    hermes = {};
  };

  runtimes = let
    common = attrValues apps.common;
    api = attrValues apps.api;
    ollama = attrValues apps.ollama;
    hermes = attrValues apps.hermes;
    default = common;
    all = default ++ ollama ++ hermes;
  in {
    inherit
      common
      api
      ollama
      hermes
      default
      all
      ;
  };

  paths = {};

  derived = import ../commands {
    inherit
      apps
      description
      dots
      env
      paths
      runtimes
      ;
  };
in {
  inherit apps paths runtimes;
  env = recursiveUpdate env derived.mergedEnv;
  packages = derived.packages ++ runtimes.all;
}
