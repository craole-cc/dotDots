{
  # host,
  # user,
  # policies,
  ...
}: {
  # This will show up in the home-manager build output
  # warnings = [
  #   "Host: ${host.name or "unknown"}"
  #   "User: ${user.name or "unknown"}"
  #   "Role: ${user.role or "unknown"}"
  #   "Git: ${builtins.toJSON user.git}"
  #   "Policies: ${builtins.toJSON policies}"
  # ];

  imports = [
    ./espanso
  ];
}
# services = {
#   swww = {inherit enable;}; # Wayland background setter
#   mako = {inherit enable;}; # Notification daemon
# };
