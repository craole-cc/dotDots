{
  browsers = import ./_registry/browsers.nix;
  terminals = import ./_registry/terminals.nix;
  editors = import ./_registry/editors.nix;
  fileManagers = import ./_registry/file-managers.nix;
  graphics = import ./_registry/graphics.nix;
  launchers = import ./_registry/launchers.nix;
  media = import ./_registry/media.nix;
  office = import ./_registry/office.nix;
  system = import ./_registry/system.nix;
  communication = import ./_registry/communication.nix;
}
