(function () {
  var remote;
  var webFrame;
  try {
    remote = require("electron").remote;
  } catch (e) {
    remote = null;
  }
  try {
    webFrame = require("electron").webFrame;
  } catch (e) {
    webFrame = null;
  }

  var MENU_H = 24;
  // Scale of the rotated lobby onto the CRT. 1 fills 480x641 CSS px 1:1.
  // CRT Chromium zoom is applied on top of this, so applyFit zeros zoom first.
  var FIT = 0.86;

  // Current fit state, refreshed by applyFit. Used to map screen (post
  // transform) pointer coordinates back into the rotated layout space so the
  // custom tooltip lands next to the cursor.
  var fitS = FIT;
  var fitWinW = 641;
  var fitLayoutW = 0;
  var fitLayoutH = 0;

  // Native `title` tooltips are painted by the OS compositor, outside the
  // rotated document, so they always face the wrong way in TATE mode. We strip
  // them and draw our own rotated tooltip instead. Styling is also mirrored in
  // inject.css, but injected here too so a page reload (which does not re-read
  // inject.css) still gets it.
  var TOOLTIP_CSS =
    "#fc-tate-tip{position:fixed;z-index:2147483646;pointer-events:none;" +
    "max-width:320px;padding:3px 8px;background:#2e3436;color:#fff;" +
    'font:12px/1.4 "Cantarell","DejaVu Sans",sans-serif;border:1px solid ' +
    "#1b1f20;border-radius:3px;box-shadow:1px 1px 4px rgba(0,0,0,0.45);" +
    "white-space:normal;word-break:break-word;}";

  // Native <select> popups are drawn by the OS compositor in screen space, so
  // they ignore the rotated document and open sideways in TATE mode. We block
  // the native popup and render our own rotated list instead. Mirrored in
  // inject.css; injected here too so a page reload still gets it.
  var SELECT_CSS =
    "#fc-tate-select{position:fixed;z-index:2147483647;display:none;" +
    "overflow-y:auto;overflow-x:hidden;" +
    "background:var(--mainColor,#2b1b2b);" +
    "border:2px solid var(--mainColor-light,#6b4a6b);border-radius:4px;" +
    "box-shadow:1px 1px 6px rgba(0,0,0,0.6);" +
    'font:0.9rem "Source Sans Pro",arial,sans-serif;color:#fff;}' +
    "#fc-tate-select .fc-opt{padding:0.3rem 0.9rem;white-space:nowrap;" +
    "cursor:pointer;}" +
    "#fc-tate-select .fc-opt:hover,#fc-tate-select .fc-opt.sel{" +
    "background:var(--accentColor,#00b3b3);color:#111;}";

  function hideNativeMenu() {
    if (!remote) {
      return;
    }
    try {
      var win = remote.getCurrentWindow();
      win.setAutoHideMenuBar(true);
      win.setMenuBarVisibility(false);
    } catch (e) {}
  }

  function spoofPortrait(w, h) {
    try {
      Object.defineProperty(window, "innerWidth", {
        configurable: true,
        get: function () { return w; },
      });
      Object.defineProperty(window, "innerHeight", {
        configurable: true,
        get: function () { return h; },
      });
      Object.defineProperty(document.documentElement, "clientWidth", {
        configurable: true,
        get: function () { return w; },
      });
      Object.defineProperty(document.documentElement, "clientHeight", {
        configurable: true,
        get: function () { return h; },
      });
    } catch (e) {}
    try {
      window.dispatchEvent(new Event("resize"));
    } catch (e) {}
  }

  function cleanLabel(item) {
    return String((item && item.label) || "").replace(/&/g, "");
  }

  function quitApp() {
    try {
      remote.app.exit(0);
    } catch (e) {
      try {
        remote.app.quit();
      } catch (e2) {
        try {
          remote.getCurrentWindow().destroy();
        } catch (e3) {}
      }
    }
  }

  function isQuitItem(item) {
    var role = String((item && item.role) || "").toLowerCase();
    var name = cleanLabel(item).toLowerCase();
    return role === "close" || role === "quit" || name === "close" || name === "quit";
  }

  function runItem(item) {
    if (!remote || !item) {
      return;
    }
    var win = remote.getCurrentWindow();
    var role = item.role || "";
    var roleLc = String(role).toLowerCase();
    var nameLc = cleanLabel(item).toLowerCase();
    try {
      if (isQuitItem(item)) {
        quitApp();
        return;
      }
      if (role === "minimize") {
        win.minimize();
        return;
      }
      // Route the menu's zoom items through our zoom-aware re-fit so the rotated
      // layout stays constrained to the CRT at any zoom.
      if (roleLc === "zoomin" || nameLc === "zoom in") {
        nudgeZoom(1);
        return;
      }
      if (roleLc === "zoomout" || nameLc === "zoom out") {
        nudgeZoom(-1);
        return;
      }
      if (
        roleLc === "resetzoom" ||
        nameLc.indexOf("reset zoom") !== -1 ||
        nameLc === "actual size"
      ) {
        setZoom(1);
        return;
      }
      item.click(undefined, win, win.webContents);
    } catch (e) {
      quitApp();
    }
  }

  function mountMenu() {
    if (!remote || !document.body) {
      return;
    }
    if (document.getElementById("fc-tate-menu")) {
      return;
    }
    var appMenu = remote.Menu.getApplicationMenu();
    if (!appMenu || !appMenu.items) {
      return;
    }
    var bar = document.createElement("div");
    bar.id = "fc-tate-menu";
    var openTop = null;

    function closeAll() {
      var nodes = bar.querySelectorAll(".fc-top.open");
      for (var i = 0; i < nodes.length; i++) {
        nodes[i].classList.remove("open");
      }
      openTop = null;
    }

    appMenu.items.forEach(function (top) {
      if (!top.visible && top.visible !== undefined) {
        return;
      }
      var label = cleanLabel(top);
      if (!label) {
        return;
      }
      var topEl = document.createElement("div");
      topEl.className = "fc-top";
      topEl.textContent = label;
      var sub = document.createElement("div");
      sub.className = "fc-sub";
      var items = (top.submenu && top.submenu.items) || [];
      items.forEach(function (item) {
        if (item.visible === false) {
          return;
        }
        if (item.type === "separator") {
          var sep = document.createElement("div");
          sep.className = "fc-sep";
          sub.appendChild(sep);
          return;
        }
        var name = cleanLabel(item);
        if (!name) {
          return;
        }
        var row = document.createElement("div");
        row.className = "fc-item";
        row.textContent = name;
        row.addEventListener("mousedown", function (ev) {
          ev.preventDefault();
          ev.stopPropagation();
          closeAll();
          runItem(item);
        });
        sub.appendChild(row);
      });
      topEl.appendChild(sub);
      topEl.addEventListener("mousedown", function (ev) {
        ev.preventDefault();
        ev.stopPropagation();
        var willOpen = openTop !== topEl;
        closeAll();
        if (willOpen) {
          topEl.classList.add("open");
          openTop = topEl;
        }
      });
      bar.appendChild(topEl);
    });
    document.addEventListener("mousedown", function (ev) {
      if (!bar.contains(ev.target)) {
        closeAll();
      }
    }, true);
    document.body.insertBefore(bar, document.body.firstChild);
  }

  // Convert a screen-space pointer position (clientX/clientY, after the CSS
  // transform) into the rotated layout coordinate space. The html transform is
  // translate(winW,0) rotate(90deg) scale(s), so screenX = winW - s*ly and
  // screenY = s*lx. Inverting: lx = screenY/s, ly = (winW - screenX)/s.
  function screenToLayout(clientX, clientY) {
    var s = fitS > 0 ? fitS : 1;
    return { x: clientY / s, y: (fitWinW - clientX) / s };
  }

  function setupTooltips() {
    if (window.__fcTipInit || !document.body) {
      return;
    }
    window.__fcTipInit = true;

    if (!document.getElementById("fc-tate-tip-style")) {
      var style = document.createElement("style");
      style.id = "fc-tate-tip-style";
      style.textContent = TOOLTIP_CSS;
      (document.head || document.documentElement).appendChild(style);
    }

    var tip = document.createElement("div");
    tip.id = "fc-tate-tip";
    tip.style.display = "none";
    // Append to <html> (the transformed stacking-context root) rather than
    // <body>, and pin z-index inline with !important so no app element or
    // cached CSS can ever paint over the tooltip (e.g. the channel rail text).
    tip.style.setProperty("z-index", "2147483647", "important");
    tip.style.setProperty("position", "fixed", "important");
    (document.documentElement || document.body).appendChild(tip);
    var current = null;

    function stealTitle(el) {
      if (!el || !el.getAttribute) {
        return;
      }
      var t = el.getAttribute("title");
      if (t) {
        el.setAttribute("data-fc-tip", t);
        el.removeAttribute("title");
        if (current === el) {
          tip.textContent = t;
        }
      }
    }

    function stripTitles(root) {
      if (!root) {
        return;
      }
      stealTitle(root);
      if (root.querySelectorAll) {
        var nodes = root.querySelectorAll("[title]");
        for (var i = 0; i < nodes.length; i++) {
          stealTitle(nodes[i]);
        }
      }
    }

    stripTitles(document.body);

    try {
      var mo = new MutationObserver(function (muts) {
        for (var i = 0; i < muts.length; i++) {
          var m = muts[i];
          if (m.type === "attributes" && m.attributeName === "title") {
            stealTitle(m.target);
          } else if (m.type === "childList") {
            for (var j = 0; j < m.addedNodes.length; j++) {
              stripTitles(m.addedNodes[j]);
            }
          }
        }
      });
      mo.observe(document.body, {
        subtree: true,
        childList: true,
        attributes: true,
        attributeFilter: ["title"],
      });
    } catch (e) {}

    function findTip(el) {
      while (el && el !== document.body) {
        if (el.getAttribute && el.hasAttribute && el.hasAttribute("data-fc-tip")) {
          return el;
        }
        el = el.parentNode;
      }
      return null;
    }

    function place(clientX, clientY) {
      var p = screenToLayout(clientX, clientY);
      var lx = p.x + 2;
      var ly = p.y + 12;
      var tw = tip.offsetWidth;
      var th = tip.offsetHeight;
      if (fitLayoutW > 0) {
        lx = Math.max(0, Math.min(lx, fitLayoutW - tw));
      }
      if (fitLayoutH > 0) {
        ly = Math.max(0, Math.min(ly, fitLayoutH - th));
      }
      tip.style.left = lx + "px";
      tip.style.top = ly + "px";
    }

    document.addEventListener(
      "mouseover",
      function (e) {
        var el = findTip(e.target);
        if (!el) {
          return;
        }
        var txt = el.getAttribute("data-fc-tip");
        if (!txt) {
          return;
        }
        current = el;
        tip.textContent = txt;
        tip.style.display = "block";
        place(e.clientX, e.clientY);
      },
      true
    );

    document.addEventListener(
      "mousemove",
      function (e) {
        if (current && tip.style.display !== "none") {
          place(e.clientX, e.clientY);
        }
      },
      true
    );

    document.addEventListener(
      "mouseout",
      function (e) {
        if (!current) {
          return;
        }
        var to = e.relatedTarget;
        if (!to || !current.contains(to)) {
          current = null;
          tip.style.display = "none";
        }
      },
      true
    );
  }

  // Replace native <select> dropdowns with a rotated in-page list so the
  // options obey the TATE transform instead of opening sideways in screen space.
  function setupSelects() {
    if (window.__fcSelInit || !document.body) {
      return;
    }
    window.__fcSelInit = true;

    if (!document.getElementById("fc-tate-select-style")) {
      var style = document.createElement("style");
      style.id = "fc-tate-select-style";
      style.textContent = SELECT_CSS;
      (document.head || document.documentElement).appendChild(style);
    }

    var box = document.createElement("div");
    box.id = "fc-tate-select";
    box.style.display = "none";
    document.body.appendChild(box);
    var activeSelect = null;

    function closeBox() {
      box.style.display = "none";
      box.innerHTML = "";
      activeSelect = null;
    }

    // Map the select's screen-space rect (post transform) into layout coords and
    // place the list left-aligned with the select. A pad-driven cursor has no
    // scroll wheel, so size the list to show the whole thing and nudge it up so
    // it stays fully on screen instead of scrolling.
    function positionBox(select) {
      var r = select.getBoundingClientRect();
      var s = fitS > 0 ? fitS : 1;
      var lxMin = r.top / s;
      var lxMax = r.bottom / s;
      var lyBottom = (fitWinW - r.left) / s;
      box.style.left = lxMin + "px";
      box.style.minWidth = Math.max(0, lxMax - lxMin) + "px";
      // Measure the natural (uncapped) height.
      box.style.setProperty("max-height", "none", "important");
      var pad = 6;
      var colTop = pad;
      var colBot = (fitLayoutH > 0 ? fitLayoutH : 745) - pad;
      var avail = colBot - colTop;
      var natural = box.offsetHeight;
      var h = Math.min(natural, avail);
      box.style.setProperty("max-height", h + "px", "important");
      var top = lyBottom + 2;
      if (top + h > colBot) {
        top = colBot - h;
      }
      if (top < colTop) {
        top = colTop;
      }
      box.style.top = top + "px";
    }

    function openFor(select) {
      box.innerHTML = "";
      var opts = select.options;
      for (var i = 0; i < opts.length; i++) {
        (function (idx) {
          var o = opts[idx];
          var row = document.createElement("div");
          row.className = "fc-opt" + (idx === select.selectedIndex ? " sel" : "");
          row.textContent = o.textContent.trim();
          row.addEventListener("mousedown", function (ev) {
            ev.preventDefault();
            ev.stopPropagation();
            if (select.selectedIndex !== idx) {
              select.selectedIndex = idx;
              try {
                select.dispatchEvent(new Event("input", { bubbles: true }));
              } catch (e) {}
              try {
                select.dispatchEvent(new Event("change", { bubbles: true }));
              } catch (e2) {}
            }
            closeBox();
          });
          box.appendChild(row);
        })(i);
      }
      activeSelect = select;
      box.style.display = "block";
      positionBox(select);
      var sel = box.querySelector(".fc-opt.sel");
      if (sel && sel.scrollIntoView) {
        try {
          sel.scrollIntoView({ block: "nearest" });
        } catch (e) {}
      }
    }

    document.addEventListener(
      "mousedown",
      function (e) {
        var sel = e.target;
        while (sel && sel !== document.body && sel.tagName !== "SELECT") {
          sel = sel.parentNode;
        }
        if (sel && sel.tagName === "SELECT") {
          // Block the native popup and drive our own list.
          e.preventDefault();
          e.stopPropagation();
          if (activeSelect === sel) {
            closeBox();
          } else {
            openFor(sel);
          }
          return;
        }
        if (!box.contains(e.target)) {
          closeBox();
        }
      },
      true
    );

    window.addEventListener("scroll", closeBox, true);
    window.addEventListener("resize", closeBox, true);
  }

  // Zoom in vertical mode. webFrame zoom multiplies every CSS px (including the
  // fit transform's translate), so naive zoom overflows the CRT and shoves the
  // menu off screen. Instead we fold the zoom factor into applyFit: layout size
  // and the translate are divided by the zoom so the rotated content always
  // re-fits the screen, while content still reflows (bigger text, less on
  // screen) like normal zoom. Handy for smaller TVs.
  var ZOOM_MIN = 0.6;
  var ZOOM_MAX = 2.2;
  var ZOOM_STEP = 0.1;
  var lastFitZoom = 1;
  // Chromium only flushes its Preferences (per-host zoom) to disk on a debounced
  // timer, so a zoom set right before ES kills the app is lost. We persist the
  // vertical-lobby zoom ourselves the instant it changes, to a flatpak-writable
  // file, and read it back on load. fightcade-lobby-zoom stays out of vertical
  // mode, so vertical and landscape zoom remain independent.
  var ZOOM_FILE = "/userdata/system/fightcade-flatpak/lobby-zoom-vertical";
  var fsMod = null;
  try {
    fsMod = require("fs");
  } catch (e) {
    fsMod = null;
  }
  var zoomLoaded = false;

  function clampZoom(z) {
    if (!(z > 0)) {
      z = 1;
    }
    if (z < ZOOM_MIN) {
      z = ZOOM_MIN;
    }
    if (z > ZOOM_MAX) {
      z = ZOOM_MAX;
    }
    return z;
  }

  function saveZoom(z) {
    try {
      if (fsMod) {
        fsMod.writeFileSync(ZOOM_FILE, String(z));
      }
    } catch (e) {}
  }

  function loadSavedZoom() {
    if (zoomLoaded) {
      return;
    }
    zoomLoaded = true;
    try {
      if (fsMod && fsMod.existsSync(ZOOM_FILE)) {
        var v = parseFloat(String(fsMod.readFileSync(ZOOM_FILE)).trim());
        if (v > 0) {
          v = clampZoom(v);
          if (webFrame && webFrame.setZoomFactor) {
            webFrame.setZoomFactor(v);
          }
        }
      }
    } catch (e) {}
  }

  function getZoom() {
    try {
      if (webFrame && webFrame.getZoomFactor) {
        var z = webFrame.getZoomFactor();
        if (z > 0) {
          return z;
        }
      }
    } catch (e) {}
    return 1;
  }

  function setZoom(z) {
    z = clampZoom(z);
    try {
      if (webFrame && webFrame.setZoomFactor) {
        webFrame.setZoomFactor(z);
      }
    } catch (e) {}
    saveZoom(z);
    applyFit();
  }

  function nudgeZoom(dir) {
    setZoom(getZoom() + dir * ZOOM_STEP);
  }

  function installZoomControls() {
    if (window.__fcZoomCtl) {
      return;
    }
    window.__fcZoomCtl = true;
    try {
      // We manage page zoom ourselves; disable pinch/visual zoom.
      if (webFrame && webFrame.setVisualZoomLevelLimits) {
        webFrame.setVisualZoomLevelLimits(1, 1);
      }
    } catch (e) {}
    try {
      window.addEventListener(
        "keydown",
        function (e) {
          if (!(e.ctrlKey || e.metaKey)) {
            return;
          }
          if (e.key === "+" || e.key === "=" || e.code === "NumpadAdd") {
            e.preventDefault();
            e.stopPropagation();
            nudgeZoom(1);
          } else if (e.key === "-" || e.code === "NumpadSubtract") {
            e.preventDefault();
            e.stopPropagation();
            nudgeZoom(-1);
          } else if (e.key === "0" || e.code === "Numpad0") {
            e.preventDefault();
            e.stopPropagation();
            setZoom(1);
          }
        },
        true
      );
      window.addEventListener(
        "wheel",
        function (e) {
          if (!e.ctrlKey) {
            return;
          }
          e.preventDefault();
          nudgeZoom(e.deltaY < 0 ? 1 : -1);
        },
        { capture: true, passive: false }
      );
    } catch (e) {}
    // Watchdog: the native window menu's Zoom items change webFrame zoom directly
    // and bypass the handlers above. Re-fit (or clamp) whenever the zoom differs
    // from what we last fit, so the layout stays constrained to the CRT.
    try {
      setInterval(function () {
        try {
          var z = getZoom();
          if (z < ZOOM_MIN - 0.001 || z > ZOOM_MAX + 0.001) {
            setZoom(z);
          } else if (Math.abs(z - lastFitZoom) > 0.001) {
            applyFit();
          }
        } catch (e) {}
      }, 200);
    } catch (e) {}
  }

  // Inject page-world scripts for the vertical genre search feature.
  // inject.js runs in Electron's isolated world so it cannot directly hook
  // WebSocket. We read the source files from disk via fs and append them as
  // <script> elements so they execute in the page world.
  var VERTICAL_SRC_DIR = "/userdata/system/fightcade-flatpak/lobby";

  function setupVerticalSearch() {
    if (window.__fcVerticalPageLoaded || !fsMod) {
      return;
    }
    window.__fcVerticalPageLoaded = true;
    var scripts = ["vertical-allowlist.js", "vertical-search.js"];
    for (var si = 0; si < scripts.length; si++) {
      var name = scripts[si];
      try {
        var filePath = VERTICAL_SRC_DIR + "/" + name;
        if (!fsMod.existsSync(filePath)) { continue; }
        var el = document.createElement("script");
        el.textContent = fsMod.readFileSync(filePath, "utf8");
        (document.head || document.documentElement).appendChild(el);
      } catch (e) {}
    }
  }

  function applyFit() {
    hideNativeMenu();
    loadSavedZoom();
    var z = getZoom();
    var winW = window.outerWidth || 641;
    var winH = window.outerHeight || 480;
    try {
      if (remote) {
        var b = remote.getCurrentWindow().getContentBounds();
        if (b && b.width && b.height) {
          winW = b.width;
          winH = b.height;
        }
      }
    } catch (e) {}
    if (winH > winW) {
      var tmp = winW;
      winW = winH;
      winH = tmp;
    }
    var s = FIT;
    if (!(s > 0) || s > 1) {
      s = 1;
    }
    // Fold zoom into the layout so the rotated content re-fits the CRT: on-screen
    // width = layoutW * s * z, so layoutW = winH / (s*z); the translate is in CSS
    // px (also multiplied by zoom), so it must be winW / z. At z=1 this is
    // identical to the un-zoomed fit.
    var layoutW = winH / (s * z);
    var layoutH = winW / (s * z);
    fitS = s;
    fitWinW = winW / z;
    fitLayoutW = layoutW;
    fitLayoutH = layoutH;
    lastFitZoom = z;
    var html = document.documentElement;
    var body = document.body;
    html.style.setProperty("position", "fixed", "important");
    html.style.setProperty("top", "0px", "important");
    html.style.setProperty("left", "0px", "important");
    html.style.setProperty("margin", "0px", "important");
    html.style.setProperty("padding", "0px", "important");
    html.style.setProperty("width", layoutW + "px", "important");
    html.style.setProperty("height", layoutH + "px", "important");
    html.style.setProperty("overflow", "hidden", "important");
    html.style.setProperty("background", "#111", "important");
    html.style.setProperty("transform-origin", "0 0", "important");
    html.style.setProperty(
      "transform",
      "translate(" + winW / z + "px,0) rotate(90deg) scale(" + s + ")",
      "important"
    );
    if (body) {
      body.style.setProperty("margin", "0px", "important");
      body.style.setProperty("width", "100%", "important");
      body.style.setProperty("height", "100%", "important");
      body.style.setProperty("overflow", "hidden", "important");
      body.style.setProperty("background", "#111", "important");
      body.style.setProperty("position", "relative", "important");
      body.style.setProperty("padding-top", MENU_H + "px", "important");
    }
    spoofPortrait(layoutW, layoutH - MENU_H);
    mountMenu();
    setupTooltips();
    setupSelects();
    setupVerticalSearch();
    installZoomControls();
  }

  hideNativeMenu();
  if (document.readyState === "loading") {
    document.addEventListener("DOMContentLoaded", function () {
      hideNativeMenu();
      setTimeout(applyFit, 150);
    });
  } else {
    setTimeout(applyFit, 150);
  }
  setTimeout(applyFit, 800);
})();
