{ user }:
with user.input;
with keyboard;
with mouse;
{
  kb_model = model;
  kb_layout = layout;
  kb_variant = variant;
  kb_options = options;
  kb_rules = rules;
  kb_file = file;
  numlock_by_default = numlockByDefault;
  resolve_binds_by_sym = resolveBindsBySym;
  repeat_rate = repeatRate;
  repeat_delay = repeatDelay;

  sensitivity = sensitivity;
  accel_profile = acceleration;
  force_no_accel = forceNoAccel;
  left_handed = leftHanded;
  scroll_points = scroll.points;
  scroll_method = scroll.method;
  scroll_button = scroll.button;
  scroll_button_lock = scroll.buttonLock;
  scroll_factor = scroll.factor;
  natural_scroll = scroll.natural;
  follow_mouse = follow;
  mouse_refocus = refocus;
  float_switch_override_focus = floatSwitchOverrideFocus;
  special_fallthrough = specialFallthrough;
  off_window_axis_events = offWindowAxisEvents;

  touchpad = with touchpad; {
    disable_while_typing = disableWhileTyping;
    natural_scroll = scroll.natural;
    scroll_factor = scroll.factor;
    middle_button_emulation = middleButtonEmulation;
    tap_button_map = tap.buttonMap;
    clickfinger_behavior = clickfingerBehavior;
    tap_to_click = tap.toClick;
    drag_lock = dragLock;
    tap_and_drag = tap.toDrag;
  };

  touchdevice = with touchdevice; {
    inherit enabled transform;
  };

  tablet = with tablet; {
    inherit transform;
    active_area_size = activeArea.size;
    active_area_position = activeArea.position;
    left_handed = leftHanded;
    region_position = region.position;
    region_size = region.size;
    relative_input = relativeInput;
  };
}
