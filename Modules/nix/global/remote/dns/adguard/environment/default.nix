# environment/default.nix
{
  lix,
  env,
  ...
}: let
  inherit (lix.attrsets.aggregation) recursiveUpdate;
  inherit (lix.strings.transformation) toUpper;

  HOME = "/home/craole-cc";
  target = env.name or "adguard";
  prefix = toUpper target;

  tag = name: "${target}-${name}";
  set = name: value: {"${prefix}_${name}" = value;};
  get = name: vars."${prefix}_${name}";

  vars =
    set "BIND_ADDRESS" "100.76.128.70"
    // set "DNS_PORT" "53"
    // set "WEB_PORT" "3000"
    // set "WEB_URL" "http://100.76.128.70:3000"
    // set "DATA_DIR" "${HOME}/data/${target}"
    // set "CONFIG_FILE" "${HOME}/data/${target}/AdGuardHome.yaml";
in {
  title = "AdGuard Home Tailnet DNS";
  env = recursiveUpdate env vars;
  lib = {inherit target prefix get set tag;};
}
