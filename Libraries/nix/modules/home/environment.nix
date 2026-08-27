{_, ...}: let
  inherit (_.schema) locale;

  mkLocale = {
    host,
    user ? {},
  }:
    locale.defaults
    // (host.localization or {})
    // (user.localization or {});

  __exports = {
    internal = {inherit mkLocale;};
    external = {
      mkUserLocale = mkLocale;
    };
  };
in
  __exports.internal // {__rootAliases = __exports.external;}
