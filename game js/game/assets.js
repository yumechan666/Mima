import manifest from "../assets.json";

const CRITICAL_KEYS = [
  "AREA_01_BG",
  "MIMA_BASIC_SHEET",
  "MIMA_AIR_SHEET",
  "MIMA_TREE_SHEET",
  "MIMA_TRAVERSAL_ONE_SHEET",
  "MIMA_ABILITIES_SHEET",
  "EUCALYPTUS_PLATFORM_TILES",
  "CLIMB_EUCALYPTUS_TILES",
  "ZONE_ONE_OBJECTS",
  "FINAL_OBJECTS",
  "TRAIL_EFFECTS_SHEET",
  "UI_ICON_ATLAS",
];

function imageFrom(url) {
  return new Promise((resolve, reject) => {
    const image = new Image();
    image.decoding = "async";
    image.onload = () => resolve(image);
    image.onerror = () => reject(new Error(`Gagal memuat ${url}`));
    image.src = url;
  });
}

function metadataUrl(url) {
  return url.replace(/\.(webp|png|jpe?g)(?:\?.*)?$/i, ".frames.json");
}

async function frameMetadata(url) {
  const response = await fetch(metadataUrl(url));
  if (!response.ok) return null;
  return response.json();
}

function preparePack(key, image, metadata) {
  const byName = new Map();
  const animations = new Map();
  for (const frame of metadata?.frames ?? []) byName.set(frame.name, frame);
  for (const animation of metadata?.animations ?? []) {
    animations.set(animation.name, {
      ...animation,
      maxContentHeight: Math.max(...animation.frames.map((frame) => (frame.content ?? frame.source).h)),
      maxContentWidth: Math.max(...animation.frames.map((frame) => (frame.content ?? frame.source).w)),
    });
  }
  return { key, image, metadata, byName, animations };
}

export function createAssetStore(assetsHandle, onProgress = () => {}) {
  const packs = new Map();
  const pending = new Map();
  const failures = new Map();
  let loadedCount = 0;

  function urlFor(key) {
    return assetsHandle?.get(key) ?? manifest[key];
  }

  function load(key) {
    if (packs.has(key)) return Promise.resolve(packs.get(key));
    if (pending.has(key)) return pending.get(key);
    const url = urlFor(key);
    if (!url) return Promise.reject(new Error(`Aset ${key} tidak terdaftar`));

    const promise = Promise.all([
      imageFrom(url),
      manifest[key]?.includes("transparent") || manifest[key]?.includes("tiles")
        ? frameMetadata(manifest[key]).catch(() => null)
        : Promise.resolve(null),
    ])
      .then(([image, metadata]) => {
        const pack = preparePack(key, image, metadata);
        packs.set(key, pack);
        loadedCount += 1;
        onProgress(loadedCount, Object.keys(manifest).length);
        return pack;
      })
      .catch((error) => {
        failures.set(key, error);
        throw error;
      })
      .finally(() => pending.delete(key));

    pending.set(key, promise);
    return promise;
  }

  return {
    load,
    get(key) {
      return packs.get(key) ?? null;
    },
    has(key) {
      return packs.has(key);
    },
    async loadCritical() {
      await Promise.all(CRITICAL_KEYS.map(load));
    },
    loadRemaining() {
      const rest = Object.keys(manifest).filter((key) => !packs.has(key) && !key.startsWith("SKIN_"));
      return Promise.allSettled(rest.map(load));
    },
    failures,
  };
}
