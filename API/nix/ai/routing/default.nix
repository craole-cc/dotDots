{
  lix,
  homePath,
  profile,
  model,
  offPeakModel,
  environmentFiles ? [],
}: let
  inherit (lix.strings.construction) toJSON fromJSON;
  inherit (lix.filesystem.access) readFile;
  policy = {
    version = 1;
    date_convention = "UTC";
    source = "https://www.beijing.gov.cn/zhengce/zhengcefagui/202511/t20251104_4258873.html";
    utc_windows = [[240 360] [600 1500]];
    calendar = fromJSON (readFile ./calendar.json);
    profiles.${profile} = {
      otherwise = {
        inherit (model) provider;
        model = model.default;
      };
      off_peak = {
        provider = "deepseek";
        model = offPeakModel;
      };
    };
  };
in {
  home.file."routing-policy.json" = toJSON policy;
  environment.files = environmentFiles;
  settings.scheduled_routes = {
    enabled = true;
    policy_file = "${homePath}/profiles/${profile}/routing-policy.json";
  };
}
