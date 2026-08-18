{paths, ...}: {
  AutofillAddressEnabled = true;
  AutofillCreditCardEnabled = false;
  DefaultDownloadDirectory = paths.user.downloads.local; # TODO: This needs to be an option
  DisableAppUpdate = true;
  DisableFeedbackCommands = true;
  DisableFirefoxStudies = true;
  DisablePocket = true;
  DisableTelemetry = true;
  DontCheckDefaultBrowser = true;
  OfferToSaveLogins = false;
  PictureInPicture = true;
  EnableTrackingProtection = {
    Value = true;
    Locked = true;
    Cryptomining = true;
    Fingerprinting = true;
  };
  SanitizeOnShutdown = {
    FormData = true;
    Cache = true;
  };
}
