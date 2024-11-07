{ ... }:
{
  imports = [
    #/> Core                                                       <\
    ./core
    ../../configuration

    #/> Desktop Manager                                            <\
    ../../services/manager/desktop
    # ../../services/manager/desktop/xfce-minimal.nix
    ../../services/manager/desktop/xfce.nix

    #/> Display Manager                                            <\
    ../../services/manager/display
    ../../services/manager/display/sddm.nix

    #/> Window Manager                                             <\
    ../../services/manager/window
    # ../../services/manager/window/bspwm.nix
    ../../services/manager/window/qtile.nix
    # ../../services/manager/window/herbstluftwm.nix

    #/> Shell                                                      <\
    # ../../packages/code/language/nushell

    #/> Development                                                <\
    # ../../packages/code/language/python
    ../../packages/code/language/nix
    ../../packages/code/language/shellscript
    ../../packages/code/editor/vscode
    ../../packages/code/editor/helix
    # ../../stacks/code/sys_web.nix
    # ../../packages/data

    #/> Packages                                                   <\
    ../../packages/base/X11.nix
    ../../packages/app
    ../../packages/core
    ../../packages/style
    ../../packages/utility
    ../../packages/web

    #/> Users                                                   <\
    # ../../clients/craole/home/default.nix
    # ../../clients/craole/default.nix
    # ../../clients/craole/dev
  ];

  services.xserver.displayManager = {
    defaultSession = "none+qtile";
    autoLogin = {
      enable = true;
      user = "craole";
    };
  };
}
