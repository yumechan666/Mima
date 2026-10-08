export function createGameUI(mount) {
  const shell = document.createElement("section");
  shell.className = "game-shell";
  shell.innerHTML = `
    <canvas class="game-canvas game-surface" aria-label="Petualangan platform Mima"></canvas>
    <div class="hud-layer">
      <div class="hud-row game-hud">
        <div class="badge area-badge"><span class="area-number">01</span><span class="area-name">Home Canopy</span></div>
        <div class="badge collectible-badge"><span class="leaf-mark" aria-hidden="true">◆</span><span class="leaf-count">0/30</span><span class="clue-count">· 0/10</span></div>
        <div class="hud-actions">
          <div class="pip-row health" aria-label="Daya tahan"></div>
          <button class="icon-btn skin-btn" type="button" aria-label="Pilih skin"><span aria-hidden="true">◉</span></button>
          <button class="icon-btn pause-btn" type="button" aria-label="Jeda"><span aria-hidden="true">Ⅱ</span></button>
        </div>
      </div>
      <div class="objective-pill"><span class="objective-text"></span></div>
      <div class="boss-pill" hidden><span class="boss-name"></span><span class="boss-meter"><i></i></span></div>
    </div>
    <div class="scent-vignette" aria-hidden="true"></div>
    <div class="toast" role="status" aria-live="polite"></div>
    <div class="context-prompt" hidden><span class="prompt-key">AKSI</span><span class="prompt-text"></span></div>
    <div class="keyboard-hint">← → / A D gerak · Space lompat · E aksi atau lempar · Shift insting</div>
    <div class="touch-layer">
      <div class="joystick" aria-label="Stik gerak">
        <div class="joystick-rings" aria-hidden="true"></div>
        <div class="joystick-knob" aria-hidden="true"></div>
      </div>
      <div class="action-cluster">
        <button class="round-btn scent-btn" type="button" aria-label="Scent Vision"><span class="btn-icon">◎</span><span class="control-label">Insting</span></button>
        <button class="round-btn action-btn" type="button" aria-label="Aksi kontekstual"><span class="btn-icon">✦</span><span class="control-label">Aksi</span></button>
        <button class="round-btn jump-btn primary" type="button" aria-label="Lompat"><span class="btn-icon">↑</span><span class="control-label">Lompat</span></button>
      </div>
    </div>
    <div class="overlay loading-overlay">
      <div class="loading-leaf" aria-hidden="true"></div>
      <strong>Menumbuhkan kanopi…</strong>
      <span class="loading-progress">0%</span>
    </div>
    <div class="overlay pause-overlay" hidden>
      <div class="overlay-panel">
        <h2>Petualangan dijeda</h2>
        <p class="pause-summary"></p>
        <button class="menu-btn resume-btn" type="button"><span class="control-label">Lanjut</span></button>
        <button class="menu-btn restart-area-btn" type="button"><span class="control-label">Ulang dari dahan aman</span></button>
      </div>
    </div>
    <div class="overlay skin-overlay" hidden>
      <div class="overlay-panel skin-panel">
        <div class="skin-heading"><h2>Pilih kulit Mima</h2><button class="icon-btn close-skin-btn" type="button" aria-label="Tutup">×</button></div>
        <div class="skin-grid"></div>
        <p class="skin-status">Semua gerakan tetap memakai lima frame.</p>
      </div>
    </div>
    <div class="overlay victory-overlay" hidden>
      <div class="overlay-panel victory-panel">
        <div class="victory-leaves" aria-hidden="true">❧</div>
        <h2>Joey selamat</h2>
        <p class="victory-copy">Mima dan Joey selamat. Wilayah baru telah terbuka di balik Baobab.</p>
        <div class="victory-stats"></div>
        <button class="menu-btn explore-btn" type="button"><span class="control-label">Lanjut ke wilayah baru</span></button>
      </div>
    </div>
    <div class="overlay error-overlay" hidden>
      <div class="overlay-panel">
        <h2>Kanopi belum tumbuh</h2>
        <p>Aset utama tidak berhasil dimuat.</p>
        <button class="menu-btn retry-load-btn" type="button"><span class="control-label">Coba lagi</span></button>
      </div>
    </div>
  `;
  shell.tabIndex = -1;
  mount.replaceChildren(shell);
  requestAnimationFrame(() => shell.focus({ preventScroll: true }));

  const find = (selector) => shell.querySelector(selector);
  let toastTimer = 0;

  return {
    shell,
    canvas: find(".game-canvas"),
    controls: {
      joystick: find(".joystick"),
      joystickKnob: find(".joystick-knob"),
      jump: find(".jump-btn"),
      action: find(".action-btn"),
      scent: find(".scent-btn"),
    },
    buttons: {
      pause: find(".pause-btn"),
      skin: find(".skin-btn"),
      closeSkin: find(".close-skin-btn"),
      resume: find(".resume-btn"),
      restartArea: find(".restart-area-btn"),
      explore: find(".explore-btn"),
      retryLoad: find(".retry-load-btn"),
    },
    setLoading(percent) {
      find(".loading-progress").textContent = `${Math.round(percent)}%`;
    },
    hideLoading() {
      find(".loading-overlay").hidden = true;
    },
    showError() {
      find(".loading-overlay").hidden = true;
      find(".error-overlay").hidden = false;
    },
    updateHUD({ level, areaIndex, chapter, leaves, clues, totalLeaves = 60, totalClues = 20, hearts, objective, heavy, rescued }) {
      find(".area-number").textContent = String(areaIndex + 1).padStart(2, "0");
      find(".area-name").textContent = chapter ? `${level.name} · ${chapter}` : level.name;
      find(".leaf-count").textContent = `${leaves}/${totalLeaves}`;
      find(".clue-count").textContent = `· ${clues}/${totalClues}`;
      find(".objective-text").textContent = rescued && areaIndex < 10 ? "Joey aman · jalur frontier terbuka" : objective;
      const health = find(".health");
      health.replaceChildren(...Array.from({ length: 3 }, (_, index) => {
        const pip = document.createElement("span");
        pip.className = `pip leaf-pip${index < hearts ? " active" : ""}`;
        pip.setAttribute("aria-hidden", "true");
        return pip;
      }));
      shell.classList.toggle("is-heavy", heavy);
    },
    setScent(active) {
      shell.classList.toggle("scent-active", active);
      find(".scent-btn").classList.toggle("active", active);
    },
    setPrompt(label) {
      const prompt = find(".context-prompt");
      prompt.hidden = !label;
      if (label) find(".prompt-text").textContent = label;
    },
    toast(message, tone = "normal") {
      const toast = find(".toast");
      window.clearTimeout(toastTimer);
      toast.textContent = message;
      toast.dataset.tone = tone;
      toast.classList.add("visible");
      toastTimer = window.setTimeout(() => toast.classList.remove("visible"), 2100);
    },
    showPause(summary) {
      find(".pause-summary").textContent = summary;
      find(".pause-overlay").hidden = false;
    },
    hidePause() {
      find(".pause-overlay").hidden = true;
    },
    renderSkins(skins, selectedIndex) {
      const grid = find(".skin-grid");
      grid.replaceChildren(...skins.map((skin, index) => {
        const button = document.createElement("button");
        button.type = "button";
        button.className = `skin-choice${index === selectedIndex ? " selected" : ""}`;
        button.dataset.skinIndex = String(index);
        button.innerHTML = `<span class="skin-swatch" aria-hidden="true"><i style="--swatch:${skin.swatch[0]}"></i><i style="--swatch:${skin.swatch[1]}"></i><i style="--swatch:${skin.swatch[2]}"></i></span><span class="control-label">${skin.name}</span>`;
        return button;
      }));
    },
    showSkinMenu() {
      find(".skin-overlay").hidden = false;
    },
    hideSkinMenu() {
      find(".skin-overlay").hidden = true;
      find(".skin-status").textContent = "Semua gerakan tetap memakai lima frame.";
    },
    setSkinStatus(message) {
      find(".skin-status").textContent = message;
    },
    skinGrid: find(".skin-grid"),
    updateBoss(name, health, maxHealth) {
      const pill = find(".boss-pill");
      pill.hidden = !name;
      if (!name) return;
      find(".boss-name").textContent = name;
      find(".boss-meter i").style.width = `${Math.max(0, Math.min(1, health / maxHealth)) * 100}%`;
    },
    showVictory({ leaves, clues, carvings }) {
      find(".victory-stats").textContent = `${leaves}/60 daun · ${clues}/20 jejak · ${carvings}/20 ukiran`;
      find(".victory-overlay").hidden = false;
    },
    showFrontierVictory({ leaves, clues, carvings }) {
      find(".victory-panel h2").textContent = "Badai telah reda";
      find(".victory-copy").textContent = "Raja Kasuari mundur dan dua puluh kawasan kini terhubung.";
      find(".victory-stats").textContent = `${leaves}/60 daun · ${clues}/20 jejak · ${carvings}/20 ukiran`;
      find(".explore-btn .control-label").textContent = "Jelajahi ulang";
      find(".victory-overlay").hidden = false;
    },
    hideVictory() {
      find(".victory-overlay").hidden = true;
    },
    destroy() {
      window.clearTimeout(toastTimer);
      mount.replaceChildren();
    },
  };
}
