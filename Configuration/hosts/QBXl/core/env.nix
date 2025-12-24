{
  paths,
  config,
  dots,
  ...
}: {
  environment = with dots.environment; {
    inherit shellAliases shellInit;
    variables =
      variables
      // {
        DOTS = paths.flake.${config.networking.hostName};
      };
  };
  # environment = {
  #   inherit (dots) shellAliases;
  #   variables = dots.variables // {
  #     DOTS = local;
  #   };
  #   # TODO: Add the bins to PATH

  #   systemPackages = [
  #     (writeShellScriptBin "dotshell" ''
  #       dev "${local}"
  #     '')
  #     (writeShellScriptBin "dev" ''
  #       set -e
  #       chmod +x "${devScript}"
  #       "${devScript}" "$@"
  #     '')
  #     (writeShellScriptBin "eda" ''
  #       set -e
  #       chmod +x "${edaScript}"
  #       "${edaScript}" "$@"
  #     '')
  #   ];
  # };
}
