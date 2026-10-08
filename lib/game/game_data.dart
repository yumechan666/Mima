import 'dart:ui';
const double worldWidth = 720;
const double sectionHeight = 1450;
const double worldHeight = sectionHeight * 3;
class InteractionDef {
  const InteractionDef({
    required this.id,
    required this.type,
    required this.x,
    required this.y,
    required this.atlas,
    required this.frame,
    required this.label,
    this.kind,
    this.ability,
    this.requirement,
  });
  final String id;
  final String type;
  final double x;
  final double y;
  final String atlas;
  final String frame;
  final String label;
  final String? kind;
  final String? ability;
  final String? requirement;
}
class NpcDef {
  const NpcDef({
    required this.type,
    required this.x,
    required this.y,
    required this.sheet,
    required this.anim,
    this.minX,
    this.maxX,
    this.speed = 0,
    this.health = 1,
    this.flying = false,
    this.boss = false,
  });
  final String type;
  final double x;
  final double y;
  final String sheet;
  final String anim;
  final double? minX;
  final double? maxX;
  final double speed;
  final int health;
  final bool flying;
  final bool boss;
}
class RectDef {
  const RectDef(this.x, this.y, this.w, this.h, [this.type = '']);
  final double x;
  final double y;
  final double w;
  final double h;
  final String type;
}
class HazardDef extends RectDef {
  const HazardDef(super.x, super.y, super.w, super.h, super.type);
}
class PuzzleDef {
  const PuzzleDef(this.kind, this.label, this.atlas, this.frame, {this.requirement});
  final String kind;
  final String label;
  final String atlas;
  final String frame;
  final String? requirement;
}
class LevelDefinition {
  const LevelDefinition({
    required this.name,
    required this.subtitle,
    required this.background,
    required this.platform,
    required this.palette,
    required this.tip,
    required this.objective,
    this.interactions = const [],
    this.npcs = const [],
    this.hazards = const [],
    this.zones = const [],
  });
  final String name;
  final String subtitle;
  final String background;
  final String platform;
  final List<Color> palette;
  final String tip;
  final String objective;
  final List<InteractionDef> interactions;
  final List<NpcDef> npcs;
  final List<HazardDef> hazards;
  final List<RectDef> zones;
}
const levelDefinitions = <LevelDefinition>[
  LevelDefinition(
    name: 'Home Canopy', subtitle: 'Eucalyptus Grove', background: 'AREA_01_BG',
    platform: 'EUCALYPTUS_PLATFORM_TILES',
    palette: [Color(0xffd9e7c9), Color(0xff6f927b), Color(0xff2f493f)],
    tip: 'Kumpulkan 3 daun, lalu tanam Gumnut di tanah bercahaya.',
    objective: '3 Golden Leaf + tumbuhkan pijakan',
    interactions: [
      InteractionDef(id: 'branch-0', type: 'branch', x: 140, y: 1175, atlas: 'ZONE_ONE_OBJECTS', frame: 'flexible_branch', label: 'Lontarkan'),
      InteractionDef(id: 'seed-0', type: 'seed', x: 522, y: 1000, atlas: 'ZONE_ONE_OBJECTS', frame: 'sprout_patch', label: 'Tanam'),
      InteractionDef(id: 'gate-0', type: 'gate', x: 640, y: 126, atlas: 'FINAL_OBJECTS', frame: 'branch_gate', label: 'Buka'),
    ],
  ),
  LevelDefinition(
    name: 'Hollow Trunk Tunnels', subtitle: 'Lorong Batang Rapuh', background: 'AREA_02_BG',
    platform: 'EUCALYPTUS_PLATFORM_TILES', palette: [Color(0xff493d32), Color(0xff9b7448), Color(0xffd5b86f)],
    tip: 'Kupas tiga panel kulit. Berjongkok di rongga gelap saat Mata Senja lewat.', objective: 'Kupas 3 panel kulit',
    interactions: [
      InteractionDef(id: 'bark-1-a', type: 'bark', x: 175, y: 1170, atlas: 'ZONE_ONE_OBJECTS', frame: 'bark_panel', label: 'Kupas'),
      InteractionDef(id: 'bark-1-b', type: 'bark', x: 515, y: 995, atlas: 'ZONE_ONE_OBJECTS', frame: 'bark_panel', label: 'Kupas'),
      InteractionDef(id: 'bark-1-c', type: 'bark', x: 225, y: 820, atlas: 'ZONE_ONE_OBJECTS', frame: 'bark_panel', label: 'Kupas'),
      InteractionDef(id: 'block-1', type: 'pushBlock', x: 520, y: 645, atlas: 'ZONE_ONE_OBJECTS', frame: 'bark_panel', label: 'Geser blok'),
      InteractionDef(id: 'shortcut-1', type: 'shortcut', x: 82, y: 1328, atlas: 'ZONE_ONE_OBJECTS', frame: 'wombat_tunnel', label: 'Terowongan Bubu'),
    ],
    zones: [RectDef(30, 1100, 235, 150, 'shadow')],
    npcs: [NpcDef(type: 'owl', x: 120, y: 720, sheet: 'OWL_SHEET', anim: 'patrol_fly', minX: 80, maxX: 620, speed: 105)],
  ),
  LevelDefinition(
    name: 'Waterfall Mist Valley', subtitle: 'Lembah Air Terjun', background: 'AREA_03_BG',
    platform: 'EUCALYPTUS_PLATFORM_TILES', palette: [Color(0xffb9e1df), Color(0xff4e8f91), Color(0xff315f62)],
    tip: 'Putar tuas agar batang mengering. Batu di kantong menekan tombol dasar.', objective: 'Alihkan arus air',
    interactions: [
      InteractionDef(id: 'weight-2', type: 'weight', x: 160, y: 1172, atlas: 'ZONE_THREE_OBJECTS', frame: 'stone_weight', label: 'Isi kantong'),
      InteractionDef(id: 'lever-2', type: 'waterLever', x: 520, y: 995, atlas: 'ZONE_ONE_OBJECTS', frame: 'water_lever', label: 'Putar arus'),
      InteractionDef(id: 'peli-2', type: 'pelican', x: 510, y: 650, atlas: 'ZONE_ONE_OBJECTS', frame: 'pelican_rope', label: 'Bebaskan Peli'),
    ],
    hazards: [HazardDef(250, 1360, 210, 90, 'water')],
    npcs: [NpcDef(type: 'pelican', x: 520, y: 620, sheet: 'PELICAN_SHEET', anim: 'trapped')],
  ),
  LevelDefinition(
    name: 'Burning Timberland', subtitle: 'Hutan Bekas Kebakaran', background: 'AREA_04_BG',
    platform: 'ROOT_PLATFORM_TILES', palette: [Color(0xffd6aa7b), Color(0xff8f533a), Color(0xff3a2928)],
    tip: 'Kosongkan kantong dan tahan Lompat di atas thermal. Dahan hangus cepat runtuh.', objective: 'Capai tapak berjelaga Joey',
    zones: [RectDef(300, 720, 150, 660, 'updraft')],
    hazards: [HazardDef(260, 1350, 160, 55, 'fire'), HazardDef(300, 825, 95, 35, 'fire')],
    interactions: [InteractionDef(id: 'thermal-3', type: 'thermal', x: 365, y: 1260, atlas: 'ZONE_TWO_OBJECTS', frame: 'thermal_vent', label: 'Buka daun')],
  ),
  LevelDefinition(
    name: 'Crystal Cave Roots', subtitle: 'Gua Akar Kristal', background: 'AREA_05_BG',
    platform: 'ROOT_PLATFORM_TILES', palette: [Color(0xff17243f), Color(0xff317f8e), Color(0xff70d5cf)],
    tip: 'Dekati kristal lalu gunakan Aksi untuk melepaskan Echo Bellow.', objective: 'Nyalakan 3 kristal gema',
    interactions: [
      InteractionDef(id: 'crystal-4-a', type: 'crystal', x: 165, y: 1170, atlas: 'ZONE_TWO_OBJECTS', frame: 'crystal_sensor', label: 'Gema'),
      InteractionDef(id: 'crystal-4-b', type: 'crystal', x: 520, y: 995, atlas: 'ZONE_TWO_OBJECTS', frame: 'crystal_sensor', label: 'Gema'),
      InteractionDef(id: 'crystal-4-c', type: 'crystal', x: 220, y: 470, atlas: 'ZONE_TWO_OBJECTS', frame: 'crystal_sensor', label: 'Gema'),
    ],
  ),
  LevelDefinition(
    name: 'Great Spider Canopy', subtitle: 'Kanopi Sarang Laba-laba', background: 'AREA_06_BG',
    platform: 'ROOT_PLATFORM_TILES', palette: [Color(0xff232b44), Color(0xff76719a), Color(0xffc9bad9)],
    tip: 'Jaring melontarkanmu tinggi. Potong tiga tali kepompong dengan Aksi.', objective: 'Potong 3 tali sarang',
    hazards: [HazardDef(420, 1350, 150, 45, 'sap')],
    interactions: [
      InteractionDef(id: 'rope-5-a', type: 'rope', x: 165, y: 1170, atlas: 'ZONE_TWO_OBJECTS', frame: 'cocoon_step', label: 'Potong'),
      InteractionDef(id: 'rope-5-b', type: 'rope', x: 535, y: 995, atlas: 'ZONE_TWO_OBJECTS', frame: 'cocoon_step', label: 'Potong'),
      InteractionDef(id: 'rope-5-c', type: 'rope', x: 215, y: 470, atlas: 'ZONE_TWO_OBJECTS', frame: 'cocoon_step', label: 'Potong'),
    ],
    npcs: [NpcDef(type: 'spider', x: 520, y: 615, sheet: 'SPIDER_SHEET', anim: 'crawl', minX: 430, maxX: 650, speed: 55)],
  ),
  LevelDefinition(
    name: 'Termite Empire Mound', subtitle: 'Sarang Rayap Raksasa', background: 'AREA_07_BG',
    platform: 'EARTH_PLATFORM_TILES', palette: [Color(0xffd8b06f), Color(0xffa5603c), Color(0xff5b382e)],
    tip: 'Tekan Bawah + Lompat di udara untuk menghancurkan dua pilar retak.', objective: 'Hancurkan 2 pilar penyangga',
    interactions: [InteractionDef(id: 'scent-6', type: 'scentBall', x: 170, y: 1170, atlas: 'ZONE_THREE_OBJECTS', frame: 'scent_ball', label: 'Lempar aroma')],
    npcs: [
      NpcDef(type: 'termite', x: 215, y: 1290, sheet: 'TERMITE_SHEET', anim: 'march', minX: 130, maxX: 390, speed: 35),
      NpcDef(type: 'dingo', x: 500, y: 970, sheet: 'DINGO_SHEET', anim: 'patrol', minX: 420, maxX: 655, speed: 80),
    ],
  ),
  LevelDefinition(
    name: 'Windswept Peaks', subtitle: 'Puncak Angin Kencang', background: 'AREA_08_BG',
    platform: 'EARTH_PLATFORM_TILES', palette: [Color(0xffc8d8d8), Color(0xff738791), Color(0xff45525f)],
    tip: 'Isi kantong dengan batu agar tak terdorong angin, lalu sentuh jangkar puncak.', objective: 'Bawa beban melewati badai',
    zones: [RectDef(150, 180, 520, 1110, 'wind')],
    interactions: [
      InteractionDef(id: 'weight-7', type: 'weight', x: 170, y: 1170, atlas: 'ZONE_THREE_OBJECTS', frame: 'stone_weight', label: 'Isi kantong'),
      InteractionDef(id: 'anchor-7', type: 'windAnchor', x: 510, y: 290, atlas: 'ZONE_THREE_OBJECTS', frame: 'wind_shelter', label: 'Tahan pijakan'),
      InteractionDef(id: 'vine-7', type: 'vine', x: 215, y: 475, atlas: 'ZONE_THREE_OBJECTS', frame: 'vine_rope', label: 'Ayun'),
    ],
  ),
  LevelDefinition(
    name: 'Human Logging Camp', subtitle: 'Area Penebangan Pohon', background: 'AREA_09_BG',
    platform: 'INDUSTRIAL_PLATFORM_TILES', palette: [Color(0xffc5c9bd), Color(0xff607f7f), Color(0xff744b3b)],
    tip: 'Aksi pada kait untuk zipline. Putar derek agar gelondongan menjadi tangga.', objective: 'Aktifkan derek utama',
    hazards: [HazardDef(350, 1340, 85, 60, 'saw'), HazardDef(360, 800, 75, 55, 'saw')],
    zones: [RectDef(170, 520, 440, 45, 'zipline')],
    interactions: [
      InteractionDef(id: 'zip-8', type: 'zipline', x: 180, y: 540, atlas: 'ZONE_THREE_OBJECTS', frame: 'zip_hook', label: 'Kaitkan cakar'),
      InteractionDef(id: 'crane-8', type: 'crane', x: 525, y: 995, atlas: 'ZONE_THREE_OBJECTS', frame: 'crane_lever', label: 'Tarik derek'),
    ],
  ),
  LevelDefinition(
    name: 'Ancient Baobab', subtitle: 'Pohon Purba Sang Predator', background: 'AREA_10_BG',
    platform: 'BAOBAB_PLATFORM_TILES', palette: [Color(0xffe4d59c), Color(0xff9d7543), Color(0xff4e382d)],
    tip: 'Aktifkan empat pengunci, lalu buka sangkar Joey sebelum elang menyambar.', objective: 'Buka 4 pengunci sangkar',
    interactions: [
      InteractionDef(id: 'lock-9-sling', type: 'lock', x: 165, y: 1170, atlas: 'FINAL_OBJECTS', frame: 'slingshot_lock', label: 'Slingshot', ability: 'gumnut'),
      InteractionDef(id: 'lock-9-thermal', type: 'lock', x: 525, y: 995, atlas: 'FINAL_OBJECTS', frame: 'thermal_lock', label: 'Thermal', ability: 'glide'),
      InteractionDef(id: 'lock-9-slam', type: 'lock', x: 215, y: 820, atlas: 'FINAL_OBJECTS', frame: 'slam_lock', label: 'Body Slam', ability: 'slam'),
      InteractionDef(id: 'lock-9-zip', type: 'lock', x: 535, y: 645, atlas: 'FINAL_OBJECTS', frame: 'zipline_lock', label: 'Zipline', ability: 'zipline'),
      InteractionDef(id: 'cage-9', type: 'cage', x: 585, y: 235, atlas: 'FINAL_OBJECTS', frame: 'twig_cage', label: 'Bebaskan Joey'),
    ],
    npcs: [
      NpcDef(type: 'eagle', x: 500, y: 440, sheet: 'EAGLE_SHEET', anim: 'circle', minX: 90, maxX: 650, speed: 135),
      NpcDef(type: 'joey', x: 585, y: 245, sheet: 'JOEY_SHEET', anim: 'captive_idle'),
    ],
  ),
  LevelDefinition(
    name: 'Bamboo Billabong', subtitle: 'Rawa Bambu Bergema', background: 'AREA_11_BG',
    platform: 'EUCALYPTUS_PLATFORM_TILES',
    palette: [Color(0xffcbd9a6), Color(0xff4d856d), Color(0xff315a4c)],
    tip: 'Panjat batang bambu, pukul gong, dan hindari lemparan biji kookaburra.', objective: 'Aktifkan gong bambu',
    hazards: [HazardDef(265, 1360, 180, 90, 'water')],    interactions: [InteractionDef(id: 'core-10', type: 'frontierPuzzle', x: 165, y: 1170, atlas: 'FRONTIER_PUZZLES_C', frame: 'bamboo_gong', label: 'Pukul gong', kind: 'bambooGong')],
    npcs: [NpcDef(type: 'kookaburra', x: 510, y: 950, sheet: 'KOOKABURRA_ENEMY_SHEET', anim: 'fly', minX: 410, maxX: 660, speed: 105, health: 2, flying: true)],
  ),
  LevelDefinition(
    name: 'Mangrove Tides', subtitle: 'Pasang Surut Bakau', background: 'AREA_12_BG',
    platform: 'ROOT_PLATFORM_TILES',
    palette: [Color(0xffb8d7c5), Color(0xff4a7c70), Color(0xff5f4b38)],
    tip: 'Putar roda pasang, lompat di gelondongan, dan jangan berada di jalur lunge buaya.', objective: 'Balikkan pasang mangrove',
    hazards: [HazardDef(240, 1350, 250, 100, 'water')],    interactions: [InteractionDef(id: 'core-11', type: 'frontierPuzzle', x: 520, y: 995, atlas: 'FRONTIER_PUZZLES_C', frame: 'mangrove_tide_wheel', label: 'Putar pasang', kind: 'tideWheel')],
    npcs: [NpcDef(type: 'crocodile', x: 475, y: 1320, sheet: 'CROCODILE_ENEMY_SHEET', anim: 'swim', minX: 270, maxX: 630, speed: 72, health: 3)],
  ),
  LevelDefinition(
    name: 'Moon Gum Marsh', subtitle: 'Rawa Gum Bulan', background: 'AREA_13_BG',
    platform: 'ROOT_PLATFORM_TILES',
    palette: [Color(0xffb9bdd7), Color(0xff5b5d88), Color(0xff282f58)],
    tip: 'Gunakan gelembung sebagai pijakan sesaat dan lempar Gumnut untuk memecahkannya.', objective: 'Nyalakan lentera pollen',
    zones: [RectDef(470, 570, 125, 620, 'updraft')],    interactions: [InteractionDef(id: 'core-12', type: 'frontierPuzzle', x: 170, y: 1170, atlas: 'FRONTIER_PUZZLES_C', frame: 'moon_pollen_lantern', label: 'Nyalakan pollen', kind: 'moonLantern')],
    npcs: [NpcDef(type: 'toad', x: 520, y: 995, sheet: 'TOAD_ENEMY_SHEET', anim: 'hop', minX: 425, maxX: 660, speed: 58, health: 2)],
  ),
  LevelDefinition(
    name: 'Redstone Gorge', subtitle: 'Ngarai Batu Merah', background: 'AREA_14_BG',
    platform: 'EARTH_PLATFORM_TILES',
    palette: [Color(0xffe1b276), Color(0xffa34f35), Color(0xff633326)],
    tip: 'Aktifkan bobot ngarai, berlindung dari kerikil, lalu lompat di sela batang sempit.', objective: 'Seimbangkan counterweight',
    hazards: [HazardDef(320, 1348, 85, 45, 'fire')],    interactions: [InteractionDef(id: 'core-13', type: 'frontierPuzzle', x: 520, y: 995, atlas: 'FRONTIER_PUZZLES_C', frame: 'gorge_counterweight', label: 'Tarik bobot', kind: 'gorgeWeight')],
    npcs: [NpcDef(type: 'goanna', x: 510, y: 1170, sheet: 'GOANNA_ENEMY_SHEET', anim: 'crawl', minX: 410, maxX: 665, speed: 85, health: 3)],
  ),
  LevelDefinition(
    name: 'Honey Ant Citadel', subtitle: 'Benteng Semut Madu', background: 'AREA_15_BG',
    platform: 'EARTH_PLATFORM_TILES',
    palette: [Color(0xffe2c079), Color(0xffa76035), Color(0xff63372d)],
    tip: 'Pantulkan aroma pada garpu resin untuk mengubah jalur patroli sentinel.', objective: 'Selaraskan garpu aroma',
    interactions: [InteractionDef(id: 'core-14', type: 'frontierPuzzle', x: 170, y: 1170, atlas: 'FRONTIER_PUZZLES_C', frame: 'honey_scent_fork', label: 'Getarkan resin', kind: 'honeyFork')],
    npcs: [NpcDef(type: 'antSentinel', x: 520, y: 995, sheet: 'ANT_SENTINEL_SHEET', anim: 'march', minX: 420, maxX: 660, speed: 78, health: 3)],
  ),
  LevelDefinition(
    name: 'Ghost Fern Observatory', subtitle: 'Observatorium Pakis Gaib', background: 'AREA_16_BG',
    platform: 'ROOT_PLATFORM_TILES',
    palette: [Color(0xff9cc8c1), Color(0xff3d7080), Color(0xff263858)],
    tip: 'Arahkan cermin pakis untuk memantulkan gema dan membuka teleskop akar.', objective: 'Sejajarkan cermin pakis',
    interactions: [InteractionDef(id: 'core-15', type: 'frontierPuzzle', x: 520, y: 995, atlas: 'FRONTIER_PUZZLES_D', frame: 'fern_mirror', label: 'Putar cermin', kind: 'fernMirror')],
    npcs: [NpcDef(type: 'fernBat', x: 510, y: 780, sheet: 'FERN_BAT_SHEET', anim: 'fly', minX: 390, maxX: 650, speed: 92, health: 2, flying: true)],
  ),
  LevelDefinition(
    name: 'Magpie Rail Trestle', subtitle: 'Jembatan Rel Murai', background: 'AREA_17_BG',
    platform: 'INDUSTRIAL_PLATFORM_TILES',
    palette: [Color(0xffc2ccd0), Color(0xff677985), Color(0xff514136)],
    tip: 'Ubah sinyal rel sebelum magpie menyambar; gunakan batang panjat sebagai perlindungan.', objective: 'Aktifkan sinyal rel',
    zones: [RectDef(180, 540, 430, 45, 'zipline')],    interactions: [InteractionDef(id: 'core-16', type: 'frontierPuzzle', x: 520, y: 995, atlas: 'FRONTIER_PUZZLES_D', frame: 'rail_signal', label: 'Ubah sinyal', kind: 'railSignal')],
    npcs: [NpcDef(type: 'magpie', x: 510, y: 720, sheet: 'MAGPIE_ENEMY_SHEET', anim: 'swoop', minX: 390, maxX: 655, speed: 120, health: 2, flying: true)],
  ),
  LevelDefinition(
    name: 'Ironbark Machine Ruins', subtitle: 'Reruntuhan Mesin Ironbark', background: 'AREA_18_BG',
    platform: 'INDUSTRIAL_PLATFORM_TILES',
    palette: [Color(0xffaebfae), Color(0xff477b75), Color(0xff6f3f32)],
    tip: 'Lempar Gumnut ke magnet untuk membelokkan gear drone dan mematikan saw lock.', objective: 'Aktifkan magnet Ironbark',
    hazards: [HazardDef(325, 1335, 90, 65, 'saw')],    interactions: [InteractionDef(id: 'core-17', type: 'frontierPuzzle', x: 170, y: 1170, atlas: 'FRONTIER_PUZZLES_D', frame: 'ironbark_magnet', label: 'Aktifkan magnet', kind: 'ironMagnet')],
    npcs: [NpcDef(type: 'drone', x: 515, y: 850, sheet: 'DRONE_ENEMY_SHEET', anim: 'hover', minX: 380, maxX: 660, speed: 90, health: 3, flying: true)],
  ),
  LevelDefinition(
    name: 'Skyflower Sanctuary', subtitle: 'Suaka Bunga Langit', background: 'AREA_19_BG',
    platform: 'BAOBAB_PLATFORM_TILES',
    palette: [Color(0xffd7d2e3), Color(0xff8b75a6), Color(0xff447f79)],
    tip: 'Putar prisma bunga saat angin moth reda, lalu glide di antara batang tinggi.', objective: 'Buka prisma Skyflower',
    zones: [RectDef(130, 240, 540, 1050, 'wind')],    interactions: [InteractionDef(id: 'core-18', type: 'frontierPuzzle', x: 520, y: 995, atlas: 'FRONTIER_PUZZLES_D', frame: 'skyflower_prism', label: 'Putar prisma', kind: 'flowerPrism')],
    npcs: [NpcDef(type: 'moth', x: 510, y: 720, sheet: 'MOTH_ENEMY_SHEET', anim: 'fly', minX: 370, maxX: 655, speed: 85, health: 3, flying: true)],
  ),
  LevelDefinition(
    name: 'Stormheart Crown', subtitle: 'Mahkota Jantung Badai', background: 'AREA_20_BG',
    platform: 'BAOBAB_PLATFORM_TILES',
    palette: [Color(0xffaabed0), Color(0xff405b79), Color(0xff392f35)],
    tip: 'Lempar buah keras, hindari tendangan Raja Kasuari, dan berpindah antar batang saat ia berlari.', objective: 'Kalahkan Raja Kasuari',
    zones: [RectDef(90, 170, 590, 1120, 'wind')],
    interactions: [InteractionDef(id: 'core-19', type: 'frontierPuzzle', x: 165, y: 1170, atlas: 'FRONTIER_PUZZLES_D', frame: 'storm_fruit_launcher', label: 'Isi pelontar buah', kind: 'stormLauncher')],
    npcs: [NpcDef(type: 'cassowary', x: 510, y: 1380, sheet: 'CASSOWARY_BOSS_SHEET', anim: 'idle', minX: 120, maxX: 640, speed: 145, health: 6, boss: true)],
  ),
];
const extraPuzzles = <List<PuzzleDef>>[
  [PuzzleDef('branchChain', 'Rantai slingshot', 'EXPANDED_PUZZLES_A', 'branch_chain_switch'), PuzzleDef('seedCrown', 'Kebun kanopi', 'EXPANDED_PUZZLES_A', 'seed_crown_bed')],
  [PuzzleDef('sapBlock', 'Sumbat getah', 'EXPANDED_PUZZLES_A', 'sap_block_cradle'), PuzzleDef('shadowBell', 'Bunyikan rongga', 'EXPANDED_PUZZLES_A', 'owl_shadow_chime', requirement: 'scent')],
  [PuzzleDef('floodGate', 'Naikkan air', 'EXPANDED_PUZZLES_A', 'flood_gate_wheel'), PuzzleDef('leafDock', 'Tambatkan daun', 'EXPANDED_PUZZLES_A', 'leaf_dock_cleat', requirement: 'row')],
  [PuzzleDef('smokeDamper', 'Tutup cerobong asap', 'EXPANDED_PUZZLES_A', 'smoke_damper'), PuzzleDef('thermalSpire', 'Nyalakan thermal', 'EXPANDED_PUZZLES_A', 'thermal_spire', requirement: 'glide')],
  [PuzzleDef('shroomChain', 'Isi lentera jamur', 'EXPANDED_PUZZLES_A', 'shroom_lantern'), PuzzleDef('prismEcho', 'Selaraskan prisma', 'EXPANDED_PUZZLES_A', 'prism_echo', requirement: 'echo')],
  [PuzzleDef('waterFruit', 'Pecahkan buah air', 'EXPANDED_PUZZLES_B', 'water_fruit_press'), PuzzleDef('cocoonLift', 'Turunkan lift kepompong', 'EXPANDED_PUZZLES_B', 'cocoon_lift', requirement: 'web')],
  [PuzzleDef('termiteSwitch', 'Pancing barisan rayap', 'EXPANDED_PUZZLES_B', 'termite_scent_beacon'), PuzzleDef('spireBreak', 'Runtuhkan dinding menara', 'EXPANDED_PUZZLES_B', 'spire_break_seal', requirement: 'slam')],
  [PuzzleDef('stormShelter', 'Kunci pelindung angin', 'EXPANDED_PUZZLES_B', 'storm_shelter_latch', requirement: 'heavy'), PuzzleDef('vineAnchor', 'Ikat akar ayun', 'EXPANDED_PUZZLES_B', 'vine_anchor')],
  [PuzzleDef('cableSwitch', 'Pindahkan jalur kabel', 'EXPANDED_PUZZLES_B', 'cable_switch', requirement: 'zipline'), PuzzleDef('conveyorBrake', 'Matikan rem konveyor', 'EXPANDED_PUZZLES_B', 'conveyor_brake')],
  [PuzzleDef('rootSeal', 'Pecahkan segel akar', 'EXPANDED_PUZZLES_B', 'root_slam_seal', requirement: 'slam'), PuzzleDef('eagleBell', 'Bunyikan penanda sarang', 'EXPANDED_PUZZLES_B', 'eagle_nest_bell')],
  [PuzzleDef('bambooGong', 'Gong bambu tengah', 'FRONTIER_PUZZLES_C', 'bamboo_gong'), PuzzleDef('reedValve', 'Katup buluh', 'FRONTIER_PUZZLES_C', 'reed_valve')],
  [PuzzleDef('tideWheel', 'Roda pasang tengah', 'FRONTIER_PUZZLES_C', 'mangrove_tide_wheel'), PuzzleDef('logAnchor', 'Jangkar gelondongan', 'FRONTIER_PUZZLES_C', 'floating_log_anchor')],
  [PuzzleDef('moonLantern', 'Lentera pollen kedua', 'FRONTIER_PUZZLES_C', 'moon_pollen_lantern'), PuzzleDef('bubbleReed', 'Buluh gelembung', 'FRONTIER_PUZZLES_C', 'bubble_reed')],
  [PuzzleDef('gorgeWeight', 'Bobot ngarai tengah', 'FRONTIER_PUZZLES_C', 'gorge_counterweight'), PuzzleDef('pebbleTarget', 'Target kerikil', 'FRONTIER_PUZZLES_C', 'pebble_target')],
  [PuzzleDef('honeyFork', 'Garpu aroma kedua', 'FRONTIER_PUZZLES_C', 'honey_scent_fork'), PuzzleDef('antBridge', 'Tuas jembatan semut', 'FRONTIER_PUZZLES_C', 'ant_bridge_lever')],
  [PuzzleDef('fernMirror', 'Cermin pakis tengah', 'FRONTIER_PUZZLES_D', 'fern_mirror'), PuzzleDef('echoTelescope', 'Teleskop gema', 'FRONTIER_PUZZLES_D', 'echo_telescope', requirement: 'echo')],
  [PuzzleDef('railSignal', 'Sinyal rel tengah', 'FRONTIER_PUZZLES_D', 'rail_signal'), PuzzleDef('cableShield', 'Pelindung kabel', 'FRONTIER_PUZZLES_D', 'cable_shield', requirement: 'zipline')],
  [PuzzleDef('ironMagnet', 'Magnet akar', 'FRONTIER_PUZZLES_D', 'ironbark_magnet'), PuzzleDef('sawLock', 'Kunci gergaji', 'FRONTIER_PUZZLES_D', 'saw_lock')],
  [PuzzleDef('flowerPrism', 'Prisma bunga tengah', 'FRONTIER_PUZZLES_D', 'skyflower_prism'), PuzzleDef('mothVane', 'Penunjuk angin moth', 'FRONTIER_PUZZLES_D', 'moth_wind_vane')],
  [PuzzleDef('stormLauncher', 'Pelontar buah kedua', 'FRONTIER_PUZZLES_D', 'storm_fruit_launcher'), PuzzleDef('arenaSeal', 'Segel arena kasuari', 'FRONTIER_PUZZLES_D', 'cassowary_arena_seal')],
];
const upgradeByArea = <String>[
  'gumnut', 'bark', 'row', 'glide', 'echo', 'web', 'slam', 'weight', 'zipline',
  'rescue', 'throw', 'tide', 'bubble', 'counterweight', 'resin', 'mirror', 'rail',
  'magnet', 'pollen', 'stormfruit',
];
const skinNames = <String>[
  'Mima Klasik', 'Embun Bulan', 'Penjaga Bara', 'Arus Kabut', 'Akar Kristal',
  'Sutra Kanopi', 'Terra Rayap', 'Puncak Badai', 'Penyelamat Kamp', 'Emas Baobab',
];
