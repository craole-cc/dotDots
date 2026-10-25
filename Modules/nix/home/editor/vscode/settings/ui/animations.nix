{
  fonts,
  lix,
  pkgs,
  inputs,
  cfg,
  ...
}: let
  inherit (lix.applications.editors) mkVSCodeSetting;
  inherit (lix.attrsets.resolution) vscodePackage;
  inherit (lix.lists.construction) optional;
  wallpaperScript = import ../../build/wallpaper-script.nix {inherit pkgs lix;};
  animations = vscodePackage {
    inherit pkgs inputs;
    entry = "brandonkirbyson.vscode-animations";
    default = throw "The VS Code Animations extension is required for animation script injection.";
  };
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
      # Nix owns the script import. The installer's versioned-path check does
      # not recognise Home Manager's extension links and repeatedly prompts.
      Auto-Install = false;

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
      # Run our driver before the animation bundle's CommonJS trailer.
      external.imports =
        optional (cfg.features.ui.transparency or false) "file://${wallpaperScript}"
        ++ [
          "file://${animations}/share/vscode/extensions/brandonkirbyson.vscode-animations/dist/updateHandler.js"
        ];
      font = {inherit (fonts.families) sansSerif monospace;};

      reloadWithoutPrompting = true;
      watch = true;
    };
  };
}
