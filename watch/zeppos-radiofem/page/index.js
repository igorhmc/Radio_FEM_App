import * as hmUI from "@zos/ui";
import {
  setScrollMode,
  swipeToIndex,
  SCROLL_MODE_SWIPER_HORIZONTAL,
} from "@zos/page";
import { BasePage } from "@zeppos/zml/base-page";

const SCREEN_SIZE = 466;
const PAGE_COUNT = 2;
const COLOR_BG = 0x0a0a0a;
const COLOR_PANEL = 0x181818;
const COLOR_ACCENT = 0xff8c1a;
const COLOR_ACCENT_SOFT = 0x5f3310;
const COLOR_TEXT = 0xffffff;
const COLOR_MUTED = 0xb5b5b5;
const REFRESH_MS = 30000;

let widgets = {};
let refreshTimer = null;

function pageX(page, x) {
  return page * SCREEN_SIZE + x;
}

function createText(page, options) {
  return hmUI.createWidget(hmUI.widget.TEXT, {
    color: COLOR_TEXT,
    text_size: 24,
    align_h: hmUI.align.CENTER_H,
    align_v: hmUI.align.CENTER_V,
    text_style: hmUI.text_style.WRAP,
    ...options,
    x: pageX(page, options.x || 0),
  });
}

function createRect(page, options) {
  return hmUI.createWidget(hmUI.widget.FILL_RECT, {
    ...options,
    x: pageX(page, options.x || 0),
  });
}

function createButton(page, options) {
  return hmUI.createWidget(hmUI.widget.BUTTON, {
    ...options,
    x: pageX(page, options.x || 0),
  });
}

function safeText(value, fallback) {
  const text = value == null ? "" : String(value).trim();
  return text || fallback;
}

function truncateText(value, limit) {
  const text = safeText(value, "");
  if (text.length <= limit) {
    return text;
  }
  return `${text.slice(0, Math.max(0, limit - 1)).trim()}…`;
}

function wrapText(value, firstLineLimit, secondLineLimit) {
  const normalized = safeText(value, "").replace(/\s+/g, " ").trim();
  if (!normalized) {
    return "";
  }

  if (normalized.length <= firstLineLimit) {
    return normalized;
  }

  let splitIndex = normalized.lastIndexOf(" ", firstLineLimit);
  if (splitIndex < Math.floor(firstLineLimit * 0.55)) {
    splitIndex = firstLineLimit;
  }

  const firstLine = normalized.slice(0, splitIndex).trim();
  const secondLine = truncateText(
    normalized.slice(splitIndex).trim(),
    secondLineLimit
  );
  return `${firstLine}\n${secondLine}`;
}

function formatUpdatedAt(value) {
  const text = safeText(value, "");
  if (!text) {
    return "Sem sincronizacao";
  }

  const date = new Date(text);
  if (Number.isNaN(date.getTime())) {
    return "Atualizado ha pouco";
  }

  const hours = String(date.getHours()).padStart(2, "0");
  const minutes = String(date.getMinutes()).padStart(2, "0");
  return `Atualizado ${hours}:${minutes}`;
}

function setControlStatus(message) {
  widgets.controlsStatus.setProperty(hmUI.prop.TEXT, message);
}

function goToPage(index) {
  swipeToIndex({
    index,
  });
}

Page(
  BasePage({
    state: {},

    build() {
      hmUI.setStatusBarVisible(false);
      setScrollMode({
        mode: SCROLL_MODE_SWIPER_HORIZONTAL,
        options: {
          width: SCREEN_SIZE,
          count: PAGE_COUNT,
        },
      });
      this.buildLayout();
      this.refreshData();
      refreshTimer = setInterval(() => {
        this.refreshData();
      }, REFRESH_MS);
    },

    buildLayout() {
      createRect(0, {
        x: 0,
        y: 0,
        w: SCREEN_SIZE,
        h: SCREEN_SIZE,
        color: COLOR_BG,
      });
      createRect(1, {
        x: 0,
        y: 0,
        w: SCREEN_SIZE,
        h: SCREEN_SIZE,
        color: COLOR_BG,
      });

      hmUI.createWidget(hmUI.widget.PAGE_INDICATOR, {
        x: 0,
        y: 16,
        w: SCREEN_SIZE,
        h: 20,
        align_h: hmUI.align.CENTER_H,
        h_space: 10,
        horizontal: true,
        use_color: true,
        select_color: COLOR_ACCENT,
        unselect_color: COLOR_ACCENT_SOFT,
        element_height: 8,
        element_radius: 4,
      });

      createRect(0, {
        x: 48,
        y: 82,
        w: 370,
        h: 216,
        color: COLOR_PANEL,
      });

      createRect(0, {
        x: 159,
        y: 26,
        w: 148,
        h: 34,
        color: COLOR_ACCENT,
      });

      widgets.liveBadge = createText(0, {
        x: 171,
        y: 29,
        w: 124,
        h: 28,
        text: "AO VIVO",
        text_size: 22,
        color: COLOR_BG,
      });

      widgets.station = createText(0, {
        x: 108,
        y: 64,
        w: 250,
        h: 22,
        text: "RADIO FEM",
        text_size: 20,
        color: COLOR_MUTED,
      });

      createRect(0, {
        x: 70,
        y: 122,
        w: 26,
        h: 6,
        color: COLOR_ACCENT_SOFT,
      });

      createRect(0, {
        x: 370,
        y: 122,
        w: 26,
        h: 6,
        color: COLOR_ACCENT_SOFT,
      });

      widgets.nowPlayingLabel = createText(0, {
        x: 120,
        y: 108,
        w: 226,
        h: 22,
        text: "TOCANDO AGORA",
        text_size: 18,
        color: COLOR_ACCENT,
      });

      widgets.title = createText(0, {
        x: 62,
        y: 140,
        w: 342,
        h: 76,
        text: "Conectando...",
        text_size: 34,
      });

      widgets.artist = createText(0, {
        x: 72,
        y: 220,
        w: 322,
        h: 44,
        text: "Carregando",
        text_size: 22,
        color: COLOR_MUTED,
      });

      createRect(0, {
        x: 128,
        y: 316,
        w: 210,
        h: 68,
        color: COLOR_PANEL,
      });

      widgets.listenersLabel = createText(0, {
        x: 140,
        y: 326,
        w: 186,
        h: 18,
        text: "OUVINTES AGORA",
        text_size: 16,
        color: COLOR_MUTED,
      });

      widgets.listenersValue = createText(0, {
        x: 140,
        y: 344,
        w: 186,
        h: 32,
        text: "0",
        text_size: 38,
        color: COLOR_ACCENT,
      });

      widgets.status = createText(0, {
        x: 76,
        y: 392,
        w: 314,
        h: 24,
        text: "Aguardando dados...",
        text_size: 18,
        color: COLOR_MUTED,
      });

      widgets.swipeHint = createText(0, {
        x: 108,
        y: 438,
        w: 250,
        h: 18,
        text: "Deslize ou toque em Controles",
        text_size: 16,
        color: COLOR_MUTED,
      });

      createButton(0, {
        x: 143,
        y: 414,
        w: 180,
        h: 34,
        text: "Controles >",
        normal_color: COLOR_ACCENT_SOFT,
        press_color: COLOR_ACCENT,
        text_size: 18,
        click_func: () => {
          goToPage(1);
        },
      });

      createRect(1, {
        x: 40,
        y: 68,
        w: 386,
        h: 298,
        color: COLOR_PANEL,
      });

      widgets.controlsTitle = createText(1, {
        x: 88,
        y: 52,
        w: 290,
        h: 30,
        text: "CONTROLE NO CELULAR",
        text_size: 22,
        color: COLOR_ACCENT,
      });

      widgets.controlsSubtitle = createText(1, {
        x: 106,
        y: 98,
        w: 254,
        h: 24,
        text: "Radio FEM no telefone",
        text_size: 18,
        color: COLOR_MUTED,
      });

      createButton(1, {
        x: 146,
        y: 108,
        w: 174,
        h: 28,
        text: "< Voltar ao ao vivo",
        normal_color: COLOR_ACCENT_SOFT,
        press_color: COLOR_ACCENT,
        text_size: 16,
        click_func: () => {
          goToPage(0);
        },
      });

      createButton(1, {
        x: 96,
        y: 154,
        w: 120,
        h: 40,
        text: "Play",
        normal_color: COLOR_ACCENT,
        press_color: 0xd88200,
        text_size: 24,
        click_func: () => {
          this.sendPhoneCommand("PLAY_ON_PHONE", "Play enviado");
        },
      });

      createButton(1, {
        x: 250,
        y: 154,
        w: 120,
        h: 40,
        text: "Pause",
        normal_color: 0x242424,
        press_color: 0x343434,
        text_size: 24,
        click_func: () => {
          this.sendPhoneCommand("PAUSE_ON_PHONE", "Pause enviado");
        },
      });

      createButton(1, {
        x: 96,
        y: 216,
        w: 120,
        h: 40,
        text: "Vol -",
        normal_color: 0x242424,
        press_color: 0x343434,
        text_size: 24,
        click_func: () => {
          this.sendPhoneCommand("VOLUME_DOWN_ON_PHONE", "Volume reduzido");
        },
      });

      createButton(1, {
        x: 250,
        y: 216,
        w: 120,
        h: 40,
        text: "Vol +",
        normal_color: COLOR_ACCENT,
        press_color: 0xd88200,
        text_size: 24,
        click_func: () => {
          this.sendPhoneCommand("VOLUME_UP_ON_PHONE", "Volume aumentado");
        },
      });

      createButton(1, {
        x: 146,
        y: 288,
        w: 174,
        h: 38,
        text: "Atualizar dados",
        normal_color: COLOR_ACCENT,
        press_color: 0xd88200,
        text_size: 20,
        click_func: () => {
          this.refreshData();
        },
      });

      widgets.controlsStatus = createText(1, {
        x: 72,
        y: 344,
        w: 322,
        h: 34,
        text: "Use esta tela para controlar",
        text_size: 18,
        color: COLOR_MUTED,
      });

      widgets.backHint = createText(1, {
        x: 120,
        y: 438,
        w: 226,
        h: 18,
        text: "Deslize ou toque em Voltar",
        text_size: 16,
        color: COLOR_MUTED,
      });
    },

    renderPayload(payload, ok) {
      const title =
        wrapText(payload && payload.title, 16, 20) || "Faixa ao vivo";
      const artist =
        wrapText(payload && payload.artist, 22, 24) ||
        "Artista desconhecido";
      const listeners =
        payload && Number.isFinite(payload.listeners)
          ? String(payload.listeners)
          : "0";

      widgets.title.setProperty(hmUI.prop.TEXT, title);
      widgets.artist.setProperty(hmUI.prop.TEXT, artist);
      widgets.listenersValue.setProperty(hmUI.prop.TEXT, listeners);
      widgets.status.setProperty(
        hmUI.prop.TEXT,
        ok ? formatUpdatedAt(payload.updatedAt) : "Sem conexao, exibindo ultimo dado"
      );
    },

    refreshData() {
      widgets.status.setProperty(hmUI.prop.TEXT, "Atualizando...");

      this.request({
        method: "GET_LIVE_STATUS",
      })
        .then((data) => {
          this.renderPayload(data.payload || {}, Boolean(data.ok));
        })
        .catch(() => {
          this.renderPayload({}, false);
        });
    },

    sendPhoneCommand(method, successMessage) {
      setControlStatus("Enviando comando...");

      this.request({ method })
        .then((data) => {
          if (data && data.ok) {
            setControlStatus(successMessage);
            return;
          }

          setControlStatus("Abra a Radio FEM no celular");
        })
        .catch(() => {
          setControlStatus("Bridge indisponivel no celular");
        });
    },

    onDestroy() {
      if (refreshTimer) {
        clearInterval(refreshTimer);
        refreshTimer = null;
      }
    },
  })
);
