{mkLockedAttrs, ...}: {
  Preferences = mkLockedAttrs {
    ## Browser UI and Behavior
    "browser.aboutConfig.showWarning" = false;
    "browser.tabs.warnOnClose" = false;
    "browser.tabs.hoverPreview.enabled" = true;
    "browser.newtabpage.activity-stream.feeds.topsites" = false;
    "browser.topsites.contile.enabled" = false;
    "browser.bookmarks.restore_default_bookmarks" = true;
    "browser.urlbar.trimURLs" = true;

    ## Media Controls
    "media.videocontrols.picture-in-picture.video-toggle.enabled" = true;

    ## Gestures and Navigation
    "browser.gesture.swipe.left" = "";
    "browser.gesture.swipe.right" = "";
    "browser.gesture.pinch.in" = "cmd_fullZoomReduce";
    "browser.gesture.pinch.out" = "cmd_fullZoomEnlarge";

    ## Privacy and Fingerprinting Resistance
    "privacy.resistFingerprinting" = true;
    "privacy.resistFingerprinting.randomization.canvas.use_siphash" = true;
    "privacy.resistFingerprinting.randomization.daily_reset.enabled" = true;
    "privacy.resistFingerprinting.randomization.daily_reset.private.enabled" = true;
    "privacy.resistFingerprinting.block_mozAddonManager" = true;
    "privacy.spoof_english" = 1;
    "privacy.firstparty.isolate" = true;
    "network.cookie.cookieBehavior" = 5; # 5 = Reject trackers and partition third-party storage
    "dom.battery.enabled" = false;
    "privacy.donottrackheader.enabled" = false;
    "privacy.trackingprotection.enabled" = false;
    "privacy.trackingprotection.pbmode.enabled" = true;
    "privacy.trackingprotection.socialtracking.enabled" = true;
    "privacy.clearOnShutdown.cache" = false;

    ## Security
    "browser.safebrowsing.malware.enabled" = true;
    "browser.safebrowsing.phishing.enabled" = true;

    ## Rendering and Graphics
    "gfx.webrender.all" = true;
    "layers.acceleration.force-enabled" = false;
    "gfx.font_rendering.cleartype_params.rendering_mode" = 5; # ClearType setting on Windows, for example

    ## Networking
    "network.http.http3.enabled" = true;
    "network.socket.ip_addr_any.disabled" = true; # Disallow binding to 0.0.0.0
    "network.http.speculative-parallel-limit" = 6;
    "network.dns.disablePrefetch" = false;
    "network.prefetch-next" = true;
  };
}
