{ config, lib, ... }:
with lib;
with types;

with config.dot;
with dib;
with sources.internal;
{
  options.dot.source.internal = {

    dot = mkOption {
      description = "The main entrypoint to the config";
      example = "/dots";
      default = toString locateProjectRoot;
      type = path;
    };

    flake = mkOption {
      description = "The main entrypoint to the config";
      example = "/dots";
      default = locateParentByChildren [
        "flake.nix"
        "flake.lock"
      ];
      type = nullOr path;
    };

    environment = mkOption {
      description = "The environment files and modules";
      default = dot + "/src/environments";
      example = "/dots/src/environments";
      type = path;
    };

    library = mkOption {
      description = "The library files and modules";
      default = dot + "/src/libraries";
      example = "/dots/src/libraries";
      type = path;
    };

    package = mkOption {
      description = "The library files and modules";
      default = dot + "/src/packages";
      example = "/dots/src/packages";
      type = path;
    };

    module = mkOption {
      description = "The dotfiles modules";
      default = dot + "/src/modules";
      example = "/dots/src/modules";
      type = path;
    };

    binary = mkOption {
      description = "The dotfiles bin/scripts directory";
      default = [
        (dot + "/bin")
        (libraries + "/shellscript")
      ];
      example = [ "/dots/bin" ];
      type = listOf path;
    };

    host = mkOption {
      description = "Host configuration directory";
      type = path;
      default = dot + "/src/configurations/hosts";
    };

    user = mkOption {
      description = "Host configuration directory";
      default = dot + "/src/configurations/users";
      type = path;
    };

    template = {
      host = mkOption {
        description = "The template for the host configuration";
        type = path;
        default = dot + "/src/templates/host.nix";
      };

      user = mkOption {
        description = "The template for the user configuration";
        type = path;
        default = dot + "/src/templates/user.nix";
      };
    };
  };
}
