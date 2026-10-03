{
  lib,
  pkgs,
  config,
  ...
}: {inherit (import ./. {inherit lib pkgs config;}) imports;}
