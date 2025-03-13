/******/ (function() { // webpackBootstrap
/******/ 	"use strict";
/******/ 	var __webpack_modules__ = ({

/***/ 97321:
/***/ (function(__unused_webpack_module, __webpack_exports__, __webpack_require__) {

__webpack_require__.r(__webpack_exports__);
// extracted by mini-css-extract-plugin


/***/ })

/******/ 	});
/************************************************************************/
/******/ 	// The module cache
/******/ 	var __webpack_module_cache__ = {};
/******/ 	
/******/ 	// The require function
/******/ 	function __webpack_require__(moduleId) {
/******/ 		// Check if module is in cache
/******/ 		var cachedModule = __webpack_module_cache__[moduleId];
/******/ 		if (cachedModule !== undefined) {
/******/ 			return cachedModule.exports;
/******/ 		}
/******/ 		// Create a new module (and put it into the cache)
/******/ 		var module = __webpack_module_cache__[moduleId] = {
/******/ 			// no module.id needed
/******/ 			// no module.loaded needed
/******/ 			exports: {}
/******/ 		};
/******/ 	
/******/ 		// Execute the module function
/******/ 		__webpack_modules__[moduleId](module, module.exports, __webpack_require__);
/******/ 	
/******/ 		// Return the exports of the module
/******/ 		return module.exports;
/******/ 	}
/******/ 	
/************************************************************************/
/******/ 	/* webpack/runtime/make namespace object */
/******/ 	!function() {
/******/ 		// define __esModule on exports
/******/ 		__webpack_require__.r = function(exports) {
/******/ 			if(typeof Symbol !== 'undefined' && Symbol.toStringTag) {
/******/ 				Object.defineProperty(exports, Symbol.toStringTag, { value: 'Module' });
/******/ 			}
/******/ 			Object.defineProperty(exports, '__esModule', { value: true });
/******/ 		};
/******/ 	}();
/******/ 	
/************************************************************************/
var __webpack_exports__ = {};

;// ../../libs/common/src/platform/enums/encryption-type.enum.ts
var EncryptionType;
(function (EncryptionType) {
    EncryptionType[EncryptionType["AesCbc256_B64"] = 0] = "AesCbc256_B64";
    EncryptionType[EncryptionType["AesCbc128_HmacSha256_B64"] = 1] = "AesCbc128_HmacSha256_B64";
    EncryptionType[EncryptionType["AesCbc256_HmacSha256_B64"] = 2] = "AesCbc256_HmacSha256_B64";
    EncryptionType[EncryptionType["Rsa2048_OaepSha256_B64"] = 3] = "Rsa2048_OaepSha256_B64";
    EncryptionType[EncryptionType["Rsa2048_OaepSha1_B64"] = 4] = "Rsa2048_OaepSha1_B64";
    EncryptionType[EncryptionType["Rsa2048_OaepSha256_HmacSha256_B64"] = 5] = "Rsa2048_OaepSha256_HmacSha256_B64";
    EncryptionType[EncryptionType["Rsa2048_OaepSha1_HmacSha256_B64"] = 6] = "Rsa2048_OaepSha1_HmacSha256_B64";
})(EncryptionType || (EncryptionType = {}));
function encryptionTypeToString(encryptionType) {
    if (encryptionType in EncryptionType) {
        return EncryptionType[encryptionType];
    }
    else {
        return "Unknown encryption type " + encryptionType;
    }
}
/** The expected number of parts to a serialized EncString of the given encryption type.
 * For example, an EncString of type AesCbc256_B64 will have 2 parts, and an EncString of type
 * AesCbc128_HmacSha256_B64 will have 3 parts.
 *
 * Example of annotated serialized EncStrings:
 * 0.iv|data
 * 1.iv|data|mac
 * 2.iv|data|mac
 * 3.data
 * 4.data
 *
 * @see EncString
 * @see EncryptionType
 * @see EncString.parseEncryptedString
 */
const EXPECTED_NUM_PARTS_BY_ENCRYPTION_TYPE = {
    [EncryptionType.AesCbc256_B64]: 2,
    [EncryptionType.AesCbc128_HmacSha256_B64]: 3,
    [EncryptionType.AesCbc256_HmacSha256_B64]: 3,
    [EncryptionType.Rsa2048_OaepSha256_B64]: 1,
    [EncryptionType.Rsa2048_OaepSha1_B64]: 1,
    [EncryptionType.Rsa2048_OaepSha256_HmacSha256_B64]: 2,
    [EncryptionType.Rsa2048_OaepSha1_HmacSha256_B64]: 2,
};

;// ../../libs/common/src/platform/enums/file-upload-type.enum.ts
var FileUploadType;
(function (FileUploadType) {
    FileUploadType[FileUploadType["Direct"] = 0] = "Direct";
    FileUploadType[FileUploadType["Azure"] = 1] = "Azure";
})(FileUploadType || (FileUploadType = {}));

;// ../../libs/common/src/platform/enums/hash-purpose.enum.ts
var HashPurpose;
(function (HashPurpose) {
    HashPurpose[HashPurpose["ServerAuthorization"] = 1] = "ServerAuthorization";
    HashPurpose[HashPurpose["LocalAuthorization"] = 2] = "LocalAuthorization";
})(HashPurpose || (HashPurpose = {}));

;// ../../libs/common/src/platform/enums/html-storage-location.enum.ts
var HtmlStorageLocation;
(function (HtmlStorageLocation) {
    HtmlStorageLocation["Local"] = "local";
    HtmlStorageLocation["Memory"] = "memory";
    HtmlStorageLocation["Session"] = "session";
})(HtmlStorageLocation || (HtmlStorageLocation = {}));

;// ../../libs/common/src/platform/enums/key-suffix-options.enum.ts
var KeySuffixOptions;
(function (KeySuffixOptions) {
    KeySuffixOptions["Auto"] = "auto";
    KeySuffixOptions["Pin"] = "pin";
})(KeySuffixOptions || (KeySuffixOptions = {}));

;// ../../libs/common/src/platform/enums/log-level-type.enum.ts
var LogLevelType;
(function (LogLevelType) {
    LogLevelType[LogLevelType["Debug"] = 0] = "Debug";
    LogLevelType[LogLevelType["Info"] = 1] = "Info";
    LogLevelType[LogLevelType["Warning"] = 2] = "Warning";
    LogLevelType[LogLevelType["Error"] = 3] = "Error";
})(LogLevelType || (LogLevelType = {}));

;// ../../libs/common/src/platform/enums/storage-location.enum.ts
var StorageLocation;
(function (StorageLocation) {
    StorageLocation["Both"] = "both";
    StorageLocation["Disk"] = "disk";
    StorageLocation["Memory"] = "memory";
})(StorageLocation || (StorageLocation = {}));

;// ../../libs/common/src/platform/enums/theme-type.enum.ts
/**
 * @deprecated prefer the `ThemeTypes` constants and `Theme` type over unsafe enum types
 **/
var ThemeType;
(function (ThemeType) {
    ThemeType["System"] = "system";
    ThemeType["Light"] = "light";
    ThemeType["Dark"] = "dark";
    ThemeType["Nord"] = "nord";
    ThemeType["SolarizedDark"] = "solarizedDark";
})(ThemeType || (ThemeType = {}));
const ThemeTypes = {
    System: "system",
    Light: "light",
    Dark: "dark",
    Nord: "nord",
    SolarizedDark: "solarizedDark",
};

;// ../../libs/common/src/platform/enums/index.ts









;// ../../libs/common/src/platform/services/console-log.service.ts

class ConsoleLogService {
    constructor(isDev, filter = null) {
        this.isDev = isDev;
        this.filter = filter;
        this.timersMap = new Map();
    }
    debug(message, ...optionalParams) {
        if (!this.isDev) {
            return;
        }
        this.write(LogLevelType.Debug, message, ...optionalParams);
    }
    info(message, ...optionalParams) {
        this.write(LogLevelType.Info, message, ...optionalParams);
    }
    warning(message, ...optionalParams) {
        this.write(LogLevelType.Warning, message, ...optionalParams);
    }
    error(message, ...optionalParams) {
        this.write(LogLevelType.Error, message, ...optionalParams);
    }
    write(level, message, ...optionalParams) {
        if (this.filter != null && this.filter(level)) {
            return;
        }
        switch (level) {
            case LogLevelType.Debug:
                // eslint-disable-next-line
                console.log(message, ...optionalParams);
                break;
            case LogLevelType.Info:
                // eslint-disable-next-line
                console.log(message, ...optionalParams);
                break;
            case LogLevelType.Warning:
                // eslint-disable-next-line
                console.warn(message, ...optionalParams);
                break;
            case LogLevelType.Error:
                // eslint-disable-next-line
                console.error(message, ...optionalParams);
                break;
            default:
                break;
        }
    }
}

;// ./src/autofill/enums/autofill-port.enum.ts
const autofill_port_enum_AutofillPort = {
    InjectedScript: "autofill-injected-script-port",
};


;// ./src/autofill/utils/index.ts
var __awaiter = (undefined && undefined.__awaiter) || function (thisArg, _arguments, P, generator) {
    function adopt(value) { return value instanceof P ? value : new P(function (resolve) { resolve(value); }); }
    return new (P || (P = Promise))(function (resolve, reject) {
        function fulfilled(value) { try { step(generator.next(value)); } catch (e) { reject(e); } }
        function rejected(value) { try { step(generator["throw"](value)); } catch (e) { reject(e); } }
        function step(result) { result.done ? resolve(result.value) : adopt(result.value).then(fulfilled, rejected); }
        step((generator = generator.apply(thisArg, _arguments || [])).next());
    });
};

/**
 * Generates a random string of characters.
 *
 * @param length - The length of the random string to generate.
 */
function generateRandomChars(length) {
    const chars = "abcdefghijklmnopqrstuvwxyz";
    const randomChars = [];
    const randomBytes = new Uint8Array(length);
    globalThis.crypto.getRandomValues(randomBytes);
    for (let byteIndex = 0; byteIndex < randomBytes.length; byteIndex++) {
        const byte = randomBytes[byteIndex];
        randomChars.push(chars[byte % chars.length]);
    }
    return randomChars.join("");
}
/**
 * Polyfills the requestIdleCallback API with a setTimeout fallback.
 *
 * @param callback - The callback function to run when the browser is idle.
 * @param options - The options to pass to the requestIdleCallback function.
 */
function requestIdleCallbackPolyfill(callback, options) {
    if ("requestIdleCallback" in globalThis) {
        return globalThis.requestIdleCallback(() => callback(), options);
    }
    const timeoutDelay = (options === null || options === void 0 ? void 0 : options.timeout) || 1;
    return globalThis.setTimeout(() => callback(), timeoutDelay);
}
/**
 * Polyfills the cancelIdleCallback API with a clearTimeout fallback.
 *
 * @param id - The ID of the idle callback to cancel.
 */
function cancelIdleCallbackPolyfill(id) {
    if ("cancelIdleCallback" in globalThis) {
        return globalThis.cancelIdleCallback(id);
    }
    return globalThis.clearTimeout(id);
}
/**
 * Generates a random string of characters that formatted as a custom element name.
 */
function generateRandomCustomElementName() {
    const length = Math.floor(Math.random() * 5) + 8; // Between 8 and 12 characters
    const numHyphens = Math.min(Math.max(Math.floor(Math.random() * 4), 1), length - 1); // At least 1, maximum of 3 hyphens
    const hyphenIndices = [];
    while (hyphenIndices.length < numHyphens) {
        const index = Math.floor(Math.random() * (length - 1)) + 1;
        if (!hyphenIndices.includes(index)) {
            hyphenIndices.push(index);
        }
    }
    hyphenIndices.sort((a, b) => a - b);
    let randomString = "";
    let prevIndex = 0;
    for (let index = 0; index < hyphenIndices.length; index++) {
        const hyphenIndex = hyphenIndices[index];
        randomString = randomString + generateRandomChars(hyphenIndex - prevIndex) + "-";
        prevIndex = hyphenIndex;
    }
    randomString += generateRandomChars(length - prevIndex);
    return randomString;
}
/**
 * Builds a DOM element from an SVG string.
 *
 * @param svgString - The SVG string to build the DOM element from.
 * @param ariaHidden - Determines whether the SVG should be hidden from screen readers.
 */
function buildSvgDomElement(svgString, ariaHidden = true) {
    const domParser = new DOMParser();
    const svgDom = domParser.parseFromString(svgString, "image/svg+xml");
    const domElement = svgDom.documentElement;
    domElement.setAttribute("aria-hidden", `${ariaHidden}`);
    return domElement;
}
/**
 * Sends a message to the extension.
 *
 * @param command - The command to send.
 * @param options - The options to send with the command.
 */
function sendExtensionMessage(command_1) {
    return __awaiter(this, arguments, void 0, function* (command, options = {}) {
        if (typeof browser !== "undefined" &&
            typeof browser.runtime !== "undefined" &&
            typeof browser.runtime.sendMessage !== "undefined") {
            return browser.runtime.sendMessage(Object.assign({ command }, options));
        }
        return new Promise((resolve) => chrome.runtime.sendMessage(Object.assign({ command }, options), (response) => {
            if (chrome.runtime.lastError) {
                resolve(null);
            }
            resolve(response);
        }));
    });
}
/**
 * Sets CSS styles on an element.
 *
 * @param element - The element to set the styles on.
 * @param styles - The styles to set on the element.
 * @param priority - Determines whether the styles should be set as important.
 */
function setElementStyles(element, styles, priority) {
    if (!element || !styles || !Object.keys(styles).length) {
        return;
    }
    for (const styleProperty in styles) {
        element.style.setProperty(styleProperty.replace(/([a-z])([A-Z])/g, "$1-$2"), // Convert camelCase to kebab-case
        styles[styleProperty], priority ? "important" : undefined);
    }
}
/**
 * Sets up a long-lived connection with the extension background
 * and triggers an onDisconnect event if the extension context
 * is invalidated.
 *
 * @param callback - Callback export function to run when the extension disconnects
 */
function setupExtensionDisconnectAction(callback) {
    const port = chrome.runtime.connect({ name: AutofillPort.InjectedScript });
    const onDisconnectCallback = (disconnectedPort) => {
        callback(disconnectedPort);
        port.onDisconnect.removeListener(onDisconnectCallback);
    };
    port.onDisconnect.addListener(onDisconnectCallback);
}
/**
 * Handles setup of the extension disconnect action for the autofill init class
 * in both instances where the overlay might or might not be initialized.
 *
 * @param windowContext - The global window context
 */
function setupAutofillInitDisconnectAction(windowContext) {
    if (!windowContext.bitwardenAutofillInit) {
        return;
    }
    const onDisconnectCallback = () => {
        windowContext.bitwardenAutofillInit.destroy();
        delete windowContext.bitwardenAutofillInit;
    };
    setupExtensionDisconnectAction(onDisconnectCallback);
}
/**
 * Identifies whether an element is a fillable form field.
 * This is determined by whether the element is a form field and not a span.
 *
 * @param formFieldElement - The form field element to check.
 */
function elementIsFillableFormField(formFieldElement) {
    return !elementIsSpanElement(formFieldElement);
}
/**
 * Identifies whether an element is an instance of a specific tag name.
 *
 * @param element - The element to check.
 * @param tagName -  The tag name to check against.
 */
function elementIsInstanceOf(element, tagName) {
    return nodeIsElement(element) && element.tagName.toLowerCase() === tagName;
}
/**
 * Identifies whether an element is a span element.
 *
 * @param element - The element to check.
 */
function elementIsSpanElement(element) {
    return elementIsInstanceOf(element, "span");
}
/**
 * Identifies whether an element is an input field.
 *
 * @param element - The element to check.
 */
function elementIsInputElement(element) {
    return elementIsInstanceOf(element, "input");
}
/**
 * Identifies whether an element is a select field.
 *
 * @param element - The element to check.
 */
function elementIsSelectElement(element) {
    return elementIsInstanceOf(element, "select");
}
/**
 * Identifies whether an element is a textarea field.
 *
 * @param element - The element to check.
 */
function elementIsTextAreaElement(element) {
    return elementIsInstanceOf(element, "textarea");
}
/**
 * Identifies whether an element is a form element.
 *
 * @param element - The element to check.
 */
function elementIsFormElement(element) {
    return elementIsInstanceOf(element, "form");
}
/**
 * Identifies whether an element is a label element.
 *
 * @param element - The element to check.
 */
function elementIsLabelElement(element) {
    return elementIsInstanceOf(element, "label");
}
/**
 * Identifies whether an element is a description details `dd` element.
 *
 * @param element - The element to check.
 */
function elementIsDescriptionDetailsElement(element) {
    return elementIsInstanceOf(element, "dd");
}
/**
 * Identifies whether an element is a description term `dt` element.
 *
 * @param element - The element to check.
 */
function elementIsDescriptionTermElement(element) {
    return elementIsInstanceOf(element, "dt");
}
/**
 * Identifies whether a node is an HTML element.
 *
 * @param node - The node to check.
 */
function nodeIsElement(node) {
    if (!node) {
        return false;
    }
    return (node === null || node === void 0 ? void 0 : node.nodeType) === Node.ELEMENT_NODE;
}
/**
 * Identifies whether a node is an input element.
 *
 * @param node - The node to check.
 */
function nodeIsInputElement(node) {
    return nodeIsElement(node) && elementIsInputElement(node);
}
/**
 * Identifies whether a node is a form element.
 *
 * @param node - The node to check.
 */
function nodeIsFormElement(node) {
    return nodeIsElement(node) && elementIsFormElement(node);
}
function nodeIsTypeSubmitElement(node) {
    return nodeIsElement(node) && getPropertyOrAttribute(node, "type") === "submit";
}
function nodeIsButtonElement(node) {
    return (nodeIsElement(node) &&
        (elementIsInstanceOf(node, "button") ||
            getPropertyOrAttribute(node, "type") === "button"));
}
function nodeIsAnchorElement(node) {
    return nodeIsElement(node) && elementIsInstanceOf(node, "a");
}
/**
 * Returns a boolean representing the attribute value of an element.
 *
 * @param element
 * @param attributeName
 * @param checkString
 */
function getAttributeBoolean(element, attributeName, checkString = false) {
    if (checkString) {
        return getPropertyOrAttribute(element, attributeName) === "true";
    }
    return Boolean(getPropertyOrAttribute(element, attributeName));
}
/**
 * Get the value of a property or attribute from a FormFieldElement.
 *
 * @param element
 * @param attributeName
 */
function getPropertyOrAttribute(element, attributeName) {
    if (attributeName in element) {
        return element[attributeName];
    }
    return element.getAttribute(attributeName);
}
/**
 * Throttles a callback function to run at most once every `limit` milliseconds.
 *
 * @param callback - The callback function to throttle.
 * @param limit - The time in milliseconds to throttle the callback.
 */
function throttle(callback, limit) {
    let waitingDelay = false;
    return function (...args) {
        if (!waitingDelay) {
            callback.apply(this, args);
            waitingDelay = true;
            globalThis.setTimeout(() => (waitingDelay = false), limit);
        }
    };
}
/**
 * Debounces a callback function to run after a delay of `delay` milliseconds.
 *
 * @param callback - The callback function to debounce.
 * @param delay - The time in milliseconds to debounce the callback.
 * @param immediate - Determines whether the callback should run immediately.
 */
function debounce(callback, delay, immediate) {
    let timeout;
    return function (...args) {
        const callImmediately = !!immediate && !timeout;
        if (timeout) {
            globalThis.clearTimeout(timeout);
        }
        timeout = globalThis.setTimeout(() => {
            timeout = null;
            if (!callImmediately) {
                callback.apply(this, args);
            }
        }, delay);
        if (callImmediately) {
            callback.apply(this, args);
        }
    };
}
/**
 * Gathers and normalizes keywords from a potential submit button element. Used
 * to verify if the element submits a login or change password form.
 *
 * @param element - The element to gather keywords from.
 */
function getSubmitButtonKeywordsSet(element) {
    const keywords = [
        element.textContent,
        element.getAttribute("type"),
        element.getAttribute("value"),
        element.getAttribute("aria-label"),
        element.getAttribute("aria-labelledby"),
        element.getAttribute("aria-describedby"),
        element.getAttribute("title"),
        element.getAttribute("id"),
        element.getAttribute("name"),
        element.getAttribute("class"),
    ];
    const keywordsSet = new Set();
    for (let i = 0; i < keywords.length; i++) {
        if (typeof keywords[i] === "string") {
            // Iterate over all keywords metadata and split them by non-letter characters.
            // This ensures we check against individual words and not the entire string.
            keywords[i]
                .toLowerCase()
                .replace(/[-\s]/g, "")
                .split(/[^\p{L}]+/gu)
                .forEach((keyword) => {
                if (keyword) {
                    keywordsSet.add(keyword);
                }
            });
        }
    }
    return keywordsSet;
}
/**
 * Generates the origin and subdomain match patterns for the URL.
 *
 * @param url - The URL of the tab
 */
function generateDomainMatchPatterns(url) {
    try {
        const extensionUrlPattern = /^(chrome|chrome-extension|moz-extension|safari-web-extension):\/\/\/?/;
        if (extensionUrlPattern.test(url)) {
            return [];
        }
        // Add protocol to URL if it is missing to allow for parsing the hostname correctly
        const urlPattern = /^(https?|file):\/\/\/?/;
        if (!urlPattern.test(url)) {
            url = `https://${url}`;
        }
        let protocolGlob = "*://";
        if (url.startsWith("file:///")) {
            protocolGlob = "*:///"; // File URLs require three slashes to be a valid match pattern
        }
        const parsedUrl = new URL(url);
        const originMatchPattern = `${protocolGlob}${parsedUrl.hostname}/*`;
        const splitHost = parsedUrl.hostname.split(".");
        const domain = splitHost.slice(-2).join(".");
        const subDomainMatchPattern = `${protocolGlob}*.${domain}/*`;
        return [originMatchPattern, subDomainMatchPattern];
    }
    catch (_a) {
        return [];
    }
}
/**
 * Determines if the status code of the web response is invalid. An invalid status code is
 * any status code that is not in the 200-299 range.
 *
 * @param statusCode - The status code of the web response
 */
function isInvalidResponseStatusCode(statusCode) {
    return statusCode < 200 || statusCode >= 300;
}
/**
 * Determines if the current context is within a sandboxed iframe.
 */
function currentlyInSandboxedIframe() {
    var _a;
    return (String(self.origin).toLowerCase() === "null" ||
        ((_a = globalThis.frameElement) === null || _a === void 0 ? void 0 : _a.hasAttribute("sandbox")) ||
        globalThis.location.hostname === "");
}
/**
 * This object allows us to map a special character to a key name. The key name is used
 * in gathering the i18n translation of the written version of the special character.
 */
const specialCharacterToKeyMap = {
    " ": "spaceCharacterDescriptor",
    "~": "tildeCharacterDescriptor",
    "`": "backtickCharacterDescriptor",
    "!": "exclamationCharacterDescriptor",
    "@": "atSignCharacterDescriptor",
    "#": "hashSignCharacterDescriptor",
    $: "dollarSignCharacterDescriptor",
    "%": "percentSignCharacterDescriptor",
    "^": "caretCharacterDescriptor",
    "&": "ampersandCharacterDescriptor",
    "*": "asteriskCharacterDescriptor",
    "(": "parenLeftCharacterDescriptor",
    ")": "parenRightCharacterDescriptor",
    "-": "hyphenCharacterDescriptor",
    _: "underscoreCharacterDescriptor",
    "+": "plusCharacterDescriptor",
    "=": "equalsCharacterDescriptor",
    "{": "braceLeftCharacterDescriptor",
    "}": "braceRightCharacterDescriptor",
    "[": "bracketLeftCharacterDescriptor",
    "]": "bracketRightCharacterDescriptor",
    "|": "pipeCharacterDescriptor",
    "\\": "backSlashCharacterDescriptor",
    ":": "colonCharacterDescriptor",
    ";": "semicolonCharacterDescriptor",
    '"': "doubleQuoteCharacterDescriptor",
    "'": "singleQuoteCharacterDescriptor",
    "<": "lessThanCharacterDescriptor",
    ">": "greaterThanCharacterDescriptor",
    ",": "commaCharacterDescriptor",
    ".": "periodCharacterDescriptor",
    "?": "questionCharacterDescriptor",
    "/": "forwardSlashCharacterDescriptor",
};
/**
 * Determines if the current rect values are not all 0.
 */
function rectHasSize(rect) {
    if (rect.right > 0 && rect.left > 0 && rect.top > 0 && rect.bottom > 0) {
        return true;
    }
    return false;
}
/**
 * Checks if all the values corresponding to the specified keys in an object are null.
 * If no keys are specified, checks all keys in the object.
 *
 * @param obj - The object to check.
 * @param keys - An optional array of keys to check in the object. Defaults to all keys.
 * @returns Returns true if all values for the specified keys (or all keys if none are provided) are null; otherwise, false.
 */
function areKeyValuesNull(obj, keys) {
    const keysToCheck = keys && keys.length > 0 ? keys : Object.keys(obj);
    return keysToCheck.every((key) => obj[key] == null);
}

;// ./src/autofill/utils/svg-icons.ts
const logoIcon = '<svg xmlns="http://www.w3.org/2000/svg" width="14" height="14" viewBox="0 0 14 14" fill="none"><path fill="#175DDC" d="M12.66.175A.566.566 0 0 0 12.25 0H1.75a.559.559 0 0 0-.409.175.561.561 0 0 0-.175.41v7c.002.532.105 1.06.305 1.554.189.488.444.948.756 1.368.322.42.682.81 1.076 1.163.365.335.75.649 1.152.939.35.248.718.483 1.103.706.385.222.656.372.815.45.16.08.29.141.386.182A.53.53 0 0 0 7 14a.509.509 0 0 0 .238-.055c.098-.043.225-.104.387-.182.162-.079.438-.23.816-.45.378-.222.75-.459 1.102-.707.403-.29.788-.604 1.154-.939a8.435 8.435 0 0 0 1.076-1.163c.312-.42.567-.88.757-1.367a4.19 4.19 0 0 0 .304-1.555v-7a.55.55 0 0 0-.174-.407Z"/><path fill="#fff" d="M7 12.365s4.306-2.18 4.306-4.717V1.5H7v10.865Z"/></svg>';
const logoLockedIcon = '<svg xmlns="http://www.w3.org/2000/svg" width="16" height="16" viewBox="0 0 16 16" fill="none"><g clip-path="url(#a)"><path fill="#175DDC" d="M12.66.175A.566.566 0 0 0 12.25 0H1.75a.559.559 0 0 0-.409.175.561.561 0 0 0-.175.41v7c.002.532.105 1.06.305 1.554.189.488.444.948.756 1.368.322.42.682.81 1.076 1.163.365.335.75.649 1.152.939.35.248.718.483 1.103.706.385.222.656.372.815.45.16.08.29.141.386.182A.53.53 0 0 0 7 14a.509.509 0 0 0 .238-.055c.098-.043.225-.104.387-.182.162-.079.438-.23.816-.45.378-.222.75-.459 1.102-.707.403-.29.788-.604 1.154-.939a8.435 8.435 0 0 0 1.076-1.163c.312-.42.567-.88.757-1.367a4.19 4.19 0 0 0 .304-1.555v-7a.55.55 0 0 0-.174-.407Z"/><path fill="#fff" d="M7 12.365s4.306-2.18 4.306-4.717V1.5H7v10.865Z"/><circle cx="12.889" cy="12.889" r="4.889" fill="#F8F9FA"/><path fill="#555" d="M11.26 11.717h2.37v-.848c0-.313-.116-.58-.348-.8a1.17 1.17 0 0 0-.838-.332c-.327 0-.606.11-.838.332a1.066 1.066 0 0 0-.347.8v.848Zm3.851.424v2.546a.4.4 0 0 1-.13.3.44.44 0 0 1-.314.124h-4.445a.44.44 0 0 1-.315-.124.4.4 0 0 1-.13-.3V12.14a.4.4 0 0 1 .13-.3.44.44 0 0 1 .315-.124h.148v-.848c0-.542.204-1.008.612-1.397a2.044 2.044 0 0 1 1.462-.583c.568 0 1.056.194 1.463.583.408.39.611.855.611 1.397v.848h.149a.44.44 0 0 1 .315.124.4.4 0 0 1 .13.3Z"/></g><defs><clipPath id="a"><rect width="16" height="16" fill="#fff" rx="2"/></clipPath></defs></svg>';
const globeIcon = '<svg xmlns="http://www.w3.org/2000/svg" width="24" height="25" viewBox="0 0 24 25" fill="none"><path fill="#777" fill-rule="evenodd" d="M18.026 17.842c-1.418 1.739-3.517 2.84-5.86 2.84a7.364 7.364 0 0 1-3.431-.848l.062-.15.062-.151.063-.157c.081-.203.17-.426.275-.646.133-.28.275-.522.426-.68.026-.028.101-.075.275-.115.165-.037.376-.059.629-.073.138-.008.288-.014.447-.02.399-.016.847-.034 1.266-.092.314-.044.566-.131.755-.271a.884.884 0 0 0 .352-.555c.037-.2.008-.392-.03-.543-.035-.135-.084-.264-.12-.355l-.01-.03a4.26 4.26 0 0 0-.145-.33c-.126-.264-.237-.497-.288-1.085-.03-.344.09-.73.251-1.138l.089-.22c.05-.123.1-.247.14-.355.064-.171.129-.375.129-.566a1.51 1.51 0 0 0-.134-.569 2.573 2.573 0 0 0-.319-.547c-.246-.323-.635-.669-1.093-.669-.44 0-1.006.169-1.487.368-.246.102-.48.216-.68.33-.192.111-.372.235-.492.359-.93.96-1.48 1.239-1.81 1.258-.277.017-.478-.15-.736-.525a9.738 9.738 0 0 1-.19-.29l-.006-.01a11.568 11.568 0 0 0-.198-.305 2.76 2.76 0 0 0-.521-.6 1.39 1.39 0 0 0-1.088-.314 8.302 8.302 0 0 1 1.987-3.936c.055.342.146.626.272.856.23.42.561.64.926.716.406.086.857-.061 1.26-.216.125-.047.248-.097.372-.147.309-.125.618-.25.947-.341.26-.072.581-.057.959.012.264.049.529.118.8.19l.36.091c.379.094.782.178 1.135.148.374-.032.733-.197.934-.623a.874.874 0 0 0 .024-.752c-.087-.197-.24-.355-.35-.47-.26-.267-.412-.427-.412-.685 0-.125.037-.2.09-.263a.982.982 0 0 1 .303-.211c.059-.03.119-.058.183-.089l.036-.016a3.79 3.79 0 0 0 .236-.118c.047-.026.098-.056.148-.093 1.936.747 3.51 2.287 4.368 4.249a7.739 7.739 0 0 0-.031-.004c-.38-.047-.738-.056-1.063.061-.34.123-.603.368-.817.74-.122.211-.284.43-.463.67l-.095.129c-.207.281-.431.595-.58.92-.15.326-.245.705-.142 1.103.104.397.387.738.837 1.036.099.065.225.112.314.145l.02.008c.108.04.195.074.268.117.07.042.106.08.124.114.017.03.037.087.022.206-.047.376-.069.73-.052 1.034.017.292.071.59.218.809.118.174.12.421.108.786v.01a2.46 2.46 0 0 0 .021.518.809.809 0 0 0 .15.35Zm1.357.059a9.654 9.654 0 0 0 1.62-5.386c0-5.155-3.957-9.334-8.836-9.334-4.88 0-8.836 4.179-8.836 9.334 0 3.495 1.82 6.543 4.513 8.142v.093h.161a8.426 8.426 0 0 0 4.162 1.098c2.953 0 5.568-1.53 7.172-3.882a.569.569 0 0 0 .048-.062l-.004-.003ZM8.152 19.495a43.345 43.345 0 0 1 .098-.238l.057-.142c.082-.205.182-.455.297-.698.143-.301.323-.624.552-.864.163-.172.392-.254.602-.302.219-.05.473-.073.732-.088.162-.01.328-.016.495-.023.386-.015.782-.03 1.168-.084.255-.036.392-.099.461-.15.06-.045.076-.084.083-.12a.534.534 0 0 0-.02-.223 2.552 2.552 0 0 0-.095-.278l-.01-.027a3.128 3.128 0 0 0-.104-.232c-.134-.282-.31-.65-.374-1.381-.046-.533.138-1.063.3-1.472.035-.09.069-.172.1-.249.046-.11.086-.21.123-.31.062-.169.083-.264.083-.312a.812.812 0 0 0-.076-.283 1.867 1.867 0 0 0-.23-.394c-.21-.274-.428-.408-.577-.408-.315 0-.788.13-1.246.32a5.292 5.292 0 0 0-.603.293 1.727 1.727 0 0 0-.347.244c-.936.968-1.641 1.421-2.235 1.457-.646.04-1.036-.413-1.31-.813-.07-.103-.139-.21-.203-.311l-.005-.007c-.064-.101-.125-.197-.188-.29a2.098 2.098 0 0 0-.387-.453.748.748 0 0 0-.436-.18c-.1-.006-.22.005-.365.046a8.707 8.707 0 0 0-.056.992c0 2.957 1.488 5.547 3.716 6.98Zm10.362-2.316.003-.192.002-.046c.01-.305.026-.786-.232-1.169-.036-.054-.082-.189-.096-.444-.014-.243.003-.55.047-.9a1.051 1.051 0 0 0-.105-.649.987.987 0 0 0-.374-.374 2.285 2.285 0 0 0-.367-.166h-.003a1.243 1.243 0 0 1-.205-.088c-.369-.244-.505-.46-.549-.629-.044-.168-.015-.364.099-.61.115-.25.297-.511.507-.796l.089-.12c.178-.239.368-.495.512-.745.152-.263.302-.382.466-.441.18-.065.416-.073.77-.03.142.018.275.04.397.063.274.837.423 1.736.423 2.671a8.45 8.45 0 0 1-1.384 4.665Zm-4.632-12.63a7.362 7.362 0 0 0-1.715-.201c-1.89 0-3.621.716-4.965 1.905.025.54.12.887.24 1.105.13.238.295.34.482.38.2.042.484-.027.905-.188l.328-.13c.32-.13.681-.275 1.048-.377.398-.111.833-.075 1.24 0 .289.053.59.132.871.205l.326.084c.383.094.694.151.932.13.216-.017.326-.092.395-.237.039-.083.027-.114.014-.144-.027-.062-.088-.136-.212-.264l-.043-.044c-.218-.222-.567-.578-.567-1.142 0-.305.101-.547.262-.734.137-.159.308-.267.46-.347Z" clip-rule="evenodd"/></svg>';
const creditCardIcon = '<svg xmlns="http://www.w3.org/2000/svg" width="23" height="24" viewBox="0 0 23 24" fill="none"><path fill="#868E96" d="M19.05 5.52H4.02a1.589 1.589 0 0 0-1.11.56c-.286.333-.433.77-.413 1.218v9.48c-.02.447.127.884.413 1.217.285.333.684.534 1.11.56h15.024a1.588 1.588 0 0 0 1.113-.558c.286-.333.435-.772.414-1.22v-9.48a1.748 1.748 0 0 0-.412-1.217 1.589 1.589 0 0 0-1.11-.56ZM4.025 6.705h15.023a.53.53 0 0 1 .37.187c.094.111.143.257.136.405v1.067a.497.497 0 0 1-.117.35.458.458 0 0 1-.319.16H3.95a.458.458 0 0 1-.317-.16.496.496 0 0 1-.117-.35V7.297a.583.583 0 0 1 .137-.405.53.53 0 0 1 .37-.187h.004Zm15.023 10.658H4.021a.53.53 0 0 1-.366-.185.581.581 0 0 1-.14-.4v-6.2a.5.5 0 0 1 .118-.35.458.458 0 0 1 .318-.161h15.17a.453.453 0 0 1 .32.161.499.499 0 0 1 .117.35v6.2a.584.584 0 0 1-.138.405.532.532 0 0 1-.37.187v-.007Zm-1.354-2.18h-2.658a.395.395 0 0 0-.248.14.432.432 0 0 0 0 .552.392.392 0 0 0 .248.138h2.662a.395.395 0 0 0 .248-.139.432.432 0 0 0 0-.552.392.392 0 0 0-.248-.138h-.004Z"/></svg>';
const idCardIcon = '<svg xmlns="http://www.w3.org/2000/svg" width="23" height="24" viewBox="0 0 23 24" fill="none"><path fill="#868E96" d="M9.465 12.038c.316-.283.544-.664.652-1.091.108-.427.092-.88-.047-1.297a2.145 2.145 0 0 0-.731-1.032 1.91 1.91 0 0 0-1.149-.394 1.909 1.909 0 0 0-1.15.386 2.143 2.143 0 0 0-.737 1.028 2.305 2.305 0 0 0-.055 1.295c.106.428.331.81.646 1.096-.485.22-.913.563-1.249 1a3.641 3.641 0 0 0-.678 1.508 1.005 1.005 0 0 0 .18.796.877.877 0 0 0 .302.257c.117.06.245.091.375.091h4.693c.13 0 .258-.031.375-.091a.882.882 0 0 0 .302-.256 1.015 1.015 0 0 0 .18-.797 3.636 3.636 0 0 0-.672-1.5 3.313 3.313 0 0 0-1.237-1ZM8.184 9.089c.24 0 .474.077.674.22.2.143.355.347.447.586.092.238.115.5.068.754a1.337 1.337 0 0 1-.332.668 1.19 1.19 0 0 1-.62.357c-.236.05-.48.024-.702-.074a1.238 1.238 0 0 1-.544-.48 1.377 1.377 0 0 1-.205-.725c0-.347.128-.678.356-.923.228-.244.536-.382.857-.382l.001-.001Zm2.333 5.742H5.824l-.083-.121c.12-.597.427-1.132.868-1.515a2.378 2.378 0 0 1 1.56-.592c.568 0 1.119.209 1.56.592.442.383.749.917.869 1.515l-.081.121Zm2.76-4.912h2.833a.384.384 0 0 0 .261-.136.445.445 0 0 0 .106-.29.444.444 0 0 0-.106-.29.387.387 0 0 0-.26-.135h-2.835a.387.387 0 0 0-.26.136.443.443 0 0 0-.106.29c0 .107.037.211.105.29a.39.39 0 0 0 .261.135ZM17.337 14h-4.066a.385.385 0 0 0-.261.136.445.445 0 0 0-.106.29c0 .107.038.21.106.29.068.078.16.126.26.135h4.067a.387.387 0 0 0 .261-.136.442.442 0 0 0 .106-.29.444.444 0 0 0-.106-.29.387.387 0 0 0-.26-.135Zm0-2.466h-4.066a.382.382 0 0 0-.28.124.442.442 0 0 0-.116.301c0 .113.042.221.116.3.074.08.175.125.28.125h4.066a.382.382 0 0 0 .28-.124.442.442 0 0 0 .116-.3.442.442 0 0 0-.116-.302.382.382 0 0 0-.28-.124ZM19.44 5.28H3.627c-.3 0-.587.128-.799.356a1.264 1.264 0 0 0-.33.859V17.43c0 .322.119.631.33.859.212.228.5.356.8.356H19.44c.299 0 .586-.128.798-.356.212-.228.331-.537.331-.859V6.495c0-.322-.12-.631-.33-.859a1.091 1.091 0 0 0-.8-.356Zm-.564 12.15H4.19a.544.544 0 0 1-.4-.178.634.634 0 0 1-.165-.43v-9.72a.63.63 0 0 1 .166-.429.547.547 0 0 1 .399-.178h14.77c.099.024.472.14.48.525v9.803a.63.63 0 0 1-.166.429.547.547 0 0 1-.4.178Z"/></svg>';
const lockIcon = '<svg xmlns="http://www.w3.org/2000/svg" width="17" height="17" viewBox="0 0 17 17" fill="none"><g clip-path="url(#a)"><path fill="#175DDC" d="M8.799 11.633a.68.68 0 0 0-.639.422.695.695 0 0 0-.054.264.682.682 0 0 0 .374.6v1.13a.345.345 0 1 0 .693 0v-1.17a.68.68 0 0 0 .315-.56.695.695 0 0 0-.204-.486.682.682 0 0 0-.485-.2Zm4.554-4.657h-7.11a.438.438 0 0 1-.406-.26A3.81 3.81 0 0 1 5.584 4.3c.112-.435.312-.842.588-1.195A3.196 3.196 0 0 1 7.19 2.25a3.468 3.468 0 0 1 3.225-.059A3.62 3.62 0 0 1 11.94 3.71l.327.59a.502.502 0 1 0 .885-.483l-.307-.552a4.689 4.689 0 0 0-2.209-2.078 4.466 4.466 0 0 0-3.936.185A4.197 4.197 0 0 0 5.37 2.49a4.234 4.234 0 0 0-.768 1.565 4.714 4.714 0 0 0 .162 2.682.182.182 0 0 1-.085.22.173.173 0 0 1-.082.02h-.353a1.368 1.368 0 0 0-1.277.842c-.07.168-.107.348-.109.53v7.1a1.392 1.392 0 0 0 .412.974 1.352 1.352 0 0 0 .974.394h9.117c.363.001.711-.142.97-.4a1.39 1.39 0 0 0 .407-.972v-7.1a1.397 1.397 0 0 0-.414-.973 1.368 1.368 0 0 0-.972-.396Zm.37 8.469a.373.373 0 0 1-.11.26.364.364 0 0 1-.26.107H4.246a.366.366 0 0 1-.26-.107.374.374 0 0 1-.11-.261V8.349a.374.374 0 0 1 .11-.26.366.366 0 0 1 .26-.108h9.116a.366.366 0 0 1 .37.367l-.008 7.097Z"/></g><defs><clipPath id="a"><path fill="#fff" d="M.798.817h16v16h-16z"/></clipPath></defs></svg>';
const plusIcon = '<svg xmlns="http://www.w3.org/2000/svg" width="17" height="17" fill="none"><g clip-path="url(#a)"><path fill="#175DDC" fill-rule="evenodd" d="M9.607 7.15h5.35c.322 0 .627.133.847.362a1.213 1.213 0 0 1 .002 1.68c-.221.23-.527.363-.85.363H9.607v5.652c0 .312-.12.613-.336.839a1.176 1.176 0 0 1-1.696.003 1.21 1.21 0 0 1-.34-.842V9.555H1.888a1.173 1.173 0 0 1-.847-.361A1.193 1.193 0 0 1 .7 8.352a1.219 1.219 0 0 1 .336-.838 1.175 1.175 0 0 1 .85-.364h5.349V1.635c0-.31.118-.611.336-.84A1.176 1.176 0 0 1 9.268.795c.222.228.34.533.34.841V7.15Z" clip-rule="evenodd"/></g><defs><clipPath id="a"><path fill="#fff" d="M.421.421h16v16h-16z"/></clipPath></defs></svg>';
const viewCipherIcon = '<svg xmlns="http://www.w3.org/2000/svg" width="20" height="20" viewBox="0 0 20 20" fill="none"><g clip-path="url(#a)"><path fill="#175DDC" d="M16.587 7.932H5.9a.455.455 0 0 1-.31-.12.393.393 0 0 1-.127-.287c0-.108.046-.211.128-.288a.455.455 0 0 1 .309-.119h10.687c.117 0 .228.043.31.12.082.076.128.179.128.287a.393.393 0 0 1-.128.288.455.455 0 0 1-.31.119Zm0 2.474H5.9a.455.455 0 0 1-.31-.119.393.393 0 0 1-.127-.287c0-.108.046-.212.128-.288a.455.455 0 0 1 .309-.119h10.687c.117 0 .228.043.31.12.082.075.128.179.128.287a.393.393 0 0 1-.128.287.455.455 0 0 1-.31.12Zm0 2.468H5.9a.455.455 0 0 1-.31-.119.393.393 0 0 1-.127-.287c0-.108.046-.212.128-.288a.455.455 0 0 1 .309-.119h10.687c.117 0 .228.043.31.12.082.075.128.179.128.287a.393.393 0 0 1-.128.287.455.455 0 0 1-.31.12Zm2.163-8.103v10.457H1.25V4.771h17.5Zm0-1.162H1.25a1.3 1.3 0 0 0-.884.34A1.122 1.122 0 0 0 0 4.772v10.457c0 .308.132.604.366.822a1.3 1.3 0 0 0 .884.34h17.5a1.3 1.3 0 0 0 .884-.34c.234-.218.366-.514.366-.822V4.771c0-.308-.132-.603-.366-.821a1.3 1.3 0 0 0-.884-.34ZM3.213 8.01c.287 0 .52-.217.52-.484s-.234-.483-.52-.483c-.288 0-.52.216-.52.483s.233.483.52.483Zm0 4.903c.287 0 .52-.217.52-.484 0-.266-.234-.483-.52-.483-.287 0-.52.216-.52.483s.233.484.52.484Zm0-2.452c.287 0 .52-.216.52-.483 0-.268-.234-.484-.52-.484-.288 0-.52.216-.52.484 0 .267.233.483.52.483Z"/></g><defs><clipPath id="a"><path fill="#fff" d="M0 .113h20v19.773H0z"/></clipPath></defs></svg>';
const passkeyIcon = '<svg xmlns="http://www.w3.org/2000/svg" width="14" height="15" viewBox="0 0 14 15" fill="none"><path fill="#6D757E" d="M2.35 12.112a.713.713 0 1 1 0-1.426.713.713 0 0 1 0 1.426Z"/><path fill="#6D757E" fill-rule="evenodd" d="M4.597 7.695a3.5 3.5 0 1 1 3.741 0A5.33 5.33 0 0 1 10.5 9.186c.154.172.29.328.384.461l1.562-.001L14 11.14l-2.188 1.952-.874-.875-.876.875-.874-.875-.876.84-2.613-.003a3.152 3.152 0 0 1-2.634 1.307c-1.729-.036-3.101-1.436-3.064-3.127C.038 9.543 1.469 8.2 3.199 8.237c.098.002.195.009.291.02a6.76 6.76 0 0 1 .296-.181c.257-.149.528-.276.81-.381Zm1.176 1.957 3.952-.004a4.11 4.11 0 0 0-.498-.462 4.452 4.452 0 0 0-2.76-.95c-.647 0-1.262.137-1.817.384a3.12 3.12 0 0 1 1.123 1.032Zm-1.93-4.916a2.625 2.625 0 1 0 5.25 0 2.625 2.625 0 0 0-5.25 0Zm1.407 7.442-.262.366a2.277 2.277 0 0 1-1.904.942C1.819 13.459.85 12.442.876 11.253c.025-1.19 1.04-2.168 2.304-2.141a2.27 2.27 0 0 1 1.86 1.019l.26.396 6.794-.006.619.595-.866.773-.91-.909-.874.875-.863-.862-1.239 1.19-2.711-.005Z" clip-rule="evenodd"/></svg>';
const circleCheckIcon = '<svg xmlns="http://www.w3.org/2000/svg" width="16" height="16" fill="none"><g clip-path="url(#a)"><path fill="#017E45" d="M8 15.5a8.383 8.383 0 0 1-4.445-1.264A7.627 7.627 0 0 1 .61 10.87a7.063 7.063 0 0 1-.455-4.333 7.368 7.368 0 0 1 2.19-3.84A8.181 8.181 0 0 1 6.438.644a8.498 8.498 0 0 1 4.623.427 7.912 7.912 0 0 1 3.59 2.762A7.171 7.171 0 0 1 16 8c-.002 1.988-.846 3.895-2.345 5.3-1.5 1.406-3.534 2.198-5.655 2.2ZM8 1.437a7.337 7.337 0 0 0-3.889 1.106 6.672 6.672 0 0 0-2.578 2.945 6.182 6.182 0 0 0-.399 3.792 6.448 6.448 0 0 0 1.916 3.36 7.156 7.156 0 0 0 3.584 1.796 7.434 7.434 0 0 0 4.044-.374 6.924 6.924 0 0 0 3.142-2.417A6.275 6.275 0 0 0 15 8c-.002-1.74-.74-3.407-2.053-4.638C11.635 2.131 9.856 1.44 8 1.437Zm-1.351 9.905a.361.361 0 0 1-.245-.094l-2.257-2.07a.326.326 0 0 1-.103-.232c0-.043.009-.085.027-.125a.334.334 0 0 1 .076-.107.366.366 0 0 1 .246-.097c.093 0 .182.033.249.093l1.843 1.687a.166.166 0 0 0 .126.044.17.17 0 0 0 .066-.018.157.157 0 0 0 .052-.041l4.623-5.636a.34.34 0 0 1 .102-.088.375.375 0 0 1 .27-.038.34.34 0 0 1 .216.156.311.311 0 0 1-.033.37L6.93 11.21a.344.344 0 0 1-.112.09.376.376 0 0 1-.141.039l-.03.003h.001Z"/></g><defs><clipPath id="a"><path fill="#fff" d="M0 .5h16v15H0z"/></clipPath></defs></svg>';
const spinnerIcon = '<svg xmlns="http://www.w3.org/2000/svg" width="16" height="16" viewBox="0 0 16 16" fill="none"><g clip-path="url(#a)"><path fill="#5A6D91" d="M4.869 15.015a.588.588 0 1 0 0-1.177.588.588 0 0 0 0 1.177ZM8.252 16a.588.588 0 1 0 0-1.176.588.588 0 0 0 0 1.176Zm3.683-.911a.589.589 0 1 0 0-1.177.589.589 0 0 0 0 1.177ZM2.43 12.882a.693.693 0 1 0 0-1.387.693.693 0 0 0 0 1.387ZM1.318 9.738a.82.82 0 1 0 0-1.64.82.82 0 0 0 0 1.64Zm.69-3.578a.968.968 0 1 0 0-1.937.968.968 0 0 0 0 1.937ZM4.81 3.337a1.175 1.175 0 1 0 0-2.35 1.175 1.175 0 0 0 0 2.35Zm4.597-.676a1.33 1.33 0 1 0 0-2.661 1.33 1.33 0 0 0 0 2.66Zm4.543 2.954a1.553 1.553 0 1 0 0-3.105 1.553 1.553 0 0 0 0 3.105Z"/></g><defs><clipPath id="a"><path fill="#fff" d="M0 0h16v16H0z"/></clipPath></defs></svg>';
const keyIcon = '<svg xmlns="http://www.w3.org/2000/svg" width="24" height="25" viewBox="0 0 24 25" fill="none"><g clip-path="url(#a)"><path fill="#175DDC" d="M21.803 3.035a7.453 7.453 0 0 0-2.427-1.567 7.763 7.763 0 0 0-2.877-.551c-.988 0-1.967.187-2.878.55a7.455 7.455 0 0 0-2.427 1.568A7.193 7.193 0 0 0 9.283 6.23a6.936 6.936 0 0 0-.023 3.675.556.556 0 0 1-.16.549L.656 18.61a.77.77 0 0 0-.233.468l-.415 3.756a.722.722 0 0 0 .04.354.773.773 0 0 0 .203.3.85.85 0 0 0 .697.201l5.141-.855a.832.832 0 0 0 .461-.241.757.757 0 0 0 .211-.458l.108-1.162a.554.554 0 0 1 .17-.35.62.62 0 0 1 .365-.167l1.2-.105a.832.832 0 0 0 .503-.23.756.756 0 0 0 .23-.482l.124-1.326a.361.361 0 0 1 .111-.23.4.4 0 0 1 .24-.108l1.381-.113a.815.815 0 0 0 .501-.225l2.473-2.386a.506.506 0 0 1 .48-.126 7.904 7.904 0 0 0 1.912.235 7.68 7.68 0 0 0 2.846-.539 7.344 7.344 0 0 0 2.402-1.546C23.213 11.905 24 10.069 24 8.155c0-1.914-.787-3.752-2.194-5.122l-.003.002Zm-10.81 7.148a5.496 5.496 0 0 1-.25-3.208 5.677 5.677 0 0 1 1.6-2.835 5.828 5.828 0 0 1 1.902-1.233 6.075 6.075 0 0 1 4.515 0 5.829 5.829 0 0 1 1.902 1.233c1.107 1.073 1.726 2.514 1.726 4.016 0 1.501-.62 2.943-1.726 4.016a5.925 5.925 0 0 1-2.93 1.537 6.135 6.135 0 0 1-3.339-.245.844.844 0 0 0-.85.182l-2.498 2.409a1.124 1.124 0 0 1-.682.308l-1.687.142a.839.839 0 0 0-.503.23.754.754 0 0 0-.23.482l-.105 1.13a.594.594 0 0 1-.181.374.653.653 0 0 1-.39.178l-1.171.1a.832.832 0 0 0-.503.23.755.755 0 0 0-.23.483l-.122 1.313a.474.474 0 0 1-.13.287.518.518 0 0 1-.288.151l-2.66.439a.36.36 0 0 1-.286-.084.314.314 0 0 1-.102-.266l.182-1.758a.724.724 0 0 1 .222-.449l8.636-8.333a.778.778 0 0 0 .215-.39.756.756 0 0 0-.036-.439h-.001Zm6.976-1.226c-.474 0-.938-.134-1.332-.384a2.31 2.31 0 0 1-.884-1.022 2.17 2.17 0 0 1-.137-1.317c.093-.442.321-.848.657-1.166a2.441 2.441 0 0 1 1.228-.624 2.516 2.516 0 0 1 1.386.13 2.37 2.37 0 0 1 1.077.84c.263.374.404.814.404 1.265 0 .605-.253 1.184-.703 1.611-.45.428-1.06.667-1.696.667Zm0-3.56c-.266 0-.527.075-.75.216-.221.14-.394.34-.496.575a1.22 1.22 0 0 0-.077.74c.053.249.18.477.37.657.189.18.43.3.691.35.262.05.533.025.78-.072.246-.097.457-.261.606-.472a1.235 1.235 0 0 0-.168-1.619 1.369 1.369 0 0 0-.954-.376v.002l-.002-.001Z"/></g><defs><clipPath id="a"><path fill="#fff" d="M0 .308h24v24H0z"/></clipPath></defs></svg>';
const refreshIcon = '<svg xmlns="http://www.w3.org/2000/svg" width="20" height="21" viewBox="0 0 20 21" fill="none"><g clip-path="url(#a)"><path fill="#175DDC" d="M18.383 11.37a.678.678 0 0 0-.496.086.65.65 0 0 0-.291.402 7.457 7.457 0 0 1-2.451 3.912 7.754 7.754 0 0 1-4.328 1.78 7.761 7.761 0 0 1-4.554-.901 7.502 7.502 0 0 1-3.167-3.318c-.025-.064.03-.159.165-.14l1.039.417a.687.687 0 0 0 .51.005.662.662 0 0 0 .365-.346.62.62 0 0 0-.142-.694.64.64 0 0 0-.214-.136l-2.656-1.061a.686.686 0 0 0-.854.31L.065 14.139a.621.621 0 0 0 .31.847.69.69 0 0 0 .639-.033.653.653 0 0 0 .247-.261l.4-.792a.167.167 0 0 1 .124-.077.173.173 0 0 1 .075.01.16.16 0 0 1 .063.04 8.813 8.813 0 0 0 3.29 3.627 9.109 9.109 0 0 0 4.764 1.358c.312 0 .632-.015.961-.044a9.223 9.223 0 0 0 5.065-2.116 8.871 8.871 0 0 0 2.89-4.578.628.628 0 0 0-.274-.656.655.655 0 0 0-.236-.095v.001Zm1.25-5.735a.693.693 0 0 0-.64.033.659.659 0 0 0-.247.262l-.4.79a.166.166 0 0 1-.261.028 8.809 8.809 0 0 0-3.29-3.63 9.113 9.113 0 0 0-4.764-1.36c-.311 0-.631.014-.961.045A9.224 9.224 0 0 0 4.004 3.92a8.863 8.863 0 0 0-2.89 4.58.622.622 0 0 0 .276.658.657.657 0 0 0 .237.094c.17.036.349.005.496-.086a.65.65 0 0 0 .29-.402 7.452 7.452 0 0 1 2.452-3.911 7.764 7.764 0 0 1 4.328-1.781 7.761 7.761 0 0 1 4.553.902 7.508 7.508 0 0 1 3.168 3.317c.023.063-.03.16-.165.138l-1.042-.42a.688.688 0 0 0-.509-.004.666.666 0 0 0-.367.345.622.622 0 0 0 .357.83l2.65 1.06c.156.064.33.067.489.01a.665.665 0 0 0 .365-.318l1.243-2.454a.622.622 0 0 0-.302-.843Z"/></g><defs><clipPath id="a"><path fill="#fff" d="M0 .421h20v19.773H0z"/></clipPath></defs></svg>';

;// ./src/autofill/notification/bar.ts
// FIXME: Update this file to be type safe and remove this and next line
// @ts-strict-ignore




// FIXME: Remove when updating file. Eslint update
// eslint-disable-next-line @typescript-eslint/no-require-imports
__webpack_require__(97321);
const logService = new ConsoleLogService(false);
let notificationBarIframeInitData = {};
let windowMessageOrigin;
const notificationBarWindowMessageHandlers = {
    initNotificationBar: ({ message }) => initNotificationBar(message),
    saveCipherAttemptCompleted: ({ message }) => handleSaveCipherAttemptCompletedMessage(message),
};
globalThis.addEventListener("load", load);
function load() {
    setupWindowMessageListener();
    postMessageToParent({ command: "initNotificationBar" });
}
function initNotificationBar(message) {
    const { initData } = message;
    if (!initData) {
        return;
    }
    notificationBarIframeInitData = initData;
    const { isVaultLocked } = notificationBarIframeInitData;
    setNotificationBarTheme();
    document.getElementById("logo").src = isVaultLocked
        ? chrome.runtime.getURL("images/icon38_locked.png")
        : chrome.runtime.getURL("images/icon38.png");
    const i18n = {
        appName: chrome.i18n.getMessage("appName"),
        close: chrome.i18n.getMessage("close"),
        never: chrome.i18n.getMessage("never"),
        folder: chrome.i18n.getMessage("folder"),
        notificationAddSave: chrome.i18n.getMessage("notificationAddSave"),
        notificationAddDesc: chrome.i18n.getMessage("notificationAddDesc"),
        notificationEdit: chrome.i18n.getMessage("edit"),
        notificationChangeSave: chrome.i18n.getMessage("notificationChangeSave"),
        notificationChangeDesc: chrome.i18n.getMessage("notificationChangeDesc"),
        notificationUnlock: chrome.i18n.getMessage("notificationUnlock"),
        notificationUnlockDesc: chrome.i18n.getMessage("notificationUnlockDesc"),
    };
    setupLogoLink(i18n);
    // i18n for "Add" template
    const addTemplate = document.getElementById("template-add");
    const neverButton = addTemplate.content.getElementById("never-save");
    neverButton.textContent = i18n.never;
    const selectFolder = addTemplate.content.getElementById("select-folder");
    selectFolder.hidden = isVaultLocked || removeIndividualVault();
    selectFolder.setAttribute("aria-label", i18n.folder);
    const addButton = addTemplate.content.getElementById("add-save");
    addButton.textContent = i18n.notificationAddSave;
    const addEditButton = addTemplate.content.getElementById("add-edit");
    // If Remove Individual Vault policy applies, "Add" opens the edit tab, so we hide the Edit button
    addEditButton.hidden = removeIndividualVault();
    addEditButton.textContent = i18n.notificationEdit;
    addTemplate.content.getElementById("add-text").textContent = i18n.notificationAddDesc;
    // i18n for "Change" (update password) template
    const changeTemplate = document.getElementById("template-change");
    const changeButton = changeTemplate.content.getElementById("change-save");
    changeButton.textContent = i18n.notificationChangeSave;
    const changeEditButton = changeTemplate.content.getElementById("change-edit");
    changeEditButton.textContent = i18n.notificationEdit;
    changeTemplate.content.getElementById("change-text").textContent = i18n.notificationChangeDesc;
    // i18n for "Unlock" (unlock extension) template
    const unlockTemplate = document.getElementById("template-unlock");
    const unlockButton = unlockTemplate.content.getElementById("unlock-vault");
    unlockButton.textContent = i18n.notificationUnlock;
    unlockTemplate.content.getElementById("unlock-text").textContent = i18n.notificationUnlockDesc;
    // i18n for body content
    const closeButton = document.getElementById("close-button");
    closeButton.title = i18n.close;
    const notificationType = initData.type;
    if (initData.type === "add") {
        handleTypeAdd();
    }
    else if (notificationType === "change") {
        handleTypeChange();
    }
    else if (notificationType === "unlock") {
        handleTypeUnlock();
    }
    closeButton.addEventListener("click", (e) => {
        e.preventDefault();
        sendPlatformMessage({
            command: "bgCloseNotificationBar",
        });
    });
    globalThis.addEventListener("resize", adjustHeight);
    adjustHeight();
}
function handleTypeAdd() {
    setContent(document.getElementById("template-add"));
    const addButton = document.getElementById("add-save");
    addButton.addEventListener("click", (e) => {
        e.preventDefault();
        // If Remove Individual Vault policy applies, "Add" opens the edit tab
        sendSaveCipherMessage(removeIndividualVault(), getSelectedFolder());
    });
    if (removeIndividualVault()) {
        // Everything past this point is only required if user has an individual vault
        return;
    }
    const editButton = document.getElementById("add-edit");
    editButton.addEventListener("click", (e) => {
        e.preventDefault();
        sendSaveCipherMessage(true, getSelectedFolder());
    });
    const neverButton = document.getElementById("never-save");
    neverButton.addEventListener("click", (e) => {
        e.preventDefault();
        sendPlatformMessage({
            command: "bgNeverSave",
        });
    });
    loadFolderSelector();
}
function handleTypeChange() {
    setContent(document.getElementById("template-change"));
    const changeButton = document.getElementById("change-save");
    changeButton.addEventListener("click", (e) => {
        e.preventDefault();
        sendSaveCipherMessage(false);
    });
    const editButton = document.getElementById("change-edit");
    editButton.addEventListener("click", (e) => {
        e.preventDefault();
        sendSaveCipherMessage(true);
    });
}
function sendSaveCipherMessage(edit, folder) {
    sendPlatformMessage({
        command: "bgSaveCipher",
        folder,
        edit,
    });
}
function handleSaveCipherAttemptCompletedMessage(message) {
    const addSaveButtonContainers = document.querySelectorAll(".add-change-cipher-buttons");
    const notificationBarOuterWrapper = document.getElementById("notification-bar-outer-wrapper");
    if (message === null || message === void 0 ? void 0 : message.error) {
        addSaveButtonContainers.forEach((element) => {
            element.textContent = chrome.i18n.getMessage("saveCipherAttemptFailed");
            element.classList.add("error-message");
            notificationBarOuterWrapper.classList.add("error-event");
        });
        adjustHeight();
        logService.error(`Error encountered when saving credentials: ${message.error}`);
        return;
    }
    const messageName = notificationBarIframeInitData.type === "add" ? "passwordSaved" : "passwordUpdated";
    addSaveButtonContainers.forEach((element) => {
        element.textContent = chrome.i18n.getMessage(messageName);
        element.prepend(buildSvgDomElement(circleCheckIcon));
        element.classList.add("success-message");
        notificationBarOuterWrapper.classList.add("success-event");
    });
    adjustHeight();
    globalThis.setTimeout(() => sendPlatformMessage({ command: "bgCloseNotificationBar", fadeOutNotification: true }), 3000);
}
function handleTypeUnlock() {
    setContent(document.getElementById("template-unlock"));
    const unlockButton = document.getElementById("unlock-vault");
    unlockButton.addEventListener("click", (e) => {
        sendPlatformMessage({
            command: "bgReopenUnlockPopout",
        });
    });
}
function setContent(template) {
    const content = document.getElementById("content");
    while (content.firstChild) {
        content.removeChild(content.firstChild);
    }
    const newElement = template.content.cloneNode(true);
    content.appendChild(newElement);
}
function sendPlatformMessage(msg, responseCallback) {
    chrome.runtime.sendMessage(msg, (response) => {
        if (responseCallback) {
            responseCallback(response);
        }
    });
}
function loadFolderSelector() {
    const populateFolderData = (folderData) => {
        const select = document.getElementById("select-folder");
        if (!(folderData === null || folderData === void 0 ? void 0 : folderData.length)) {
            select.appendChild(new Option(chrome.i18n.getMessage("noFoldersFound"), null, true));
            select.setAttribute("disabled", "true");
            return;
        }
        select.appendChild(new Option(chrome.i18n.getMessage("selectFolder"), null, true));
        folderData.forEach((folder) => {
            // Select "No Folder" (id=null) folder by default
            select.appendChild(new Option(folder.name, folder.id || "", false));
        });
    };
    sendPlatformMessage({ command: "bgGetFolderData" }, populateFolderData);
}
function getSelectedFolder() {
    return document.getElementById("select-folder").value;
}
function removeIndividualVault() {
    return notificationBarIframeInitData.removeIndividualVault;
}
function adjustHeight() {
    const data = {
        height: document.querySelector("body").scrollHeight,
    };
    sendPlatformMessage({
        command: "bgAdjustNotificationBar",
        data,
    });
}
function setupWindowMessageListener() {
    globalThis.addEventListener("message", handleWindowMessage);
}
function handleWindowMessage(event) {
    if (!windowMessageOrigin) {
        windowMessageOrigin = event.origin;
    }
    if (event.origin !== windowMessageOrigin) {
        return;
    }
    const message = event.data;
    const handler = notificationBarWindowMessageHandlers[message.command];
    if (!handler) {
        return;
    }
    handler({ message });
}
function setupLogoLink(i18n) {
    const logoLink = document.getElementById("logo-link");
    logoLink.title = i18n.appName;
    const setWebVaultUrlLink = (webVaultURL) => {
        const newVaultURL = webVaultURL && decodeURIComponent(webVaultURL);
        if (newVaultURL && newVaultURL !== logoLink.href) {
            logoLink.href = newVaultURL;
        }
    };
    sendPlatformMessage({ command: "getWebVaultUrlForNotification" }, setWebVaultUrlLink);
}
function setNotificationBarTheme() {
    let theme = notificationBarIframeInitData.theme;
    if (theme === ThemeTypes.System) {
        theme = globalThis.matchMedia("(prefers-color-scheme: dark)").matches
            ? ThemeTypes.Dark
            : ThemeTypes.Light;
    }
    document.documentElement.classList.add(`theme_${theme}`);
    if (notificationBarIframeInitData.applyRedesign) {
        document.body.classList.add("notification-bar-redesign");
    }
}
function postMessageToParent(message) {
    globalThis.parent.postMessage(message, windowMessageOrigin || "*");
}

/******/ })()
;