{ pkgs, ... }:

{
  environment = {
    variables = {
      EDIT_WITH = "hx";
    };
    systemPackages = with pkgs; [
      kitty
      alacritty
    ];
  };
}
