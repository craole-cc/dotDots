{
  lib ? import <nixpkgs/lib>,
  user,
}:
let
  inherit (user.input) mouse keyboard touchpad;
  mkVal = _var: lib.mkIf (_var != null) _var;
in
with keyboard;
with mouse;
{
  kb_model = mkVal model;
  kb_layout = mkVal layout;
  kb_variant = mkVal variant;
  kb_options = mkVal options;
  kb_rules = mkVal rules;
  kb_file = mkVal file;
  numlock_by_default = mkVal numlockByDefault;
  resolve_binds_by_sym = mkVal resolveBindsBySym;
  repeat_rate = mkVal repeatRate;
  repeat_delay = mkVal repeatDelay;

  sensitivity = mkVal sensitivity;
  accel_profile = mkVal acceleration;
  force_no_accel = mkVal forceNoAccel;
  left_handed = mkVal leftHanded;
  scroll_points = mkVal scroll.points;
  scroll_method = mkVal scroll.method;
  scroll_button = mkVal scroll.button;
  scroll_button_lock = mkVal scroll.buttonLock;
  scroll_factor = mkVal scroll.factor;
  natural_scroll = mkVal scroll.natural;
  follow_mouse = mkVal follow;
  mouse_refocus = mkVal refocus;
  float_switch_override_focus = mkVal floatSwitchOverrideFocus;
  # special_fallthrough = mkVal specialFallthrough;
  # off_window_axis_events = mkVal offWindowAxisEvents;

  touchpad = with touchpad; {
    disable_while_typing = mkVal disableWhileTyping;
    natural_scroll = mkVal scroll.natural;
    scroll_factor = mkVal scroll.factor;
    middle_button_emulation = mkVal middleButtonEmulation;
    tap_button_map = mkVal tap.buttonMap;
    clickfinger_behavior = mkVal clickfingerBehavior;
    tap_to_click = mkVal tap.toClick;
    drag_lock = mkVal dragLock;
    tap_and_drag = mkVal tap.toDrag;
  };

  touchdevice = with touchdevice; {
    enabled = mkVal enabled;
    transform = mkVal transform;
    output = mkVal output;
  };

  tablet = with tablet; {
    active_area_size = mkVal activeArea.size;
    active_area_position = mkVal activeArea.position;
    left_handed = mkVal leftHanded;
    output = mkVal output;
    region_position = mkVal region.position;
    region_size = mkVal region.size;
    relative_input = mkVal relativeInput;
    transform = mkVal transform;
  };
}
