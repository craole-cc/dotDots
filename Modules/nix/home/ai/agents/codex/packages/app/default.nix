{
  lix,
  cfg,
  tools,
  host,
  user,
  ...
}: let
  inherit (lix.options.construction) mkEnable mkOption;
  inherit (lix.modules.construction) mkIf;
  inherit (lix.lists.predicates) isIn;
  inherit (lix.schema.packages) selectedPackages;
  inherit (lix.types.primitives) package;

  selectedApplications = selectedPackages user;

  isGraphical =
    isIn
    (host.type or (host.specs.machine or null))
    ["desktop" "laptop"];
in {
  options.app = {
    enable = mkEnable {
      description = ''
        Install the ChatGPT desktop app (it also runs Codex) alongside the CLI.
        Defaults to on when ChatGPT is selected and the host is a desktop or laptop.
      '';
      condition = isIn selectedApplications ["chatgpt"] && isGraphical;
    };

    package = mkOption {
      type = package;
      default = tools.records.chatgpt.package;
      description = "Desktop application for ChatGPT and Codex, from the flake inputs.";
    };
  };

  outputs = mkIf cfg.app.enable {home.packages = [cfg.app.package];};
}
