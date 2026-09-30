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
    try {
      if (isQuitItem(item)) {
        quitApp();
        return;
      }
      if (role === "minimize") {
        win.minimize();
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

  function applyFit() {
    hideNativeMenu();
    try {
      if (webFrame) {
        webFrame.setZoomLevel(0);
        webFrame.setZoomFactor(1);
      }
    } catch (e) {}
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
    var layoutW = winH / s;
    var layoutH = winW / s;
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
      "translate(" + winW + "px,0) rotate(90deg) scale(" + s + ")",
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
