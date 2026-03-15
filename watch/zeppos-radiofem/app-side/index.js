import { BaseSideService } from "@zeppos/zml/base-side";

const API_URL = "https://radio.forroemmilao.com/api/nowplaying/radiofem";
const BRIDGE_URL = "http://127.0.0.1:43871";
const BRIDGE_KEY = "radiofem-watch-bridge-v1";

let lastPayload = {
  stationName: "Radio FEM",
  artist: "Loading",
  title: "Connecting...",
  listeners: 0,
  updatedAt: "",
};

function asObject(value) {
  if (value && typeof value === "object" && !Array.isArray(value)) {
    return value;
  }
  return {};
}

function asString(value) {
  return value == null ? "" : String(value).trim();
}

function asInt(value) {
  const parsed = Number.parseInt(asString(value), 10);
  return Number.isFinite(parsed) ? parsed : 0;
}

function normalizePayload(rawBody) {
  const body = asObject(rawBody);
  const station = asObject(body.station);
  const listeners = asObject(body.listeners);
  const nowPlaying = asObject(body.now_playing);
  const song = asObject(nowPlaying.song);

  let artist = asString(song.artist);
  let title = asString(song.title);
  const text = asString(song.text);

  if ((!artist || !title) && text.includes(" - ")) {
    const parts = text.split(" - ");
    if (!artist) {
      artist = parts.shift() || "";
    }
    if (!title) {
      title = parts.join(" - ");
    }
  }

  return {
    stationName: asString(station.name) || "Radio FEM",
    artist: artist || "Unknown artist",
    title: title || text || "Live track",
    listeners: asInt(listeners.current),
    updatedAt: new Date().toISOString(),
  };
}

async function fetchLiveStatus(res) {
  try {
    const response = await fetch({
      url: API_URL,
      method: "GET",
      headers: {
        Accept: "application/json",
      },
    });

    if (response.status < 200 || response.status >= 300) {
      throw new Error(`HTTP ${response.status}`);
    }

    const body =
      typeof response.body === "string" ? JSON.parse(response.body) : response.body;

    lastPayload = normalizePayload(body);
    res(null, {
      ok: true,
      payload: lastPayload,
    });
  } catch (error) {
    res(null, {
      ok: false,
      payload: lastPayload,
      error: error && error.message ? error.message : "Request failed",
    });
  }
}

async function sendRemoteCommand(command, res) {
  try {
    const response = await fetch({
      url: `${BRIDGE_URL}/command/${command}?key=${encodeURIComponent(BRIDGE_KEY)}`,
      method: "GET",
      headers: {
        Accept: "application/json",
      },
    });

    const body =
      typeof response.body === "string" ? JSON.parse(response.body) : response.body;

    if (response.status < 200 || response.status >= 300) {
      throw new Error(
        body && body.error ? body.error : `HTTP ${response.status}`
      );
    }

    res(null, {
      ok: true,
      payload: body || {},
    });
  } catch (error) {
    res(null, {
      ok: false,
      error: error && error.message ? error.message : "Bridge unavailable",
    });
  }
}

AppSideService(
  BaseSideService({
    onInit() {},
    onRequest(req, res) {
      if (req.method === "GET_LIVE_STATUS") {
        fetchLiveStatus(res);
        return;
      }

      if (req.method === "PLAY_ON_PHONE") {
        sendRemoteCommand("play-live", res);
        return;
      }

      if (req.method === "PAUSE_ON_PHONE") {
        sendRemoteCommand("pause", res);
        return;
      }

      if (req.method === "VOLUME_DOWN_ON_PHONE") {
        sendRemoteCommand("volume-down", res);
        return;
      }

      if (req.method === "VOLUME_UP_ON_PHONE") {
        sendRemoteCommand("volume-up", res);
      }
    },
    onRun() {},
    onDestroy() {},
  })
);
