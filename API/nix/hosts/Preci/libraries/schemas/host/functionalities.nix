{
  lib,
  lix,
  ...
}: let
  inherit (lib.attrsets) attrNames;
  inherit (lib.lists) filter unique;
  inherit (lix.debug) requireThat;

  default = [];

  allowed = {
    audio = {};
    battery = {};
    bluetooth = {};
    efi = {};
    gpu = {};
    keyboard = {};
    network = {};
    secureboot = {};
    storage = {};
    touchpad = {};
    tpm = {};
    video = {};
    virtualization = {};
    vpn = {};
    wired = {};
    wireless = {};
    webcam = {};
  };

  resolve = {args ? {}}: let
    names = unique (attrNames (args.functionalities or {}));
    unknown = filter (name: !(allowed ? ${name})) names;
    context = "resolve host functionalities";
  in
    assert requireThat {
      inherit context;
      condition = unknown == [];
      message = "unknown functionalities: ${toString unknown}";
    }; names;
in {inherit default resolve;}
