{lib, ...}: let
  inherit (lib.attrsets) recursiveUpdate;

  default = {
    writing = {};
    conferencing = {};
    development = {
      languages = {};
      tools = {};
      platforms = {};
      environment = {};
    };
    creation = {};
    analysis = {};
    management = {};
    gaming = {};
    multimedia = {};
  };

  resolve = {args ? {}}:
    recursiveUpdate default (args.capabilities or {});
in {inherit default resolve;}
