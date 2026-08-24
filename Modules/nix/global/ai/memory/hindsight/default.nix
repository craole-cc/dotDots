args @ {HOME ? "/home/craole", ...}: let
  environment = import ./environment.nix args;
  packages = import ./packages.nix args;
in {
  inherit environment;
  env = environment;
  inherit (packages) packages;

  shellHook = ''
    if [ -t 1 ]; then
      printf '%s\n' 'Hindsight shell: hindsight-up, hindsight-down, hindsight-status, hindsight-verify'
      printf '%s\n' "API URL: $HINDSIGHT_API_URL"
    fi
  '';
}
