{
  # host,
  # lix,
  ...
}: let
  # style = lix.modules.home.style.mkStyle {inherit host;};
  # inherit (style) accent catppuccin flavor;
  # TODO: This should not have to be forced. Something is wrong upstream with how catppuccin is defined in style.
  enable = true;
  accent = "teal";
  flavor = "frappe";
in {
  catppuccin = {
    inherit accent enable flavor;
    autoEnable = enable;
    cache = {inherit enable;};
  };
}
