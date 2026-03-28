{
  browsers = import ./browsers.nix;
  terminals = import ./terminals.nix;
  editors = import ./editors.nix;
  fileManagers = import ./file-managers.nix;
  graphics = import ./graphics.nix;
  launchers = import ./launchers.nix;
  media = import ./media.nix;
  office = import ./office.nix;
  system = import ./system.nix;
  communication = import ./communication.nix;
}
