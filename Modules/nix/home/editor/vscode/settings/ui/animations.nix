{
  fonts,
  lix,
  ...
}: let
  inherit (lix.applications.editors) mkVSCodeSetting;
in {
  name = "animations";
  description = "Animations";
  extensions = [
    "brandonkirbyson.vscode-animations"
    "subframe7536.custom-ui-style"
    "be5invis.vscode-custom-css"
  ];
  keybindings = [];

  settings = {
    #~@ Animations
    animations = {
      #> Install method used to inject the animations.
      #? Relies on the Custom UI Style extension, so it needs a writable VS Code install.
      Install-Method = "Custom UI Style";

      CursorAnimation = true;

      #> Object-valued setting: keep as a real attrset, do not flatten
      CursorAnimationOptions = mkVSCodeSetting {
        Color = "teal";
        CursorStyle = "block";
        TrailLength = 8;
      };
    };

    #~@ Custom UI Style
    custom-ui-style = {
      font = {inherit (fonts.families) sansSerif monospace;};

      reloadWithoutPrompting = true;
      watch = true;
    };
  };
}
