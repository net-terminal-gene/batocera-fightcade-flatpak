// Fightcade vertical genre search — page-world script.
// Loaded by inject.js via a <script> element so it runs in the page world
// and can intercept the real WebSocket used by Fightcade.
//
// When the user selects Vertical, intercept the genre=Vertical WS request,
// page the all-games API, merge against __FC_VERTICAL_IDS, and deliver one
// synthetic reply. Results only appear once the fetch is done. Later pages
// come from cache.

(function () {
  if (window.__fcVerticalSearch) { return; }
  window.__fcVerticalSearch = true;

  var VERTICAL_GENRE = "Vertical";
  var PAGE_SIZE = 50;
  var TIMEOUT_MS = 30000;

  function buildSyntheticChannel(gameid, info) {
    return {
      gameid: gameid,
      name: info[0],
      emulator: info[1],
      system: info[2],
      clients: 0,
      ranked: false,
      training: false,
      available_for: 0,
    };
  }

  function norm(s) {
    return String(s == null ? "" : s).trim().toLowerCase();
  }

  function isAllValue(v) {
    if (v == null || v === false || v === "") { return true; }
    var n = norm(v);
    return n === "all" || n === "null" || n === "undefined";
  }

  function domFilterText(kind) {
    try {
      var sel = document.querySelector(".filterItem." + kind + " select");
      if (!sel) { return null; }
      var opt = sel.options[sel.selectedIndex];
      return opt ? String(opt.text).trim() : null;
    } catch (e) { return null; }
  }

  function pickSpec(msg) {
    var system = msg && msg.system;
    if (isAllValue(system)) { system = domFilterText("system"); }
    var year = msg && msg.year;
    if (isAllValue(year)) { year = domFilterText("year"); }
    return {
      filter: (msg && msg.filter) || "",
      system: isAllValue(system) ? "" : system,
      year: isAllValue(year) ? "" : year,
      ranked: !!(msg && msg.ranked === true),
      favorites: !!(msg && msg.favorites === true),
    };
  }

  function applyNestedFilters(channels, spec) {
    var q = norm(spec.filter);
    var system = norm(spec.system);
    var year = spec.year ? String(spec.year) : "";
    var out = [];
    for (var i = 0; i < channels.length; i++) {
      var c = channels[i];
      if (q) {
        var blob = ((c.name || "") + " " + (c.gameid || "")).toLowerCase();
        if (blob.indexOf(q) === -1) { continue; }
      }
      if (system && norm(c.system) !== system) { continue; }
      if (year && String(c.year || "") !== year) { continue; }
      if (spec.ranked && !c.ranked) { continue; }
      if (spec.favorites && !c.favorite && !c.favorites) { continue; }
      out.push(c);
    }
    return out;
  }

  function buildMergedList(apiChannels) {
    var ids = window.__FC_VERTICAL_IDS;
    if (!ids) { return []; }

    var realByGameid = {};
    for (var i = 0; i < apiChannels.length; i++) {
      var c = apiChannels[i];
      if (!c || !c.gameid) { continue; }
      var rid = String(c.gameid).replace(/^fc1_/, "");
      if (!realByGameid[rid]) { realByGameid[rid] = c; }
    }

    var out = [];
    var keys = Object.keys(ids);
    for (var j = 0; j < keys.length; j++) {
      var gameid = keys[j];
      if (realByGameid[gameid]) {
        out.push(realByGameid[gameid]);
      } else {
        out.push(buildSyntheticChannel(gameid, ids[gameid] || []));
      }
    }

    out.sort(function (a, b) {
      var an = a.name.toLowerCase(), bn = b.name.toLowerCase();
      return an < bn ? -1 : an > bn ? 1 : 0;
    });
    return out;
  }

  function buildReply(requestIdx, filtered, page) {
    var pg = page || 0;
    var start = pg * PAGE_SIZE;
    return JSON.stringify({
      req: "channels",
      result: 200,
      requestIdx: requestIdx,
      genre: VERTICAL_GENRE,
      page: pg,
      totalChannels: filtered.length,
      channels: filtered.slice(start, start + PAGE_SIZE),
    });
  }

  function deliverReply(ws, payload) {
    try {
      ws.dispatchEvent(new MessageEvent("message", { data: payload }));
    } catch (e) {}
  }

  function parseMsg(data) {
    if (typeof data !== "string" || data.charAt(0) !== "{") { return null; }
    try { return JSON.parse(data); } catch (e) { return null; }
  }

  var pending = {};
  var verticalAll = null;
  var ignoreIdx = {};

  function cancelPending(idx, abandon) {
    var p = pending[idx];
    if (!p) { return; }
    clearTimeout(p.timer);
    delete pending[idx];
    if (abandon) { ignoreIdx[idx] = Date.now(); }
  }

  function cancelAllPending() {
    var keys = Object.keys(pending);
    for (var i = 0; i < keys.length; i++) {
      cancelPending(keys[i], true);
    }
  }

  function serveList(ws, idx, page, spec) {
    var filtered = applyNestedFilters(verticalAll || [], spec);
    deliverReply(ws, buildReply(idx, filtered, page));
  }

  function deliverAndCancel(idx) {
    var p = pending[idx];
    if (!p) { return; }
    verticalAll = buildMergedList(p.accum);
    cancelPending(idx);
    serveList(p.ws, idx, 0, p.spec);
  }

  function startFetch(ws, originalMsg) {
    var idx = originalMsg.requestIdx;
    cancelPending(idx);
    pending[idx] = {
      ws: ws,
      accum: [],
      spec: pickSpec(originalMsg),
      requestIdx: idx,
      totalExpected: -1,
      pagesReceived: 0,
      timer: setTimeout(function () {
        deliverAndCancel(idx);
      }, TIMEOUT_MS),
    };
    sendAllPage(ws, idx, 0, "");
  }

  function sendAllPage(ws, idx, page, filter) {
    try {
      nativeSend.call(ws, JSON.stringify({
        req: "channels",
        all: true,
        page: page,
        filter: filter || "",
        requestIdx: idx,
      }));
    } catch (e) {}
  }

  function handlePendingReply(msg, ev) {
    if (ignoreIdx[msg.requestIdx] && !pending[msg.requestIdx]) {
      if (ev && ev.stopImmediatePropagation) { ev.stopImmediatePropagation(); }
      return true;
    }
    var p = pending[msg.requestIdx];
    if (!p) { return false; }
    var chunk = msg.channels || [];
    p.accum = p.accum.concat(chunk);
    if (p.totalExpected < 0 && msg.totalChannels > 0) {
      p.totalExpected = msg.totalChannels;
    }
    p.pagesReceived++;
    if (ev && ev.stopImmediatePropagation) { ev.stopImmediatePropagation(); }
    var done = (msg.result !== 200) ||
      (p.totalExpected > 0 && p.accum.length >= p.totalExpected) ||
      (chunk.length < PAGE_SIZE);
    if (done) {
      deliverAndCancel(msg.requestIdx);
    } else {
      sendAllPage(p.ws, msg.requestIdx, p.pagesReceived, "");
    }
    return true;
  }

  var OrigWS = window.WebSocket;
  var nativeSend = OrigWS.prototype.send;

  OrigWS.prototype.send = function (data) {
    var msg = parseMsg(data);
    if (msg && msg.req === "channels") {
      var isVertical = String(msg.genre || "").toLowerCase() === "vertical";
      if (!isVertical && msg.paginated) {
        cancelAllPending();
      } else if (isVertical && !msg._fcVerticalPage) {
        var spec = pickSpec(msg);
        var reqPage = msg.page || 0;
        if (verticalAll) {
          var _ws = this;
          var _idx = msg.requestIdx;
          setTimeout(function () {
            serveList(_ws, _idx, reqPage, spec);
          }, 0);
          return;
        }
        startFetch(this, msg);
        return;
      }
    }
    return nativeSend.apply(this, arguments);
  };

  function attachReceiver(ws) {
    if (!ws || ws.__fcVerticalRx) { return; }
    ws.__fcVerticalRx = true;
    ws.addEventListener("message", function (ev) {
      if (typeof ev.data !== "string") { return; }
      var msg = parseMsg(ev.data);
      if (!msg || msg.req !== "channels") { return; }
      handlePendingReply(msg, ev);
    }, true);
  }

  window.WebSocket = function (url, protocols) {
    var ws = protocols !== undefined ? new OrigWS(url, protocols) : new OrigWS(url);
    attachReceiver(ws);
    return ws;
  };
  window.WebSocket.prototype = OrigWS.prototype;
  window.WebSocket.CONNECTING = OrigWS.CONNECTING;
  window.WebSocket.OPEN = OrigWS.OPEN;
  window.WebSocket.CLOSING = OrigWS.CLOSING;
  window.WebSocket.CLOSED = OrigWS.CLOSED;

  if (!OrigWS.prototype.__fcVerticalDispatchTap) {
    OrigWS.prototype.__fcVerticalDispatchTap = true;
    var origDispatch = OrigWS.prototype.dispatchEvent;
    OrigWS.prototype.dispatchEvent = function (ev) {
      if (ev && ev.type === "message" && typeof ev.data === "string") {
        var msg = parseMsg(ev.data);
        if (msg && msg.req === "channels" && handlePendingReply(msg, ev)) {
          return;
        }
      }
      return origDispatch.apply(this, arguments);
    };
  }

  function injectVerticalGenre() {
    var nodes = document.querySelectorAll(".filterItem.genre select");
    for (var i = 0; i < nodes.length; i++) {
      var el = nodes[i];
      while (el) {
        var vm = el.__vue__;
        if (vm && Array.isArray(vm.genres)) {
          if (vm.genres.indexOf(VERTICAL_GENRE) < 0) {
            vm.genres.push(VERTICAL_GENRE);
          }
          return;
        }
        el = el.parentElement;
      }
    }
  }

  setInterval(injectVerticalGenre, 1000);
})();
