{ pkgs, ... }:
let
  my-python-packages = p: with p; [
    pandas
    requests
    # other python packages
  ];
in
{
  environment.systemPackages = with pkgs; [
    python3
    black
  ];
}
# let
#   my-python-packages = p: with p; [
#     pandas
#     requests
#     # other python packages
#   ];
# in
# {
#   environment.systemPackages = [
#     (pkgs.python3.withPackages my-python-packages)
#   ];
# }
