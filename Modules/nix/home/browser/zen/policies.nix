{ config, ... }:
{
  AutofillAddressEnabled = true;
  AutofillCreditCardEnabled = false;
  DefaultDownloadDirectory = config.home.homeDirectory + "/Downloads";
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
