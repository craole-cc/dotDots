{ config, lib, ... }:
let
  cfg = config.dots.sources.home-manager;
in
with builtins;
with lib;
with types;
{

  options.dots.sources.home-manager = {
    enable = mkEnableOption "Home-Manager Source";
    source = mkOption {
      description = "The path to the home-manager source";
      default =
        let
          channel = __tryEval <home-manager>;
          tarball = fetchTarball {
            url = "https://github.com/nix-community/home-manager/archive/master.tar.gz";
            sha256 = "1fd7631c8f5l1ma5ksn8i57xhx5iiwqw9mwf5cxis3hmq7z9wpk6";
          };
        in
        import "${if channel.success then channel.value else tarball}/nixos";
      # type = path; 
      # TODO: `config.dots.sources.home-manager.source` is a lamda function but needs to be a path. 
    };
  };

  # TODO:how can `config.dots.sources.home-manager.source` be imported without risk of infinite recursion?
  # imports = [ cfg.source ];
}
