{}
# {
#   uid = null; #? Numeric user ID (must be unique per host; e.g. 1000)
#   role = "normal"; #? User classification (e.g. "normal", "guest", "admin")
#   description = null; #? Human-readable full name (e.g. "Craig 'Craole' Cole")
#   password = null; #? Hashed password string (mkpasswd -m sha-512); omit for key-only/no local auth
#   git = {
#     name = null; #? Git commit author name
#     email = null; #? Git commit author email
#   };
#   capabilities = []; #? High-level functional roles for this user (e.g. ["development" "gaming"])
#   shells = ["bash"]; #? Ordered list of shells available to the user; first is primary
#   interface = {
#     displayProtocol = null; #? Display server protocol override ("wayland" or "x11")
#     desktopEnvironment = null; #? Desktop environment override (e.g. "plasma", "gnome")
#     windowManager = null; #? Window manager override (e.g. "hyprland", "niri")
#     keyboard = {
#       modifier = "SUPER"; #? Main window manager modifier key ("SUPER" or "ALT")
#       swapCapsEscape = false; #? Remap Caps Lock key to Escape key
#       vimKeybinds = false; #? Enable vim-style keybindings where supported
#     };
#     prompt = null; #? Shell prompt theme/framework
#   };
#   style = {
#     autoSwitch = false; #? Automatically switch theme polarity by time of day
#     theme = {
#       polarity = "dark"; #? Default theme polarity ("dark" or "light")
#       accent = null; #? Accent color name
#       dark = null; #? Dark theme name
#       light = null; #? Light theme name
#     };
#     icons = {
#       dark = null; #? Icon theme for dark polarity
#       light = null; #? Icon theme for light polarity
#     };
#     cursors = {
#       accent = null; #? Cursor accent color name
#       dark = null; #? Cursor theme for dark polarity
#       light = null; #? Cursor theme for light polarity
#     };
#     fonts = {
#       emoji = null; #? Emoji font
#       monospace = null; #? Monospace font
#       sans = null; #? Sans-serif font
#       serif = null; #? Serif font
#       material = null; #? Icon/symbol font
#       clock = null; #? Clock widget font
#     };
#   };
#   applications = {
#     browser = {
#       primary = null; #? Primary browser identifier
#       secondary = null; #? Secondary browser identifier
#     };
#     editor = {
#       tty = {
#         primary = null; #? Primary TTY editor
#         secondary = null; #? Secondary TTY editor
#       };
#       gui = {
#         primary = null; #? Primary GUI editor
#         secondary = null; #? Secondary GUI editor
#       };
#     };
#     terminal = {
#       primary = null; #? Primary terminal emulator
#       secondary = null; #? Secondary terminal emulator
#     };
#     launcher = {
#       primary = null; #? Primary application launcher
#       secondary = null; #? Secondary application launcher
#     };
#     bar = null; #? Status bar identifier
#     allowed = []; #? Extra ad-hoc packages allowed for this user
#     utilities = {}; #? Per-utility enable flags (freeform attrset)
#   };
#   paths = {}; #? Freeform per-user path overrides (shape varies by user)
# }
