/******/ (function() { // webpackBootstrap
/******/ 	var __webpack_modules__ = ({

/***/ 70526:
/***/ (function() {

(function () {
  /*
  
   Copyright (c) 2016 The Polymer Project Authors. All rights reserved.
   This code may only be used under the BSD style license found at
   http://polymer.github.io/LICENSE.txt The complete set of authors may be found
   at http://polymer.github.io/AUTHORS.txt The complete set of contributors may
   be found at http://polymer.github.io/CONTRIBUTORS.txt Code distributed by
   Google as part of the polymer project is also subject to an additional IP
   rights grant found at http://polymer.github.io/PATENTS.txt
  */
  'use strict';

  var n = window.Document.prototype.createElement,
    p = window.Document.prototype.createElementNS,
    aa = window.Document.prototype.importNode,
    ba = window.Document.prototype.prepend,
    ca = window.Document.prototype.append,
    da = window.DocumentFragment.prototype.prepend,
    ea = window.DocumentFragment.prototype.append,
    q = window.Node.prototype.cloneNode,
    r = window.Node.prototype.appendChild,
    t = window.Node.prototype.insertBefore,
    u = window.Node.prototype.removeChild,
    v = window.Node.prototype.replaceChild,
    w = Object.getOwnPropertyDescriptor(window.Node.prototype, "textContent"),
    y = window.Element.prototype.attachShadow,
    z = Object.getOwnPropertyDescriptor(window.Element.prototype, "innerHTML"),
    A = window.Element.prototype.getAttribute,
    B = window.Element.prototype.setAttribute,
    C = window.Element.prototype.removeAttribute,
    D = window.Element.prototype.toggleAttribute,
    E = window.Element.prototype.getAttributeNS,
    F = window.Element.prototype.setAttributeNS,
    G = window.Element.prototype.removeAttributeNS,
    H = window.Element.prototype.insertAdjacentElement,
    fa = window.Element.prototype.insertAdjacentHTML,
    ha = window.Element.prototype.prepend,
    ia = window.Element.prototype.append,
    ja = window.Element.prototype.before,
    ka = window.Element.prototype.after,
    la = window.Element.prototype.replaceWith,
    ma = window.Element.prototype.remove,
    na = window.HTMLElement,
    I = Object.getOwnPropertyDescriptor(window.HTMLElement.prototype, "innerHTML"),
    oa = window.HTMLElement.prototype.insertAdjacentElement,
    pa = window.HTMLElement.prototype.insertAdjacentHTML;
  var qa = new Set();
  "annotation-xml color-profile font-face font-face-src font-face-uri font-face-format font-face-name missing-glyph".split(" ").forEach(function (a) {
    return qa.add(a);
  });
  function ra(a) {
    var b = qa.has(a);
    a = /^[a-z][.0-9_a-z]*-[-.0-9_a-z]*$/.test(a);
    return !b && a;
  }
  var sa = document.contains ? document.contains.bind(document) : document.documentElement.contains.bind(document.documentElement);
  function J(a) {
    var b = a.isConnected;
    if (void 0 !== b) return b;
    if (sa(a)) return !0;
    for (; a && !(a.__CE_isImportDocument || a instanceof Document);) a = a.parentNode || (window.ShadowRoot && a instanceof ShadowRoot ? a.host : void 0);
    return !(!a || !(a.__CE_isImportDocument || a instanceof Document));
  }
  function K(a) {
    var b = a.children;
    if (b) return Array.prototype.slice.call(b);
    b = [];
    for (a = a.firstChild; a; a = a.nextSibling) a.nodeType === Node.ELEMENT_NODE && b.push(a);
    return b;
  }
  function L(a, b) {
    for (; b && b !== a && !b.nextSibling;) b = b.parentNode;
    return b && b !== a ? b.nextSibling : null;
  }
  function M(a, b, d) {
    for (var f = a; f;) {
      if (f.nodeType === Node.ELEMENT_NODE) {
        var c = f;
        b(c);
        var e = c.localName;
        if ("link" === e && "import" === c.getAttribute("rel")) {
          f = c.import;
          void 0 === d && (d = new Set());
          if (f instanceof Node && !d.has(f)) for (d.add(f), f = f.firstChild; f; f = f.nextSibling) M(f, b, d);
          f = L(a, c);
          continue;
        } else if ("template" === e) {
          f = L(a, c);
          continue;
        }
        if (c = c.__CE_shadowRoot) for (c = c.firstChild; c; c = c.nextSibling) M(c, b, d);
      }
      f = f.firstChild ? f.firstChild : L(a, f);
    }
  }
  ;
  function N() {
    var a = !(null === O || void 0 === O || !O.noDocumentConstructionObserver),
      b = !(null === O || void 0 === O || !O.shadyDomFastWalk);
    this.m = [];
    this.g = [];
    this.j = !1;
    this.shadyDomFastWalk = b;
    this.I = !a;
  }
  function P(a, b, d, f) {
    var c = window.ShadyDOM;
    if (a.shadyDomFastWalk && c && c.inUse) {
      if (b.nodeType === Node.ELEMENT_NODE && d(b), b.querySelectorAll) for (a = c.nativeMethods.querySelectorAll.call(b, "*"), b = 0; b < a.length; b++) d(a[b]);
    } else M(b, d, f);
  }
  function ta(a, b) {
    a.j = !0;
    a.m.push(b);
  }
  function ua(a, b) {
    a.j = !0;
    a.g.push(b);
  }
  function Q(a, b) {
    a.j && P(a, b, function (d) {
      return R(a, d);
    });
  }
  function R(a, b) {
    if (a.j && !b.__CE_patched) {
      b.__CE_patched = !0;
      for (var d = 0; d < a.m.length; d++) a.m[d](b);
      for (d = 0; d < a.g.length; d++) a.g[d](b);
    }
  }
  function S(a, b) {
    var d = [];
    P(a, b, function (c) {
      return d.push(c);
    });
    for (b = 0; b < d.length; b++) {
      var f = d[b];
      1 === f.__CE_state ? a.connectedCallback(f) : T(a, f);
    }
  }
  function U(a, b) {
    var d = [];
    P(a, b, function (c) {
      return d.push(c);
    });
    for (b = 0; b < d.length; b++) {
      var f = d[b];
      1 === f.__CE_state && a.disconnectedCallback(f);
    }
  }
  function V(a, b, d) {
    d = void 0 === d ? {} : d;
    var f = d.J,
      c = d.upgrade || function (g) {
        return T(a, g);
      },
      e = [];
    P(a, b, function (g) {
      a.j && R(a, g);
      if ("link" === g.localName && "import" === g.getAttribute("rel")) {
        var h = g.import;
        h instanceof Node && (h.__CE_isImportDocument = !0, h.__CE_registry = document.__CE_registry);
        h && "complete" === h.readyState ? h.__CE_documentLoadHandled = !0 : g.addEventListener("load", function () {
          var k = g.import;
          if (!k.__CE_documentLoadHandled) {
            k.__CE_documentLoadHandled = !0;
            var l = new Set();
            f && (f.forEach(function (m) {
              return l.add(m);
            }), l.delete(k));
            V(a, k, {
              J: l,
              upgrade: c
            });
          }
        });
      } else e.push(g);
    }, f);
    for (b = 0; b < e.length; b++) c(e[b]);
  }
  function T(a, b) {
    try {
      var d = b.ownerDocument,
        f = d.__CE_registry;
      var c = f && (d.defaultView || d.__CE_isImportDocument) ? W(f, b.localName) : void 0;
      if (c && void 0 === b.__CE_state) {
        c.constructionStack.push(b);
        try {
          try {
            if (new c.constructorFunction() !== b) throw Error("The custom element constructor did not produce the element being upgraded.");
          } finally {
            c.constructionStack.pop();
          }
        } catch (k) {
          throw b.__CE_state = 2, k;
        }
        b.__CE_state = 1;
        b.__CE_definition = c;
        if (c.attributeChangedCallback && b.hasAttributes()) {
          var e = c.observedAttributes;
          for (c = 0; c < e.length; c++) {
            var g = e[c],
              h = b.getAttribute(g);
            null !== h && a.attributeChangedCallback(b, g, null, h, null);
          }
        }
        J(b) && a.connectedCallback(b);
      }
    } catch (k) {
      X(k);
    }
  }
  N.prototype.connectedCallback = function (a) {
    var b = a.__CE_definition;
    if (b.connectedCallback) try {
      b.connectedCallback.call(a);
    } catch (d) {
      X(d);
    }
  };
  N.prototype.disconnectedCallback = function (a) {
    var b = a.__CE_definition;
    if (b.disconnectedCallback) try {
      b.disconnectedCallback.call(a);
    } catch (d) {
      X(d);
    }
  };
  N.prototype.attributeChangedCallback = function (a, b, d, f, c) {
    var e = a.__CE_definition;
    if (e.attributeChangedCallback && -1 < e.observedAttributes.indexOf(b)) try {
      e.attributeChangedCallback.call(a, b, d, f, c);
    } catch (g) {
      X(g);
    }
  };
  function va(a, b, d, f) {
    var c = b.__CE_registry;
    if (c && (null === f || "http://www.w3.org/1999/xhtml" === f) && (c = W(c, d))) try {
      var e = new c.constructorFunction();
      if (void 0 === e.__CE_state || void 0 === e.__CE_definition) throw Error("Failed to construct '" + d + "': The returned value was not constructed with the HTMLElement constructor.");
      if ("http://www.w3.org/1999/xhtml" !== e.namespaceURI) throw Error("Failed to construct '" + d + "': The constructed element's namespace must be the HTML namespace.");
      if (e.hasAttributes()) throw Error("Failed to construct '" + d + "': The constructed element must not have any attributes.");
      if (null !== e.firstChild) throw Error("Failed to construct '" + d + "': The constructed element must not have any children.");
      if (null !== e.parentNode) throw Error("Failed to construct '" + d + "': The constructed element must not have a parent node.");
      if (e.ownerDocument !== b) throw Error("Failed to construct '" + d + "': The constructed element's owner document is incorrect.");
      if (e.localName !== d) throw Error("Failed to construct '" + d + "': The constructed element's local name is incorrect.");
      return e;
    } catch (g) {
      return X(g), b = null === f ? n.call(b, d) : p.call(b, f, d), Object.setPrototypeOf(b, HTMLUnknownElement.prototype), b.__CE_state = 2, b.__CE_definition = void 0, R(a, b), b;
    }
    b = null === f ? n.call(b, d) : p.call(b, f, d);
    R(a, b);
    return b;
  }
  function X(a) {
    var b = "",
      d = "",
      f = 0,
      c = 0;
    a instanceof Error ? (b = a.message, d = a.sourceURL || a.fileName || "", f = a.line || a.lineNumber || 0, c = a.column || a.columnNumber || 0) : b = "Uncaught " + String(a);
    var e = void 0;
    void 0 === ErrorEvent.prototype.initErrorEvent ? e = new ErrorEvent("error", {
      cancelable: !0,
      message: b,
      filename: d,
      lineno: f,
      colno: c,
      error: a
    }) : (e = document.createEvent("ErrorEvent"), e.initErrorEvent("error", !1, !0, b, d, f), e.preventDefault = function () {
      Object.defineProperty(this, "defaultPrevented", {
        configurable: !0,
        get: function () {
          return !0;
        }
      });
    });
    void 0 === e.error && Object.defineProperty(e, "error", {
      configurable: !0,
      enumerable: !0,
      get: function () {
        return a;
      }
    });
    window.dispatchEvent(e);
    e.defaultPrevented || console.error(a);
  }
  ;
  function wa() {
    var a = this;
    this.g = void 0;
    this.F = new Promise(function (b) {
      a.l = b;
    });
  }
  wa.prototype.resolve = function (a) {
    if (this.g) throw Error("Already resolved.");
    this.g = a;
    this.l(a);
  };
  function xa(a) {
    var b = document;
    this.l = void 0;
    this.h = a;
    this.g = b;
    V(this.h, this.g);
    "loading" === this.g.readyState && (this.l = new MutationObserver(this.G.bind(this)), this.l.observe(this.g, {
      childList: !0,
      subtree: !0
    }));
  }
  function ya(a) {
    a.l && a.l.disconnect();
  }
  xa.prototype.G = function (a) {
    var b = this.g.readyState;
    "interactive" !== b && "complete" !== b || ya(this);
    for (b = 0; b < a.length; b++) for (var d = a[b].addedNodes, f = 0; f < d.length; f++) V(this.h, d[f]);
  };
  function Y(a) {
    this.s = new Map();
    this.u = new Map();
    this.C = new Map();
    this.A = !1;
    this.B = new Map();
    this.o = function (b) {
      return b();
    };
    this.i = !1;
    this.v = [];
    this.h = a;
    this.D = a.I ? new xa(a) : void 0;
  }
  Y.prototype.H = function (a, b) {
    var d = this;
    if (!(b instanceof Function)) throw new TypeError("Custom element constructor getters must be functions.");
    za(this, a);
    this.s.set(a, b);
    this.v.push(a);
    this.i || (this.i = !0, this.o(function () {
      return Aa(d);
    }));
  };
  Y.prototype.define = function (a, b) {
    var d = this;
    if (!(b instanceof Function)) throw new TypeError("Custom element constructors must be functions.");
    za(this, a);
    Ba(this, a, b);
    this.v.push(a);
    this.i || (this.i = !0, this.o(function () {
      return Aa(d);
    }));
  };
  function za(a, b) {
    if (!ra(b)) throw new SyntaxError("The element name '" + b + "' is not valid.");
    if (W(a, b)) throw Error("A custom element with name '" + (b + "' has already been defined."));
    if (a.A) throw Error("A custom element is already being defined.");
  }
  function Ba(a, b, d) {
    a.A = !0;
    var f;
    try {
      var c = d.prototype;
      if (!(c instanceof Object)) throw new TypeError("The custom element constructor's prototype is not an object.");
      var e = function (m) {
        var x = c[m];
        if (void 0 !== x && !(x instanceof Function)) throw Error("The '" + m + "' callback must be a function.");
        return x;
      };
      var g = e("connectedCallback");
      var h = e("disconnectedCallback");
      var k = e("adoptedCallback");
      var l = (f = e("attributeChangedCallback")) && d.observedAttributes || [];
    } catch (m) {
      throw m;
    } finally {
      a.A = !1;
    }
    d = {
      localName: b,
      constructorFunction: d,
      connectedCallback: g,
      disconnectedCallback: h,
      adoptedCallback: k,
      attributeChangedCallback: f,
      observedAttributes: l,
      constructionStack: []
    };
    a.u.set(b, d);
    a.C.set(d.constructorFunction, d);
    return d;
  }
  Y.prototype.upgrade = function (a) {
    V(this.h, a);
  };
  function Aa(a) {
    if (!1 !== a.i) {
      a.i = !1;
      for (var b = [], d = a.v, f = new Map(), c = 0; c < d.length; c++) f.set(d[c], []);
      V(a.h, document, {
        upgrade: function (k) {
          if (void 0 === k.__CE_state) {
            var l = k.localName,
              m = f.get(l);
            m ? m.push(k) : a.u.has(l) && b.push(k);
          }
        }
      });
      for (c = 0; c < b.length; c++) T(a.h, b[c]);
      for (c = 0; c < d.length; c++) {
        for (var e = d[c], g = f.get(e), h = 0; h < g.length; h++) T(a.h, g[h]);
        (e = a.B.get(e)) && e.resolve(void 0);
      }
      d.length = 0;
    }
  }
  Y.prototype.get = function (a) {
    if (a = W(this, a)) return a.constructorFunction;
  };
  Y.prototype.whenDefined = function (a) {
    if (!ra(a)) return Promise.reject(new SyntaxError("'" + a + "' is not a valid custom element name."));
    var b = this.B.get(a);
    if (b) return b.F;
    b = new wa();
    this.B.set(a, b);
    var d = this.u.has(a) || this.s.has(a);
    a = -1 === this.v.indexOf(a);
    d && a && b.resolve(void 0);
    return b.F;
  };
  Y.prototype.polyfillWrapFlushCallback = function (a) {
    this.D && ya(this.D);
    var b = this.o;
    this.o = function (d) {
      return a(function () {
        return b(d);
      });
    };
  };
  function W(a, b) {
    var d = a.u.get(b);
    if (d) return d;
    if (d = a.s.get(b)) {
      a.s.delete(b);
      try {
        return Ba(a, b, d());
      } catch (f) {
        X(f);
      }
    }
  }
  Y.prototype.define = Y.prototype.define;
  Y.prototype.upgrade = Y.prototype.upgrade;
  Y.prototype.get = Y.prototype.get;
  Y.prototype.whenDefined = Y.prototype.whenDefined;
  Y.prototype.polyfillDefineLazy = Y.prototype.H;
  Y.prototype.polyfillWrapFlushCallback = Y.prototype.polyfillWrapFlushCallback;
  function Z(a, b, d) {
    function f(c) {
      return function (e) {
        for (var g = [], h = 0; h < arguments.length; ++h) g[h] = arguments[h];
        h = [];
        for (var k = [], l = 0; l < g.length; l++) {
          var m = g[l];
          m instanceof Element && J(m) && k.push(m);
          if (m instanceof DocumentFragment) for (m = m.firstChild; m; m = m.nextSibling) h.push(m);else h.push(m);
        }
        c.apply(this, g);
        for (g = 0; g < k.length; g++) U(a, k[g]);
        if (J(this)) for (g = 0; g < h.length; g++) k = h[g], k instanceof Element && S(a, k);
      };
    }
    void 0 !== d.prepend && (b.prepend = f(d.prepend));
    void 0 !== d.append && (b.append = f(d.append));
  }
  ;
  function Ca(a) {
    Document.prototype.createElement = function (b) {
      return va(a, this, b, null);
    };
    Document.prototype.importNode = function (b, d) {
      b = aa.call(this, b, !!d);
      this.__CE_registry ? V(a, b) : Q(a, b);
      return b;
    };
    Document.prototype.createElementNS = function (b, d) {
      return va(a, this, d, b);
    };
    Z(a, Document.prototype, {
      prepend: ba,
      append: ca
    });
  }
  ;
  function Da(a) {
    function b(f) {
      return function (c) {
        for (var e = [], g = 0; g < arguments.length; ++g) e[g] = arguments[g];
        g = [];
        for (var h = [], k = 0; k < e.length; k++) {
          var l = e[k];
          l instanceof Element && J(l) && h.push(l);
          if (l instanceof DocumentFragment) for (l = l.firstChild; l; l = l.nextSibling) g.push(l);else g.push(l);
        }
        f.apply(this, e);
        for (e = 0; e < h.length; e++) U(a, h[e]);
        if (J(this)) for (e = 0; e < g.length; e++) h = g[e], h instanceof Element && S(a, h);
      };
    }
    var d = Element.prototype;
    void 0 !== ja && (d.before = b(ja));
    void 0 !== ka && (d.after = b(ka));
    void 0 !== la && (d.replaceWith = function (f) {
      for (var c = [], e = 0; e < arguments.length; ++e) c[e] = arguments[e];
      e = [];
      for (var g = [], h = 0; h < c.length; h++) {
        var k = c[h];
        k instanceof Element && J(k) && g.push(k);
        if (k instanceof DocumentFragment) for (k = k.firstChild; k; k = k.nextSibling) e.push(k);else e.push(k);
      }
      h = J(this);
      la.apply(this, c);
      for (c = 0; c < g.length; c++) U(a, g[c]);
      if (h) for (U(a, this), c = 0; c < e.length; c++) g = e[c], g instanceof Element && S(a, g);
    });
    void 0 !== ma && (d.remove = function () {
      var f = J(this);
      ma.call(this);
      f && U(a, this);
    });
  }
  ;
  function Ea(a) {
    function b(c, e) {
      Object.defineProperty(c, "innerHTML", {
        enumerable: e.enumerable,
        configurable: !0,
        get: e.get,
        set: function (g) {
          var h = this,
            k = void 0;
          J(this) && (k = [], P(a, this, function (x) {
            x !== h && k.push(x);
          }));
          e.set.call(this, g);
          if (k) for (var l = 0; l < k.length; l++) {
            var m = k[l];
            1 === m.__CE_state && a.disconnectedCallback(m);
          }
          this.ownerDocument.__CE_registry ? V(a, this) : Q(a, this);
          return g;
        }
      });
    }
    function d(c, e) {
      c.insertAdjacentElement = function (g, h) {
        var k = J(h);
        g = e.call(this, g, h);
        k && U(a, h);
        J(g) && S(a, h);
        return g;
      };
    }
    function f(c, e) {
      function g(h, k) {
        for (var l = []; h !== k; h = h.nextSibling) l.push(h);
        for (k = 0; k < l.length; k++) V(a, l[k]);
      }
      c.insertAdjacentHTML = function (h, k) {
        h = h.toLowerCase();
        if ("beforebegin" === h) {
          var l = this.previousSibling;
          e.call(this, h, k);
          g(l || this.parentNode.firstChild, this);
        } else if ("afterbegin" === h) l = this.firstChild, e.call(this, h, k), g(this.firstChild, l);else if ("beforeend" === h) l = this.lastChild, e.call(this, h, k), g(l || this.firstChild, null);else if ("afterend" === h) l = this.nextSibling, e.call(this, h, k), g(this.nextSibling, l);else throw new SyntaxError("The value provided (" + String(h) + ") is not one of 'beforebegin', 'afterbegin', 'beforeend', or 'afterend'.");
      };
    }
    y && (Element.prototype.attachShadow = function (c) {
      c = y.call(this, c);
      if (a.j && !c.__CE_patched) {
        c.__CE_patched = !0;
        for (var e = 0; e < a.m.length; e++) a.m[e](c);
      }
      return this.__CE_shadowRoot = c;
    });
    z && z.get ? b(Element.prototype, z) : I && I.get ? b(HTMLElement.prototype, I) : ua(a, function (c) {
      b(c, {
        enumerable: !0,
        configurable: !0,
        get: function () {
          return q.call(this, !0).innerHTML;
        },
        set: function (e) {
          var g = "template" === this.localName,
            h = g ? this.content : this,
            k = p.call(document, this.namespaceURI, this.localName);
          for (k.innerHTML = e; 0 < h.childNodes.length;) u.call(h, h.childNodes[0]);
          for (e = g ? k.content : k; 0 < e.childNodes.length;) r.call(h, e.childNodes[0]);
        }
      });
    });
    Element.prototype.setAttribute = function (c, e) {
      if (1 !== this.__CE_state) return B.call(this, c, e);
      var g = A.call(this, c);
      B.call(this, c, e);
      e = A.call(this, c);
      a.attributeChangedCallback(this, c, g, e, null);
    };
    Element.prototype.setAttributeNS = function (c, e, g) {
      if (1 !== this.__CE_state) return F.call(this, c, e, g);
      var h = E.call(this, c, e);
      F.call(this, c, e, g);
      g = E.call(this, c, e);
      a.attributeChangedCallback(this, e, h, g, c);
    };
    Element.prototype.removeAttribute = function (c) {
      if (1 !== this.__CE_state) return C.call(this, c);
      var e = A.call(this, c);
      C.call(this, c);
      null !== e && a.attributeChangedCallback(this, c, e, null, null);
    };
    D && (Element.prototype.toggleAttribute = function (c, e) {
      if (1 !== this.__CE_state) return D.call(this, c, e);
      var g = A.call(this, c),
        h = null !== g;
      e = D.call(this, c, e);
      h !== e && a.attributeChangedCallback(this, c, g, e ? "" : null, null);
      return e;
    });
    Element.prototype.removeAttributeNS = function (c, e) {
      if (1 !== this.__CE_state) return G.call(this, c, e);
      var g = E.call(this, c, e);
      G.call(this, c, e);
      var h = E.call(this, c, e);
      g !== h && a.attributeChangedCallback(this, e, g, h, c);
    };
    oa ? d(HTMLElement.prototype, oa) : H && d(Element.prototype, H);
    pa ? f(HTMLElement.prototype, pa) : fa && f(Element.prototype, fa);
    Z(a, Element.prototype, {
      prepend: ha,
      append: ia
    });
    Da(a);
  }
  ;
  var Fa = {};
  function Ga(a) {
    function b() {
      var d = this.constructor;
      var f = document.__CE_registry.C.get(d);
      if (!f) throw Error("Failed to construct a custom element: The constructor was not registered with `customElements`.");
      var c = f.constructionStack;
      if (0 === c.length) return c = n.call(document, f.localName), Object.setPrototypeOf(c, d.prototype), c.__CE_state = 1, c.__CE_definition = f, R(a, c), c;
      var e = c.length - 1,
        g = c[e];
      if (g === Fa) throw Error("Failed to construct '" + f.localName + "': This element was already constructed.");
      c[e] = Fa;
      Object.setPrototypeOf(g, d.prototype);
      R(a, g);
      return g;
    }
    b.prototype = na.prototype;
    Object.defineProperty(HTMLElement.prototype, "constructor", {
      writable: !0,
      configurable: !0,
      enumerable: !1,
      value: b
    });
    window.HTMLElement = b;
  }
  ;
  function Ha(a) {
    function b(d, f) {
      Object.defineProperty(d, "textContent", {
        enumerable: f.enumerable,
        configurable: !0,
        get: f.get,
        set: function (c) {
          if (this.nodeType === Node.TEXT_NODE) f.set.call(this, c);else {
            var e = void 0;
            if (this.firstChild) {
              var g = this.childNodes,
                h = g.length;
              if (0 < h && J(this)) {
                e = Array(h);
                for (var k = 0; k < h; k++) e[k] = g[k];
              }
            }
            f.set.call(this, c);
            if (e) for (c = 0; c < e.length; c++) U(a, e[c]);
          }
        }
      });
    }
    Node.prototype.insertBefore = function (d, f) {
      if (d instanceof DocumentFragment) {
        var c = K(d);
        d = t.call(this, d, f);
        if (J(this)) for (f = 0; f < c.length; f++) S(a, c[f]);
        return d;
      }
      c = d instanceof Element && J(d);
      f = t.call(this, d, f);
      c && U(a, d);
      J(this) && S(a, d);
      return f;
    };
    Node.prototype.appendChild = function (d) {
      if (d instanceof DocumentFragment) {
        var f = K(d);
        d = r.call(this, d);
        if (J(this)) for (var c = 0; c < f.length; c++) S(a, f[c]);
        return d;
      }
      f = d instanceof Element && J(d);
      c = r.call(this, d);
      f && U(a, d);
      J(this) && S(a, d);
      return c;
    };
    Node.prototype.cloneNode = function (d) {
      d = q.call(this, !!d);
      this.ownerDocument.__CE_registry ? V(a, d) : Q(a, d);
      return d;
    };
    Node.prototype.removeChild = function (d) {
      var f = d instanceof Element && J(d),
        c = u.call(this, d);
      f && U(a, d);
      return c;
    };
    Node.prototype.replaceChild = function (d, f) {
      if (d instanceof DocumentFragment) {
        var c = K(d);
        d = v.call(this, d, f);
        if (J(this)) for (U(a, f), f = 0; f < c.length; f++) S(a, c[f]);
        return d;
      }
      c = d instanceof Element && J(d);
      var e = v.call(this, d, f),
        g = J(this);
      g && U(a, f);
      c && U(a, d);
      g && S(a, d);
      return e;
    };
    w && w.get ? b(Node.prototype, w) : ta(a, function (d) {
      b(d, {
        enumerable: !0,
        configurable: !0,
        get: function () {
          for (var f = [], c = this.firstChild; c; c = c.nextSibling) c.nodeType !== Node.COMMENT_NODE && f.push(c.textContent);
          return f.join("");
        },
        set: function (f) {
          for (; this.firstChild;) u.call(this, this.firstChild);
          null != f && "" !== f && r.call(this, document.createTextNode(f));
        }
      });
    });
  }
  ;
  var O = window.customElements;
  function Ia() {
    var a = new N();
    Ga(a);
    Ca(a);
    Z(a, DocumentFragment.prototype, {
      prepend: da,
      append: ea
    });
    Ha(a);
    Ea(a);
    window.CustomElementRegistry = Y;
    a = new Y(a);
    document.__CE_registry = a;
    Object.defineProperty(window, "customElements", {
      configurable: !0,
      enumerable: !0,
      value: a
    });
  }
  O && !O.forcePolyfill && "function" == typeof O.define && "function" == typeof O.get || Ia();
  window.__CE_installPolyfill = Ia;
}).call(self);

/***/ }),

/***/ 87281:
/***/ (function(__unused_webpack_module, __webpack_exports__, __webpack_require__) {

"use strict";
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
// This entry needs to be wrapped in an IIFE because it needs to be in strict mode.
!function() {
"use strict";

;// ./src/autofill/enums/autofill-overlay.enum.ts
const AutofillOverlayElement = {
    Button: "autofill-inline-menu-button",
    List: "autofill-inline-menu-list",
};
const AutofillOverlayPort = {
    Button: "autofill-inline-menu-button-port",
    ButtonMessageConnector: "autofill-inline-menu-button-message-connector",
    List: "autofill-inline-menu-list-port",
    ListMessageConnector: "autofill-inline-menu-list-message-connector",
};
const RedirectFocusDirection = {
    Current: "current",
    Previous: "previous",
    Next: "next",
};
var InlineMenuFillType;
(function (InlineMenuFillType) {
    InlineMenuFillType[InlineMenuFillType["AccountCreationUsername"] = 5] = "AccountCreationUsername";
    InlineMenuFillType[InlineMenuFillType["PasswordGeneration"] = 6] = "PasswordGeneration";
    InlineMenuFillType[InlineMenuFillType["CurrentPasswordUpdate"] = 7] = "CurrentPasswordUpdate";
})(InlineMenuFillType || (InlineMenuFillType = {}));
const InlineMenuAccountCreationFieldType = {
    Text: "text",
    Email: "email",
    Password: "password",
};
const MAX_SUB_FRAME_DEPTH = 8;

// EXTERNAL MODULE: ../../node_modules/@webcomponents/custom-elements/custom-elements.min.js
var custom_elements_min = __webpack_require__(70526);
;// ../../node_modules/lit/polyfill-support.js
!function (i) {
  "function" == typeof define && define.amd ? define(i) : i();
}(function () {
  "use strict";

  /**
       * @license
       * Copyright 2017 Google LLC
       * SPDX-License-Identifier: BSD-3-Clause
       */
  var i,
    n,
    o = "__scoped";
  null !== (i = globalThis.reactiveElementPolyfillSupport) && void 0 !== i || (globalThis.reactiveElementPolyfillSupport = function (i) {
    var n = i.ReactiveElement;
    if (void 0 !== window.ShadyCSS && (!window.ShadyCSS.nativeShadow || window.ShadyCSS.ApplyShim)) {
      var t = n.prototype;
      window.ShadyDOM && window.ShadyDOM.inUse && !0 === window.ShadyDOM.noPatch && window.ShadyDOM.patchElementProto(t);
      var d = t.createRenderRoot;
      t.createRenderRoot = function () {
        var i,
          n,
          t,
          w = this.localName;
        if (window.ShadyCSS.nativeShadow) return d.call(this);
        if (!this.constructor.hasOwnProperty(o)) {
          this.constructor[o] = !0;
          var v = this.constructor.elementStyles.map(function (i) {
            return i instanceof CSSStyleSheet ? Array.from(i.cssRules).reduce(function (i, n) {
              return i + n.cssText;
            }, "") : i.cssText;
          });
          null === (n = null === (i = window.ShadyCSS) || void 0 === i ? void 0 : i.ScopingShim) || void 0 === n || n.prepareAdoptedCssText(v, w), void 0 === this.constructor._$AJ && window.ShadyCSS.prepareTemplateStyles(document.createElement("template"), w);
        }
        return null !== (t = this.shadowRoot) && void 0 !== t ? t : this.attachShadow(this.constructor.shadowRootOptions);
      };
      var w = t.connectedCallback;
      t.connectedCallback = function () {
        w.call(this), this.hasUpdated && window.ShadyCSS.styleElement(this);
      };
      var v = t._$AE;
      t._$AE = function (i) {
        this.hasUpdated || window.ShadyCSS.styleElement(this), v.call(this, i);
      };
    }
  });
  var t,
    d = new Set(),
    w = new Map();
  null !== (n = globalThis.litHtmlPolyfillSupport) && void 0 !== n || (globalThis.litHtmlPolyfillSupport = function (i, n) {
    if (void 0 !== window.ShadyCSS && (!window.ShadyCSS.nativeShadow || window.ShadyCSS.ApplyShim)) {
      var o = function (i) {
          return void 0 !== i && !d.has(i);
        },
        t = function (i) {
          var n = w.get(i);
          return void 0 === n && w.set(i, n = []), n;
        },
        v = new Map(),
        l = i.createElement;
      i.createElement = function (n, d) {
        var w = l.call(i, n, d),
          v = null == d ? void 0 : d.scope;
        if (void 0 !== v && (window.ShadyCSS.nativeShadow || window.ShadyCSS.prepareTemplateDom(w, v), o(v))) {
          var r = t(v),
            u = w.content.querySelectorAll("style");
          r.push.apply(r, Array.from(u).map(function (i) {
            var n;
            return null === (n = i.parentNode) || void 0 === n || n.removeChild(i), i.textContent;
          }));
        }
        return w;
      };
      var r = document.createDocumentFragment(),
        u = document.createComment(""),
        s = n.prototype,
        e = s._$AI;
      s._$AI = function (i, n) {
        var v, l;
        void 0 === n && (n = this);
        var s = this._$AA.parentNode,
          a = null === (v = this.options) || void 0 === v ? void 0 : v.scope;
        if (s instanceof ShadowRoot && o(a)) {
          var h = this._$AA,
            f = this._$AB;
          r.appendChild(u), this._$AA = u, this._$AB = null, e.call(this, i, n);
          var c = (null == i ? void 0 : i._$litType$) ? this._$AH._$AD.el : document.createElement("template");
          if (function (i, n) {
            var o,
              v = t(i),
              l = 0 !== v.length;
            l && ((o = document.createElement("style")).textContent = v.join("\n"), n.content.appendChild(o)), d.add(i), w.delete(i), window.ShadyCSS.prepareTemplateStyles(n, i), l && window.ShadyCSS.nativeShadow && null !== (o = n.content.querySelector("style")) && n.content.appendChild(o);
          }(a, c), r.removeChild(u), null === (l = window.ShadyCSS) || void 0 === l ? void 0 : l.nativeShadow) {
            var y = c.content.querySelector("style");
            null !== y && r.appendChild(y.cloneNode(!0));
          }
          s.insertBefore(r, f), this._$AA = h, this._$AB = f;
        } else e.call(this, i, n);
      }, s._$AC = function (n) {
        var o,
          t = null === (o = this.options) || void 0 === o ? void 0 : o.scope,
          d = v.get(t);
        void 0 === d && v.set(t, d = new Map());
        var w = d.get(n.strings);
        return void 0 === w && d.set(n.strings, w = new i(n, this.options)), w;
      };
    }
  }), null !== (t = globalThis.litElementPolyfillSupport) && void 0 !== t || (globalThis.litElementPolyfillSupport = function (i) {
    var n = i.LitElement;
    if (void 0 !== window.ShadyCSS && (!window.ShadyCSS.nativeShadow || window.ShadyCSS.ApplyShim)) {
      n._$AJ = !0;
      var o = n.prototype,
        t = o.createRenderRoot;
      o.createRenderRoot = function () {
        return this.renderOptions.scope = this.localName, t.call(this);
      };
    }
  });
});
;// ../../libs/common/src/auth/enums/authentication-status.ts
var AuthenticationStatus;
(function (AuthenticationStatus) {
    AuthenticationStatus[AuthenticationStatus["LoggedOut"] = 0] = "LoggedOut";
    AuthenticationStatus[AuthenticationStatus["Locked"] = 1] = "Locked";
    AuthenticationStatus[AuthenticationStatus["Unlocked"] = 2] = "Unlocked";
})(AuthenticationStatus || (AuthenticationStatus = {}));

;// ../../libs/common/src/autofill/constants/match-patterns.ts
const CardExpiryDateDelimiters = ["/", "-", ".", " "];
// `CardExpiryDateDelimiters` is not intended solely for regex consumption,
// so we need to format it here
const ExpiryDateDelimitersPattern = "\\" +
    CardExpiryDateDelimiters.join("\\")
        // replace space character with the regex whitespace character class
        .replace(" ", "s");
const MonthPattern = "(([1]{1}[0-2]{1})|(0?[1-9]{1}))";
// Because we're dealing with expiry dates, we assume the year will be in current or next century (as of 2024)
const ExpiryFullYearPattern = "2[0-1]{1}\\d{2}";
const DelimiterPatternExpression = new RegExp(`[${ExpiryDateDelimitersPattern}]`, "g");
const IrrelevantExpiryCharactersPatternExpression = new RegExp(
// "nor digits" to ensure numbers are removed from guidance pattern, which aren't covered by ^\w
`[^\\d${ExpiryDateDelimitersPattern}]`, "g");
const MonthPatternExpression = new RegExp(`^${MonthPattern}$`);
const ExpiryFullYearPatternExpression = new RegExp(`^${ExpiryFullYearPattern}$`);

;// ../../libs/common/src/autofill/constants/index.ts
const TYPE_CHECK = {
    FUNCTION: "function",
    NUMBER: "number",
    STRING: "string",
};
const EVENTS = {
    CHANGE: "change",
    INPUT: "input",
    KEYDOWN: "keydown",
    KEYPRESS: "keypress",
    KEYUP: "keyup",
    BLUR: "blur",
    CLICK: "click",
    FOCUS: "focus",
    FOCUSIN: "focusin",
    FOCUSOUT: "focusout",
    SCROLL: "scroll",
    RESIZE: "resize",
    DOMCONTENTLOADED: "DOMContentLoaded",
    LOAD: "load",
    MESSAGE: "message",
    VISIBILITYCHANGE: "visibilitychange",
    MOUSEENTER: "mouseenter",
    MOUSELEAVE: "mouseleave",
    MOUSEUP: "mouseup",
    MOUSEOUT: "mouseout",
    SUBMIT: "submit",
};
const ClearClipboardDelay = {
    Never: null,
    TenSeconds: 10,
    TwentySeconds: 20,
    ThirtySeconds: 30,
    OneMinute: 60,
    TwoMinutes: 120,
    FiveMinutes: 300,
};
/* Context Menu item Ids */
const AUTOFILL_CARD_ID = "autofill-card";
const AUTOFILL_ID = "autofill";
const SHOW_AUTOFILL_BUTTON = "show-autofill-button";
const AUTOFILL_IDENTITY_ID = "autofill-identity";
const COPY_IDENTIFIER_ID = "copy-identifier";
const COPY_PASSWORD_ID = "copy-password";
const COPY_USERNAME_ID = "copy-username";
const COPY_VERIFICATION_CODE_ID = "copy-totp";
const CREATE_CARD_ID = "create-card";
const CREATE_IDENTITY_ID = "create-identity";
const CREATE_LOGIN_ID = "create-login";
const GENERATE_PASSWORD_ID = "generate-password";
const NOOP_COMMAND_SUFFIX = "noop";
const ROOT_ID = "root";
const SEPARATOR_ID = "separator";
const NOTIFICATION_BAR_LIFESPAN_MS = 150000; // 150 seconds
const AUTOFILL_OVERLAY_HANDLE_REPOSITION = "autofill-overlay-handle-reposition-event";
const AUTOFILL_OVERLAY_HANDLE_SCROLL = "autofill-overlay-handle-scroll-event";
const UPDATE_PASSKEYS_HEADINGS_ON_SCROLL = "update-passkeys-headings-on-scroll";
const AUTOFILL_TRIGGER_FORM_FIELD_SUBMIT = "autofill-trigger-form-field-submit";
const AutofillOverlayVisibility = {
    Off: 0,
    OnButtonClick: 1,
    OnFieldFocus: 2,
};
const BrowserClientVendors = {
    Chrome: "Chrome",
    Opera: "Opera",
    Edge: "Edge",
    Vivaldi: "Vivaldi",
    Unknown: "Unknown",
};
const BrowserShortcutsUris = {
    Chrome: "chrome://extensions/shortcuts",
    Opera: "opera://extensions/shortcuts",
    Edge: "edge://extensions/shortcuts",
    Vivaldi: "vivaldi://extensions/shortcuts",
    Unknown: "https://bitwarden.com/help/keyboard-shortcuts",
};
const DisablePasswordManagerUris = {
    Chrome: "chrome://settings/autofill",
    Opera: "opera://settings/autofill",
    Edge: "edge://settings/passwords",
    Vivaldi: "vivaldi://settings/autofill",
    Unknown: "https://bitwarden.com/help/disable-browser-autofill/",
};
const ExtensionCommand = {
    AutofillCommand: "autofill_cmd",
    AutofillCard: "autofill_card",
    AutofillIdentity: "autofill_identity",
    AutofillLogin: "autofill_login",
    OpenAutofillOverlay: "open_autofill_overlay",
    GeneratePassword: "generate_password",
    OpenPopup: "open_popup",
    LockVault: "lock_vault",
    NoopCommand: "noop",
};
const CLEAR_NOTIFICATION_LOGIN_DATA_DURATION = (/* unused pure expression or super */ null && (60 * 1000)); // 1 minute
const MAX_DEEP_QUERY_RECURSION_DEPTH = 4;


;// ../../libs/common/src/vault/enums/cipher-reprompt-type.ts
var CipherRepromptType;
(function (CipherRepromptType) {
    CipherRepromptType[CipherRepromptType["None"] = 0] = "None";
    CipherRepromptType[CipherRepromptType["Password"] = 1] = "Password";
})(CipherRepromptType || (CipherRepromptType = {}));

;// ../../libs/common/src/vault/enums/cipher-type.ts
var CipherType;
(function (CipherType) {
    CipherType[CipherType["Login"] = 1] = "Login";
    CipherType[CipherType["SecureNote"] = 2] = "SecureNote";
    CipherType[CipherType["Card"] = 3] = "Card";
    CipherType[CipherType["Identity"] = 4] = "Identity";
    CipherType[CipherType["SshKey"] = 5] = "SshKey";
})(CipherType || (CipherType = {}));

;// ../../libs/common/src/vault/enums/field-type.enum.ts
var FieldType;
(function (FieldType) {
    FieldType[FieldType["Text"] = 0] = "Text";
    FieldType[FieldType["Hidden"] = 1] = "Hidden";
    FieldType[FieldType["Boolean"] = 2] = "Boolean";
    FieldType[FieldType["Linked"] = 3] = "Linked";
})(FieldType || (FieldType = {}));

;// ../../libs/common/src/vault/enums/linked-id-type.enum.ts
// LoginView
var LoginLinkedId;
(function (LoginLinkedId) {
    LoginLinkedId[LoginLinkedId["Username"] = 100] = "Username";
    LoginLinkedId[LoginLinkedId["Password"] = 101] = "Password";
})(LoginLinkedId || (LoginLinkedId = {}));
// CardView
var CardLinkedId;
(function (CardLinkedId) {
    CardLinkedId[CardLinkedId["CardholderName"] = 300] = "CardholderName";
    CardLinkedId[CardLinkedId["ExpMonth"] = 301] = "ExpMonth";
    CardLinkedId[CardLinkedId["ExpYear"] = 302] = "ExpYear";
    CardLinkedId[CardLinkedId["Code"] = 303] = "Code";
    CardLinkedId[CardLinkedId["Brand"] = 304] = "Brand";
    CardLinkedId[CardLinkedId["Number"] = 305] = "Number";
})(CardLinkedId || (CardLinkedId = {}));
// IdentityView
var IdentityLinkedId;
(function (IdentityLinkedId) {
    IdentityLinkedId[IdentityLinkedId["Title"] = 400] = "Title";
    IdentityLinkedId[IdentityLinkedId["MiddleName"] = 401] = "MiddleName";
    IdentityLinkedId[IdentityLinkedId["Address1"] = 402] = "Address1";
    IdentityLinkedId[IdentityLinkedId["Address2"] = 403] = "Address2";
    IdentityLinkedId[IdentityLinkedId["Address3"] = 404] = "Address3";
    IdentityLinkedId[IdentityLinkedId["City"] = 405] = "City";
    IdentityLinkedId[IdentityLinkedId["State"] = 406] = "State";
    IdentityLinkedId[IdentityLinkedId["PostalCode"] = 407] = "PostalCode";
    IdentityLinkedId[IdentityLinkedId["Country"] = 408] = "Country";
    IdentityLinkedId[IdentityLinkedId["Company"] = 409] = "Company";
    IdentityLinkedId[IdentityLinkedId["Email"] = 410] = "Email";
    IdentityLinkedId[IdentityLinkedId["Phone"] = 411] = "Phone";
    IdentityLinkedId[IdentityLinkedId["Ssn"] = 412] = "Ssn";
    IdentityLinkedId[IdentityLinkedId["Username"] = 413] = "Username";
    IdentityLinkedId[IdentityLinkedId["PassportNumber"] = 414] = "PassportNumber";
    IdentityLinkedId[IdentityLinkedId["LicenseNumber"] = 415] = "LicenseNumber";
    IdentityLinkedId[IdentityLinkedId["FirstName"] = 416] = "FirstName";
    IdentityLinkedId[IdentityLinkedId["LastName"] = 417] = "LastName";
    IdentityLinkedId[IdentityLinkedId["FullName"] = 418] = "FullName";
})(IdentityLinkedId || (IdentityLinkedId = {}));

;// ../../libs/common/src/vault/enums/secure-note-type.enum.ts
var SecureNoteType;
(function (SecureNoteType) {
    SecureNoteType[SecureNoteType["Generic"] = 0] = "Generic";
})(SecureNoteType || (SecureNoteType = {}));

;// ../../libs/common/src/vault/enums/index.ts






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

;// ./src/autofill/overlay/inline-menu/pages/shared/autofill-inline-menu-page-element.ts
var autofill_inline_menu_page_element_awaiter = (undefined && undefined.__awaiter) || function (thisArg, _arguments, P, generator) {
    function adopt(value) { return value instanceof P ? value : new P(function (resolve) { resolve(value); }); }
    return new (P || (P = Promise))(function (resolve, reject) {
        function fulfilled(value) { try { step(generator.next(value)); } catch (e) { reject(e); } }
        function rejected(value) { try { step(generator["throw"](value)); } catch (e) { reject(e); } }
        function step(result) { result.done ? resolve(result.value) : adopt(result.value).then(fulfilled, rejected); }
        step((generator = generator.apply(thisArg, _arguments || [])).next());
    });
};
// FIXME: Update this file to be type safe and remove this and next line
// @ts-strict-ignore


class AutofillInlineMenuPageElement extends HTMLElement {
    constructor() {
        super();
        /**
         * Handles window messages from the parent window.
         *
         * @param event - The window message event
         */
        this.handleWindowMessage = (event) => {
            if (!this.windowMessageHandlers) {
                return;
            }
            if (!this.messageOrigin) {
                this.messageOrigin = event.origin;
            }
            if (event.origin !== this.messageOrigin) {
                return;
            }
            const message = event === null || event === void 0 ? void 0 : event.data;
            const handler = this.windowMessageHandlers[message === null || message === void 0 ? void 0 : message.command];
            if (!handler) {
                return;
            }
            handler({ message });
        };
        /**
         * Handles the window blur event.
         */
        this.handleWindowBlurEvent = () => {
            this.postMessageToParent({ command: "autofillInlineMenuBlurred" });
        };
        /**
         * Handles the document keydown event. Facilitates redirecting the
         * user focus in the right direction out of the inline menu. Also facilitates
         * closing the inline menu when the user presses the Escape key.
         *
         * @param event - The document keydown event
         */
        this.handleDocumentKeyDownEvent = (event) => {
            const listenedForKeys = new Set(["Tab", "Escape", "ArrowUp", "ArrowDown"]);
            if (!listenedForKeys.has(event.code)) {
                return;
            }
            event.preventDefault();
            event.stopPropagation();
            if (event.code === "Tab") {
                this.sendRedirectFocusOutMessage(event.shiftKey ? RedirectFocusDirection.Previous : RedirectFocusDirection.Next);
                return;
            }
            if (event.code === "Escape") {
                this.sendRedirectFocusOutMessage(RedirectFocusDirection.Current);
            }
        };
        this.shadowDom = this.attachShadow({ mode: "closed" });
    }
    /**
     * Initializes the inline menu page element. Facilitates ensuring that the page
     * is set up with the expected styles and translations.
     *
     * @param elementName - The name of the element, e.g. "button" or "list"
     * @param styleSheetUrl - The URL of the stylesheet to apply to the page
     * @param translations - The translations to apply to the page
     * @param portKey - Background generated key that allows the port to communicate with the background
     */
    initAutofillInlineMenuPage(elementName, styleSheetUrl, translations, portKey) {
        return autofill_inline_menu_page_element_awaiter(this, void 0, void 0, function* () {
            this.portKey = portKey;
            this.translations = translations;
            globalThis.document.documentElement.setAttribute("lang", this.getTranslation("locale"));
            globalThis.document.head.title = this.getTranslation(`${elementName}PageTitle`);
            this.shadowDom.innerHTML = "";
            const linkElement = globalThis.document.createElement("link");
            linkElement.setAttribute("rel", "stylesheet");
            linkElement.setAttribute("href", styleSheetUrl);
            return linkElement;
        });
    }
    /**
     * Posts a window message to the parent window.
     *
     * @param message - The message to post
     */
    postMessageToParent(message) {
        globalThis.parent.postMessage(Object.assign({ portKey: this.portKey }, message), "*");
    }
    /**
     * Gets a translation from the translations object.
     *
     * @param key - The key of the translation to get
     */
    getTranslation(key) {
        return this.translations[key] || "";
    }
    /**
     * Sets up global listeners for the window message, window blur, and
     * document keydown events.
     *
     * @param windowMessageHandlers - The window message handlers to use
     */
    setupGlobalListeners(windowMessageHandlers) {
        this.windowMessageHandlers = windowMessageHandlers;
        globalThis.addEventListener(EVENTS.MESSAGE, this.handleWindowMessage);
        globalThis.addEventListener(EVENTS.BLUR, this.handleWindowBlurEvent);
        globalThis.document.addEventListener(EVENTS.KEYDOWN, this.handleDocumentKeyDownEvent);
    }
    /**
     * Redirects the inline menu focus out to the previous element on KeyDown of the `Tab+Shift` keys.
     * Redirects the inline menu focus out to the next element on KeyDown of the `Tab` key.
     * Redirects the inline menu focus out to the current element on KeyDown of the `Escape` key.
     *
     * @param direction - The direction to redirect the focus out
     */
    sendRedirectFocusOutMessage(direction) {
        this.postMessageToParent({ command: "redirectAutofillInlineMenuFocusOut", direction });
    }
}

;// ./src/autofill/overlay/inline-menu/pages/list/autofill-inline-menu-list.ts
var autofill_inline_menu_list_awaiter = (undefined && undefined.__awaiter) || function (thisArg, _arguments, P, generator) {
    function adopt(value) { return value instanceof P ? value : new P(function (resolve) { resolve(value); }); }
    return new (P || (P = Promise))(function (resolve, reject) {
        function fulfilled(value) { try { step(generator.next(value)); } catch (e) { reject(e); } }
        function rejected(value) { try { step(generator["throw"](value)); } catch (e) { reject(e); } }
        function step(result) { result.done ? resolve(result.value) : adopt(result.value).then(fulfilled, rejected); }
        step((generator = generator.apply(thisArg, _arguments || [])).next());
    });
};
// FIXME: Update this file to be type safe and remove this and next line
// @ts-strict-ignore








class AutofillInlineMenuList extends AutofillInlineMenuPageElement {
    constructor() {
        super();
        this.eventHandlersMemo = {};
        this.ciphers = [];
        this.cipherListScrollIsDebounced = false;
        this.currentCipherIndex = 0;
        this.isPasskeyAuthInProgress = false;
        this.showCiphersPerPage = 6;
        this.headingBorderClass = "inline-menu-list-heading--bordered";
        this.inlineMenuListWindowMessageHandlers = {
            initAutofillInlineMenuList: ({ message }) => this.initAutofillInlineMenuList(message),
            checkAutofillInlineMenuListFocused: () => this.checkInlineMenuListFocused(),
            updateAutofillInlineMenuListCiphers: ({ message }) => this.updateListItems(message),
            updateAutofillInlineMenuGeneratedPassword: ({ message }) => this.handleUpdateAutofillInlineMenuGeneratedPassword(message),
            showSaveLoginInlineMenuList: () => this.handleShowSaveLoginInlineMenuList(),
            focusAutofillInlineMenuList: () => this.focusInlineMenuList(),
        };
        /**
         * Handles the click event for the unlock button.
         * Sends a message to the parent window to unlock the vault.
         */
        this.handleUnlockButtonClick = () => {
            this.postMessageToParent({ command: "unlockVault" });
        };
        /**
         * Handles the click event for the fill generated password button. Triggers
         * a message to the background script to fill the generated password.
         */
        this.handleFillGeneratedPasswordClick = () => {
            this.postMessageToParent({ command: "fillGeneratedPassword" });
        };
        /**
         * Handles the keyup event for the fill generated password button.
         *
         * @param event - The keyup event.
         */
        this.handleFillGeneratedPasswordKeyUp = (event) => {
            if (event.ctrlKey || event.altKey || event.metaKey || event.shiftKey) {
                return;
            }
            if (event.code === "Space") {
                this.handleFillGeneratedPasswordClick();
                return;
            }
            if (event.code === "ArrowRight" &&
                event.target instanceof HTMLElement &&
                event.target.nextElementSibling) {
                event.target.nextElementSibling.focus();
                event.target.parentElement.classList.add("remove-outline");
                return;
            }
        };
        /**
         * Handles the click event of the password regenerator button.
         *
         * @param event - The click event.
         */
        this.handleRefreshGeneratedPasswordClick = (event) => {
            var _a;
            if (event) {
                (_a = event.target
                    .closest(".password-generator-actions")) === null || _a === void 0 ? void 0 : _a.classList.add("remove-outline");
            }
            this.postMessageToParent({ command: "refreshGeneratedPassword" });
        };
        /**
         * Handles the keyup event for the password regenerator button.
         *
         * @param event - The keyup event.
         */
        this.handleRefreshGeneratedPasswordKeyUp = (event) => {
            if (event.ctrlKey || event.altKey || event.metaKey || event.shiftKey) {
                return;
            }
            if (event.code === "Space") {
                this.handleRefreshGeneratedPasswordClick();
                return;
            }
            if (event.code === "ArrowLeft" &&
                event.target instanceof HTMLElement &&
                event.target.previousElementSibling) {
                event.target.previousElementSibling.focus();
                event.target.parentElement.classList.remove("remove-outline");
                return;
            }
        };
        /**
         * Handles the click event for the new item button.
         * Sends a message to the parent window to add a new vault item.
         */
        this.handeNewItemButtonClick = () => {
            let addNewCipherType = this.inlineMenuFillType;
            if (this.showInlineMenuAccountCreation) {
                addNewCipherType = CipherType.Login;
            }
            this.postMessageToParent({
                command: "addNewVaultItem",
                addNewCipherType,
            });
        };
        /**
         * Handles updating the list of ciphers when the
         * user scrolls to the bottom of the list.
         */
        this.updateCiphersListOnScroll = (event) => {
            event.preventDefault();
            event.stopPropagation();
            if (this.cipherListScrollIsDebounced) {
                return;
            }
            this.cipherListScrollIsDebounced = true;
            if (this.cipherListScrollDebounceTimeout) {
                clearTimeout(this.cipherListScrollDebounceTimeout);
            }
            this.cipherListScrollDebounceTimeout = globalThis.setTimeout(this.handleDebouncedScrollEvent, 300);
        };
        /**
         * Debounced handler for updating the list of ciphers when the user scrolls to
         * the bottom of the list. Triggers at most once every 300ms.
         */
        this.handleDebouncedScrollEvent = () => {
            this.cipherListScrollIsDebounced = false;
            const cipherListScrollTop = this.ciphersList.scrollTop;
            this.updatePasskeysHeadingsOnScroll(cipherListScrollTop);
            if (this.allCiphersLoaded()) {
                return;
            }
            if (!this.ciphersListHeight) {
                this.ciphersListHeight = this.ciphersList.offsetHeight;
            }
            const scrollPercentage = (cipherListScrollTop / (this.ciphersList.scrollHeight - this.ciphersListHeight)) * 100;
            if (scrollPercentage >= 80) {
                this.loadPageOfCiphers();
            }
        };
        /**
         * Throttled handler for updating the passkeys and login headings when the user scrolls the ciphers list.
         *
         * @param event - The scroll event.
         */
        this.handleThrottledOnScrollEvent = (event) => {
            event.preventDefault();
            event.stopPropagation();
            this.updatePasskeysHeadingsOnScroll(this.ciphersList.scrollTop);
        };
        /**
         * Updates the passkeys and login headings when the user scrolls the ciphers list.
         *
         * @param cipherListScrollTop - The current scroll top position of the ciphers list.
         */
        this.updatePasskeysHeadingsOnScroll = (cipherListScrollTop) => {
            if (!this.showPasskeysLabels) {
                return;
            }
            if (this.passkeysHeadingElement) {
                this.togglePasskeysHeadingAnchored(cipherListScrollTop);
                this.togglePasskeysHeadingBorder(cipherListScrollTop);
            }
            if (this.loginHeadingElement) {
                this.toggleLoginHeadingBorder(cipherListScrollTop);
            }
        };
        /**
         * Handles the click event for the fill cipher button.
         * Sends a message to the parent window to fill the selected cipher.
         *
         * @param cipher - The cipher to fill.
         */
        this.handleFillCipherClickEvent = (cipher) => {
            var _a;
            const usePasskey = !!((_a = cipher.login) === null || _a === void 0 ? void 0 : _a.passkey);
            return this.useEventHandlersMemo(() => this.triggerFillCipherClickEvent(cipher, usePasskey), `${cipher.id}-fill-cipher-button-click-handler-${usePasskey ? "passkey" : ""}`);
        };
        /**
         * Triggers a fill of the currently selected cipher.
         *
         * @param cipher - The cipher to fill.
         * @param usePasskey - Whether the cipher uses a passkey.
         */
        this.triggerFillCipherClickEvent = (cipher, usePasskey) => {
            if (usePasskey) {
                this.createPasskeyAuthenticatingLoader();
            }
            this.postMessageToParent({
                command: "fillAutofillInlineMenuCipher",
                inlineMenuCipherId: cipher.id,
                usePasskey,
            });
        };
        /**
         * Handles the keyup event for the fill cipher button. Facilitates
         * selecting the next/previous cipher item on ArrowDown/ArrowUp. Also
         * facilitates moving keyboard focus to the view cipher button on ArrowRight.
         *
         * @param event - The keyup event.
         */
        this.handleFillCipherKeyUpEvent = (event) => {
            const listenedForKeys = new Set(["ArrowDown", "ArrowUp", "ArrowRight"]);
            if (!listenedForKeys.has(event.code) || !(event.target instanceof Element)) {
                return;
            }
            event.preventDefault();
            const currentListItem = event.target.closest(".inline-menu-list-actions-item");
            if (event.code === "ArrowDown") {
                this.focusNextListItem(currentListItem);
                return;
            }
            if (event.code === "ArrowUp") {
                this.focusPreviousListItem(currentListItem);
                return;
            }
            this.focusViewCipherButton(currentListItem, event.target);
        };
        /**
         * Handles the keyup event for the "New Item" button. Allows for keyboard navigation
         * between ciphers elements if the other ciphers exist in the inline menu.
         *
         * @param event - The captured keyup event.
         */
        this.handleNewItemButtonKeyUpEvent = (event) => {
            var _a, _b;
            const listenedForKeys = new Set(["ArrowDown", "ArrowUp"]);
            if (!listenedForKeys.has(event.code) || !(event.target instanceof Element)) {
                return;
            }
            if (event.code === "ArrowDown") {
                const firstFillButton = (_a = this.ciphersList.firstElementChild) === null || _a === void 0 ? void 0 : _a.querySelector(".fill-cipher-button");
                firstFillButton === null || firstFillButton === void 0 ? void 0 : firstFillButton.focus();
                return;
            }
            const lastFillButton = (_b = this.ciphersList.lastElementChild) === null || _b === void 0 ? void 0 : _b.querySelector(".fill-cipher-button");
            lastFillButton === null || lastFillButton === void 0 ? void 0 : lastFillButton.focus();
        };
        /**
         * Handles the click event for the view cipher button. Sends a
         * message to the parent window to view the selected cipher.
         *
         * @param cipher - The cipher to view.
         */
        this.handleViewCipherClickEvent = (cipher) => {
            return this.useEventHandlersMemo(() => this.postMessageToParent({ command: "viewSelectedCipher", inlineMenuCipherId: cipher.id }), `${cipher.id}-view-cipher-button-click-handler`);
        };
        /**
         * Handles the keyup event for the view cipher button. Facilitates
         * selecting the next/previous cipher item on ArrowDown/ArrowUp.
         * Also facilitates moving keyboard focus to the current fill
         * cipher button on ArrowLeft.
         *
         * @param event - The keyup event.
         */
        this.handleViewCipherKeyUpEvent = (event) => {
            const listenedForKeys = new Set(["ArrowDown", "ArrowUp", "ArrowLeft"]);
            if (!listenedForKeys.has(event.code) || !(event.target instanceof Element)) {
                return;
            }
            event.preventDefault();
            const currentListItem = event.target.closest(".inline-menu-list-actions-item");
            const cipherContainer = currentListItem.querySelector(".cipher-container");
            cipherContainer === null || cipherContainer === void 0 ? void 0 : cipherContainer.classList.remove("remove-outline");
            if (event.code === "ArrowDown") {
                this.focusNextListItem(currentListItem);
                return;
            }
            if (event.code === "ArrowUp") {
                this.focusPreviousListItem(currentListItem);
                return;
            }
            const previousSibling = event.target.previousElementSibling;
            previousSibling === null || previousSibling === void 0 ? void 0 : previousSibling.focus();
        };
        /**
         * Triggers a re-check of the list's focus status when the mouse leaves the list.
         */
        this.handleMouseOutEvent = () => {
            globalThis.document.removeEventListener(EVENTS.MOUSEOUT, this.handleMouseOutEvent);
            this.checkInlineMenuListFocused();
        };
        /**
         * Validates whether the inline menu list iframe is currently hovered.
         */
        this.isListHovered = () => {
            var _a;
            const hoveredElement = (_a = this.inlineMenuListContainer) === null || _a === void 0 ? void 0 : _a.querySelector(":hover");
            return !!(hoveredElement &&
                (hoveredElement === this.inlineMenuListContainer ||
                    this.inlineMenuListContainer.contains(hoveredElement)));
        };
        /**
         * Handles the resize observer event. Facilitates updating the height of the
         * inline menu list iframe when the height of the list changes.
         *
         * @param entries - The resize observer entries.
         */
        this.handleResizeObserver = (entries) => {
            for (let entryIndex = 0; entryIndex < entries.length; entryIndex++) {
                const entry = entries[entryIndex];
                if (entry.target !== this.inlineMenuListContainer) {
                    continue;
                }
                const { height } = entry.contentRect;
                this.toggleScrollClass(height);
                this.postMessageToParent({
                    command: "updateAutofillInlineMenuListHeight",
                    styles: { height: `${height}px` },
                });
                break;
            }
        };
        /**
         * Toggles the scrollbar class on the inline menu list actions container.
         *
         * @param height - The height of the inline menu list actions container.
         */
        this.toggleScrollClass = (height) => {
            if (!this.ciphersList) {
                return;
            }
            const scrollbarClass = "inline-menu-list-actions--scrollbar";
            let containerHeight = height;
            if (!containerHeight) {
                const inlineMenuListContainerRects = this.inlineMenuListContainer.getBoundingClientRect();
                containerHeight = inlineMenuListContainerRects.height;
            }
            if (containerHeight >= 170) {
                this.ciphersList.classList.add(scrollbarClass);
                return;
            }
            this.ciphersList.classList.remove(scrollbarClass);
        };
        /**
         * Establishes a memoized event handler for a given event.
         *
         * @param eventHandler - The event handler to memoize.
         * @param memoIndex - The memo index to use for the event handler.
         */
        this.useEventHandlersMemo = (eventHandler, memoIndex) => {
            return this.eventHandlersMemo[memoIndex] || (this.eventHandlersMemo[memoIndex] = eventHandler);
        };
        /**
         * Identifies if the current focused field is filled by a login cipher.
         */
        this.isFilledByLoginCipher = () => {
            return this.inlineMenuFillType === CipherType.Login;
        };
        /**
         * Identifies if the current focused field is filled by a card cipher.
         */
        this.isFilledByCardCipher = () => {
            return this.inlineMenuFillType === CipherType.Card;
        };
        /**
         * Identifies if the current focused field is filled by an identity cipher.
         */
        this.isFilledByIdentityCipher = () => {
            return this.inlineMenuFillType === CipherType.Identity;
        };
        /**
         * Identifies if the passed list item is a heading element.
         *
         * @param listItem - The list item to check.
         */
        this.listItemIsHeadingElement = (listItem) => {
            return listItem === this.passkeysHeadingElement || listItem === this.loginHeadingElement;
        };
        this.setupInlineMenuListGlobalListeners();
    }
    /**
     * Initializes the inline menu list and updates the list items with the passed ciphers.
     * If the auth status is not `Unlocked`, the locked inline menu is built.
     *
     * @param message - The message containing the data to initialize the inline menu list.
     */
    initAutofillInlineMenuList(message) {
        return autofill_inline_menu_list_awaiter(this, void 0, void 0, function* () {
            const { translations, styleSheetUrl, theme, authStatus, ciphers, portKey, inlineMenuFillType, showInlineMenuAccountCreation, showPasskeysLabels, generatedPassword, showSaveLoginMenu, } = message;
            const linkElement = yield this.initAutofillInlineMenuPage("list", styleSheetUrl, translations, portKey);
            this.authStatus = authStatus;
            this.inlineMenuFillType = inlineMenuFillType;
            this.showPasskeysLabels = showPasskeysLabels;
            const themeClass = `theme_${theme}`;
            globalThis.document.documentElement.classList.add(themeClass);
            this.inlineMenuListContainer = globalThis.document.createElement("div");
            this.inlineMenuListContainer.classList.add("inline-menu-list-container", themeClass);
            this.resizeObserver.observe(this.inlineMenuListContainer);
            this.shadowDom.append(linkElement, this.inlineMenuListContainer);
            if (authStatus !== AuthenticationStatus.Unlocked) {
                this.buildLockedInlineMenu();
                return;
            }
            if (showSaveLoginMenu) {
                this.buildSaveLoginInlineMenuList();
                return;
            }
            if (generatedPassword) {
                this.buildPasswordGenerator(generatedPassword);
                return;
            }
            this.updateListItems({
                ciphers,
                showInlineMenuAccountCreation,
            });
        });
    }
    /**
     * Builds the locked inline menu, which is displayed when the user is not authenticated.
     * Facilitates the ability to unlock the extension from the inline menu.
     */
    buildLockedInlineMenu() {
        const lockedInlineMenu = globalThis.document.createElement("div");
        lockedInlineMenu.id = "locked-inline-menu-description";
        lockedInlineMenu.classList.add("locked-inline-menu", "inline-menu-list-message");
        lockedInlineMenu.textContent = this.getTranslation("unlockYourAccountToViewAutofillSuggestions");
        const unlockButtonElement = globalThis.document.createElement("button");
        unlockButtonElement.id = "unlock-button";
        unlockButtonElement.tabIndex = -1;
        unlockButtonElement.classList.add("unlock-button", "inline-menu-list-button", "inline-menu-list-action");
        unlockButtonElement.textContent = this.getTranslation("unlockAccount");
        unlockButtonElement.setAttribute("aria-label", this.getTranslation("unlockAccountAria"));
        unlockButtonElement.prepend(buildSvgDomElement(lockIcon));
        unlockButtonElement.addEventListener(EVENTS.CLICK, this.handleUnlockButtonClick);
        const inlineMenuListButtonContainer = this.buildButtonContainer(unlockButtonElement);
        this.inlineMenuListContainer.append(lockedInlineMenu, inlineMenuListButtonContainer);
    }
    /**
     * Builds the inline menu list as a prompt that asks the user if they'd like to save the login data.
     */
    buildSaveLoginInlineMenuList() {
        const saveLoginMessage = globalThis.document.createElement("div");
        saveLoginMessage.classList.add("save-login", "inline-menu-list-message");
        saveLoginMessage.textContent = this.getTranslation("saveLoginToBitwarden");
        const newItemButton = this.buildNewItemButton(true);
        this.showInlineMenuAccountCreation = true;
        this.inlineMenuListContainer.append(saveLoginMessage, newItemButton);
    }
    /**
     * Handles the show save login inline menu list message that is triggered from the background script.
     */
    handleShowSaveLoginInlineMenuList() {
        if (this.authStatus === AuthenticationStatus.Unlocked) {
            this.resetInlineMenuContainer();
            this.buildSaveLoginInlineMenuList();
        }
    }
    /**
     * Builds the password generator within the inline menu.
     *
     * @param generatedPassword - The generated password to display.
     */
    buildPasswordGenerator(generatedPassword) {
        this.passwordGeneratorContainer = globalThis.document.createElement("div");
        this.passwordGeneratorContainer.classList.add("password-generator-container");
        const passwordGeneratorActions = globalThis.document.createElement("div");
        passwordGeneratorActions.classList.add("password-generator-actions");
        const fillGeneratedPasswordButton = globalThis.document.createElement("button");
        fillGeneratedPasswordButton.tabIndex = -1;
        fillGeneratedPasswordButton.classList.add("fill-generated-password-button", "inline-menu-list-action");
        fillGeneratedPasswordButton.setAttribute("aria-label", this.getTranslation("fillGeneratedPassword"));
        const passwordGeneratorHeading = globalThis.document.createElement("div");
        passwordGeneratorHeading.classList.add("password-generator-heading");
        passwordGeneratorHeading.textContent = this.getTranslation("fillGeneratedPassword");
        const passwordGeneratorContent = globalThis.document.createElement("div");
        passwordGeneratorContent.id = "password-generator-content";
        passwordGeneratorContent.classList.add("password-generator-content");
        passwordGeneratorContent.append(passwordGeneratorHeading, this.buildColorizedPasswordElement(generatedPassword));
        fillGeneratedPasswordButton.append(buildSvgDomElement(keyIcon), passwordGeneratorContent);
        fillGeneratedPasswordButton.addEventListener(EVENTS.CLICK, this.handleFillGeneratedPasswordClick);
        fillGeneratedPasswordButton.addEventListener(EVENTS.KEYUP, this.handleFillGeneratedPasswordKeyUp);
        const refreshGeneratedPasswordButton = globalThis.document.createElement("button");
        refreshGeneratedPasswordButton.tabIndex = -1;
        refreshGeneratedPasswordButton.classList.add("refresh-generated-password-button", "inline-menu-list-action");
        refreshGeneratedPasswordButton.setAttribute("aria-label", this.getTranslation("regeneratePassword"));
        refreshGeneratedPasswordButton.appendChild(buildSvgDomElement(refreshIcon));
        refreshGeneratedPasswordButton.addEventListener(EVENTS.CLICK, this.handleRefreshGeneratedPasswordClick);
        refreshGeneratedPasswordButton.addEventListener(EVENTS.KEYUP, this.handleRefreshGeneratedPasswordKeyUp);
        passwordGeneratorActions.append(fillGeneratedPasswordButton, refreshGeneratedPasswordButton);
        this.passwordGeneratorContainer.appendChild(passwordGeneratorActions);
        this.inlineMenuListContainer.appendChild(this.passwordGeneratorContainer);
    }
    /**
     * Builds the colorized password content element.
     *
     * @param password - The password to display.
     */
    buildColorizedPasswordElement(password) {
        let ariaDescription = `${this.getTranslation("generatedPassword")}: `;
        const passwordContainer = globalThis.document.createElement("div");
        passwordContainer.classList.add("colorized-password");
        const appendPasswordCharacter = (character, type) => {
            const characterElement = globalThis.document.createElement("div");
            characterElement.classList.add(`password-${type}`);
            characterElement.textContent = character;
            passwordContainer.appendChild(characterElement);
        };
        const passwordArray = Array.from(password);
        for (let i = 0; i < passwordArray.length; i++) {
            const character = passwordArray[i];
            if (character.match(/\W/)) {
                appendPasswordCharacter(character, "special");
                ariaDescription += `${this.getTranslation(specialCharacterToKeyMap[character])} `;
                continue;
            }
            if (character.match(/\d/)) {
                appendPasswordCharacter(character, "number");
                ariaDescription += `${character} `;
                continue;
            }
            appendPasswordCharacter(character, "letter");
            ariaDescription +=
                character === character.toLowerCase()
                    ? `${this.getTranslation("lowercaseAriaLabel")} ${character} `
                    : `${this.getTranslation("uppercaseAriaLabel")} ${character} `;
        }
        passwordContainer.setAttribute("aria-label", ariaDescription);
        return passwordContainer;
    }
    /**
     * Updates the generated password content element with the passed generated password.
     *
     * @param message - The message containing the generated password.
     */
    handleUpdateAutofillInlineMenuGeneratedPassword(message) {
        if (this.authStatus !== AuthenticationStatus.Unlocked || !message.generatedPassword) {
            return;
        }
        const passwordGeneratorContentElement = this.inlineMenuListContainer.querySelector("#password-generator-content");
        const colorizedPasswordElement = passwordGeneratorContentElement === null || passwordGeneratorContentElement === void 0 ? void 0 : passwordGeneratorContentElement.querySelector(".colorized-password");
        if (!colorizedPasswordElement) {
            this.resetInlineMenuContainer();
            this.buildPasswordGenerator(message.generatedPassword);
            return;
        }
        colorizedPasswordElement.replaceWith(this.buildColorizedPasswordElement(message.generatedPassword));
    }
    /**
     * Filters the ciphers to include only TOTP-related ones if the field is a TOTP field.
     * If the field is a TOTP field but no TOTP is present, it returns an empty array.
     *
     * @param ciphers - The list of ciphers to filter.
     * @returns The filtered list of ciphers or an empty list if no valid TOTP ciphers are present.
     */
    getFilteredCiphersForTotpField(ciphers) {
        if (!(ciphers === null || ciphers === void 0 ? void 0 : ciphers.length)) {
            return [];
        }
        const isTotpField = this.inlineMenuFillType === CipherType.Login &&
            ciphers.some((cipher) => { var _a; return (_a = cipher.login) === null || _a === void 0 ? void 0 : _a.totpField; });
        if (isTotpField) {
            return ciphers.filter((cipher) => { var _a; return (_a = cipher.login) === null || _a === void 0 ? void 0 : _a.totp; });
        }
        return ciphers;
    }
    /**
     * Updates the list items with the passed ciphers.
     * If no ciphers are passed, the no results inline menu is built.
     *
     * @param ciphers - The ciphers to display in the inline menu list.
     * @param showInlineMenuAccountCreation - Whether identity ciphers are shown on login fields.
     */
    updateListItems({ ciphers, showInlineMenuAccountCreation, }) {
        var _a;
        if (this.isPasskeyAuthInProgress) {
            return;
        }
        this.ciphers = this.getFilteredCiphersForTotpField(ciphers);
        this.currentCipherIndex = 0;
        this.showInlineMenuAccountCreation = showInlineMenuAccountCreation;
        this.resetInlineMenuContainer();
        if (!((_a = this.ciphers) === null || _a === void 0 ? void 0 : _a.length)) {
            this.buildNoResultsInlineMenuList();
            return;
        }
        this.ciphersList = globalThis.document.createElement("ul");
        this.ciphersList.classList.add("inline-menu-list-actions");
        this.ciphersList.setAttribute("role", "list");
        this.setupCipherListScrollListeners();
        this.loadPageOfCiphers();
        this.inlineMenuListContainer.appendChild(this.ciphersList);
        this.toggleScrollClass();
        if (!this.showInlineMenuAccountCreation) {
            return;
        }
        const addNewLoginButtonContainer = this.buildNewItemButton();
        this.inlineMenuListContainer.appendChild(addNewLoginButtonContainer);
        this.inlineMenuListContainer.classList.add("inline-menu-list-container--with-new-item-button");
        this.newItemButtonElement.addEventListener(EVENTS.KEYUP, this.handleNewItemButtonKeyUpEvent);
    }
    /**
     * Clears and resets the inline menu list container.
     */
    resetInlineMenuContainer() {
        if (this.inlineMenuListContainer) {
            this.inlineMenuListContainer.innerHTML = "";
            this.inlineMenuListContainer.classList.remove("inline-menu-list-container--with-new-item-button");
        }
    }
    /**
     * Inline menu view that is presented when no ciphers are found for a given page.
     * Facilitates the ability to add a new vault item from the inline menu.
     */
    buildNoResultsInlineMenuList() {
        const noItemsMessage = globalThis.document.createElement("div");
        noItemsMessage.classList.add("no-items", "inline-menu-list-message");
        noItemsMessage.textContent = this.getTranslation("noItemsToShow");
        const newItemButton = this.buildNewItemButton();
        this.inlineMenuListContainer.append(noItemsMessage, newItemButton);
    }
    /**
     * Builds a "New Item" button and returns the container of that button.
     */
    buildNewItemButton(showLogin = false) {
        this.newItemButtonElement = globalThis.document.createElement("button");
        this.newItemButtonElement.tabIndex = -1;
        this.newItemButtonElement.id = "new-item-button";
        this.newItemButtonElement.classList.add("add-new-item-button", "inline-menu-list-button", "inline-menu-list-action");
        this.newItemButtonElement.textContent = this.getNewItemButtonText(showLogin);
        this.newItemButtonElement.setAttribute("aria-label", this.getNewItemAriaLabel(showLogin));
        this.newItemButtonElement.prepend(buildSvgDomElement(plusIcon));
        this.newItemButtonElement.addEventListener(EVENTS.CLICK, this.handeNewItemButtonClick);
        return this.buildButtonContainer(this.newItemButtonElement);
    }
    /**
     * Gets the new item text for the button based on the cipher type the focused field is filled by.
     */
    getNewItemButtonText(showLogin) {
        if (this.isFilledByLoginCipher() || this.showInlineMenuAccountCreation || showLogin) {
            return this.getTranslation("newLogin");
        }
        if (this.isFilledByCardCipher()) {
            return this.getTranslation("newCard");
        }
        if (this.isFilledByIdentityCipher()) {
            return this.getTranslation("newIdentity");
        }
        return this.getTranslation("newItem");
    }
    /**
     * Gets the aria label for the new item button based on the cipher type the focused field is filled by.
     */
    getNewItemAriaLabel(showLogin) {
        if (this.isFilledByLoginCipher() || this.showInlineMenuAccountCreation || showLogin) {
            return this.getTranslation("addNewLoginItemAria");
        }
        if (this.isFilledByCardCipher()) {
            return this.getTranslation("addNewCardItemAria");
        }
        if (this.isFilledByIdentityCipher()) {
            return this.getTranslation("addNewIdentityItemAria");
        }
        return this.getTranslation("addNewVaultItem");
    }
    /**
     * Builds a container for a given element.
     *
     * @param element - The element to build the container for.
     */
    buildButtonContainer(element) {
        const inlineMenuListButtonContainer = globalThis.document.createElement("div");
        inlineMenuListButtonContainer.classList.add("inline-menu-list-button-container");
        inlineMenuListButtonContainer.appendChild(element);
        return inlineMenuListButtonContainer;
    }
    /**
     * Loads a page of ciphers into the inline menu list container.
     */
    loadPageOfCiphers() {
        const lastIndex = Math.min(this.currentCipherIndex + this.showCiphersPerPage, this.ciphers.length);
        for (let cipherIndex = this.currentCipherIndex; cipherIndex < lastIndex; cipherIndex++) {
            this.ciphersList.appendChild(this.buildInlineMenuListActionsItem(this.ciphers[cipherIndex]));
            this.currentCipherIndex++;
        }
        if (!this.showPasskeysLabels && this.allCiphersLoaded()) {
            this.ciphersList.removeEventListener(EVENTS.SCROLL, this.updateCiphersListOnScroll);
        }
    }
    /**
     * Validates whether the list of ciphers has been fully loaded.
     */
    allCiphersLoaded() {
        return this.currentCipherIndex >= this.ciphers.length;
    }
    /**
     * Sets up the scroll listeners for the ciphers list. These are used to trigger an update of
     * the list of ciphers when the user scrolls to the bottom of the list. Also sets up the
     * scroll listeners that reposition the passkeys and login headings when the user scrolls.
     */
    setupCipherListScrollListeners() {
        const options = { passive: true };
        this.ciphersList.addEventListener(EVENTS.SCROLL, this.updateCiphersListOnScroll, options);
        if (this.showPasskeysLabels) {
            this.ciphersList.addEventListener(EVENTS.SCROLL, this.useEventHandlersMemo(throttle(this.handleThrottledOnScrollEvent, 50), UPDATE_PASSKEYS_HEADINGS_ON_SCROLL), options);
        }
    }
    /**
     * Anchors the passkeys heading to the top of the last passkey item when the user scrolls.
     *
     * @param cipherListScrollTop - The current scroll top position of the ciphers list.
     */
    togglePasskeysHeadingAnchored(cipherListScrollTop) {
        if (!this.passkeysHeadingHeight) {
            this.passkeysHeadingHeight = this.passkeysHeadingElement.offsetHeight;
        }
        const passkeysHeadingOffset = this.lastPasskeysListItem.offsetTop - this.passkeysHeadingHeight;
        if (cipherListScrollTop >= passkeysHeadingOffset) {
            this.passkeysHeadingElement.style.position = "relative";
            this.passkeysHeadingElement.style.top = `${passkeysHeadingOffset}px`;
            return;
        }
        this.passkeysHeadingElement.setAttribute("style", "");
    }
    /**
     * Toggles a border on the passkeys heading on scroll, adding it when the user has
     * scrolled at all and removing it once the user scrolls back to the top.
     *
     * @param cipherListScrollTop - The current scroll top position of the ciphers list.
     */
    togglePasskeysHeadingBorder(cipherListScrollTop) {
        if (cipherListScrollTop < 1) {
            this.passkeysHeadingElement.classList.remove(this.headingBorderClass);
            return;
        }
        this.passkeysHeadingElement.classList.add(this.headingBorderClass);
    }
    /**
     * Toggles a border on  the login heading on scroll, adding it when the user has
     * scrolled past the last passkey item and removing it once the user scrolls back up.
     *
     * @param cipherListScrollTop - The current scroll top position of the ciphers list.
     */
    toggleLoginHeadingBorder(cipherListScrollTop) {
        if (!this.lastPasskeysListItemHeight) {
            this.lastPasskeysListItemHeight = this.lastPasskeysListItem.offsetHeight;
        }
        const lastPasskeyOffset = this.lastPasskeysListItem.offsetTop + this.lastPasskeysListItemHeight;
        if (cipherListScrollTop < lastPasskeyOffset) {
            this.loginHeadingElement.classList.remove(this.headingBorderClass);
            return;
        }
        this.loginHeadingElement.classList.add(this.headingBorderClass);
    }
    /**
     * Builds the list item for a given cipher.
     *
     * @param cipher - The cipher to build the list item for.
     */
    buildInlineMenuListActionsItem(cipher) {
        var _a;
        this.buildPasskeysHeadingElements(cipher);
        const fillCipherElement = this.buildFillCipherElement(cipher);
        const viewCipherElement = this.buildViewCipherElement(cipher);
        const cipherContainerElement = globalThis.document.createElement("div");
        cipherContainerElement.classList.add("cipher-container");
        cipherContainerElement.append(fillCipherElement, viewCipherElement);
        const inlineMenuListActionsItem = globalThis.document.createElement("li");
        inlineMenuListActionsItem.setAttribute("role", "listitem");
        inlineMenuListActionsItem.classList.add("inline-menu-list-actions-item");
        inlineMenuListActionsItem.appendChild(cipherContainerElement);
        if (this.showPasskeysLabels && ((_a = cipher.login) === null || _a === void 0 ? void 0 : _a.passkey)) {
            this.lastPasskeysListItem = inlineMenuListActionsItem;
        }
        return inlineMenuListActionsItem;
    }
    /**
     * Builds the passkeys and login headings for the list of cipher items.
     *
     * @param cipher - The cipher that will follow the heading.
     */
    buildPasskeysHeadingElements(cipher) {
        var _a;
        if (!this.showPasskeysLabels || (this.passkeysHeadingElement && this.loginHeadingElement)) {
            return;
        }
        const passkeyData = (_a = cipher.login) === null || _a === void 0 ? void 0 : _a.passkey;
        if (!this.passkeysHeadingElement && passkeyData) {
            this.passkeysHeadingElement = globalThis.document.createElement("li");
            this.passkeysHeadingElement.classList.add("inline-menu-list-heading");
            this.passkeysHeadingElement.textContent = this.getTranslation("passkeys");
            this.ciphersList.appendChild(this.passkeysHeadingElement);
            return;
        }
        if (!this.passkeysHeadingElement || this.loginHeadingElement || passkeyData) {
            return;
        }
        this.loginHeadingElement = globalThis.document.createElement("li");
        this.loginHeadingElement.classList.add("inline-menu-list-heading");
        this.loginHeadingElement.textContent = this.getTranslation("passwords");
        this.ciphersList.appendChild(this.loginHeadingElement);
    }
    /**
     * Builds the fill cipher button for a given cipher.
     * Wraps the cipher icon and details.
     *
     * @param cipher - The cipher to build the fill cipher button for.
     */
    buildFillCipherElement(cipher) {
        var _a;
        const cipherIcon = this.buildCipherIconElement(cipher);
        const cipherDetailsElement = this.buildCipherDetailsElement(cipher);
        const fillCipherElement = globalThis.document.createElement("button");
        fillCipherElement.tabIndex = -1;
        fillCipherElement.classList.add("fill-cipher-button", "inline-menu-list-action");
        fillCipherElement.setAttribute("aria-label", `${((_a = cipher.login) === null || _a === void 0 ? void 0 : _a.passkey)
            ? this.getTranslation("logInWithPasskeyAriaLabel")
            : this.getTranslation("fillCredentialsFor")} ${cipher.name}`);
        this.addFillCipherElementAriaDescription(fillCipherElement, cipher);
        fillCipherElement.append(cipherIcon, cipherDetailsElement);
        fillCipherElement.addEventListener(EVENTS.CLICK, this.handleFillCipherClickEvent(cipher));
        fillCipherElement.addEventListener(EVENTS.KEYUP, this.handleFillCipherKeyUpEvent);
        return fillCipherElement;
    }
    /**
     * Adds an aria description to the fill cipher button for a given cipher.
     *
     * @param fillCipherElement - The fill cipher button element.
     * @param cipher - The cipher to add the aria description for.
     */
    addFillCipherElementAriaDescription(fillCipherElement, cipher) {
        var _a, _b;
        if (cipher.login) {
            const passkeyUserName = ((_a = cipher.login.passkey) === null || _a === void 0 ? void 0 : _a.userName) || "";
            const username = cipher.login.username || passkeyUserName;
            if (username) {
                fillCipherElement.setAttribute("aria-description", `${(_b = this.getTranslation("username")) === null || _b === void 0 ? void 0 : _b.toLowerCase()}: ${username}`);
            }
            return;
        }
        if (cipher.card) {
            const cardParts = cipher.card.split(", *");
            if (cardParts.length === 1) {
                const cardDigits = cardParts[0].startsWith("*") ? cardParts[0].substring(1) : cardParts[0];
                fillCipherElement.setAttribute("aria-description", `${this.getTranslation("cardNumberEndsWith")} ${cardDigits}`);
                return;
            }
            const cardBrand = cardParts[0];
            const cardDigits = cardParts[1];
            fillCipherElement.setAttribute("aria-description", `${cardBrand}, ${this.getTranslation("cardNumberEndsWith")} ${cardDigits}`);
        }
    }
    /**
     * Builds the button that facilitates viewing a cipher in the vault.
     *
     * @param cipher - The cipher to view.
     */
    buildViewCipherElement(cipher) {
        const viewCipherElement = globalThis.document.createElement("button");
        viewCipherElement.tabIndex = -1;
        viewCipherElement.classList.add("view-cipher-button");
        viewCipherElement.setAttribute("aria-label", `${this.getTranslation("view")} ${cipher.name}, ${this.getTranslation("opensInANewWindow")}`);
        viewCipherElement.append(buildSvgDomElement(viewCipherIcon));
        viewCipherElement.addEventListener(EVENTS.CLICK, this.handleViewCipherClickEvent(cipher));
        viewCipherElement.addEventListener(EVENTS.KEYUP, this.handleViewCipherKeyUpEvent);
        return viewCipherElement;
    }
    /**
     * Builds the icon for a given cipher. Prioritizes the favicon from a given cipher url
     * and the default icon element within the extension. If neither are available, the
     * globe icon is used.
     *
     * @param cipher - The cipher to build the icon for.
     */
    buildCipherIconElement(cipher) {
        var _a, _b, _c, _d;
        const cipherIcon = globalThis.document.createElement("span");
        cipherIcon.classList.add("cipher-icon");
        cipherIcon.setAttribute("aria-hidden", "true");
        if (((_a = cipher.login) === null || _a === void 0 ? void 0 : _a.totpField) && ((_b = cipher.login) === null || _b === void 0 ? void 0 : _b.totp)) {
            const totpContainer = document.createElement("div");
            totpContainer.style.position = "relative";
            const svgElement = buildSvgDomElement(`
      <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 29 29">
          <circle fill="none" cx="14.5" cy="14.5" r="12.5" 
                  stroke-width="3" stroke-dasharray="78.5" 
                  stroke-dashoffset="78.5" transform="rotate(-90 14.5 14.5)"></circle>
          <circle fill="none" cx="14.5" cy="14.5" r="14" stroke-width="1"></circle>
      </svg>
    `);
            const [innerCircleElement, outerCircleElement] = svgElement.querySelectorAll("circle");
            innerCircleElement.classList.add("circle-color");
            outerCircleElement.classList.add("circle-color");
            totpContainer.appendChild(svgElement);
            const totpSecondsSpan = document.createElement("span");
            totpSecondsSpan.classList.add("totp-sec-span");
            totpSecondsSpan.setAttribute("bitTypography", "helper");
            totpSecondsSpan.setAttribute("aria-label", this.getTranslation("totpSecondsSpanAria"));
            totpContainer.appendChild(totpSecondsSpan);
            cipherIcon.appendChild(totpContainer);
            const intervalSeconds = cipher.login.totpCodeTimeInterval;
            const updateCountdown = () => {
                const epoch = Math.round(Date.now() / 1000);
                const mod = epoch % intervalSeconds;
                const totpSeconds = intervalSeconds - mod;
                totpSecondsSpan.textContent = `${totpSeconds}`;
                /**
                 * Design specifies a seven-second time span as the period where expiry is approaching.
                 */
                const totpExpiryApproaching = totpSeconds <= 7;
                totpSecondsSpan.classList.toggle("totp-sec-span-danger", totpExpiryApproaching);
                innerCircleElement.classList.toggle("circle-danger-color", totpExpiryApproaching);
                outerCircleElement.classList.toggle("circle-danger-color", totpExpiryApproaching);
                innerCircleElement.style.strokeDashoffset = `${((intervalSeconds - totpSeconds) / intervalSeconds) * (2 * Math.PI * 12.5)}`;
                if (mod === 0) {
                    this.postMessageToParent({ command: "refreshOverlayCiphers" });
                }
            };
            updateCountdown();
            setInterval(updateCountdown, 1000);
            return cipherIcon;
        }
        if ((_c = cipher.icon) === null || _c === void 0 ? void 0 : _c.image) {
            try {
                const url = new URL(cipher.icon.image);
                cipherIcon.style.backgroundImage = `url(${url.href})`;
                const dummyImageElement = globalThis.document.createElement("img");
                dummyImageElement.src = url.href;
                dummyImageElement.addEventListener("error", () => {
                    cipherIcon.style.backgroundImage = "";
                    cipherIcon.classList.add("cipher-icon");
                    cipherIcon.append(buildSvgDomElement(globeIcon));
                });
                dummyImageElement.remove();
                return cipherIcon;
            }
            catch (_e) {
                // Silently default to the globe icon element if the image URL is invalid
            }
        }
        if (!((_d = cipher.icon) === null || _d === void 0 ? void 0 : _d.icon)) {
            cipherIcon.append(buildSvgDomElement(globeIcon));
            return cipherIcon;
        }
        if (cipher.icon.icon.includes("bwi-credit-card")) {
            cipherIcon.append(buildSvgDomElement(creditCardIcon));
            return cipherIcon;
        }
        if (cipher.icon.icon.includes("bwi-id-card")) {
            cipherIcon.append(buildSvgDomElement(idCardIcon));
            return cipherIcon;
        }
        const iconClasses = cipher.icon.icon.split(" ");
        cipherIcon.classList.add("cipher-icon", "bwi", ...iconClasses);
        return cipherIcon;
    }
    /**
     * Builds the details for a given cipher. Includes the cipher name and subtitle.
     *
     * @param cipher - The cipher to build the details for.
     */
    buildCipherDetailsElement(cipher) {
        var _a, _b, _c, _d, _e;
        const cipherDetailsElement = globalThis.document.createElement("span");
        cipherDetailsElement.classList.add("cipher-details");
        const cipherNameElement = this.buildCipherNameElement(cipher);
        if (cipherNameElement) {
            cipherDetailsElement.appendChild(cipherNameElement);
        }
        if ((_a = cipher.login) === null || _a === void 0 ? void 0 : _a.passkey) {
            return this.buildPasskeysCipherDetailsElement(cipher, cipherDetailsElement);
        }
        if (((_b = cipher.login) === null || _b === void 0 ? void 0 : _b.totpField) && ((_c = cipher.login) === null || _c === void 0 ? void 0 : _c.totp)) {
            return this.buildTotpElement((_d = cipher.login) === null || _d === void 0 ? void 0 : _d.totp, (_e = cipher.login) === null || _e === void 0 ? void 0 : _e.username, cipher.reprompt);
        }
        const subTitleText = this.getSubTitleText(cipher);
        const cipherSubtitleElement = this.buildCipherSubtitleElement(subTitleText);
        if (cipherSubtitleElement) {
            cipherDetailsElement.appendChild(cipherSubtitleElement);
        }
        return cipherDetailsElement;
    }
    /**
     * Checks if there is more than one TOTP element being displayed.
     *
     * @returns {boolean} - Returns true if more than one TOTP element is displayed, otherwise false.
     */
    multipleTotpElements() {
        return (this.ciphers.filter((cipher) => { var _a, _b; return ((_a = cipher.login) === null || _a === void 0 ? void 0 : _a.totpField) && ((_b = cipher.login) === null || _b === void 0 ? void 0 : _b.totp); }).length > 1);
    }
    /**
     * Builds a TOTP element for a given TOTP code.
     *
     * @param totp - The TOTP code to display.
     */
    buildTotpElement(totpCode, username, reprompt) {
        if (!totpCode) {
            return null;
        }
        const formattedTotpCode = `${totpCode.substring(0, 3)} ${totpCode.substring(3)}`;
        const containerElement = globalThis.document.createElement("div");
        containerElement.classList.add("cipher-details");
        const totpHeading = document.createElement("span");
        totpHeading.classList.add("cipher-name");
        totpHeading.textContent = this.getTranslation("fillVerificationCode");
        totpHeading.setAttribute("aria-label", this.getTranslation("fillVerificationCodeAria"));
        containerElement.appendChild(totpHeading);
        if (this.multipleTotpElements() && username) {
            const usernameSubtitle = this.buildCipherSubtitleElement(username);
            containerElement.appendChild(usernameSubtitle);
        }
        const totpCodeSpan = document.createElement("span");
        totpCodeSpan.classList.toggle("cipher-subtitle");
        totpCodeSpan.classList.toggle("masked-totp", !!reprompt);
        totpCodeSpan.textContent = reprompt ? "●●●●●●" : formattedTotpCode;
        totpCodeSpan.setAttribute("aria-label", this.getTranslation("totpCodeAria"));
        totpCodeSpan.setAttribute("data-testid", "totp-code");
        containerElement.appendChild(totpCodeSpan);
        return containerElement;
    }
    /**
     * Builds the name element for a given cipher.
     *
     * @param cipher - The cipher to build the name element for.
     */
    buildCipherNameElement(cipher) {
        if (!cipher.name) {
            return null;
        }
        const cipherNameElement = globalThis.document.createElement("span");
        cipherNameElement.classList.add("cipher-name");
        cipherNameElement.textContent = cipher.name;
        cipherNameElement.setAttribute("title", cipher.name);
        return cipherNameElement;
    }
    /**
     * Builds the subtitle element for a given cipher.
     *
     * @param subTitleText - The subtitle text to display.
     */
    buildCipherSubtitleElement(subTitleText) {
        if (!subTitleText) {
            return null;
        }
        const cipherSubtitleElement = globalThis.document.createElement("span");
        cipherSubtitleElement.classList.add("cipher-subtitle");
        cipherSubtitleElement.textContent = subTitleText;
        cipherSubtitleElement.setAttribute("title", subTitleText);
        return cipherSubtitleElement;
    }
    /**
     * Builds the passkeys details for a given cipher. Includes the passkey name and username.
     *
     * @param cipher - The cipher to build the passkey details for.
     * @param cipherDetailsElement - The cipher details element to append the passkey details to.
     */
    buildPasskeysCipherDetailsElement(cipher, cipherDetailsElement) {
        let rpNameSubtitle;
        if (cipher.name !== cipher.login.passkey.rpName) {
            rpNameSubtitle = this.buildCipherSubtitleElement(cipher.login.passkey.rpName);
            if (rpNameSubtitle) {
                rpNameSubtitle.prepend(buildSvgDomElement(passkeyIcon));
                rpNameSubtitle.classList.add("cipher-subtitle--passkey");
                cipherDetailsElement.appendChild(rpNameSubtitle);
            }
        }
        if (cipher.login.username) {
            const usernameSubtitle = this.buildCipherSubtitleElement(cipher.login.username);
            if (usernameSubtitle) {
                if (!rpNameSubtitle) {
                    usernameSubtitle.prepend(buildSvgDomElement(passkeyIcon));
                    usernameSubtitle.classList.add("cipher-subtitle--passkey");
                }
                cipherDetailsElement.appendChild(usernameSubtitle);
            }
            return cipherDetailsElement;
        }
        const passkeySubtitle = this.buildCipherSubtitleElement(cipher.login.passkey.userName);
        if (passkeySubtitle) {
            if (!rpNameSubtitle) {
                passkeySubtitle.prepend(buildSvgDomElement(passkeyIcon));
                passkeySubtitle.classList.add("cipher-subtitle--passkey");
            }
            cipherDetailsElement.appendChild(passkeySubtitle);
        }
        return cipherDetailsElement;
    }
    /**
     * Creates an indicator for the user that the passkey is being authenticated.
     */
    createPasskeyAuthenticatingLoader() {
        this.isPasskeyAuthInProgress = true;
        this.resetInlineMenuContainer();
        const passkeyAuthenticatingLoader = globalThis.document.createElement("div");
        passkeyAuthenticatingLoader.classList.add("passkey-authenticating-loader");
        passkeyAuthenticatingLoader.textContent = this.getTranslation("authenticating");
        passkeyAuthenticatingLoader.appendChild(buildSvgDomElement(spinnerIcon));
        this.inlineMenuListContainer.appendChild(passkeyAuthenticatingLoader);
        globalThis.setTimeout(() => {
            this.isPasskeyAuthInProgress = false;
            this.postMessageToParent({ command: "checkAutofillInlineMenuButtonFocused" });
        }, 4000);
    }
    /**
     * Gets the subtitle text for a given cipher.
     *
     * @param cipher - The cipher to get the subtitle text for.
     */
    getSubTitleText(cipher) {
        var _a, _b, _c;
        if ((_a = cipher.identity) === null || _a === void 0 ? void 0 : _a.username) {
            return cipher.identity.username;
        }
        if ((_b = cipher.identity) === null || _b === void 0 ? void 0 : _b.fullName) {
            return cipher.identity.fullName;
        }
        if ((_c = cipher.login) === null || _c === void 0 ? void 0 : _c.username) {
            return cipher.login.username;
        }
        if (cipher.card) {
            return cipher.card;
        }
        return "";
    }
    /**
     * Validates whether the inline menu list iframe is currently focused.
     * If not focused, will check if the button element is focused.
     */
    checkInlineMenuListFocused() {
        if (globalThis.document.hasFocus()) {
            return;
        }
        if (this.isListHovered()) {
            globalThis.document.addEventListener(EVENTS.MOUSEOUT, this.handleMouseOutEvent);
            return;
        }
        this.postMessageToParent({ command: "checkAutofillInlineMenuButtonFocused" });
    }
    /**
     * Focuses the inline menu list iframe. The element that receives focus is
     * determined by the presence of the unlock button, new item button, or
     * the first cipher button.
     */
    focusInlineMenuList() {
        this.inlineMenuListContainer.setAttribute("role", "dialog");
        this.inlineMenuListContainer.setAttribute("aria-modal", "true");
        const unlockButtonElement = this.inlineMenuListContainer.querySelector("#unlock-button");
        if (unlockButtonElement) {
            unlockButtonElement.focus();
            return;
        }
        const firstListElement = this.inlineMenuListContainer.querySelector(".inline-menu-list-action");
        firstListElement === null || firstListElement === void 0 ? void 0 : firstListElement.focus();
    }
    /**
     * Sets up the global listeners for the inline menu list iframe.
     */
    setupInlineMenuListGlobalListeners() {
        this.setupGlobalListeners(this.inlineMenuListWindowMessageHandlers);
        this.resizeObserver = new ResizeObserver(this.handleResizeObserver);
    }
    /**
     * Focuses the next list item in the inline menu list. If the current list item is the last
     * item in the list, the first item is focused.
     *
     * @param currentListItem - The current list item.
     */
    focusNextListItem(currentListItem) {
        var _a;
        let nextListItem = currentListItem.nextSibling;
        if (this.listItemIsHeadingElement(nextListItem)) {
            nextListItem = nextListItem.nextSibling;
        }
        const nextSibling = nextListItem === null || nextListItem === void 0 ? void 0 : nextListItem.querySelector(".inline-menu-list-action");
        if (nextSibling) {
            nextSibling.focus();
            return;
        }
        if (this.newItemButtonElement) {
            this.newItemButtonElement.focus();
            return;
        }
        let firstListItem = (_a = currentListItem.parentElement) === null || _a === void 0 ? void 0 : _a.firstChild;
        if (this.listItemIsHeadingElement(firstListItem)) {
            firstListItem = firstListItem.nextSibling;
        }
        const firstSibling = firstListItem === null || firstListItem === void 0 ? void 0 : firstListItem.querySelector(".inline-menu-list-action");
        firstSibling === null || firstSibling === void 0 ? void 0 : firstSibling.focus();
    }
    /**
     * Focuses the previous list item in the inline menu list. If the current list item is the first
     * item in the list, the last item is focused.
     *
     * @param currentListItem - The current list item.
     */
    focusPreviousListItem(currentListItem) {
        var _a;
        let previousListItem = currentListItem.previousSibling;
        if (this.listItemIsHeadingElement(previousListItem)) {
            previousListItem = previousListItem.previousSibling;
        }
        const previousSibling = previousListItem === null || previousListItem === void 0 ? void 0 : previousListItem.querySelector(".inline-menu-list-action");
        if (previousSibling) {
            previousSibling.focus();
            return;
        }
        if (this.newItemButtonElement) {
            this.newItemButtonElement.focus();
            return;
        }
        const lastListItem = (_a = currentListItem.parentElement) === null || _a === void 0 ? void 0 : _a.lastChild;
        const lastSibling = lastListItem === null || lastListItem === void 0 ? void 0 : lastListItem.querySelector(".inline-menu-list-action");
        lastSibling === null || lastSibling === void 0 ? void 0 : lastSibling.focus();
    }
    /**
     * Focuses the view cipher button relative to the current fill cipher button.
     *
     * @param currentListItem - The current list item.
     * @param currentButtonElement - The current button element.
     */
    focusViewCipherButton(currentListItem, currentButtonElement) {
        const cipherContainer = currentListItem.querySelector(".cipher-container");
        cipherContainer.classList.add("remove-outline");
        const nextSibling = currentButtonElement.nextElementSibling;
        nextSibling === null || nextSibling === void 0 ? void 0 : nextSibling.focus();
    }
}

;// ./src/autofill/overlay/inline-menu/pages/list/bootstrap-autofill-inline-menu-list.ts


// FIXME: Remove when updating file. Eslint update
// eslint-disable-next-line @typescript-eslint/no-require-imports
__webpack_require__(87281);
(function () {
    globalThis.customElements.define(AutofillOverlayElement.List, AutofillInlineMenuList);
})();

}();
/******/ })()
;