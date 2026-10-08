const BASE_HEIGHT = 1450;
export const WORLD = { width: 720, height: BASE_HEIGHT * 3 };

const p = (x, y, w, type = "normal", extra = {}) => ({ x, y, w, h: 58, type, ...extra });
const basePlatforms = () => [
  p(0, 1380, 720, "ground"),
  p(26, 1205, 220),
  p(405, 1030, 270),
  p(126, 855, 230),
  p(420, 680, 245),
  p(55, 505, 235),
  p(350, 325, 255),
  p(555, 170, 155),
];

const leaves = (area) => [
  { id: `leaf-${area}-1`, x: 142, y: 1150 },
  { id: `leaf-${area}-2`, x: 522, y: 975 },
  { id: `leaf-${area}-3`, x: 215, y: 450 },
];

const common = (index, data) => ({
  id: index,
  world: WORLD,
  start: { x: 92, y: 1368 },
  platforms: basePlatforms(),
  climbables: [],
  hazards: [],
  zones: [],
  interactions: [
    ...(index > 0
      ? [{ id: `back-${index}`, type: "back", x: 58, y: 1325, atlas: "FINAL_OBJECTS", frame: "shortcut_arch", label: "Turun" }]
      : []),
    { id: `gate-${index}`, type: "gate", x: 640, y: 126, atlas: "FINAL_OBJECTS", frame: "branch_gate", label: index === 9 ? "Sangkar" : "Naik" },
  ],
  leaves: leaves(index),
  clue: { id: `clue-${index}`, x: 585, y: 245, atlas: index < 3 ? "ZONE_ONE_OBJECTS" : index < 6 ? "ZONE_TWO_OBJECTS" : "ZONE_THREE_OBJECTS", frame: index === 0 ? "fur_tuft" : index === 1 ? "joey_toy" : index === 2 ? "pelican_rope" : index === 3 ? "ash_print" : index === 4 ? "joey_drawing" : index === 5 ? "cocoon_step" : index === 6 ? "scent_ball" : "joey_cloth" },
  carving: { id: `carving-${index}`, x: 72, y: 655, atlas: "FINAL_OBJECTS", frame: "secret_carving" },
  npcs: [],
  ...data,
});

const BASE_LEVELS = [
  common(0, {
    name: "Home Canopy",
    subtitle: "Eucalyptus Grove",
    bg: "AREA_01_BG",
    platform: "EUCALYPTUS_PLATFORM_TILES",
    palette: ["#d9e7c9", "#6f927b", "#2f493f"],
    tip: "Kumpulkan 3 daun, lalu tanam Gumnut di tanah bercahaya.",
    objective: "3 Golden Leaf + tumbuhkan pijakan",
    climbables: [{ x: 300, y: 560, w: 92, h: 800 }],
    interactions: [
      { id: "branch-0", type: "branch", x: 140, y: 1175, atlas: "ZONE_ONE_OBJECTS", frame: "flexible_branch", label: "Lontarkan" },
      { id: "seed-0", type: "seed", x: 522, y: 1000, atlas: "ZONE_ONE_OBJECTS", frame: "sprout_patch", label: "Tanam" },
      { id: "gate-0", type: "gate", x: 640, y: 126, atlas: "FINAL_OBJECTS", frame: "branch_gate", label: "Buka" },
    ],
  }),
  common(1, {
    name: "Hollow Trunk Tunnels",
    subtitle: "Lorong Batang Rapuh",
    bg: "AREA_02_BG",
    platform: "EUCALYPTUS_PLATFORM_TILES",
    palette: ["#493d32", "#9b7448", "#d5b86f"],
    tip: "Kupas tiga panel kulit. Berjongkok di rongga gelap saat Mata Senja lewat.",
    objective: "Kupas 3 panel kulit",
    climbables: [{ x: 342, y: 210, w: 76, h: 1110 }],
    interactions: [
      { id: "bark-1-a", type: "bark", x: 175, y: 1170, atlas: "ZONE_ONE_OBJECTS", frame: "bark_panel", label: "Kupas" },
      { id: "bark-1-b", type: "bark", x: 515, y: 995, atlas: "ZONE_ONE_OBJECTS", frame: "bark_panel", label: "Kupas" },
      { id: "bark-1-c", type: "bark", x: 225, y: 820, atlas: "ZONE_ONE_OBJECTS", frame: "bark_panel", label: "Kupas" },
      { id: "block-1", type: "pushBlock", x: 520, y: 645, atlas: "ZONE_ONE_OBJECTS", frame: "bark_panel", label: "Geser blok" },
      { id: "bubu-1", type: "shortcut", x: 82, y: 1328, atlas: "ZONE_ONE_OBJECTS", frame: "wombat_tunnel", label: "Terowongan Bubu" },
      { id: "gate-1", type: "gate", x: 640, y: 126, atlas: "FINAL_OBJECTS", frame: "branch_gate", label: "Naik" },
    ],
    zones: [{ type: "shadow", x: 30, y: 1100, w: 235, h: 150 }],
    npcs: [{ type: "owl", x: 120, y: 720, sheet: "OWL_SHEET", anim: "patrol_fly", minX: 80, maxX: 620, speed: 105 }],
  }),
  common(2, {
    name: "Waterfall Mist Valley",
    subtitle: "Lembah Air Terjun",
    bg: "AREA_03_BG",
    platform: "EUCALYPTUS_PLATFORM_TILES",
    palette: ["#b9e1df", "#4e8f91", "#315f62"],
    tip: "Putar tuas agar batang mengering. Batu di kantong menekan tombol dasar.",
    objective: "Alihkan arus air",
    platforms: [
      ...basePlatforms().map((platform, i) => (i === 3 ? { ...platform, type: "slippery" } : platform)),
      p(278, 1190, 150, "raft", { vx: 50, minX: 250, maxX: 430 }),
    ],
    climbables: [{ x: 355, y: 320, w: 80, h: 460 }],
    interactions: [
      { id: "weight-2", type: "weight", x: 160, y: 1172, atlas: "ZONE_THREE_OBJECTS", frame: "stone_weight", label: "Isi kantong" },
      { id: "lever-2", type: "waterLever", x: 520, y: 995, atlas: "ZONE_ONE_OBJECTS", frame: "water_lever", label: "Putar arus" },
      { id: "peli-2", type: "pelican", x: 510, y: 650, atlas: "ZONE_ONE_OBJECTS", frame: "pelican_rope", label: "Bebaskan Peli" },
      { id: "gate-2", type: "gate", x: 640, y: 126, atlas: "FINAL_OBJECTS", frame: "branch_gate", label: "Naik" },
      { id: "back-2", type: "back", x: 58, y: 1325, atlas: "FINAL_OBJECTS", frame: "shortcut_arch", label: "Turun" },
    ],
    hazards: [{ type: "water", x: 250, y: 1360, w: 210, h: 90 }],
    npcs: [{ type: "pelican", x: 520, y: 620, sheet: "PELICAN_SHEET", anim: "trapped" }],
  }),
  common(3, {
    name: "Burning Timberland",
    subtitle: "Hutan Bekas Kebakaran",
    bg: "AREA_04_BG",
    platform: "ROOT_PLATFORM_TILES",
    palette: ["#d6aa7b", "#8f533a", "#3a2928"],
    tip: "Kosongkan kantong dan tahan Lompat di atas thermal. Dahan hangus cepat runtuh.",
    objective: "Capai tapak berjelaga Joey",
    platforms: basePlatforms().map((platform, i) => (i > 1 && i < 6 ? { ...platform, type: "crumble", timer: 0 } : platform)),
    zones: [{ type: "updraft", x: 300, y: 720, w: 150, h: 660 }],
    hazards: [
      { type: "fire", x: 260, y: 1350, w: 160, h: 55 },
      { type: "fire", x: 300, y: 825, w: 95, h: 35 },
    ],
    interactions: [
      { id: "thermal-3", type: "thermal", x: 365, y: 1260, atlas: "ZONE_TWO_OBJECTS", frame: "thermal_vent", label: "Buka daun" },
      { id: "gate-3", type: "gate", x: 640, y: 126, atlas: "FINAL_OBJECTS", frame: "branch_gate", label: "Naik" },
      { id: "back-3", type: "back", x: 58, y: 1325, atlas: "FINAL_OBJECTS", frame: "shortcut_arch", label: "Turun" },
    ],
  }),
  common(4, {
    name: "Crystal Cave Roots",
    subtitle: "Gua Akar Kristal",
    bg: "AREA_05_BG",
    platform: "ROOT_PLATFORM_TILES",
    palette: ["#17243f", "#317f8e", "#70d5cf"],
    tip: "Dekati kristal lalu gunakan Aksi untuk melepaskan Echo Bellow.",
    objective: "Nyalakan 3 kristal gema",
    platforms: basePlatforms(),
    climbables: [{ x: 330, y: 300, w: 80, h: 1050 }],
    interactions: [
      { id: "crystal-4-a", type: "crystal", x: 165, y: 1170, atlas: "ZONE_TWO_OBJECTS", frame: "crystal_sensor", label: "Gema" },
      { id: "crystal-4-b", type: "crystal", x: 520, y: 995, atlas: "ZONE_TWO_OBJECTS", frame: "crystal_sensor", label: "Gema" },
      { id: "crystal-4-c", type: "crystal", x: 220, y: 470, atlas: "ZONE_TWO_OBJECTS", frame: "crystal_sensor", label: "Gema" },
      { id: "gate-4", type: "gate", x: 640, y: 126, atlas: "FINAL_OBJECTS", frame: "branch_gate", label: "Lift akar" },
      { id: "back-4", type: "back", x: 58, y: 1325, atlas: "FINAL_OBJECTS", frame: "shortcut_arch", label: "Turun" },
    ],
  }),
  common(5, {
    name: "Great Spider Canopy",
    subtitle: "Kanopi Sarang Laba-laba",
    bg: "AREA_06_BG",
    platform: "ROOT_PLATFORM_TILES",
    palette: ["#232b44", "#76719a", "#c9bad9"],
    tip: "Jaring melontarkanmu tinggi. Potong tiga tali kepompong dengan Aksi.",
    objective: "Potong 3 tali sarang",
    platforms: [
      ...basePlatforms(),
      p(255, 1120, 210, "web"),
      p(300, 610, 170, "web"),
    ],
    hazards: [{ type: "sap", x: 420, y: 1350, w: 150, h: 45 }],
    interactions: [
      { id: "rope-5-a", type: "rope", x: 165, y: 1170, atlas: "ZONE_TWO_OBJECTS", frame: "cocoon_step", label: "Potong" },
      { id: "rope-5-b", type: "rope", x: 535, y: 995, atlas: "ZONE_TWO_OBJECTS", frame: "cocoon_step", label: "Potong" },
      { id: "rope-5-c", type: "rope", x: 215, y: 470, atlas: "ZONE_TWO_OBJECTS", frame: "cocoon_step", label: "Potong" },
      { id: "gate-5", type: "gate", x: 640, y: 126, atlas: "FINAL_OBJECTS", frame: "branch_gate", label: "Ikuti tangisan" },
      { id: "back-5", type: "back", x: 58, y: 1325, atlas: "FINAL_OBJECTS", frame: "shortcut_arch", label: "Turun" },
    ],
    npcs: [{ type: "spider", x: 520, y: 615, sheet: "SPIDER_SHEET", anim: "crawl", minX: 430, maxX: 650, speed: 55 }],
  }),
  common(6, {
    name: "Termite Empire Mound",
    subtitle: "Sarang Rayap Raksasa",
    bg: "AREA_07_BG",
    platform: "EARTH_PLATFORM_TILES",
    palette: ["#d8b06f", "#a5603c", "#5b382e"],
    tip: "Tekan Bawah + Lompat di udara untuk menghancurkan dua pilar retak.",
    objective: "Hancurkan 2 pilar penyangga",
    platforms: basePlatforms().map((platform, i) => (i === 2 || i === 4 ? { ...platform, type: "cracked", id: `pillar-6-${i}` } : platform)),
    interactions: [
      { id: "scent-6", type: "scentBall", x: 170, y: 1170, atlas: "ZONE_THREE_OBJECTS", frame: "scent_ball", label: "Lempar aroma" },
      { id: "gate-6", type: "gate", x: 640, y: 126, atlas: "FINAL_OBJECTS", frame: "branch_gate", label: "Jembatan runtuh" },
      { id: "back-6", type: "back", x: 58, y: 1325, atlas: "FINAL_OBJECTS", frame: "shortcut_arch", label: "Turun" },
    ],
    npcs: [
      { type: "termite", x: 215, y: 1290, sheet: "TERMITE_SHEET", anim: "march", minX: 130, maxX: 390, speed: 35 },
      { type: "dingo", x: 500, y: 970, sheet: "DINGO_SHEET", anim: "patrol", minX: 420, maxX: 655, speed: 80 },
    ],
  }),
  common(7, {
    name: "Windswept Peaks",
    subtitle: "Puncak Angin Kencang",
    bg: "AREA_08_BG",
    platform: "EARTH_PLATFORM_TILES",
    palette: ["#c8d8d8", "#738791", "#45525f"],
    tip: "Isi kantong dengan batu agar tak terdorong angin, lalu sentuh jangkar puncak.",
    objective: "Bawa beban melewati badai",
    zones: [{ type: "wind", x: 150, y: 180, w: 520, h: 1110, force: -520 }],
    interactions: [
      { id: "weight-7", type: "weight", x: 170, y: 1170, atlas: "ZONE_THREE_OBJECTS", frame: "stone_weight", label: "Isi kantong" },
      { id: "anchor-7", type: "windAnchor", x: 510, y: 290, atlas: "ZONE_THREE_OBJECTS", frame: "wind_shelter", label: "Tahan pijakan" },
      { id: "vine-7", type: "vine", x: 215, y: 475, atlas: "ZONE_THREE_OBJECTS", frame: "vine_rope", label: "Ayun" },
      { id: "gate-7", type: "gate", x: 640, y: 126, atlas: "FINAL_OBJECTS", frame: "branch_gate", label: "Naik" },
      { id: "back-7", type: "back", x: 58, y: 1325, atlas: "FINAL_OBJECTS", frame: "shortcut_arch", label: "Turun" },
    ],
  }),
  common(8, {
    name: "Human Logging Camp",
    subtitle: "Area Penebangan Pohon",
    bg: "AREA_09_BG",
    platform: "INDUSTRIAL_PLATFORM_TILES",
    palette: ["#c5c9bd", "#607f7f", "#744b3b"],
    tip: "Aksi pada kait untuk zipline. Putar derek agar gelondongan menjadi tangga.",
    objective: "Aktifkan derek utama",
    platforms: basePlatforms().map((platform, i) => (i === 3 ? { ...platform, type: "conveyor", vx: 75 } : platform)),
    hazards: [
      { type: "saw", x: 350, y: 1340, w: 85, h: 60 },
      { type: "saw", x: 360, y: 800, w: 75, h: 55 },
    ],
    zones: [{ type: "zipline", x: 170, y: 520, w: 440, h: 45 }],
    interactions: [
      { id: "zip-8", type: "zipline", x: 180, y: 540, atlas: "ZONE_THREE_OBJECTS", frame: "zip_hook", label: "Kaitkan cakar" },
      { id: "crane-8", type: "crane", x: 525, y: 995, atlas: "ZONE_THREE_OBJECTS", frame: "crane_lever", label: "Tarik derek" },
      { id: "gate-8", type: "gate", x: 640, y: 126, atlas: "FINAL_OBJECTS", frame: "branch_gate", label: "Ke Baobab" },
      { id: "back-8", type: "back", x: 58, y: 1325, atlas: "FINAL_OBJECTS", frame: "shortcut_arch", label: "Turun" },
    ],
  }),
  common(9, {
    name: "Ancient Baobab",
    subtitle: "Pohon Purba Sang Predator",
    bg: "AREA_10_BG",
    platform: "BAOBAB_PLATFORM_TILES",
    palette: ["#e4d59c", "#9d7543", "#4e382d"],
    tip: "Aktifkan empat pengunci, lalu buka sangkar Joey sebelum elang menyambar.",
    objective: "Buka 4 pengunci sangkar",
    climbables: [{ x: 320, y: 220, w: 90, h: 1140 }],
    interactions: [
      { id: "lock-9-sling", type: "lock", x: 165, y: 1170, atlas: "FINAL_OBJECTS", frame: "slingshot_lock", label: "Slingshot", ability: "gumnut" },
      { id: "lock-9-thermal", type: "lock", x: 525, y: 995, atlas: "FINAL_OBJECTS", frame: "thermal_lock", label: "Thermal", ability: "glide" },
      { id: "lock-9-slam", type: "lock", x: 215, y: 820, atlas: "FINAL_OBJECTS", frame: "slam_lock", label: "Body Slam", ability: "slam" },
      { id: "lock-9-zip", type: "lock", x: 535, y: 645, atlas: "FINAL_OBJECTS", frame: "zipline_lock", label: "Zipline", ability: "zipline" },
      { id: "cage-9", type: "cage", x: 585, y: 235, atlas: "FINAL_OBJECTS", frame: "twig_cage", label: "Bebaskan Joey" },
      { id: "back-9", type: "back", x: 58, y: 1325, atlas: "FINAL_OBJECTS", frame: "shortcut_arch", label: "Turun" },
    ],
    npcs: [
      { type: "eagle", x: 500, y: 440, sheet: "EAGLE_SHEET", anim: "circle", minX: 90, maxX: 650, speed: 135 },
      { type: "joey", x: 585, y: 245, sheet: "JOEY_SHEET", anim: "captive_idle" },
    ],
  }),
  common(10, {
    name: "Bamboo Billabong",
    subtitle: "Rawa Bambu Bergema",
    bg: "AREA_11_BG",
    platform: "EUCALYPTUS_PLATFORM_TILES",
    climbAsset: "CLIMB_BAMBOO_TILES",
    palette: ["#cbd9a6", "#4d856d", "#315a4c"],
    tip: "Panjat batang bambu, pukul gong, dan hindari lemparan biji kookaburra.",
    objective: "Aktifkan gong bambu",
    climbables: [{ x: 315, y: 230, w: 86, h: 1110 }],
    hazards: [{ type: "water", x: 265, y: 1360, w: 180, h: 90 }],
    interactions: [{ id: "core-10", type: "frontierPuzzle", kind: "bambooGong", x: 165, y: 1170, atlas: "FRONTIER_PUZZLES_C", frame: "bamboo_gong", label: "Pukul gong" }],
    npcs: [{ type: "kookaburra", x: 510, y: 950, sheet: "KOOKABURRA_ENEMY_SHEET", anim: "fly", minX: 410, maxX: 660, speed: 105, health: 2, flying: true }],
  }),
  common(11, {
    name: "Mangrove Tides",
    subtitle: "Pasang Surut Bakau",
    bg: "AREA_12_BG",
    platform: "ROOT_PLATFORM_TILES",
    climbAsset: "CLIMB_EUCALYPTUS_TILES",
    palette: ["#b8d7c5", "#4a7c70", "#5f4b38"],
    tip: "Putar roda pasang, lompat di gelondongan, dan jangan berada di jalur lunge buaya.",
    objective: "Balikkan pasang mangrove",
    climbables: [{ x: 335, y: 330, w: 82, h: 940 }],
    hazards: [{ type: "water", x: 240, y: 1350, w: 250, h: 100 }],
    interactions: [{ id: "core-11", type: "frontierPuzzle", kind: "tideWheel", x: 520, y: 995, atlas: "FRONTIER_PUZZLES_C", frame: "mangrove_tide_wheel", label: "Putar pasang" }],
    npcs: [{ type: "crocodile", x: 475, y: 1320, sheet: "CROCODILE_ENEMY_SHEET", anim: "swim", minX: 270, maxX: 630, speed: 72, health: 3 }],
  }),
  common(12, {
    name: "Moon Gum Marsh",
    subtitle: "Rawa Gum Bulan",
    bg: "AREA_13_BG",
    platform: "ROOT_PLATFORM_TILES",
    climbAsset: "CLIMB_EUCALYPTUS_TILES",
    palette: ["#b9bdd7", "#5b5d88", "#282f58"],
    tip: "Gunakan gelembung sebagai pijakan sesaat dan lempar Gumnut untuk memecahkannya.",
    objective: "Nyalakan lentera pollen",
    climbables: [{ x: 322, y: 250, w: 88, h: 1060 }],
    zones: [{ type: "updraft", x: 470, y: 570, w: 125, h: 620 }],
    interactions: [{ id: "core-12", type: "frontierPuzzle", kind: "moonLantern", x: 170, y: 1170, atlas: "FRONTIER_PUZZLES_C", frame: "moon_pollen_lantern", label: "Nyalakan pollen" }],
    npcs: [{ type: "toad", x: 520, y: 995, sheet: "TOAD_ENEMY_SHEET", anim: "hop", minX: 425, maxX: 660, speed: 58, health: 2 }],
  }),
  common(13, {
    name: "Redstone Gorge",
    subtitle: "Ngarai Batu Merah",
    bg: "AREA_14_BG",
    platform: "EARTH_PLATFORM_TILES",
    climbAsset: "CLIMB_EUCALYPTUS_TILES",
    palette: ["#e1b276", "#a34f35", "#633326"],
    tip: "Aktifkan bobot ngarai, berlindung dari kerikil, lalu lompat di sela batang sempit.",
    objective: "Seimbangkan counterweight",
    climbables: [{ x: 185, y: 310, w: 82, h: 980 }],
    hazards: [{ type: "fire", x: 320, y: 1348, w: 85, h: 45 }],
    interactions: [{ id: "core-13", type: "frontierPuzzle", kind: "gorgeWeight", x: 520, y: 995, atlas: "FRONTIER_PUZZLES_C", frame: "gorge_counterweight", label: "Tarik bobot" }],
    npcs: [{ type: "goanna", x: 510, y: 1170, sheet: "GOANNA_ENEMY_SHEET", anim: "crawl", minX: 410, maxX: 665, speed: 85, health: 3 }],
  }),
  common(14, {
    name: "Honey Ant Citadel",
    subtitle: "Benteng Semut Madu",
    bg: "AREA_15_BG",
    platform: "EARTH_PLATFORM_TILES",
    climbAsset: "CLIMB_EUCALYPTUS_TILES",
    palette: ["#e2c079", "#a76035", "#63372d"],
    tip: "Pantulkan aroma pada garpu resin untuk mengubah jalur patroli sentinel.",
    objective: "Selaraskan garpu aroma",
    climbables: [{ x: 344, y: 220, w: 76, h: 1120 }],
    interactions: [{ id: "core-14", type: "frontierPuzzle", kind: "honeyFork", x: 170, y: 1170, atlas: "FRONTIER_PUZZLES_C", frame: "honey_scent_fork", label: "Getarkan resin" }],
    npcs: [{ type: "antSentinel", x: 520, y: 995, sheet: "ANT_SENTINEL_SHEET", anim: "march", minX: 420, maxX: 660, speed: 78, health: 3 }],
  }),
  common(15, {
    name: "Ghost Fern Observatory",
    subtitle: "Observatorium Pakis Gaib",
    bg: "AREA_16_BG",
    platform: "ROOT_PLATFORM_TILES",
    climbAsset: "CLIMB_EUCALYPTUS_TILES",
    palette: ["#9cc8c1", "#3d7080", "#263858"],
    tip: "Arahkan cermin pakis untuk memantulkan gema dan membuka teleskop akar.",
    objective: "Sejajarkan cermin pakis",
    climbables: [{ x: 300, y: 260, w: 88, h: 1050 }],
    interactions: [{ id: "core-15", type: "frontierPuzzle", kind: "fernMirror", x: 520, y: 995, atlas: "FRONTIER_PUZZLES_D", frame: "fern_mirror", label: "Putar cermin" }],
    npcs: [{ type: "fernBat", x: 510, y: 780, sheet: "FERN_BAT_SHEET", anim: "fly", minX: 390, maxX: 650, speed: 92, health: 2, flying: true }],
  }),
  common(16, {
    name: "Magpie Rail Trestle",
    subtitle: "Jembatan Rel Murai",
    bg: "AREA_17_BG",
    platform: "INDUSTRIAL_PLATFORM_TILES",
    climbAsset: "CLIMB_EUCALYPTUS_TILES",
    palette: ["#c2ccd0", "#677985", "#514136"],
    tip: "Ubah sinyal rel sebelum magpie menyambar; gunakan batang panjat sebagai perlindungan.",
    objective: "Aktifkan sinyal rel",
    climbables: [{ x: 180, y: 250, w: 82, h: 1090 }],
    zones: [{ type: "zipline", x: 180, y: 540, w: 430, h: 45 }],
    interactions: [{ id: "core-16", type: "frontierPuzzle", kind: "railSignal", x: 520, y: 995, atlas: "FRONTIER_PUZZLES_D", frame: "rail_signal", label: "Ubah sinyal" }],
    npcs: [{ type: "magpie", x: 510, y: 720, sheet: "MAGPIE_ENEMY_SHEET", anim: "swoop", minX: 390, maxX: 655, speed: 120, health: 2, flying: true }],
  }),
  common(17, {
    name: "Ironbark Machine Ruins",
    subtitle: "Reruntuhan Mesin Ironbark",
    bg: "AREA_18_BG",
    platform: "INDUSTRIAL_PLATFORM_TILES",
    climbAsset: "CLIMB_EUCALYPTUS_TILES",
    palette: ["#aebfae", "#477b75", "#6f3f32"],
    tip: "Lempar Gumnut ke magnet untuk membelokkan gear drone dan mematikan saw lock.",
    objective: "Aktifkan magnet Ironbark",
    climbables: [{ x: 335, y: 230, w: 82, h: 1110 }],
    hazards: [{ type: "saw", x: 325, y: 1335, w: 90, h: 65 }],
    interactions: [{ id: "core-17", type: "frontierPuzzle", kind: "ironMagnet", x: 170, y: 1170, atlas: "FRONTIER_PUZZLES_D", frame: "ironbark_magnet", label: "Aktifkan magnet" }],
    npcs: [{ type: "drone", x: 515, y: 850, sheet: "DRONE_ENEMY_SHEET", anim: "hover", minX: 380, maxX: 660, speed: 90, health: 3, flying: true }],
  }),
  common(18, {
    name: "Skyflower Sanctuary",
    subtitle: "Suaka Bunga Langit",
    bg: "AREA_19_BG",
    platform: "BAOBAB_PLATFORM_TILES",
    climbAsset: "CLIMB_BAMBOO_TILES",
    palette: ["#d7d2e3", "#8b75a6", "#447f79"],
    tip: "Putar prisma bunga saat angin moth reda, lalu glide di antara batang tinggi.",
    objective: "Buka prisma Skyflower",
    climbables: [{ x: 300, y: 190, w: 88, h: 1150 }],
    zones: [{ type: "wind", x: 130, y: 240, w: 540, h: 1050, force: -370 }],
    interactions: [{ id: "core-18", type: "frontierPuzzle", kind: "flowerPrism", x: 520, y: 995, atlas: "FRONTIER_PUZZLES_D", frame: "skyflower_prism", label: "Putar prisma" }],
    npcs: [{ type: "moth", x: 510, y: 720, sheet: "MOTH_ENEMY_SHEET", anim: "fly", minX: 370, maxX: 655, speed: 85, health: 3, flying: true }],
  }),
  common(19, {
    name: "Stormheart Crown",
    subtitle: "Mahkota Jantung Badai",
    bg: "AREA_20_BG",
    platform: "BAOBAB_PLATFORM_TILES",
    climbAsset: "CLIMB_BAMBOO_TILES",
    palette: ["#aabed0", "#405b79", "#392f35"],
    tip: "Lempar buah keras, hindari tendangan Raja Kasuari, dan berpindah antar batang saat ia berlari.",
    objective: "Kalahkan Raja Kasuari",
    climbables: [
      { x: 155, y: 210, w: 78, h: 1100 },
      { x: 480, y: 210, w: 78, h: 1100 },
    ],
    zones: [{ type: "wind", x: 90, y: 170, w: 590, h: 1120, force: -280 }],
    interactions: [{ id: "core-19", type: "frontierPuzzle", kind: "stormLauncher", x: 165, y: 1170, atlas: "FRONTIER_PUZZLES_D", frame: "storm_fruit_launcher", label: "Isi pelontar buah" }],
    npcs: [{ type: "cassowary", x: 510, y: 1380, sheet: "CASSOWARY_BOSS_SHEET", anim: "idle", minX: 120, maxX: 640, speed: 145, health: 6, boss: true, topOnly: true }],
  }),
];

const EXTRA_PUZZLES = [
  [
    { kind: "branchChain", label: "Rantai slingshot", atlas: "EXPANDED_PUZZLES_A", frame: "branch_chain_switch" },
    { kind: "seedCrown", label: "Kebun kanopi", atlas: "EXPANDED_PUZZLES_A", frame: "seed_crown_bed" },
  ],
  [
    { kind: "sapBlock", label: "Sumbat getah", atlas: "EXPANDED_PUZZLES_A", frame: "sap_block_cradle" },
    { kind: "shadowBell", label: "Bunyikan rongga", atlas: "EXPANDED_PUZZLES_A", frame: "owl_shadow_chime", requirement: "scent" },
  ],
  [
    { kind: "floodGate", label: "Naikkan air", atlas: "EXPANDED_PUZZLES_A", frame: "flood_gate_wheel" },
    { kind: "leafDock", label: "Tambatkan daun", atlas: "EXPANDED_PUZZLES_A", frame: "leaf_dock_cleat", requirement: "row" },
  ],
  [
    { kind: "smokeDamper", label: "Tutup cerobong asap", atlas: "EXPANDED_PUZZLES_A", frame: "smoke_damper" },
    { kind: "thermalSpire", label: "Nyalakan thermal", atlas: "EXPANDED_PUZZLES_A", frame: "thermal_spire", requirement: "glide" },
  ],
  [
    { kind: "shroomChain", label: "Isi lentera jamur", atlas: "EXPANDED_PUZZLES_A", frame: "shroom_lantern" },
    { kind: "prismEcho", label: "Selaraskan prisma", atlas: "EXPANDED_PUZZLES_A", frame: "prism_echo", requirement: "echo" },
  ],
  [
    { kind: "waterFruit", label: "Pecahkan buah air", atlas: "EXPANDED_PUZZLES_B", frame: "water_fruit_press" },
    { kind: "cocoonLift", label: "Turunkan lift kepompong", atlas: "EXPANDED_PUZZLES_B", frame: "cocoon_lift", requirement: "web" },
  ],
  [
    { kind: "termiteSwitch", label: "Pancing barisan rayap", atlas: "EXPANDED_PUZZLES_B", frame: "termite_scent_beacon" },
    { kind: "spireBreak", label: "Runtuhkan dinding menara", atlas: "EXPANDED_PUZZLES_B", frame: "spire_break_seal", requirement: "slam" },
  ],
  [
    { kind: "stormShelter", label: "Kunci pelindung angin", atlas: "EXPANDED_PUZZLES_B", frame: "storm_shelter_latch", requirement: "heavy" },
    { kind: "vineAnchor", label: "Ikat akar ayun", atlas: "EXPANDED_PUZZLES_B", frame: "vine_anchor" },
  ],
  [
    { kind: "cableSwitch", label: "Pindahkan jalur kabel", atlas: "EXPANDED_PUZZLES_B", frame: "cable_switch", requirement: "zipline" },
    { kind: "conveyorBrake", label: "Matikan rem konveyor", atlas: "EXPANDED_PUZZLES_B", frame: "conveyor_brake" },
  ],
  [
    { kind: "rootSeal", label: "Pecahkan segel akar", atlas: "EXPANDED_PUZZLES_B", frame: "root_slam_seal", requirement: "slam" },
    { kind: "eagleBell", label: "Bunyikan penanda sarang", atlas: "EXPANDED_PUZZLES_B", frame: "eagle_nest_bell" },
  ],
  [
    { kind: "bambooGong", label: "Gong bambu tengah", atlas: "FRONTIER_PUZZLES_C", frame: "bamboo_gong" },
    { kind: "reedValve", label: "Katup buluh", atlas: "FRONTIER_PUZZLES_C", frame: "reed_valve" },
  ],
  [
    { kind: "tideWheel", label: "Roda pasang tengah", atlas: "FRONTIER_PUZZLES_C", frame: "mangrove_tide_wheel" },
    { kind: "logAnchor", label: "Jangkar gelondongan", atlas: "FRONTIER_PUZZLES_C", frame: "floating_log_anchor" },
  ],
  [
    { kind: "moonLantern", label: "Lentera pollen kedua", atlas: "FRONTIER_PUZZLES_C", frame: "moon_pollen_lantern" },
    { kind: "bubbleReed", label: "Buluh gelembung", atlas: "FRONTIER_PUZZLES_C", frame: "bubble_reed" },
  ],
  [
    { kind: "gorgeWeight", label: "Bobot ngarai tengah", atlas: "FRONTIER_PUZZLES_C", frame: "gorge_counterweight" },
    { kind: "pebbleTarget", label: "Target kerikil", atlas: "FRONTIER_PUZZLES_C", frame: "pebble_target" },
  ],
  [
    { kind: "honeyFork", label: "Garpu aroma kedua", atlas: "FRONTIER_PUZZLES_C", frame: "honey_scent_fork" },
    { kind: "antBridge", label: "Tuas jembatan semut", atlas: "FRONTIER_PUZZLES_C", frame: "ant_bridge_lever" },
  ],
  [
    { kind: "fernMirror", label: "Cermin pakis tengah", atlas: "FRONTIER_PUZZLES_D", frame: "fern_mirror" },
    { kind: "echoTelescope", label: "Teleskop gema", atlas: "FRONTIER_PUZZLES_D", frame: "echo_telescope", requirement: "echo" },
  ],
  [
    { kind: "railSignal", label: "Sinyal rel tengah", atlas: "FRONTIER_PUZZLES_D", frame: "rail_signal" },
    { kind: "cableShield", label: "Pelindung kabel", atlas: "FRONTIER_PUZZLES_D", frame: "cable_shield", requirement: "zipline" },
  ],
  [
    { kind: "ironMagnet", label: "Magnet akar", atlas: "FRONTIER_PUZZLES_D", frame: "ironbark_magnet" },
    { kind: "sawLock", label: "Kunci gergaji", atlas: "FRONTIER_PUZZLES_D", frame: "saw_lock" },
  ],
  [
    { kind: "flowerPrism", label: "Prisma bunga tengah", atlas: "FRONTIER_PUZZLES_D", frame: "skyflower_prism" },
    { kind: "mothVane", label: "Penunjuk angin moth", atlas: "FRONTIER_PUZZLES_D", frame: "moth_wind_vane" },
  ],
  [
    { kind: "stormLauncher", label: "Pelontar buah kedua", atlas: "FRONTIER_PUZZLES_D", frame: "storm_fruit_launcher" },
    { kind: "arenaSeal", label: "Segel arena kasuari", atlas: "FRONTIER_PUZZLES_D", frame: "cassowary_arena_seal" },
  ],
];

const offsetRect = (value, offset, suffix) => ({
  ...value,
  y: value.y + offset,
  ...(value.id ? { id: `${value.id}-section-${suffix}` } : {}),
});

function expandLevel(base) {
  const offsets = [BASE_HEIGHT * 2, BASE_HEIGHT, 0];
  const platforms = offsets.flatMap((offset, section) => base.platforms.map((platform) => ({
    ...platform,
    y: platform.y + offset,
    ...(platform.id ? { id: `${platform.id}-section-${section}` } : {}),
    breakAt: null,
    broken: false,
  })));
  platforms.push(
    p(275, BASE_HEIGHT * 2 + 25, 170),
    p(275, BASE_HEIGHT + 25, 170),
  );

  const ordinaryInteractions = base.interactions.filter((item) => !["gate", "back"].includes(item.type));
  const interactions = ordinaryInteractions.map((item) => ({ ...item, y: item.y + BASE_HEIGHT * 2 }));
  const [middlePuzzle, topPuzzle] = EXTRA_PUZZLES[base.id];
  interactions.push(
    { id: `puzzle-${base.id}-middle`, type: "areaPuzzle", x: 520, y: 995 + BASE_HEIGHT, ...middlePuzzle },
    { id: `puzzle-${base.id}-top`, type: "areaPuzzle", x: 215, y: 470, ...topPuzzle },
  );

  if (base.id === 9) {
    for (const interaction of interactions) {
      if (interaction.id === "lock-9-thermal") interaction.y = 995 + BASE_HEIGHT;
      if (interaction.id === "lock-9-slam") interaction.y = 820 + BASE_HEIGHT;
      if (interaction.id === "lock-9-zip") interaction.y = 645;
      if (interaction.id === "cage-9") interaction.y = 235;
    }
  }

  if (base.id > 0) {
    interactions.push({ id: `back-${base.id}`, type: "back", x: 58, y: WORLD.height - 125, atlas: "FINAL_OBJECTS", frame: "shortcut_arch", label: "Turun" });
  }
  if (base.id < 9) {
    interactions.push({ id: `gate-${base.id}`, type: "gate", x: 640, y: 126, atlas: "FINAL_OBJECTS", frame: "branch_gate", label: "Naik" });
  }

  const npcs = base.npcs.flatMap((npc) => {
    if (["eagle", "joey"].includes(npc.type)) return [{ ...npc }];
    return offsets.map((offset, section) => ({ ...npc, y: npc.y + offset, section }));
  });

  return {
    ...base,
    start: { x: 92, y: WORLD.height - 82 },
    platforms,
    climbables: offsets.flatMap((offset, section) => base.climbables.map((zone) => offsetRect(zone, offset, section))),
    hazards: offsets.flatMap((offset, section) => base.hazards.map((hazard) => offsetRect(hazard, offset, section))),
    zones: offsets.flatMap((offset, section) => base.zones.map((zone) => offsetRect(zone, offset, section))),
    interactions,
    leaves: [
      { ...base.leaves[0], y: base.leaves[0].y + BASE_HEIGHT * 2 },
      { ...base.leaves[1], y: base.leaves[1].y + BASE_HEIGHT },
      { ...base.leaves[2] },
    ],
    clue: { ...base.clue },
    carving: { ...base.carving, y: base.carving.y + BASE_HEIGHT },
    npcs,
    chapters: ["Akar", "Jantung", "Mahkota"],
  };
}

export const LEVELS = BASE_LEVELS.map(expandLevel);

export function cloneLevel(index) {
  return structuredClone(LEVELS[index]);
}

export const UPGRADE_BY_AREA = [
  "gumnut",
  "bark",
  "row",
  "glide",
  "echo",
  "web",
  "slam",
  "weight",
  "zipline",
  "rescue",
  "throw",
  "tide",
  "bubble",
  "counterweight",
  "resin",
  "mirror",
  "rail",
  "magnet",
  "pollen",
  "stormfruit",
];
