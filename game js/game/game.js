import { createAssetStore } from "./assets.js";
import { createAudio } from "./audio.js";
import { createInput } from "./input.js";
import { cloneLevel, LEVELS, UPGRADE_BY_AREA, WORLD } from "./levels.js";
import { createPlayer, distanceTo, overlaps, resetPlayer, updatePlayer } from "./physics.js";
import { createRenderer } from "./renderer.js";
import { SKINS, skinKeys } from "./skins.js";
import { createGameUI } from "./ui.js";

const SAVE_VERSION = 2;
const clamp = (value, min, max) => Math.max(min, Math.min(max, value));
const TOTAL_LEAVES = LEVELS.length * 3;
const TOTAL_CLUES = LEVELS.length;

function safeArray(value) {
  return Array.isArray(value) ? value.filter((item) => typeof item === "string") : [];
}

function parseSave(saved) {
  if (!saved || ![1, SAVE_VERSION].includes(saved.version)) {
    return {
      version: SAVE_VERSION,
      area: 0,
      leaves: [],
      clues: [],
      carvings: [],
      actions: [],
      abilities: ["scent", "gumnut"],
      rescued: false,
      hearts: 3,
      bestScore: 0,
      skinIndex: 0,
      checkpointSection: 0,
    };
  }
  return {
    version: SAVE_VERSION,
    area: clamp(Number(saved.area) || 0, 0, LEVELS.length - 1),
    leaves: safeArray(saved.leaves),
    clues: safeArray(saved.clues),
    carvings: safeArray(saved.carvings),
    actions: safeArray(saved.actions),
    abilities: safeArray(saved.abilities),
    rescued: Boolean(saved.rescued),
    hearts: clamp(Number(saved.hearts) || 3, 1, 3),
    bestScore: Math.max(0, Number(saved.bestScore) || 0),
    skinIndex: clamp(Number(saved.skinIndex) || 0, 0, SKINS.length - 1),
    checkpointSection: clamp(Number(saved.checkpointSection) || 0, 0, 2),
  };
}

function checkpointSpawn(section) {
  if (section >= 2) return { x: 92, y: 1368 };
  if (section === 1) return { x: 92, y: 2818 };
  return { x: 92, y: 4268 };
}

function scoreFor(progress) {
  return progress.leaves.size * 100 + progress.clues.size * 500 + progress.carvings.size * 250;
}

export function createGame({ mount, sdk, tweaks, assets }) {
  let teardown = () => {};

  async function boot() {
    const ui = createGameUI(mount);
    let destroyed = false;
    let frameId = 0;
    let renderer = null;
    let input = null;
    let audio = null;
    const listeners = [];
    const unsubscribes = [];

    const config = {
      playerSpeed: Number(tweaks.get("playerSpeed")),
      jumpForce: Number(tweaks.get("jumpForce")),
      gravity: Number(tweaks.get("gravity")),
      scentSeconds: Number(tweaks.get("scentSeconds")),
      effectsIntensity: Number(tweaks.get("effectsIntensity")),
    };
    for (const key of Object.keys(config)) {
      unsubscribes.push(tweaks.subscribe(key, (value) => {
        config[key] = Number(value);
      }));
    }

    const store = createAssetStore(assets, (loaded, total) => ui.setLoading((loaded / total) * 100));
    let saved;
    try {
      [saved] = await Promise.all([
        sdk.gameState.load().catch(() => null),
        store.loadCritical(),
      ]);
    } catch {
      ui.showError();
      const retry = () => window.location.reload();
      ui.buttons.retryLoad.addEventListener("click", retry);
      teardown = () => {
        destroyed = true;
        ui.buttons.retryLoad.removeEventListener("click", retry);
        unsubscribes.forEach((unsubscribe) => unsubscribe());
        ui.destroy();
      };
      return;
    }
    if (destroyed) return;

    const loaded = parseSave(saved);
    let skinIndex = loaded.skinIndex;
    let skin = SKINS[skinIndex];
    if (skinIndex > 0) {
      try {
        ui.setLoading(86);
        await Promise.all(skinKeys(skin).map((key) => store.load(key)));
      } catch {
        skinIndex = 0;
        skin = SKINS[0];
      }
    }
    const progress = {
      leaves: new Set(loaded.leaves),
      clues: new Set(loaded.clues),
      carvings: new Set(loaded.carvings),
      actions: new Set(loaded.actions),
      abilities: new Set(["scent", "gumnut", ...loaded.abilities]),
      rescued: loaded.rescued,
      hearts: loaded.hearts,
      bestScore: loaded.bestScore,
    };

    let areaIndex = loaded.area;
    let level = cloneLevel(areaIndex);
    let checkpointSection = loaded.checkpointSection;
    let player = createPlayer(checkpointSpawn(checkpointSection));
    let npcs = level.npcs.map((npc) => ({ ...npc, facing: 1, baseAnim: npc.anim, maxHealth: npc.health ?? 1, homeY: npc.y }));
    let effects = [];
    let projectiles = [];
    let running = true;
    let paused = false;
    let scentUntil = 0;
    let lastTime = performance.now();
    let flash = 0;
    let shake = 0;
    let nearest = null;
    let lastThrowAt = 0;
    let initialSkinSelection = true;

    for (let i = 0; i <= areaIndex; i += 1) progress.abilities.add(UPGRADE_BY_AREA[i]);
    ui.hideLoading();
    ui.renderSkins(SKINS, skinIndex);
    renderer = createRenderer(ui.canvas, store);
    input = createInput({ shell: ui.shell, ...ui.controls });
    audio = createAudio({ sdk, shell: ui.shell });
    void store.loadRemaining();

    function listen(target, type, handler, options) {
      target.addEventListener(type, handler, options);
      listeners.push(() => target.removeEventListener(type, handler, options));
    }

    function serialize() {
      return {
        version: SAVE_VERSION,
        area: areaIndex,
        leaves: [...progress.leaves],
        clues: [...progress.clues],
        carvings: [...progress.carvings],
        actions: [...progress.actions],
        abilities: [...progress.abilities],
        rescued: progress.rescued,
        hearts: progress.hearts,
        bestScore: progress.bestScore,
        skinIndex,
        checkpointSection,
      };
    }

    function save() {
      void sdk.gameState.save(serialize()).catch(() => {});
    }

    function haptic(pattern = 24) {
      if (!sdk.device.haptics.isSupported()) return;
      void sdk.device.haptics.vibrate(pattern).catch(() => {});
    }

    function addEffect(key, anim, x, y, duration = 520, size = 90, facing = 1) {
      effects.push({ key, anim, x, y, duration, size, facing, startedAt: performance.now() });
    }

    function animatePlayer(key, name, duration = 520) {
      player.animOverride = { key, name };
      player.animOverrideUntil = performance.now() + duration;
    }

    function throwGumnut() {
      const now = performance.now();
      if (now - lastThrowAt < 360) return;
      lastThrowAt = now;
      animatePlayer("MIMA_ABILITIES_SHEET", "gumnut_throw", 360);
      projectiles.push({
        owner: "player",
        x: player.x + player.facing * 30,
        y: player.y - 46,
        vx: player.facing * 620,
        vy: -80,
        life: 1.5,
        visual: "gumnut",
      });
      audio.play("action");
    }

    function areaLeavesCount(index = areaIndex) {
      return LEVELS[index].leaves.filter((leaf) => progress.leaves.has(leaf.id)).length;
    }

    function actionCount(prefix) {
      let count = 0;
      for (const id of progress.actions) if (id.startsWith(prefix)) count += 1;
      return count;
    }

    function solved() {
      let coreSolved = false;
      switch (areaIndex) {
        case 0: coreSolved = areaLeavesCount() >= 3 && progress.actions.has("seed-0"); break;
        case 1: coreSolved = actionCount("bark-1-") >= 3; break;
        case 2: coreSolved = progress.actions.has("lever-2"); break;
        case 3: coreSolved = progress.clues.has("clue-3"); break;
        case 4: coreSolved = actionCount("crystal-4-") >= 3; break;
        case 5: coreSolved = actionCount("rope-5-") >= 3; break;
        case 6: coreSolved = actionCount("pillar-6-") >= 2; break;
        case 7: coreSolved = progress.actions.has("anchor-7"); break;
        case 8: coreSolved = progress.actions.has("crane-8"); break;
        case 9: coreSolved = actionCount("lock-9-") >= 4; break;
        case 19: coreSolved = progress.actions.has("core-19") && progress.actions.has("boss-19"); break;
        default: coreSolved = progress.actions.has(`core-${areaIndex}`);
      }
      return coreSolved
        && progress.actions.has(`puzzle-${areaIndex}-middle`)
        && progress.actions.has(`puzzle-${areaIndex}-top`);
    }

    function routePuzzleCount() {
      return Number(progress.actions.has(`puzzle-${areaIndex}-middle`))
        + Number(progress.actions.has(`puzzle-${areaIndex}-top`));
    }

    function objectiveText() {
      switch (areaIndex) {
        case 0: return `${areaLeavesCount()}/3 daun · jalur ${routePuzzleCount()}/2`;
        case 1: return `${actionCount("bark-1-")}/3 kulit terkupas`;
        case 2: return progress.actions.has("lever-2") ? "Arus berbalik · menuju atas" : "Temukan tuas aliran";
        case 3: return progress.clues.has("clue-3") ? "Tapak Joey ditemukan" : "Ikuti tapak berjelaga";
        case 4: return `${actionCount("crystal-4-")}/3 kristal menyala`;
        case 5: return `${actionCount("rope-5-")}/3 tali terpotong`;
        case 6: return `${actionCount("pillar-6-")}/2 pilar runtuh`;
        case 7: return progress.actions.has("anchor-7") ? "Jangkar badai terkunci" : "Bawa batu ke jangkar";
        case 8: return progress.actions.has("crane-8") ? "Tangga gelondongan siap" : "Aktifkan derek";
        case 9: return `${actionCount("lock-9-")}/4 pengunci · jalur ${routePuzzleCount()}/2`;
        case 19: return `${progress.actions.has("boss-19") ? "Boss kalah" : "Boss 6 hit"} · jalur ${routePuzzleCount()}/2`;
        default: return level.objective;
      }
    }

    function updateHUD() {
      const chapterIndex = player.y < 1450 ? 2 : player.y < 2900 ? 1 : 0;
      ui.updateHUD({
        level,
        areaIndex,
        chapter: level.chapters?.[chapterIndex],
        leaves: progress.leaves.size,
        clues: progress.clues.size,
        totalLeaves: TOTAL_LEAVES,
        totalClues: TOTAL_CLUES,
        hearts: progress.hearts,
        objective: objectiveText(),
        heavy: player.heavy,
        rescued: progress.rescued,
      });
    }

    function enterArea(nextIndex, direction = "forward") {
      areaIndex = clamp(nextIndex, 0, LEVELS.length - 1);
      level = cloneLevel(areaIndex);
      npcs = level.npcs.map((npc) => ({ ...npc, facing: 1, baseAnim: npc.anim, maxHealth: npc.health ?? 1, homeY: npc.y }));
      effects = [];
      projectiles = [];
      progress.hearts = 3;
      progress.abilities.add(UPGRADE_BY_AREA[areaIndex]);
      checkpointSection = direction === "back" ? 2 : 0;
      resetPlayer(player, direction === "back" ? { x: 620, y: 160 } : checkpointSpawn(checkpointSection));
      player.heavy = false;
      ui.updateBoss("", 0, 1);
      renderer.resetCamera(player.y);
      ui.toast(`${String(areaIndex + 1).padStart(2, "0")} · ${level.name}`);
      updateHUD();
      save();
    }

    function restartCheckpoint(message = "Kembali ke dahan aman") {
      progress.hearts = 3;
      resetPlayer(player, checkpointSpawn(checkpointSection));
      level.platforms.forEach((platform) => {
        if (platform.type === "crumble") platform.breakAt = null;
      });
      ui.toast(message);
      updateHUD();
    }

    function damage(type) {
      const now = performance.now();
      if (now < player.invulnerableUntil) return;
      player.invulnerableUntil = now + 1350;
      progress.hearts -= 1;
      player.vy = -430;
      player.vx = -player.facing * 260;
      animatePlayer("MIMA_CONDITIONS_SHEET", "hurt_recover", 520);
      flash = 0.38;
      shake = 12 * config.effectsIntensity;
      addEffect("HAZARD_EFFECTS_SHEET", "damage_burst", player.x, player.y - 20, 480, 100);
      audio.play("hit");
      haptic([32, 28, 42]);
      if (type === "fall" || type === "water" || progress.hearts <= 0) restartCheckpoint("Mima kembali ke dahan aman");
      updateHUD();
    }

    function collectNearby() {
      for (const leaf of level.leaves) {
        if (progress.leaves.has(leaf.id) || Math.hypot(player.x - leaf.x, player.y - leaf.y) > 52) continue;
        progress.leaves.add(leaf.id);
        addEffect("TRAIL_EFFECTS_SHEET", "pickup_burst", leaf.x, leaf.y, 470, 82);
        audio.play("leaf");
        haptic(18);
        ui.toast(`Golden Leaf ${progress.leaves.size}/30`, "gold");
        updateHUD();
        save();
      }
    }

    function nearestAction(scentActive) {
      const candidates = level.interactions.filter((object) => {
        if (progress.actions.has(object.id) && !["gate", "back", "shortcut", "pelican", "cage"].includes(object.type)) return false;
        return true;
      });
      if (!progress.clues.has(level.clue.id)) candidates.push({ ...level.clue, type: "clue", label: "Ambil jejak Joey" });
      if (!progress.carvings.has(level.carving.id) && scentActive) candidates.push({ ...level.carving, type: "carving", label: "Baca ukiran" });
      let best = null;
      let distance = Infinity;
      for (const candidate of candidates) {
        const value = distanceTo(player, candidate);
        if (value < distance) {
          best = candidate;
          distance = value;
        }
      }
      return distance <= 105 ? best : null;
    }

    function finishRescue() {
      if (progress.rescued) return;
      progress.rescued = true;
      progress.clues.add("clue-9");
      progress.actions.add("cage-9");
      const score = scoreFor(progress);
      progress.bestScore = Math.max(progress.bestScore, score);
      const joey = npcs.find((npc) => npc.type === "joey");
      if (joey) joey.anim = "freed_hop";
      const eagle = npcs.find((npc) => npc.type === "eagle");
      if (eagle) eagle.hidden = true;
      animatePlayer("MIMA_INTERACTIONS_SHEET", "rescue_hug", 1700);
      addEffect("IMPACT_EFFECTS_SHEET", "cage_unlock", 585, 245, 900, 145);
      flash = 0.75;
      audio.play("success");
      haptic([45, 35, 80]);
      updateHUD();
      save();
      void sdk.leaderboard.submit(score).catch(() => {});
      window.setTimeout(() => {
        if (!destroyed) ui.showVictory({ leaves: progress.leaves.size, clues: progress.clues.size, carvings: progress.carvings.size });
      }, 900);
    }

    function performAction(object) {
      if (!object) return;
      const complete = () => {
        progress.actions.add(object.id);
        audio.play("action");
        haptic(20);
        updateHUD();
        save();
      };

      switch (object.type) {
        case "back":
          enterArea(areaIndex - 1, "back");
          break;
        case "gate":
          if (areaIndex === 9 && !progress.rescued) ui.toast("Bebaskan Joey sebelum menuju frontier");
          else if (areaIndex < LEVELS.length - 1 && solved()) enterArea(areaIndex + 1, "forward");
          else ui.toast(`Belum selesai · ${objectiveText()}`);
          break;
        case "branch":
          animatePlayer("MIMA_TRAVERSAL_ONE_SHEET", "branch_launch", 520);
          player.vy = -1120;
          player.grounded = false;
          addEffect("FIRE_WIND_EFFECTS_SHEET", "storm_blast", player.x, player.y, 420, 88);
          audio.play("jump");
          complete();
          break;
        case "seed":
          animatePlayer("MIMA_INTERACTIONS_SHEET", "seed_plant", 680);
          level.platforms.push({ x: object.x - 68, y: object.y - 75, w: 155, h: 58, type: "normal", grown: true });
          ui.toast("Gumnut tumbuh menjadi pijakan");
          complete();
          break;
        case "bark":
          animatePlayer("MIMA_TREE_SHEET", "bark_peel", 650);
          addEffect("IMPACT_EFFECTS_SHEET", "bark_break", object.x, object.y, 520, 82);
          complete();
          break;
        case "pushBlock":
          animatePlayer("MIMA_INTERACTIONS_SHEET", "push_block", 720);
          ui.toast("Blok kayu menyumbat aliran getah");
          complete();
          break;
        case "shortcut":
          if (areaIndex === 1) enterArea(0, "back");
          break;
        case "weight":
          player.heavy = !player.heavy;
          if (player.heavy) progress.actions.add(object.id);
          ui.toast(player.heavy ? "Kantong berat · tahan angin" : "Kantong ringan · lompat lebih tinggi");
          audio.play("action");
          updateHUD();
          save();
          break;
        case "waterLever":
          animatePlayer("MIMA_INTERACTIONS_SHEET", "pull_lever", 650);
          ui.toast("Arus air berbalik");
          complete();
          break;
        case "pelican":
          if (progress.actions.has("peli-2")) enterArea(0, "back");
          else if (!progress.actions.has("lever-2")) ui.toast("Arus terlalu deras untuk membebaskan Peli");
          else {
            const peli = npcs.find((npc) => npc.type === "pelican");
            if (peli) peli.anim = "flap";
            ui.toast("Peli kini membuka jalur danau");
            complete();
          }
          break;
        case "vine":
          animatePlayer("MIMA_TRAVERSAL_TWO_SHEET", "vine_swing", 720);
          player.vx = player.facing * 520;
          player.vy = -780;
          player.grounded = false;
          audio.play("jump");
          complete();
          break;
        case "thermal":
          progress.abilities.add("glide");
          animatePlayer("MIMA_TRAVERSAL_ONE_SHEET", "leaf_glide", 600);
          complete();
          break;
        case "crystal": {
          animatePlayer("MIMA_ABILITIES_SHEET", "echo_bellow", 700);
          addEffect("CAVE_EFFECTS_SHEET", "echo_wave", player.x, player.y - 30, 650, 150);
          audio.play("echo");
          complete();
          const count = actionCount("crystal-4-");
          level.platforms.filter((platform) => platform.type === "ghost").forEach((platform) => { platform.active = count > 0; });
          break;
        }
        case "rope":
          addEffect("IMPACT_EFFECTS_SHEET", "bark_break", object.x, object.y, 500, 80);
          ui.toast("Kepompong jatuh menjadi pijakan");
          complete();
          break;
        case "scentBall": {
          animatePlayer("MIMA_ABILITIES_SHEET", "gumnut_throw", 580);
          const dingo = npcs.find((npc) => npc.type === "dingo");
          if (dingo) {
            dingo.anim = "sniff";
            dingo.distractedUntil = performance.now() + 5000;
          }
          complete();
          break;
        }
        case "windAnchor":
          if (!player.heavy) ui.toast("Kantong terlalu ringan untuk menahan pijakan");
          else {
            animatePlayer("MIMA_INTERACTIONS_SHEET", "pull_lever", 620);
            ui.toast("Jangkar badai terkunci");
            complete();
          }
          break;
        case "zipline":
          player.attachedZip = 1.25;
          progress.abilities.add("zipline");
          complete();
          break;
        case "crane":
          animatePlayer("MIMA_INTERACTIONS_SHEET", "pull_lever", 680);
          level.platforms.push({ x: 285, y: object.y - 395, w: 205, h: 58, type: "conveyor", vx: 35 });
          ui.toast("Gelondongan membentuk tangga");
          complete();
          break;
        case "frontierPuzzle":
        case "areaPuzzle": {
          const requirementMet = object.requirement === "heavy"
            ? player.heavy
            : !object.requirement || progress.abilities.has(object.requirement);
          if (!requirementMet) {
            ui.toast(object.requirement === "heavy" ? "Isi kantong dengan batu dahulu" : "Kemampuan ini belum siap");
            break;
          }
          const animationByKind = {
            branchChain: ["MIMA_TRAVERSAL_ONE_SHEET", "branch_pull"],
            seedCrown: ["MIMA_INTERACTIONS_SHEET", "seed_plant"],
            sapBlock: ["MIMA_INTERACTIONS_SHEET", "push_block"],
            shadowBell: ["MIMA_ABILITIES_SHEET", "scent_cast"],
            floodGate: ["MIMA_INTERACTIONS_SHEET", "pull_lever"],
            leafDock: ["MIMA_TRAVERSAL_TWO_SHEET", "leaf_row"],
            smokeDamper: ["MIMA_TREE_SHEET", "bark_peel"],
            thermalSpire: ["MIMA_TRAVERSAL_ONE_SHEET", "leaf_glide"],
            shroomChain: ["MIMA_ABILITIES_SHEET", "scent_cast"],
            prismEcho: ["MIMA_ABILITIES_SHEET", "echo_bellow"],
            waterFruit: ["MIMA_ABILITIES_SHEET", "gumnut_throw"],
            cocoonLift: ["MIMA_INTERACTIONS_SHEET", "pull_lever"],
            termiteSwitch: ["MIMA_ABILITIES_SHEET", "gumnut_throw"],
            spireBreak: ["MIMA_ABILITIES_SHEET", "body_slam"],
            stormShelter: ["MIMA_CONDITIONS_SHEET", "heavy_carry"],
            vineAnchor: ["MIMA_TRAVERSAL_TWO_SHEET", "vine_swing"],
            cableSwitch: ["MIMA_TRAVERSAL_TWO_SHEET", "zipline_crawl"],
            conveyorBrake: ["MIMA_INTERACTIONS_SHEET", "pull_lever"],
            rootSeal: ["MIMA_ABILITIES_SHEET", "body_slam"],
            eagleBell: ["MIMA_INTERACTIONS_SHEET", "pull_lever"],
            bambooGong: ["MIMA_ABILITIES_SHEET", "echo_bellow"],
            reedValve: ["MIMA_INTERACTIONS_SHEET", "pull_lever"],
            tideWheel: ["MIMA_INTERACTIONS_SHEET", "pull_lever"],
            logAnchor: ["MIMA_INTERACTIONS_SHEET", "pull_lever"],
            moonLantern: ["MIMA_ABILITIES_SHEET", "scent_cast"],
            bubbleReed: ["MIMA_ABILITIES_SHEET", "gumnut_throw"],
            gorgeWeight: ["MIMA_CONDITIONS_SHEET", "heavy_carry"],
            pebbleTarget: ["MIMA_ABILITIES_SHEET", "gumnut_throw"],
            honeyFork: ["MIMA_ABILITIES_SHEET", "scent_cast"],
            antBridge: ["MIMA_INTERACTIONS_SHEET", "pull_lever"],
            fernMirror: ["MIMA_ABILITIES_SHEET", "scent_cast"],
            echoTelescope: ["MIMA_ABILITIES_SHEET", "echo_bellow"],
            railSignal: ["MIMA_INTERACTIONS_SHEET", "pull_lever"],
            cableShield: ["MIMA_TRAVERSAL_TWO_SHEET", "zipline_crawl"],
            ironMagnet: ["MIMA_ABILITIES_SHEET", "gumnut_throw"],
            sawLock: ["MIMA_ABILITIES_SHEET", "body_slam"],
            flowerPrism: ["MIMA_ABILITIES_SHEET", "echo_bellow"],
            mothVane: ["MIMA_TRAVERSAL_TWO_SHEET", "vine_swing"],
            stormLauncher: ["MIMA_ABILITIES_SHEET", "gumnut_throw"],
            arenaSeal: ["MIMA_ABILITIES_SHEET", "body_slam"],
          };
          const [sheet, animation] = animationByKind[object.kind] ?? ["MIMA_INTERACTIONS_SHEET", "pull_lever"];
          animatePlayer(sheet, animation, 720);
          if (["prismEcho", "eagleBell"].includes(object.kind)) {
            addEffect("CAVE_EFFECTS_SHEET", "echo_wave", object.x, object.y, 650, 125);
            audio.play("echo");
          } else if (["spireBreak", "rootSeal"].includes(object.kind)) {
            addEffect("IMPACT_EFFECTS_SHEET", "mound_crumble", object.x, object.y, 620, 115);
            shake = 13 * config.effectsIntensity;
            audio.play("slam");
          } else {
            addEffect("TRAIL_EFFECTS_SHEET", "pickup_burst", object.x, object.y, 520, 78);
          }
          ui.toast(`${object.label} selesai`);
          complete();
          break;
        }
        case "lock":
          if (!progress.abilities.has(object.ability)) ui.toast("Kemampuan itu belum ditemukan");
          else {
            addEffect("IMPACT_EFFECTS_SHEET", "cage_unlock", object.x, object.y, 560, 86);
            complete();
          }
          break;
        case "cage":
          if (!solved()) ui.toast("Pengunci atau jalur Baobab masih belum selesai");
          else finishRescue();
          break;
        case "clue":
          progress.clues.add(object.id);
          addEffect("TRAIL_EFFECTS_SHEET", "fur_glint", object.x, object.y, 620, 90);
          audio.play("clue");
          haptic([18, 20, 28]);
          ui.toast(`Jejak Joey ${progress.clues.size}/10`, "clue");
          updateHUD();
          save();
          break;
        case "carving":
          progress.carvings.add(object.id);
          audio.play("clue");
          ui.toast(`Ukiran rahasia ${progress.carvings.size}/10`);
          updateHUD();
          save();
          break;
        default:
          break;
      }
    }

    function checkFrontierComplete() {
      if (areaIndex !== 19 || !solved() || progress.actions.has("frontier-complete")) return;
      progress.actions.add("frontier-complete");
      const score = scoreFor(progress) + 10000;
      progress.bestScore = Math.max(progress.bestScore, score);
      save();
      void sdk.leaderboard.submit(score).catch(() => {});
      ui.showFrontierVictory({ leaves: progress.leaves.size, clues: progress.clues.size, carvings: progress.carvings.size });
    }

    function updateProjectiles(dt, now) {
      const heroRect = { x: player.x - player.width / 2, y: player.y - player.height, w: player.width, h: player.height };
      for (const projectile of projectiles) {
        projectile.life -= dt;
        projectile.x += projectile.vx * dt;
        projectile.y += projectile.vy * dt;
        if (projectile.owner === "player") projectile.vy += 180 * dt;

        if (projectile.owner === "player") {
          for (const npc of npcs) {
            if (npc.hidden || npc.hitUntil > now) continue;
            const radius = npc.boss ? 78 : 48;
            if (Math.hypot(projectile.x - npc.x, projectile.y - (npc.y - radius * 0.55)) > radius) continue;
            projectile.life = 0;
            npc.health = (npc.health ?? 1) - 1;
            npc.hitUntil = now + 520;
            npc.anim = "hit";
            addEffect("HAZARD_EFFECTS_SHEET", "damage_burst", npc.x, npc.y - 20, 480, npc.boss ? 135 : 90);
            audio.play("hit");
            haptic(npc.boss ? 35 : 18);
            if (npc.health <= 0) {
              npc.hidden = true;
              if (npc.boss) {
                progress.actions.add("boss-19");
                ui.toast("Raja Kasuari mundur!", "gold");
                shake = 18 * config.effectsIntensity;
                save();
                updateHUD();
                checkFrontierComplete();
              }
            }
            break;
          }
        } else {
          const projectileRect = { x: projectile.x - 12, y: projectile.y - 12, w: 24, h: 24 };
          if (overlaps(heroRect, projectileRect)) {
            projectile.life = 0;
            damage(projectile.visual ?? "projectile");
          }
        }
      }
      projectiles = projectiles.filter((projectile) => projectile.life > 0 && projectile.x > -80 && projectile.x < 800 && projectile.y > -80 && projectile.y < WORLD.height + 80);
    }

    function updateNpcs(dt, now, hiding) {
      const ranged = {
        kookaburra: ["seed_throw", "seed"],
        toad: ["bubble_spit", "bubble"],
        goanna: ["pebble_throw", "pebble"],
        fernBat: ["sonic_cast", "sonic"],
        magpie: ["seed_drop", "seed"],
        drone: ["blade_shot", "gear"],
        moth: ["wind_cast", "wind"],
      };
      const sizes = {
        owl: [85, 75], dingo: [92, 62], eagle: [145, 95], spider: [85, 55],
        kookaburra: [92, 70], crocodile: [120, 54], toad: [82, 62], goanna: [112, 48],
        antSentinel: [86, 62], fernBat: [88, 70], magpie: [92, 72], drone: [88, 70],
        moth: [100, 82], cassowary: [155, 145],
      };
      for (const npc of npcs) {
        if (npc.hidden) continue;
        if (npc.hitUntil > now) {
          npc.anim = "hit";
          continue;
        }
        if (npc.attackUntil && now > npc.attackUntil) npc.anim = npc.baseAnim;

        if (npc.minX !== undefined && npc.maxX !== undefined) {
          if (npc.distractedUntil && now < npc.distractedUntil) {
            npc.anim = "sniff";
          } else {
            npc.x += (npc.facing ?? 1) * npc.speed * dt;
            if (npc.x > npc.maxX) npc.facing = -1;
            if (npc.x < npc.minX) npc.facing = 1;
            if (npc.type === "dingo") npc.anim = "patrol";
          }
        }
        if (npc.flying) npc.y = npc.homeY + Math.sin(now * 0.0025 + npc.homeY) * 36;

        if (npc.type === "eagle") {
          const phase = now % 4300;
          if (phase > 2850 && phase < 3450) {
            npc.anim = "claw_telegraph";
          } else if (phase >= 3450) {
            npc.anim = "dive";
            npc.x += (player.x - npc.x) * dt * 2.8;
            npc.y += (player.y - 110 - npc.y) * dt * 2.4;
          } else {
            npc.anim = "circle";
            npc.y = 420 + Math.sin(now * 0.002) * 60;
          }
        }

        if (npc.type === "cassowary") {
          if (player.y < 1450) {
            const phase = now % 3600;
            if (phase > 2650) {
              npc.anim = "kick";
              npc.attackUntil = now + 180;
            } else if (phase > 900) {
              npc.anim = "run";
              npc.speed = 185;
            } else {
              npc.anim = "idle";
              npc.speed = 90;
            }
          } else {
            npc.anim = "idle";
            npc.speed = 0;
          }
        }

        const rangedAttack = ranged[npc.type];
        if (rangedAttack && (!npc.nextAttack || now > npc.nextAttack) && Math.abs(player.y - npc.y) < 520) {
          npc.nextAttack = now + 1900 + Math.random() * 900;
          npc.attackUntil = now + 520;
          npc.anim = rangedAttack[0];
          const direction = player.x < npc.x ? -1 : 1;
          npc.facing = direction;
          projectiles.push({
            owner: "enemy",
            x: npc.x + direction * 30,
            y: npc.y - 42,
            vx: direction * (npc.type === "magpie" ? 120 : 290),
            vy: npc.type === "magpie" ? 210 : (player.y - npc.y) * 0.22,
            life: 2.4,
            visual: rangedAttack[1],
          });
        }
        if (["crocodile", "antSentinel"].includes(npc.type) && Math.abs(player.x - npc.x) < 135 && Math.abs(player.y - npc.y) < 90) {
          npc.anim = npc.type === "crocodile" ? "lunge" : "bite";
          npc.attackUntil = now + 430;
        }

        const size = sizes[npc.type];
        if (!size || hiding || (npc.distractedUntil && now < npc.distractedUntil)) continue;
        const enemyRect = { x: npc.x - size[0] / 2, y: npc.y - size[1], w: size[0], h: size[1] };
        const heroRect = { x: player.x - player.width / 2, y: player.y - player.height, w: player.width, h: player.height };
        if (overlaps(heroRect, enemyRect)) damage(npc.type);
      }
    }

    function isHiding(frameInput) {
      if (frameInput.y < 0.45) return false;
      const hero = { x: player.x - player.width / 2, y: player.y - player.height, w: player.width, h: player.height };
      return level.zones.some((zone) => zone.type === "shadow" && overlaps(hero, zone));
    }

    function frame(time) {
      if (destroyed) return;
      const dt = clamp((time - lastTime) / 1000, 0, 0.033);
      lastTime = time;
      const scentActive = time < scentUntil;

      if (!paused && running) {
        const frameInput = {
          x: input.state.x,
          y: input.state.y,
          jumpHeld: input.state.jumpHeld,
          jumpPressed: input.consume("jumpPressed"),
        };
        if (input.consume("scentPressed")) {
          scentUntil = scentActive ? 0 : time + config.scentSeconds * 1000;
          animatePlayer("MIMA_ABILITIES_SHEET", "scent_cast", 480);
          audio.play("action");
        }

        const hiding = isHiding(frameInput);
        if (hiding) {
          player.animOverride = { key: "MIMA_CONDITIONS_SHEET", name: "shadow_hide" };
          player.animOverrideUntil = time + 90;
        }

        updatePlayer({
          player,
          level,
          input: frameInput,
          dt,
          now: time,
          config,
          abilities: progress.abilities,
          onLand(kind) {
            if (kind === "web") {
              addEffect("WATER_WEB_EFFECTS_SHEET", "web_rebound", player.x, player.y, 520, 100);
              audio.play("jump");
              haptic(24);
            }
          },
          onBreak(platform) {
            progress.actions.add(platform.id);
            addEffect("IMPACT_EFFECTS_SHEET", "mound_crumble", player.x, platform.y, 650, 120);
            shake = 16 * config.effectsIntensity;
            audio.play("slam");
            haptic([42, 25, 45]);
            ui.toast(`${actionCount("pillar-6-")}/2 pilar runtuh`);
            updateHUD();
            save();
          },
          onDamage: damage,
        });

        for (const platform of level.platforms) {
          if (platform.type === "crumble" && platform.breakAt && time > platform.breakAt + 2200) platform.breakAt = null;
        }

        const reachedSection = player.y < 1450 ? 2 : player.y < 2900 ? 1 : 0;
        if (reachedSection > checkpointSection) {
          checkpointSection = reachedSection;
          ui.toast(`Dahan aman · ${level.chapters[checkpointSection]}`);
          addEffect("TRAIL_EFFECTS_SHEET", "leaf_shimmer", 92, checkpointSpawn(checkpointSection).y, 620, 88);
          haptic(18);
          updateHUD();
          save();
        }

        collectNearby();
        nearest = nearestAction(time < scentUntil);
        ui.setPrompt(nearest?.label ?? "");
        if (input.consume("actionPressed")) {
          if (nearest) performAction(nearest);
          else throwGumnut();
        }
        updateNpcs(dt, time, hiding);
        updateProjectiles(dt, time);
        checkFrontierComplete();
        const boss = npcs.find((npc) => npc.boss && !npc.hidden);
        ui.updateBoss(areaIndex === 19 && player.y < 1450 && boss ? "Raja Kasuari" : "", boss?.health ?? 0, boss?.maxHealth ?? 1);
        effects = effects.filter((effect) => time - effect.startedAt < effect.duration);
        flash = Math.max(0, flash - dt * 1.8);
        shake = Math.max(0, shake - dt * 42);
        ui.setScent(time < scentUntil);
      }

      renderer.render({
        level,
        player,
        progress,
        npcs,
        effects,
        projectiles,
        now: time,
        dt,
        scentActive: time < scentUntil,
        flash,
        shake,
        skin,
      });
      frameId = requestAnimationFrame(frame);
    }

    function togglePause(force) {
      paused = force ?? !paused;
      if (paused) {
        ui.showPause(`${progress.leaves.size}/${TOTAL_LEAVES} daun · ${progress.clues.size}/${TOTAL_CLUES} jejak`);
      } else {
        ui.hidePause();
        lastTime = performance.now();
      }
    }

    listen(ui.buttons.pause, "click", () => togglePause(true));
    listen(ui.buttons.skin, "click", () => {
      paused = true;
      ui.renderSkins(SKINS, skinIndex);
      ui.showSkinMenu();
    });
    listen(ui.buttons.closeSkin, "click", () => {
      ui.hideSkinMenu();
      paused = false;
      initialSkinSelection = false;
      lastTime = performance.now();
      ui.toast("Keyboard: ← → bergerak · Space melompat · E aksi/lempar");
    });
    function loadSkinAssetsProgressively(keys) {
      return new Promise((resolve, reject) => {
        const load = async (index) => {
          if (index >= keys.length) {
            resolve();
            return;
          }
          const key = keys[index];
          try {
            await store.load(key);
            await new Promise(resolve => setTimeout(resolve, 50));
            if ("requestIdleCallback" in window) {
              requestIdleCallback(() => load(index + 1), { timeout: 100 });
            } else {
              setTimeout(() => load(index + 1), 100);
            }
          } catch (error) {
            reject(error);
          }
        };
        load(0);
      });
    }

    listen(ui.skinGrid, "click", async (event) => {
      const button = event.target.closest(".skin-choice");
      if (!button) return;
      const nextIndex = clamp(Number(button.dataset.skinIndex) || 0, 0, SKINS.length - 1);
      const nextSkin = SKINS[nextIndex];
      ui.setSkinStatus(`Memuat paket ${nextSkin.name}…`);
      try {
        cancelAnimationFrame(frameId);
        await loadSkinAssetsProgressively(skinKeys(nextSkin));
        skinIndex = nextIndex;
        skin = nextSkin;
        ui.renderSkins(SKINS, skinIndex);
        ui.setSkinStatus(`${skin.name} aktif · seluruh sheet diganti`);
        audio.play("success");
        haptic(22);
        save();
        lastTime = performance.now();
        frameId = requestAnimationFrame(frame);
        if (initialSkinSelection) {
          initialSkinSelection = false;
          ui.hideSkinMenu();
          paused = false;
          ui.toast("Keyboard: ← → bergerak · Space melompat · E aksi/lempar");
        }
      } catch {
        ui.setSkinStatus("Paket skin belum berhasil dimuat. Pilih lagi.");
        lastTime = performance.now();
        frameId = requestAnimationFrame(frame);
      }
    });
    listen(ui.buttons.resume, "click", () => togglePause(false));
    listen(ui.buttons.restartArea, "click", () => {
      restartCheckpoint();
      togglePause(false);
    });
    listen(ui.buttons.explore, "click", () => {
      ui.hideVictory();
      enterArea(progress.rescued ? 10 : 0, "forward");
    });
    listen(window, "keydown", (event) => {
      if (event.key === "Escape") togglePause();
    });

    updateHUD();
    paused = true;
    ui.setSkinStatus("Pilih satu skin untuk memulai petualangan.");
    ui.showSkinMenu();
    frameId = requestAnimationFrame(frame);

    teardown = () => {
      destroyed = true;
      running = false;
      cancelAnimationFrame(frameId);
      listeners.splice(0).forEach((remove) => remove());
      unsubscribes.splice(0).forEach((unsubscribe) => unsubscribe());
      input?.destroy();
      renderer?.destroy();
      void audio?.destroy();
      ui.destroy();
    };
  }

  return {
    start() {
      void boot();
    },
    destroy() {
      teardown();
      teardown = () => {};
    },
  };
}
