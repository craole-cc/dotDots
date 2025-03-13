/******/ (function() { // webpackBootstrap
/******/ 	"use strict";

;// ../../libs/common/src/vault/enums/vault-onboarding.enum.ts
const VaultOnboardingMessages = {
    HasBwInstalled: "hasBwInstalled",
    checkBwInstalled: "checkIfBWExtensionInstalled",
};


;// ./src/vault/content/send-on-installed-message.ts

(function (globalContext) {
    globalContext.postMessage({ command: VaultOnboardingMessages.HasBwInstalled });
})(window);

/******/ })()
;