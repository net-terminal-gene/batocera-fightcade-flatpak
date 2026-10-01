// Fightcade vertical genre search — page-world script.
// Loaded by inject.js via a <script> element so it runs in the page world
// and can intercept the real WebSocket used by Fightcade.
//
// Vertical is not a server genre. The list is the local allowlist, delivered
// like one normal filter page. Join looks up that single game (one channels
// request) so the socket is never used to download the whole library.

(function () {
  if (window.__fcVerticalSearch) { return; }
  window.__fcVerticalSearch = true;

  var VERTICAL_GENRE = "Vertical";
  var PAGE_SIZE = 50;
  var LOOKUP_TIMEOUT_MS = 5000;

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
      _fcSynthetic: true,
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

  function buildAllowlist() {
    var ids = window.__FC_VERTICAL_IDS;
    if (!ids) { return []; }
    var out = [];
    var keys = Object.keys(ids);
    for (var i = 0; i < keys.length; i++) {
      out.push(buildSyntheticChannel(keys[i], ids[keys[i]] || []));
    }
    out.sort(function (a, b) {
      var an = (a.name || "").toLowerCase(), bn = (b.name || "").toLowerCase();
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

  var verticalAll = null;
  var liveIds = {};
  var liveByGameid = {};
  var liveByName = {};
  var lastClick = null;
  var lookups = {};
  var swallowedLookup = {};
  var lookupSeq = 800000;
  var joinClickToken = 0;
  var lastJoinId = "";
  var lastJoinAt = 0;

  function ensureAllowlist() {
    if (verticalAll) { return; }
    verticalAll = buildAllowlist();
    fcLog("[fc-cta] vertical-list " + JSON.stringify({
      ts: tsNow(),
      count: verticalAll.length,
      source: "allowlist",
    }));
  }

  function serveList(ws, idx, page, spec) {
    var filtered = applyNestedFilters(verticalAll || [], spec);
    deliverReply(ws, buildReply(idx, filtered, page));
  }

  function bareGameid(id) {
    return String(id || "").replace(/^fc1_/, "");
  }

  function rememberLive(ch, allowName) {
    if (!ch || !ch.gameid) { return; }
    var gid = bareGameid(ch.gameid);
    liveByGameid[gid] = ch;
    liveIds[gid] = true;
    window.__FC_VERTICAL_LIVE = liveIds;
    if (ch.name) { liveByName[ch.name] = ch; }
    if (allowName) { liveByName[allowName] = ch; }
    if (!verticalAll) { return; }
    for (var i = 0; i < verticalAll.length; i++) {
      if (bareGameid(verticalAll[i].gameid) === gid) {
        verticalAll[i] = ch;
        return;
      }
    }
  }

  function findGame(channels, gameid) {
    var want = bareGameid(gameid);
    if (!want || !channels) { return null; }
    for (var i = 0; i < channels.length; i++) {
      var c = channels[i];
      if (c && bareGameid(c.gameid) === want) { return c; }
    }
    return null;
  }

  function fcLog(line) {
    try { console.log(line); } catch (e) {}
    try {
      var el = document.getElementById("fc-cta-log");
      if (!el) {
        el = document.createElement("pre");
        el.id = "fc-cta-log";
        el.setAttribute("style", "display:none");
        (document.documentElement || document.body).appendChild(el);
      }
      el.appendChild(document.createTextNode(line + "\n"));
    } catch (e2) {}
  }

  function tsNow() {
    return new Date().toISOString();
  }

  function closestClass(el, className) {
    while (el && el !== document.documentElement) {
      if (el.classList && el.classList.contains(className)) { return el; }
      el = el.parentElement;
    }
    return null;
  }

  function vueOf(el) {
    while (el) {
      if (el.__vue__) { return el.__vue__; }
      el = el.parentElement;
    }
    return null;
  }

  function appVm() {
    var root = document.getElementById("app");
    var vm = root && root.__vue__;
    if (!vm) { return null; }
    if (vm.global && vm.global.localUser) { return vm; }
    var kids = vm.$children || [];
    for (var i = 0; i < kids.length; i++) {
      if (kids[i] && kids[i].global && kids[i].global.localUser) { return kids[i]; }
    }
    return null;
  }

  function localUser() {
    var app = appVm();
    return app && app.global && app.global.localUser;
  }

  function channelSnap(ch) {
    if (!ch) { return null; }
    var keys = [];
    try { keys = Object.keys(ch); } catch (e) {}
    var plain = [];
    for (var i = 0; i < keys.length; i++) {
      if (keys[i].charAt(0) !== "_" && keys[i].charAt(0) !== "$") { plain.push(keys[i]); }
    }
    var gid = bareGameid(ch.gameid);
    return {
      gameid: ch.gameid || "",
      name: ch.name || "",
      emulator: ch.emulator || "",
      system: ch.system || "",
      available_for: ch.available_for,
      alreadyJoined: !!ch.alreadyJoined,
      clients: ch.clients,
      ranked: !!ch.ranked,
      training: !!ch.training,
      owner: ch.owner || "",
      year: ch.year == null ? "" : ch.year,
      synthetic: !!ch._fcSynthetic,
      liveApi: !!(gid && liveIds[gid]),
      keys: plain.join(","),
    };
  }

  function userSnap(user) {
    if (!user) { return null; }
    return {
      role: user.role,
      maxNumChannelsReached: !!user.maxNumChannelsReached,
      maxNumChannels: user.perks ? user.perks.maxNumChannels : null,
      openChannels: user.channels ? user.channels.length : null,
    };
  }

  function joinReason(ch, user) {
    if (!ch) { return "no channel object on the Join button"; }
    if (ch.alreadyJoined) { return "already joined"; }
    if (user && ch.available_for != null && user.role < ch.available_for) {
      return "role below available_for";
    }
    if (user && user.maxNumChannelsReached) { return "max channels reached"; }
    if (ch._fcSynthetic || (ch.gameid && !liveIds[bareGameid(ch.gameid)])) {
      return "allowlist card; lookup one game then join";
    }
    return "card passed the client join checks";
  }

  function joinable(ch, user) {
    if (!ch) { return false; }
    if (ch.alreadyJoined) { return false; }
    if (user && user.maxNumChannelsReached) { return false; }
    if (user && ch.available_for != null && user.role < ch.available_for) { return false; }
    return true;
  }

  function logJoinSend(msg, extra) {
    joinClickToken = 0;
    var row = {
      ts: tsNow(),
      channelname: msg.channelname || "",
      status: msg.status || "",
      away: !!msg.away,
      idx: msg.idx,
      requestIdx: msg.requestIdx,
    };
    if (extra) {
      var ek = Object.keys(extra);
      for (var i = 0; i < ek.length; i++) { row[ek[i]] = extra[ek[i]]; }
    }
    fcLog("[fc-cta] join-api-send " + JSON.stringify(row));
  }

  function noteJoinRecv(msg) {
    var row = {
      ts: tsNow(),
      result: msg.result,
      ok: msg.result === 200,
      requestIdx: msg.requestIdx,
      channelname: msg.channelname || "",
      gameid: msg.gameid || "",
      emulator: msg.emulator || "",
      ranked: msg.ranked,
      training: msg.training,
      users: msg.users ? msg.users.length : 0,
      quarks: msg.quarks ? msg.quarks.length : 0,
    };
    if (msg.result !== 200) {
      var raw = {};
      var rk = [];
      try { rk = Object.keys(msg); } catch (e) {}
      for (var i = 0; i < rk.length; i++) {
        if (rk[i] === "users" || rk[i] === "quarks") { continue; }
        raw[rk[i]] = msg[rk[i]];
      }
      row.raw = raw;
    }
    fcLog("[fc-cta] join-api-recv " + JSON.stringify(row));
  }

  function onJoinMessage(msg) {
    if (!msg || msg.req !== "join" || msg.result == null) { return false; }
    var now = Date.now();
    var id = String(msg.requestIdx) + ":" + String(msg.result) + ":" + String(msg.channelname || "");
    if (id === lastJoinId && (now - lastJoinAt) < 300) { return false; }
    lastJoinId = id;
    lastJoinAt = now;
    noteJoinRecv(msg);
    return false;
  }

  function lookupFilters(flight) {
    var gid = flight.gameid || "";
    var name = flight.allowName || "";
    var colon = name.indexOf(" : ") >= 0 ? name.replace(" : ", ": ") : "";
    var steps = [gid, name, colon];
    var out = [];
    var seen = {};
    for (var i = 0; i < steps.length; i++) {
      var f = String(steps[i] || "").trim();
      if (!f || seen[f]) { continue; }
      seen[f] = 1;
      out.push(f);
    }
    return out;
  }

  function sendRewrittenJoin(ws, payload, channelname, gameid) {
    var msg = parseMsg(payload) || {};
    msg.channelname = channelname;
    try { nativeSend.call(ws, JSON.stringify(msg)); } catch (e) {}
    logJoinSend(msg, { lookup: true, gameid: gameid || "" });
  }

  function finishLookup(flight, match) {
    if (flight.timer) { clearTimeout(flight.timer); }
    if (flight.lookupIdx != null) { delete lookups[flight.lookupIdx]; }
    if (match && match.name) {
      rememberLive(match, flight.allowName);
      sendRewrittenJoin(flight.ws, flight.payload, match.name, flight.gameid);
      return;
    }
    fcLog("[fc-cta] join-lookup-miss " + JSON.stringify({
      ts: tsNow(),
      gameid: flight.gameid || "",
      channelname: flight.channelname || "",
    }));
    var msg = parseMsg(flight.payload);
    try { nativeSend.call(flight.ws, flight.payload); } catch (e) {}
    if (msg) { logJoinSend(msg, { lookup: false }); }
  }

  function sendLookup(flight) {
    var filters = lookupFilters(flight);
    if (flight.step >= filters.length) {
      finishLookup(flight, null);
      return;
    }
    var filter = filters[flight.step];
    var idx = lookupSeq++;
    flight.lookupIdx = idx;
    lookups[idx] = flight;
    if (flight.timer) { clearTimeout(flight.timer); }
    flight.timer = setTimeout(function () {
      if (lookups[idx] !== flight) { return; }
      flight.step++;
      sendLookup(flight);
    }, LOOKUP_TIMEOUT_MS);
    fcLog("[fc-cta] join-lookup " + JSON.stringify({
      ts: tsNow(),
      gameid: flight.gameid || "",
      filter: filter,
      step: flight.step,
    }));
    try {
      nativeSend.call(flight.ws, JSON.stringify({
        req: "channels",
        filter: filter,
        paginated: true,
        page: 0,
        requestIdx: idx,
      }));
    } catch (e) {}
  }

  function handleLookupReply(msg, ev) {
    if (swallowedLookup[msg.requestIdx]) {
      if (ev && ev.stopImmediatePropagation) { ev.stopImmediatePropagation(); }
      return true;
    }
    var flight = lookups[msg.requestIdx];
    if (!flight) { return false; }
    swallowedLookup[msg.requestIdx] = 1;
    if (ev && ev.stopImmediatePropagation) { ev.stopImmediatePropagation(); }
    if (flight.settled) { return true; }
    var match = findGame(msg.channels, flight.gameid);
    if (match) {
      flight.settled = true;
      finishLookup(flight, match);
      return true;
    }
    flight.settled = true;
    if (flight.timer) { clearTimeout(flight.timer); }
    delete lookups[msg.requestIdx];
    flight.step++;
    flight.settled = false;
    sendLookup(flight);
    return true;
  }

  // Returns true when this send is held for a one-game lookup.
  function prepareJoin(msg, ws, raw) {
    var click = lastClick;
    var recent = click && (Date.now() - click.at) < 3000 && click.name === msg.channelname;
    if (!recent) { return false; }
    lastClick = null;
    var gid = bareGameid(click.gameid);
    var live = liveByGameid[gid] || liveByName[msg.channelname];
    if (live && live.name) {
      if (live.name !== msg.channelname) {
        sendRewrittenJoin(ws, raw, live.name, gid);
        return true;
      }
      return false;
    }
    sendLookup({
      ws: ws,
      payload: typeof raw === "string" ? raw : JSON.stringify(msg),
      gameid: gid,
      allowName: click.name || msg.channelname,
      channelname: msg.channelname || "",
      step: 0,
      settled: false,
      timer: null,
      lookupIdx: null,
    });
    return true;
  }

  function onJoinButton(btn) {
    var token = Date.now();
    joinClickToken = token;
    var vm = vueOf(btn);
    var ch = vm && (vm.channel || vm.event);
    if (ch) {
      lastClick = {
        gameid: ch.gameid || "",
        name: ch.name || "",
        at: Date.now(),
      };
    }
    var user = localUser();
    fcLog("[fc-cta] join-click " + JSON.stringify({
      ts: tsNow(),
      joinable: joinable(ch, user),
      reason: joinReason(ch, user),
      channel: channelSnap(ch),
      user: userSnap(user),
    }));
    setTimeout(function () {
      if (joinClickToken === token) {
        joinClickToken = 0;
        fcLog("[fc-cta] join-api-send missing " + JSON.stringify({ ts: tsNow() }));
      }
    }, 20000);
  }

  var BASE_ROOMS = {
    "about-channel": 1,
    "welcome-channel": 1,
    "patreon-channel": 1,
    "search-channel": 1,
  };

  function onJoinedRoom(item) {
    var vm = vueOf(item);
    var data = vm && vm.data;
    if (!data) { return; }
    var id = String(data.id || "");
    if (BASE_ROOMS[id] || !data.gameid) { return; }
    fcLog("[fc-cta] join-room true " + JSON.stringify({
      ts: tsNow(),
      id: id,
      gameid: data.gameid,
      name: data.name || "",
    }));
  }

  document.addEventListener("mousedown", function (ev) {
    if (ev.button != null && ev.button !== 0) { return; }
    var joinBtn = closestClass(ev.target, "joinButton");
    if (joinBtn) {
      onJoinButton(joinBtn);
      return;
    }
    var room = closestClass(ev.target, "channelItem");
    if (room) { onJoinedRoom(room); }
  }, true);

  var OrigWS = window.WebSocket;
  var nativeSend = OrigWS.prototype.send;

  OrigWS.prototype.send = function (data) {
    var msg = parseMsg(data);
    if (msg && msg.req === "join") {
      if (prepareJoin(msg, this, data)) { return; }
      logJoinSend(msg);
    }
    if (msg && msg.req === "channels") {
      var isVertical = String(msg.genre || "").toLowerCase() === "vertical";
      if (isVertical && !msg._fcLookup) {
        var spec = pickSpec(msg);
        var reqPage = msg.page || 0;
        ensureAllowlist();
        var _ws = this;
        var _idx = msg.requestIdx;
        setTimeout(function () {
          serveList(_ws, _idx, reqPage, spec);
        }, 0);
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
      if (!msg) { return; }
      if (msg.req === "join") { onJoinMessage(msg); }
      if (msg.req === "channels" && handleLookupReply(msg, ev)) { return; }
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
        if (msg && msg.req === "join") { onJoinMessage(msg); }
        if (msg && msg.req === "channels" && handleLookupReply(msg, ev)) {
          return;
        }
      }
      return origDispatch.apply(this, arguments);
    };
  }

  // Index Vertical would have in the list after it is removed.
  // "All" stays first. Vertical lands before the first genre that sorts after it.
  function verticalSlot(genres) {
    var at = 0;
    for (var i = 0; i < genres.length; i++) {
      if (genres[i] === VERTICAL_GENRE) { continue; }
      if (genres[i] > VERTICAL_GENRE) { break; }
      at++;
    }
    return at;
  }

  function placeVertical(genres) {
    var want = verticalSlot(genres);
    var current = genres.indexOf(VERTICAL_GENRE);
    if (current === want) { return; }
    if (current >= 0) { genres.splice(current, 1); }
    genres.splice(want, 0, VERTICAL_GENRE);
  }

  function injectVerticalGenre() {
    var nodes = document.querySelectorAll(".filterItem.genre select");
    for (var i = 0; i < nodes.length; i++) {
      var el = nodes[i];
      while (el) {
        var vm = el.__vue__;
        if (vm && Array.isArray(vm.genres)) {
          placeVertical(vm.genres);
          return;
        }
        el = el.parentElement;
      }
    }
  }

  setInterval(injectVerticalGenre, 1000);
  fcLog("[fc-cta] ready " + JSON.stringify({ ts: tsNow() }));
})();
