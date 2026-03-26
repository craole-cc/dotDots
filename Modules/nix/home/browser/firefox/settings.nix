{program, ...}: let
  forAll = {
    #| Common preferences (work in most Gecko browsers)
    "browser.profiles.enabled" = true; #? Enable profile selector in menu
    "browser.profiles.default" = "default"; #? Name of default profile

    #| Privacy & tracking
    "privacy.trackingprotection.enabled" = true; #? Enable tracking protection
    "privacy.resistFingerprinting" = false; #? Disable if it breaks sites
    "privacy.donottrackheader.enabled" = true; #? Send DNT header

    #| URL bar / search
    "browser.urlbar.suggest.searches" = false; #? Disable search suggestions
    "browser.urlbar.suggest.history" = true; #? Suggest history
    "browser.urlbar.suggest.bookmark" = true; #? Suggest bookmarks
    "browser.urlbar.suggest.openpage" = true; #? Suggest open tabs

    #| Tabs & windows
    "toolkit.tabbox.switchByScrolling" = true; #? Switch tabs by scrolling over them
    "browser.tabs.loadInBackground" = true; #? Open links in background tabs
    "browser.tabs.warnOnClose" = false; #? Don’t warn when closing multiple tabs

    #| Media & performance
    "media.videocontrols.picture-in-picture.enabled" = true; #? Enable PiP
    "media.autoplay.default" = 0; #? 0=allow all, 1=block audio, 5=block all
    "gfx.webrender.all" = true; #? Force WebRender (if stable on your GPU)

    #| Scrolling & input
    "general.smoothScroll" = true; #? Smooth scrolling
    "mousewheel.default.delta_multiplier_y" = 100; #? Adjust scroll speed

    #| Downloads
    "browser.download.useDownloadDir" = true; #? Use default download dir
    "browser.download.folderList" = 1; #? 1=Downloads, 2=Desktop, 0=custom
  };

  forZen =
    if program == "zen-browser"
    then {
      #| Zen workspaces
      "zen.workspaces.continue-where-left-off" = true; #? Restore workspace on startup
      "zen.workspaces.natural-scroll" = true; #? Natural scroll direction in workspaces
      "zen.workspaces.swipe-actions" = true; #? Enable swipe gestures between workspaces

      #| Zen view / compact mode
      "zen.view.compact.hide-tabbar" = true; #? Hide tab bar in compact mode
      "zen.view.compact.hide-toolbar" = true; #? Hide toolbar in compact mode
      "zen.view.compact.animate-sidebar" = false; #? Disable sidebar animation

      #| Zen welcome & onboarding
      "zen.welcome-screen.seen" = true; #? Mark welcome screen as seen

      #| Zen URL bar
      "zen.urlbar.behavior" = "float"; #? Floating URL bar (float, static, hidden)

      #? Zen theme & appearance
      "zen.theme.accent-color" = "#6366f1"; #? Main accent color (hex)
      "zen.theme.gradient" = true; #? Enable sidebar gradient
      "zen.theme.gradient.show-custom-colors" = false; #? Show custom sidebar colors
      "zen.view.gray-out-inactive-windows" = true; #? Gray out inactive windows
      "zen.watermark.enabled" = true; #? Show splash screen on startup

      #? Zen tabs
      "zen.tabs.rename-tabs" = true; #? Allow renaming pinned tabs
      "zen.tabs.dim-pending" = true; #? Dim unloaded tabs
      "zen.ctrlTab.show-pending-tabs" = true; #? Show unloaded tabs in Ctrl+Tab

      #? Zen media & controls
      "zen.mediacontrols.enabled" = true; #? Show media controls in tab bar
      "zen.mediacontrols.show-on-hover" = true; #? Show media controls only on hover

      #? Zen glance / search
      "zen.glance.enable-contextmenu-search" = true; #? Open Glance on right-click search
      "zen.glance.show-bookmarks" = true; #? Show bookmarks in Glance
      "zen.glance.show-history" = true; #? Show history in Glance

      #? Zen tab unloader (memory)
      "zen.tab-unloader.enabled" = true; #? Unload inactive tabs to save memory
      "zen.tab-unloader.delay" = 300; #? Delay in seconds before unloading (default 300)
      "zen.tab-unloader.excluded-urls" = "https://meet.google.com,https://app.slack.com"; #? Comma-separated URLs to never unload

      #? Zen experimental / hidden
      "zen.view.experimental-rounded-view" = false; #? Enable rounded corners (if available)
      "zen.theme.content-element-separation" = 8; #? Border size around window (default 8)
    }
    else {};
in {settings = forAll // forZen;}
