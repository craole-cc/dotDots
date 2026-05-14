{ _, ... }:
let
  inherit (_.schema.locale) defaults;

  mkLocale =
    {
      host,
      user ? { },
    }:
    let
      loc = defaults // (host.localization or { }) // (user.localization or { });
    in
    loc;

  __exports = {
    internal = { inherit mkLocale; };
    external = {
      mkUserLocale = mkLocale;
    };
  };
in
__exports.internal // { __rootAliases = __exports.external; }
