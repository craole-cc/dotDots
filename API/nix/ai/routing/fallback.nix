{
  lix,
  homePath,
  profile,
  ...
}: let
  inherit (lix.filesystem.access) readFile;
  inherit (lix.strings.construction) toJSON fromJSON;
  policy = {
    version = 1;
    date_convention = "UTC";
    utc_windows = [[240 360] [600 1500]];
    calendar = fromJSON (readFile ./calendar.json);
  };
in {
  home.file."fallback-policy.json" = toJSON policy;
  settings = {
    fallback_model = null;
    fallback_providers = [
      {
        provider = "deepseek";
        model = "deepseek-flash";
        off_peak_policy_file = "${homePath}/profiles/${profile}/fallback-policy.json";
      }
    ];
  };
}
