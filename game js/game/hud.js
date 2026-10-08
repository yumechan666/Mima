import { frameCrop } from "./asset-loader.js";

export function createHud(mount) {
  const shell = document.createElement("section");
  shell.className = "game-shell";
  shell.innerHTML = `
    <canvas class="game-canvas game-surface" aria-label="Venomcoil game world"></canvas>
    <div class="hud-layer">
      <div class="hud-row venom-hud">
        <div class="hud-cluster health-cluster" aria-label="Health">
          <div class="pip-row" data-hearts>
            <span class="pip"><canvas data-icon="heart_full"></canvas></span>
            <span class="pip"><canvas data-icon="heart_full"></canvas></span>
            <span class="pip"><canvas data-icon="heart_full"></canvas></span>
          </div>
          <div class="meter momentum-meter" title="Momentum"><i data-momentum></i></div>
        </div>
        <div class="area-chip badge"><b data-area>1</b><span data-area-name>CANOPY</span><i data-progress></i></div>
        <div class="hud-cluster hud-end">
          <span class="timer badge" data-time>00:00.0</span>
          <button class="icon-button" data-control="pause" aria-label="Pause"><canvas data-icon="pause"></canvas></button>
        </div>
      </div>
      <div class="lesson-banner" data-lesson hidden></div>
      <div class="toast" data-toast hidden></div>
      <div class="controls-dock" aria-label="Game controls">
        <div class="move-controls">
          <button class="control-btn round-control" data-control="left" aria-label="Move left"><canvas data-icon="arrow_left"></canvas></button>
          <button class="control-btn round-control" data-control="right" aria-label="Move right"><canvas data-icon="arrow_right"></canvas></button>
        </div>
        <div class="ability-controls">
          <button class="control-btn ability-btn" data-control="coil"><canvas data-icon="coil"></canvas><span class="control-label">COIL</span><i data-coil-charge></i></button>
          <button class="control-btn ability-btn" data-control="venom"><canvas data-icon="venom"></canvas><span class="control-label">VENOM</span></button>
          <button class="control-btn ability-btn" data-control="tail"><canvas data-icon="tail"></canvas><span class="control-label">TAIL</span></button>
        </div>
      </div>
    </div>
    <div class="game-overlay overlay" data-overlay hidden>
      <div class="overlay-panel">
        <span data-overlay-kicker></span>
        <h2 data-overlay-title></h2>
        <p data-overlay-body></p>
        <div class="area-select-grid" data-area-select hidden></div>
        <div class="overlay-actions">
          <button class="overlay-button" data-overlay-primary><span class="control-label">CONTINUE</span></button>
          <button class="overlay-button secondary" data-overlay-secondary hidden><span class="control-label">RETRY</span></button>
        </div>
      </div>
    </div>
    <div class="loading-screen">
      <div class="loading-coil"></div>
      <strong>WAKING THE TRAIL</strong>
      <small data-loading-status>Painting the canopy…</small>
      <button class="overlay-button" data-loading-retry hidden><span class="control-label">TRY AGAIN</span></button>
    </div>
  `;
  mount.replaceChildren(shell);

  const refs = {
    shell,
    canvas: shell.querySelector(".game-canvas"),
    loading: shell.querySelector(".loading-screen"),
    loadingStatus: shell.querySelector("[data-loading-status]"),
    loadingRetry: shell.querySelector("[data-loading-retry]"),
    hearts: [...shell.querySelectorAll("[data-hearts] .pip")],
    area: shell.querySelector("[data-area]"),
    areaName: shell.querySelector("[data-area-name]"),
    progress: shell.querySelector("[data-progress]"),
    momentum: shell.querySelector("[data-momentum]"),
    time: shell.querySelector("[data-time]"),
    coil: shell.querySelector("[data-coil-charge]"),
    lesson: shell.querySelector("[data-lesson]"),
    toast: shell.querySelector("[data-toast]"),
    overlay: shell.querySelector("[data-overlay]"),
    overlayKicker: shell.querySelector("[data-overlay-kicker]"),
    overlayTitle: shell.querySelector("[data-overlay-title]"),
    overlayBody: shell.querySelector("[data-overlay-body]"),
    areaSelect: shell.querySelector("[data-area-select]"),
    overlayPrimary: shell.querySelector("[data-overlay-primary]"),
    overlaySecondary: shell.querySelector("[data-overlay-secondary]"),
  };
  let toastTimer = 0;
  let lessonTimer = 0;

  return {
    ...refs,
    setLoading(text) {
      refs.loadingStatus.textContent = text;
    },
    failLoading(onRetry) {
      refs.loadingStatus.textContent = "The trail could not form.";
      refs.loadingRetry.hidden = false;
      refs.loadingRetry.onclick = onRetry;
    },
    hideLoading() {
      refs.loading.classList.add("is-hidden");
      window.setTimeout(() => refs.loading.remove(), 350);
    },
    paintIcons(store) {
      const image = store.image("HUD_ATLAS");
      if (!image) return;
      shell.querySelectorAll("canvas[data-icon]").forEach((canvas) => {
        const frame = store.frame("HUD_ATLAS", canvas.dataset.icon);
        const crop = frameCrop(frame);
        if (!crop) return;
        canvas.width = 80;
        canvas.height = 80;
        const context = canvas.getContext("2d");
        const scale = Math.min(68 / crop.w, 68 / crop.h);
        const w = crop.w * scale;
        const h = crop.h * scale;
        context.clearRect(0, 0, 80, 80);
        context.drawImage(image, crop.x, crop.y, crop.w, crop.h, 40 - w / 2, 40 - h / 2, w, h);
      });
    },
    update({ hearts, momentum, coilCharge, areaIndex, areaName, progress, elapsed }) {
      refs.hearts.forEach((pip, index) => pip.classList.toggle("empty", index >= hearts));
      refs.momentum.style.setProperty("--fill", `${Math.round(momentum * 100)}%`);
      refs.coil.style.setProperty("--charge", `${Math.round(coilCharge * 100)}%`);
      refs.area.textContent = String(areaIndex + 1).padStart(2, "0");
      refs.areaName.textContent = areaName.toUpperCase();
      refs.progress.style.setProperty("--progress", `${Math.round(progress * 100)}%`);
      refs.time.textContent = formatTime(elapsed);
    },
    showLesson(text, duration = 3000) {
      window.clearTimeout(lessonTimer);
      refs.lesson.textContent = text;
      refs.lesson.hidden = false;
      refs.lesson.classList.remove("fade-out");
      lessonTimer = window.setTimeout(() => refs.lesson.classList.add("fade-out"), duration);
    },
    toast(text, duration = 1200) {
      window.clearTimeout(toastTimer);
      refs.toast.textContent = text;
      refs.toast.hidden = false;
      refs.toast.classList.remove("fade-out");
      toastTimer = window.setTimeout(() => refs.toast.classList.add("fade-out"), duration);
    },
    setOverlay(config) {
      if (!config) {
        refs.overlay.hidden = true;
        refs.overlayPrimary.onclick = null;
        refs.overlaySecondary.onclick = null;
        return;
      }
      refs.overlayKicker.textContent = config.kicker ?? "";
      refs.overlayTitle.textContent = config.title ?? "";
      refs.overlayBody.textContent = config.body ?? "";
      refs.areaSelect.hidden = true;
      refs.areaSelect.className = "area-select-grid";
      refs.areaSelect.replaceChildren();
      refs.overlayPrimary.querySelector("span").textContent = config.primaryLabel ?? "CONTINUE";
      refs.overlayPrimary.onclick = config.onPrimary ?? null;
      refs.overlaySecondary.hidden = !config.onSecondary;
      refs.overlaySecondary.querySelector("span").textContent = config.secondaryLabel ?? "RETRY";
      refs.overlaySecondary.onclick = config.onSecondary ?? null;
      refs.overlay.hidden = false;
    },
    showAreaSelect(unlocked, onSelect, onClose, total = 20) {
      refs.overlayKicker.textContent = "TWENTYFOLD TRAIL";
      refs.overlayTitle.textContent = "CHOOSE AN AREA";
      refs.overlayBody.textContent = "Replay any trail you have reached.";
      refs.areaSelect.hidden = false;
      refs.areaSelect.className = "area-select-grid";
      refs.areaSelect.replaceChildren(...Array.from({ length: total }, (_, index) => {
        const button = document.createElement("button");
        button.className = "area-select-button";
        button.disabled = index >= unlocked;
        button.textContent = String(index + 1).padStart(2, "0");
        button.onclick = () => onSelect(index);
        return button;
      }));
      refs.overlayPrimary.querySelector("span").textContent = "BACK";
      refs.overlayPrimary.onclick = onClose;
      refs.overlaySecondary.hidden = true;
      refs.overlay.hidden = false;
    },
    showSkinSelect(skins, store, current, onSelect, onClose) {
      refs.overlayKicker.textContent = "VEXA FORMS";
      refs.overlayTitle.textContent = "CHOOSE A SKIN";
      refs.overlayBody.textContent = "Each form has its own body, venom, tail trail, and parry flash.";
      refs.areaSelect.hidden = false;
      refs.areaSelect.className = "skin-select-grid";
      refs.areaSelect.replaceChildren(...skins.map((skin, index) => {
        const button = document.createElement("button");
        button.className = "skin-select-button";
        button.classList.toggle("selected", index === current);
        button.style.setProperty("--skin-accent", skin.accent);
        const preview = document.createElement("canvas");
        preview.width = 160;
        preview.height = 100;
        const label = document.createElement("span");
        label.textContent = skin.name;
        button.append(preview, label);
        const image = store.image(skin.keys.motionA);
        const frame = store.frame(skin.keys.motionA, `${skin.prefix}_idle_breathe_1`);
        const crop = frameCrop(frame);
        if (image && crop) {
          const ctx = preview.getContext("2d");
          const scale = Math.min(142 / crop.w, 86 / crop.h);
          const w = crop.w * scale;
          const h = crop.h * scale;
          ctx.drawImage(image, crop.x, crop.y, crop.w, crop.h, 80 - w / 2, 94 - h, w, h);
        }
        button.onclick = () => onSelect(index);
        return button;
      }));
      refs.overlayPrimary.querySelector("span").textContent = "BACK";
      refs.overlayPrimary.onclick = onClose;
      refs.overlaySecondary.hidden = true;
      refs.overlay.hidden = false;
    },
    destroy() {
      window.clearTimeout(toastTimer);
      window.clearTimeout(lessonTimer);
      shell.remove();
    },
  };
}

export function formatTime(milliseconds) {
  const totalSeconds = Math.max(0, milliseconds / 1000);
  const minutes = Math.floor(totalSeconds / 60);
  const seconds = Math.floor(totalSeconds % 60);
  const tenths = Math.floor((totalSeconds % 1) * 10);
  return `${String(minutes).padStart(2, "0")}:${String(seconds).padStart(2, "0")}.${tenths}`;
}
