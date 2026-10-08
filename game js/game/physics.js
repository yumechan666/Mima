import { WORLD } from "./levels.js";

const clamp = (value, min, max) => Math.max(min, Math.min(max, value));

export function createPlayer(start) {
  return {
    x: start.x,
    y: start.y,
    vx: 0,
    vy: 0,
    width: 46,
    height: 76,
    facing: 1,
    grounded: false,
    climbing: false,
    circling: false,
    gliding: false,
    bodySlamming: false,
    attachedZip: 0,
    heavy: false,
    stickyUntil: 0,
    slidingUntil: 0,
    rowingUntil: 0,
    bouncingUntil: 0,
    invulnerableUntil: 0,
    animOverride: null,
    animOverrideUntil: 0,
  };
}

export function resetPlayer(player, start) {
  Object.assign(player, {
    x: start.x,
    y: start.y,
    vx: 0,
    vy: 0,
    grounded: false,
    climbing: false,
    circling: false,
    gliding: false,
    bodySlamming: false,
    attachedZip: 0,
    stickyUntil: 0,
    slidingUntil: 0,
    rowingUntil: 0,
    bouncingUntil: 0,
  });
}

function playerRect(player) {
  return {
    x: player.x - player.width / 2,
    y: player.y - player.height,
    w: player.width,
    h: player.height,
  };
}

export function overlaps(a, b) {
  return a.x < b.x + b.w && a.x + a.w > b.x && a.y < b.y + b.h && a.y + a.h > b.y;
}

export function distanceTo(player, object) {
  return Math.hypot(player.x - object.x, player.y - object.y);
}

export function updatePlayer({
  player,
  level,
  input,
  dt,
  now,
  config,
  abilities,
  onLand = () => {},
  onBreak = () => {},
  onDamage = () => {},
}) {
  const wasGrounded = player.grounded;
  const previousY = player.y;
  const sticky = now < player.stickyUntil;
  const moveScale = (player.heavy ? 0.72 : 1) * (sticky ? 0.34 : 1);

  if (player.attachedZip > 0) {
    player.attachedZip -= dt;
    player.vx = 420;
    player.vy = -115;
  } else {
    const targetVx = input.x * config.playerSpeed * moveScale;
    player.vx += (targetVx - player.vx) * Math.min(1, dt * 13);
  }

  if (Math.abs(input.x) > 0.1) player.facing = input.x < 0 ? -1 : 1;

  const climbable = level.climbables.find((zone) =>
    overlaps(playerRect(player), { x: zone.x, y: zone.y, w: zone.w, h: zone.h }),
  );
  player.climbing = Boolean(climbable && Math.abs(input.y) > 0.12 && player.attachedZip <= 0);
  player.circling = Boolean(climbable && Math.abs(input.x) > 0.4 && Math.abs(input.y) <= 0.4);

  if (player.climbing || player.circling) {
    player.vy = player.circling ? 0 : input.y * config.playerSpeed * 0.72;
    player.x += (climbable.x + climbable.w / 2 - player.x) * Math.min(1, dt * 8);
  } else if (input.jumpPressed && input.y > 0.45 && !player.grounded && abilities.has("slam")) {
    player.bodySlamming = true;
    player.gliding = false;
    player.vy = Math.max(980, player.vy);
  } else {
    if (input.jumpPressed && player.grounded) {
      player.vy = -config.jumpForce * (player.heavy ? 0.72 : 1);
      player.grounded = false;
    }
    player.gliding = Boolean(input.jumpHeld && abilities.has("glide") && player.vy > 30 && !player.bodySlamming);
    player.vy += config.gravity * (player.gliding ? 0.28 : 1) * dt;
  }

  for (const zone of level.zones) {
    if (!overlaps(playerRect(player), zone)) continue;
    if (zone.type === "updraft" && input.jumpHeld && abilities.has("glide") && !player.heavy) {
      player.vy -= 1280 * dt;
      player.gliding = true;
    }
    if (zone.type === "wind" && !player.heavy && Math.sin(now * 0.003) > -0.35) {
      player.vx += zone.force * dt;
    }
  }

  player.x += player.vx * dt;
  player.y += player.vy * dt;
  player.x = clamp(player.x, player.width / 2, WORLD.width - player.width / 2);
  player.grounded = false;

  const activePlatforms = level.platforms.filter((platform) => {
    if (platform.type === "ghost" && !platform.active) return false;
    if (platform.broken) return false;
    if (platform.breakAt && now > platform.breakAt) return false;
    return true;
  });

  if (player.vy >= 0 && !player.climbing) {
    for (const platform of activePlatforms) {
      const insideX = player.x + player.width * 0.34 > platform.x && player.x - player.width * 0.34 < platform.x + platform.w;
      if (!insideX || previousY > platform.y + 10 || player.y < platform.y) continue;

      if (platform.type === "cracked" && player.bodySlamming) {
        platform.broken = true;
        onBreak(platform);
        continue;
      }

      player.y = platform.y;
      player.vy = 0;
      player.grounded = true;
      if (platform.type === "web") {
        player.vy = -1080;
        player.grounded = false;
        player.bouncingUntil = now + 520;
        onLand("web", platform);
      } else {
        if (!wasGrounded) onLand("normal", platform);
        if (platform.type === "slippery") {
          player.vx += player.facing * 135;
          player.slidingUntil = now + 320;
        }
        if (platform.type === "raft") player.rowingUntil = now + 260;
        if (platform.type === "conveyor") player.x += platform.vx * dt;
        if (platform.type === "crumble" && !platform.breakAt) platform.breakAt = now + 920;
      }
      player.bodySlamming = false;
      break;
    }
  }

  for (const hazard of level.hazards) {
    if (!overlaps(playerRect(player), hazard)) continue;
    if (hazard.type === "sap") {
      player.stickyUntil = now + 1300;
    } else {
      onDamage(hazard.type);
    }
  }

  if (player.y > WORLD.height + 160) onDamage("fall");
  return { landed: !wasGrounded && player.grounded };
}
