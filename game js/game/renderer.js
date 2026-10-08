import { WORLD } from "./levels.js";
import { skinAssetKey } from "./skins.js";

const clamp = (value, min, max) => Math.max(min, Math.min(max, value));

function drawFrameInCell(ctx, pack, frameName, x, y, w, h, alpha = 1) {
  const frame = pack?.byName.get(frameName);
  if (!pack?.image || !frame) return false;
  const crop = frame.content ?? frame.source;
  if (!crop || frame.empty) return false;
  const scale = Math.min(w / crop.w, h / crop.h);
  const drawW = crop.w * scale;
  const drawH = crop.h * scale;
  ctx.save();
  ctx.globalAlpha *= alpha;
  ctx.drawImage(
    pack.image,
    crop.x,
    crop.y,
    crop.w,
    crop.h,
    x + (w - drawW) / 2,
    y + (h - drawH) / 2,
    drawW,
    drawH,
  );
  ctx.restore();
  return true;
}

function drawAnimation(ctx, pack, animationName, frameIndex, x, y, targetHeight, facing = 1, alpha = 1) {
  const animation = pack?.animations.get(animationName);
  if (!pack?.image || !animation) return false;
  const frame = animation.frames[frameIndex % animation.frames.length];
  const crop = frame.content ?? frame.source;
  if (!crop) return false;
  const scale = targetHeight / animation.maxContentHeight;
  const anchor = frame.anchor ?? {
    x: frame.source.x + frame.source.w / 2,
    y: frame.source.y + frame.source.h,
  };
  ctx.save();
  ctx.globalAlpha *= alpha;
  ctx.translate(x, y);
  ctx.scale(facing, 1);
  ctx.drawImage(
    pack.image,
    crop.x,
    crop.y,
    crop.w,
    crop.h,
    -(anchor.x - crop.x) * scale,
    -(anchor.y - crop.y) * scale,
    crop.w * scale,
    crop.h * scale,
  );
  ctx.restore();
  return true;
}

function animationFrame(time, speed = 9) {
  return Math.floor(time * speed) % 5;
}

function selectPlayerAnimation(player, now, skin) {
  const use = (key, name) => ({ key: skinAssetKey(skin, key), name });
  if (player.animOverride && now < player.animOverrideUntil) return { ...player.animOverride, key: skinAssetKey(skin, player.animOverride.key) };
  if (player.attachedZip > 0) return use("MIMA_TRAVERSAL_TWO_SHEET", "zipline_crawl");
  if (now < player.bouncingUntil) return use("MIMA_TRAVERSAL_TWO_SHEET", "web_bounce");
  if (now < player.rowingUntil) return use("MIMA_TRAVERSAL_TWO_SHEET", "leaf_row");
  if (now < player.slidingUntil) return use("MIMA_TRAVERSAL_ONE_SHEET", "bark_slide");
  if (now < player.stickyUntil) return use("MIMA_CONDITIONS_SHEET", "sap_struggle");
  if (player.circling) return use("MIMA_TREE_SHEET", "circle_trunk");
  if (player.climbing) return use("MIMA_TREE_SHEET", "climb");
  if (player.bodySlamming) return use("MIMA_ABILITIES_SHEET", "body_slam");
  if (player.gliding) return use("MIMA_TRAVERSAL_ONE_SHEET", "leaf_glide");
  if (!player.grounded) {
    if (player.vy < -90) return use("MIMA_AIR_SHEET", "jump_rise");
    if (player.vy > 110) return use("MIMA_AIR_SHEET", "fall");
    return use("MIMA_AIR_SHEET", "apex");
  }
  if (player.heavy) return use("MIMA_CONDITIONS_SHEET", "heavy_carry");
  if (Math.abs(player.vx) > 210) return use("MIMA_BASIC_SHEET", "run");
  if (Math.abs(player.vx) > 20) return use("MIMA_BASIC_SHEET", "walk");
  return use("MIMA_BASIC_SHEET", "idle");
}

export function createRenderer(canvas, store) {
  const ctx = canvas.getContext("2d", { alpha: false });
  let width = 1;
  let height = 1;
  let cameraY = 0;
  let shakeX = 0;
  let shakeY = 0;

  function resize() {
    const rect = canvas.getBoundingClientRect();
    if (!rect.width || !rect.height) return;
    const dpr = Math.min(window.devicePixelRatio || 1, 2);
    canvas.width = Math.round(rect.width * dpr);
    canvas.height = Math.round(rect.height * dpr);
    ctx.setTransform(dpr, 0, 0, dpr, 0, 0);
    width = rect.width;
    height = rect.height;
  }

  const observer = new ResizeObserver(resize);
  observer.observe(canvas);
  resize();

  function drawBackground(level, scentActive) {
    const pack = store.get(level.bg);
    const image = pack?.image;
    ctx.fillStyle = level.palette[0];
    ctx.fillRect(0, 0, width, height);
    if (image) {
      const scale = Math.max(width / image.width, height / image.height);
      const drawW = image.width * scale;
      const drawH = image.height * scale;
      ctx.drawImage(image, (width - drawW) / 2, (height - drawH) / 2, drawW, drawH);
    }
    ctx.fillStyle = scentActive ? "rgba(16, 29, 42, .58)" : "rgba(26, 28, 22, .08)";
    ctx.fillRect(0, 0, width, height);
  }

  function drawPlatform(level, platform, now) {
    if (platform.broken || (platform.breakAt && now > platform.breakAt)) return;
    if (platform.type === "ghost" && !platform.active) return;
    if (platform.type === "web") {
      const pack = store.get("ZONE_TWO_OBJECTS");
      drawFrameInCell(ctx, pack, "web_pad", platform.x, platform.y - 48, platform.w, 78);
      return;
    }
    if (platform.type === "raft") {
      drawFrameInCell(ctx, store.get("ZONE_ONE_OBJECTS"), "leaf_raft", platform.x, platform.y - 45, platform.w, 74);
      return;
    }
    if (platform.type === "ghost") {
      drawFrameInCell(ctx, store.get("ZONE_TWO_OBJECTS"), "ghost_root", platform.x, platform.y - 55, platform.w, 90, 0.82);
      return;
    }
    const pack = store.get(level.platform);
    const frame = pack?.byName.get("center");
    if (pack?.image && frame?.content) {
      const crop = frame.content;
      const surfaceY = frame.surfaceY ?? crop.y;
      const drawH = platform.type === "ground" ? 105 : 76;
      const scaleY = drawH / crop.h;
      const drawY = platform.y - (surfaceY - crop.y) * scaleY;
      ctx.save();
      if (platform.breakAt) ctx.globalAlpha = 0.55 + Math.sin(now * 0.04) * 0.3;
      ctx.drawImage(pack.image, crop.x, crop.y, crop.w, crop.h, platform.x, drawY, platform.w, drawH);
      ctx.restore();
    } else {
      ctx.fillStyle = level.palette[2];
      ctx.beginPath();
      ctx.roundRect(platform.x, platform.y - 8, platform.w, 44, 20);
      ctx.fill();
    }
    if (platform.type === "cracked") {
      drawFrameInCell(ctx, store.get("ZONE_THREE_OBJECTS"), "cracked_mound", platform.x + platform.w / 2 - 36, platform.y - 50, 72, 72);
    }
    if (platform.type === "conveyor") {
      ctx.strokeStyle = "rgba(203, 224, 217, .8)";
      ctx.lineWidth = 5;
      for (let x = platform.x + ((now * 0.08) % 34); x < platform.x + platform.w; x += 34) {
        ctx.beginPath();
        ctx.moveTo(x, platform.y + 7);
        ctx.lineTo(x + 16, platform.y + 7);
        ctx.stroke();
      }
    }
  }

  function drawZones(level, now) {
    for (const climb of level.climbables) {
      const climbPack = store.get(level.climbAsset ?? "CLIMB_EUCALYPTUS_TILES");
      const body = climbPack?.byName.get("body");
      if (climbPack?.image && body?.content) {
        const crop = body.content;
        const drawWidth = climb.w * 1.42;
        ctx.drawImage(
          climbPack.image,
          crop.x,
          crop.y,
          crop.w,
          crop.h,
          climb.x + (climb.w - drawWidth) / 2,
          climb.y,
          drawWidth,
          climb.h,
        );
      } else {
        const gradient = ctx.createLinearGradient(climb.x, 0, climb.x + climb.w, 0);
        gradient.addColorStop(0, "rgba(92, 66, 45, .18)");
        gradient.addColorStop(0.5, "rgba(221, 190, 131, .75)");
        gradient.addColorStop(1, "rgba(92, 66, 45, .2)");
        ctx.fillStyle = gradient;
        ctx.fillRect(climb.x, climb.y, climb.w, climb.h);
      }
    }
    for (const zone of level.zones) {
      if (zone.type === "shadow") {
        ctx.fillStyle = "rgba(21, 25, 36, .46)";
        ctx.fillRect(zone.x, zone.y, zone.w, zone.h);
      }
      if (zone.type === "updraft") {
        ctx.strokeStyle = "rgba(244, 184, 102, .55)";
        ctx.lineWidth = 5;
        for (let y = zone.y + ((now * 0.09) % 90); y < zone.y + zone.h; y += 90) {
          ctx.beginPath();
          ctx.arc(zone.x + zone.w / 2, y, 35, 0.2, 2.7);
          ctx.stroke();
        }
      }
      if (zone.type === "wind" && Math.sin(now * 0.003) > -0.35) {
        ctx.strokeStyle = "rgba(226, 240, 239, .5)";
        ctx.lineWidth = 4;
        for (let y = zone.y + 60; y < zone.y + zone.h; y += 115) {
          const offset = (now * 0.25 + y) % 180;
          ctx.beginPath();
          ctx.moveTo(zone.x + zone.w - offset, y);
          ctx.lineTo(zone.x + zone.w - offset - 100, y + 12);
          ctx.stroke();
        }
      }
      if (zone.type === "zipline") {
        ctx.strokeStyle = "#4d5355";
        ctx.lineWidth = 6;
        ctx.beginPath();
        ctx.moveTo(zone.x, zone.y + 16);
        ctx.lineTo(zone.x + zone.w, zone.y - 90);
        ctx.stroke();
      }
    }
  }

  function drawHazard(hazard, now) {
    const bob = Math.sin(now * 0.008) * 3;
    if (hazard.type === "fire") {
      drawFrameInCell(ctx, store.get("ZONE_TWO_OBJECTS"), "ember_pit", hazard.x, hazard.y - 40 + bob, hazard.w, hazard.h + 45);
    } else if (hazard.type === "sap") {
      drawFrameInCell(ctx, store.get("ZONE_TWO_OBJECTS"), "sticky_sap", hazard.x, hazard.y - 24, hazard.w, hazard.h + 36);
    } else if (hazard.type === "saw") {
      ctx.save();
      ctx.translate(hazard.x + hazard.w / 2, hazard.y + hazard.h / 2);
      ctx.rotate(now * 0.006);
      drawFrameInCell(ctx, store.get("ZONE_THREE_OBJECTS"), "saw_blade", -hazard.w / 2, -hazard.h / 2, hazard.w, hazard.h);
      ctx.restore();
    } else if (hazard.type === "water") {
      const gradient = ctx.createLinearGradient(0, hazard.y, 0, hazard.y + hazard.h);
      gradient.addColorStop(0, "rgba(140, 220, 221, .78)");
      gradient.addColorStop(1, "rgba(38, 101, 119, .78)");
      ctx.fillStyle = gradient;
      ctx.fillRect(hazard.x, hazard.y, hazard.w, hazard.h);
    }
  }

  function drawObject(object, alpha = 1, size = 82) {
    return drawFrameInCell(ctx, store.get(object.atlas), object.frame, object.x - size / 2, object.y - size, size, size, alpha);
  }

  function renderWorld(state) {
    const { level, player, progress, now, scentActive } = state;
    drawZones(level, now);
    level.platforms.forEach((platform) => drawPlatform(level, platform, now));
    level.hazards.forEach((hazard) => drawHazard(hazard, now));

    for (const offset of [0, 1450, 2900]) {
      drawFrameInCell(ctx, store.get("FINAL_OBJECTS"), "checkpoint_blossom", 55, 1285 + offset, 76, 88, 0.9);
    }

    for (const leaf of level.leaves) {
      if (progress.leaves.has(leaf.id)) continue;
      const y = leaf.y + Math.sin(now * 0.004 + leaf.x) * 9;
      drawFrameInCell(ctx, store.get("ZONE_ONE_OBJECTS"), "golden_leaf", leaf.x - 30, y - 52, 60, 60);
    }

    if (!progress.clues.has(level.clue.id)) {
      const glow = scentActive ? 1 : 0.75;
      drawObject({ ...level.clue, y: level.clue.y + Math.sin(now * 0.005) * 5 }, glow, 74);
    }

    if (!progress.carvings.has(level.carving.id) && scentActive) {
      drawObject(level.carving, 0.95, 76);
    }

    for (const object of level.interactions) {
      const completed = progress.actions.has(object.id);
      if (completed && !["gate", "back", "shortcut", "pelican", "cage"].includes(object.type)) continue;
      const alpha = completed ? 0.42 : 1;
      const size = object.type === "gate" ? 112 : object.type === "cage" ? 126 : 84;
      drawObject(object, alpha, size);
      if (scentActive && !completed && !["back", "gate"].includes(object.type)) {
        ctx.strokeStyle = "rgba(91, 235, 216, .86)";
        ctx.lineWidth = 5;
        ctx.beginPath();
        ctx.arc(object.x, object.y - size * 0.45, 28 + Math.sin(now * 0.008) * 6, 0, Math.PI * 2);
        ctx.stroke();
      }
    }

    for (const npc of state.npcs) {
      if (npc.hidden) continue;
      const pack = store.get(npc.sheet);
      const facing = npc.facing ?? 1;
      const sizes = {
        eagle: 150, joey: 70, termite: 64, crocodile: 82, toad: 84,
        goanna: 74, antSentinel: 84, fernBat: 86, magpie: 92,
        kookaburra: 92, drone: 86, moth: 100, cassowary: 178,
      };
      const size = sizes[npc.type] ?? 92;
      drawAnimation(ctx, pack, npc.anim, animationFrame(now / 1000, npc.type === "eagle" ? 7 : 9), npc.x, npc.y, size, facing, npc.alpha ?? 1);
    }

    for (const effect of state.effects) {
      const age = now - effect.startedAt;
      const fraction = clamp(age / effect.duration, 0, 0.999);
      const frameIndex = Math.floor(fraction * 5);
      drawAnimation(ctx, store.get(effect.key), effect.anim, frameIndex, effect.x, effect.y, effect.size ?? 90, effect.facing ?? 1, 1 - fraction * 0.2);
    }

    for (const projectile of state.projectiles ?? []) {
      ctx.save();
      ctx.translate(projectile.x, projectile.y);
      ctx.rotate(now * 0.012 * (projectile.vx < 0 ? -1 : 1));
      if (projectile.visual === "gear") {
        drawFrameInCell(ctx, store.get("ZONE_THREE_OBJECTS"), "saw_blade", -18, -18, 36, 36);
      } else if (projectile.visual === "pebble") {
        drawFrameInCell(ctx, store.get("ZONE_THREE_OBJECTS"), "stone_weight", -14, -14, 28, 28);
      } else if (projectile.visual === "bubble") {
        drawFrameInCell(ctx, store.get("ZONE_TWO_OBJECTS"), "water_fruit", -16, -16, 32, 32, 0.85);
      } else if (projectile.visual === "sonic" || projectile.visual === "wind") {
        drawFrameInCell(ctx, store.get("UI_ICON_ATLAS"), "echo_ring", -19, -19, 38, 38, 0.9);
      } else {
        drawFrameInCell(ctx, store.get("ZONE_ONE_OBJECTS"), "gumnut", -15, -15, 30, 30);
      }
      ctx.restore();
    }

    if (scentActive) {
      const destination = progress.clues.has(level.clue.id)
        ? level.interactions.find((item) => item.type === "gate")
        : level.clue;
      if (destination) {
        ctx.strokeStyle = "rgba(71, 231, 210, .8)";
        ctx.lineWidth = 7;
        ctx.setLineDash([13, 18]);
        ctx.lineDashOffset = -now * 0.035;
        ctx.beginPath();
        ctx.moveTo(player.x, player.y - 35);
        ctx.quadraticCurveTo((player.x + destination.x) / 2, Math.min(player.y, destination.y) - 70, destination.x, destination.y - 45);
        ctx.stroke();
        ctx.setLineDash([]);
      }
    }

    const animation = selectPlayerAnimation(player, now, state.skin);
    const rendered = drawAnimation(
      ctx,
      store.get(animation.key),
      animation.name,
      animationFrame(now / 1000, animation.name === "idle" ? 5 : 10),
      player.x,
      player.y,
      92,
      player.facing,
      now < player.invulnerableUntil && Math.floor(now / 80) % 2 ? 0.35 : 1,
    );
    if (!rendered) {
      ctx.fillStyle = "#817d72";
      ctx.beginPath();
      ctx.ellipse(player.x, player.y - 38, 26, 38, 0, 0, Math.PI * 2);
      ctx.fill();
    }
  }

  return {
    resize,
    render(state) {
      const scale = width / WORLD.width;
      const viewportHeight = height / scale;
      const maxCamera = Math.max(0, WORLD.height - viewportHeight);
      const target = clamp(state.player.y - viewportHeight * 0.56, 0, maxCamera);
      cameraY += (target - cameraY) * Math.min(1, state.dt * 7.5);
      const shake = state.shake ?? 0;
      shakeX = (Math.random() - 0.5) * shake;
      shakeY = (Math.random() - 0.5) * shake;

      ctx.save();
      ctx.translate(shakeX, shakeY);
      drawBackground(state.level, state.scentActive);
      ctx.scale(scale, scale);
      ctx.translate(0, -cameraY);
      renderWorld(state);
      ctx.restore();

      if (state.flash > 0) {
        ctx.fillStyle = `rgba(255, 238, 190, ${state.flash})`;
        ctx.fillRect(0, 0, width, height);
      }
    },
    resetCamera(playerY = WORLD.height) {
      const scale = width / WORLD.width;
      cameraY = clamp(playerY - height / scale * 0.56, 0, Math.max(0, WORLD.height - height / scale));
    },
    destroy() {
      observer.disconnect();
    },
  };
}
