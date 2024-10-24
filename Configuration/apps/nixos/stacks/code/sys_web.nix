{ ... }:

{
  imports = [
    #/> Languages                                   <\
    ../../packages/code/language/nix
    # ../../packages/code/language/javascript
    # ../../packages/code/language/python
    # ../../packages/code/language/rust
    ../../packages/code/language/shellscript

    #/> Editor                                      <\
    ../../packages/code/editor/vscode
    ../../packages/code/editor/helix
    # ../../packages/code/editor/neovim

    #/> Addons                                      <\

  ];
}
