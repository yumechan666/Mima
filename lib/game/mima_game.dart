import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flame/flame.dart';
import 'package:flame/game.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'game_data.dart';
import 'audio_manager.dart';

class GameHudState {
  const GameHudState({
    this.loading = true,
    this.ready = false,
    this.paused = true,
    this.mainMenu = false,
    this.skinMenu = false,
    this.areaMenu = false,
    this.victory = false,
    this.frontierVictory = false,
    this.busy = false,
    this.area = 0,
    this.areaName = '',
    this.chapter = '',
    this.hearts = 3,
    this.leaves = 0,
    this.clues = 0,
    this.carvings = 0,
    this.objective = '',
    this.prompt = '',
    this.toast = '',
    this.toastTone = 'normal',
    this.bossHealth = 0,
    this.bossMaxHealth = 1,
    this.skinIndex = 0,
    this.error = '',
  });

  final bool loading;
  final bool ready;
  final bool paused;
  final bool mainMenu;
  final bool skinMenu;
  final bool areaMenu;
  final bool victory;
  final bool frontierVictory;
  final bool busy;
  final int area;
  final String areaName;
  final String chapter;
  final int hearts;
  final int leaves;
  final int clues;
  final int carvings;
  final String objective;
  final String prompt;
  final String toast;
  final String toastTone;
  final int bossHealth;
  final int bossMaxHealth;
  final int skinIndex;
  final String error;
}

class _Player {
  _Player(this.x, this.y);
  double x;
  double y;
  double vx = 0;
  double vy = 0;
  double width = 46;
  double height = 76;
  double facing = 1;
  bool grounded = false;
  bool climbing = false;
  bool circling = false;
  bool gliding = false;
  bool bodySlamming = false;
  bool heavy = false;
  double attachedZip = 0;
  double stickyUntil = 0;
  double slidingUntil = 0;
  double rowingUntil = 0;
  double bouncingUntil = 0;
  double invulnerableUntil = 0;
  double dropThroughUntil = 0;
  double dropThroughY = 0;
  String? animOverrideKey;
  String? animOverride;
  double animOverrideUntil = 0;
}

class _Platform {
  _Platform({
    required this.x,
    required this.y,
    required this.w,
    required this.type,
    this.vx = 0,
    this.minX,
    this.maxX,
    this.active = true,
    this.grown = false,
    this.id,
  });

  double x;
  double y;
  final double w;
  final String type;
  double vx;
  double? minX;
  double? maxX;
  bool active;
  bool grown;
  bool broken = false;
  double breakAt = 0;
  final String? id;
}

class _Npc {
  _Npc(NpcDef def, double yOffset)
    : type = def.type,
      x = def.x,
      y = def.y + yOffset,
      homeY = def.y + yOffset,
      sheet = def.sheet,
      anim = def.anim,
      baseAnim = def.anim,
      minX = def.minX,
      maxX = def.maxX,
      speed = def.speed,
      health = def.health,
      maxHealth = def.health,
      flying = def.flying,
      boss = def.boss;

  final String type;
  final String sheet;
  final String baseAnim;
  final double? minX;
  final double? maxX;
  final int maxHealth;
  final bool flying;
  final bool boss;
  double x;
  double y;
  double homeY;
  double speed;
  int health;
  double facing = 1;
  double distractedUntil = 0;
  double hitUntil = 0;
  double nextAttack = 0;
  double attackUntil = 0;
  String anim;
  bool hidden = false;
}

class _Projectile {
  _Projectile({
    required this.x,
    required this.y,
    required this.vx,
    required this.vy,
    required this.owner,
    required this.visual,
  });
  double x;
  double y;
  double vx;
  double vy;
  double life = 2.4;
  final String owner;
  final String visual;
}

class _Effect {
  _Effect(
    this.key,
    this.animation,
    this.x,
    this.y,
    this.startedAt,
    this.duration,
    this.size,
  );
  final String key;
  final String animation;
  final double x;
  final double y;
  final double startedAt;
  final double duration;
  final double size;
}

class _AtlasFrame {
  _AtlasFrame(Map<String, dynamic> source)
    : source = _parseRect(source['source']),
      content = _parseRect(source['content']),
      anchor = _parsePoint(source['anchor']),
      surfaceY = (source['surfaceY'] as num?)?.toDouble(),
      empty = source['empty'] == true;

  final ui.Rect? source;
  final ui.Rect? content;
  final ui.Offset? anchor;
  final double? surfaceY;
  final bool empty;

  static ui.Rect? _parseRect(dynamic value) {
    if (value is! Map) return null;
    final data = Map<String, dynamic>.from(value);
    return ui.Rect.fromLTWH(
      (data['x'] as num? ?? 0).toDouble(),
      (data['y'] as num? ?? 0).toDouble(),
      (data['w'] as num? ?? 0).toDouble(),
      (data['h'] as num? ?? 0).toDouble(),
    );
  }

  static ui.Offset? _parsePoint(dynamic value) {
    if (value is! Map) return null;
    final data = Map<String, dynamic>.from(value);
    return ui.Offset(
      (data['x'] as num? ?? 0).toDouble(),
      (data['y'] as num? ?? 0).toDouble(),
    );
  }
}

class _Atlas {
  _Atlas(Map<String, dynamic> json) {
    final rawFrames = json['frames'];
    if (rawFrames is List) {
      for (final value in rawFrames) {
        if (value is Map) {
          final data = Map<String, dynamic>.from(value);
          frames[data['name'] as String? ?? ''] = _AtlasFrame(data);
        }
      }
    }
    final rawAnimations = json['animations'];
    if (rawAnimations is List) {
      for (final value in rawAnimations) {
        if (value is Map) {
          final data = Map<String, dynamic>.from(value);
          final name = data['name'] as String? ?? '';
          final raw = data['frames'];
          if (raw is List) {
            final list = <_AtlasFrame>[];
            for (final entry in raw) {
              if (entry is Map) {
                list.add(_AtlasFrame(Map<String, dynamic>.from(entry)));
              }
            }
            animations[name] = list;
          }
        }
      }
    }
  }

  final Map<String, _AtlasFrame> frames = {};
  final Map<String, List<_AtlasFrame>> animations = {};
}

class MimaGame extends FlameGame {
  MimaGame() {
    hud = ValueNotifier(const GameHudState());
  }

  late final ValueNotifier<GameHudState> hud;

  final Set<String> leaves = {};
  final Set<String> clues = {};
  final Set<String> carvings = {};
  final Set<String> actions = {};
  final Set<String> abilities = {'scent', 'gumnut'};
  final Map<String, String> _assetPaths = {};
  final Map<String, _Atlas> _atlases = {};
  final Set<String> _loadedImages = {};
  final Map<String, Future<void>> _loadingImages = {};
  final List<_Effect> _effects = [];
  final List<_Projectile> _projectiles = [];
  final math.Random _random = math.Random();

  late SharedPreferences _preferences;
  // The renderer and simulation are private implementation details of this game.
  // ignore: library_private_types_in_public_api
  late _Player player;
  late LevelDefinition level;
  // ignore: library_private_types_in_public_api
  late List<_Platform> platforms;
  late List<InteractionDef> interactions;
  // ignore: library_private_types_in_public_api
  late List<_Npc> npcs;
  late List<RectDef> climbables;
  late List<RectDef> zones;
  late List<HazardDef> hazards;
  late List<({String id, double x, double y})> levelLeaves;

  int areaIndex = 0;
  int checkpointSection = 0;
  int hearts = 3;
  int skinIndex = 0;
  int bestScore = 0;
  int maxAreaUnlocked = levelDefinitions.length - 1;
  bool rescued = false;
  bool gamePaused = true;
  bool mainMenu = false;
  bool skinMenu = false;
  bool areaMenu = false;
  bool victory = false;
  bool frontierVictory = false;
  bool heavy = false;
  bool loading = true;
  bool _busy = false;
  bool _loaded = false;
  bool _startupReady = false;
  bool _returnToMenu = false;
  Future<void>? _startupLoad;
  bool _areaSolved = false;
  bool _initialSkinPick = true;
  bool _jumpHeld = false;
  bool _jumpPressed = false;
  bool _actionPressed = false;
  bool _scentPressed = false;
  bool _scentActive = false;
  double moveX = 0;
  double moveY = 0;
  double _elapsed = 0;
  double _cameraY = 0;
  double _scentUntil = 0;
  double _nextHudAt = 0;
  double _flash = 0;
  double _shake = 0;
  double _lastThrowAt = -10;
  double _toastUntil = 0;
  InteractionDef? _nearest;
  String _toast = '';
  String _toastTone = 'normal';
  String _animOverrideKey = '';
  String _animOverride = '';
  double _animOverrideUntil = 0;
  int _skinLoadRequest = 0;
  bool _allSkinsPreloaded = false;
  int _skinPreloadToken = 0;

  static const _saveKey = 'mima_game_save_v2';
  static const _basePlatforms = <(double, double, double, String)>[
    (0, 1380, 720, 'ground'),
    (26, 1205, 220, 'normal'),
    (405, 1030, 270, 'normal'),
    (126, 855, 230, 'normal'),
    (420, 680, 245, 'normal'),
    (55, 505, 235, 'normal'),
    (350, 325, 255, 'normal'),
    (555, 170, 155, 'normal'),
  ];

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    await AudioManager.instance.init();
    try {
      final manifest =
          jsonDecode(
                await rootBundle.loadString('assets/json/assets_manifest.json'),
              )
              as Map<String, dynamic>;
      for (final entry in manifest.entries) {
        if (entry.value is String) {
          _assetPaths[entry.key] = (entry.value as String).split('/').last;
        }
      }
      _preferences = await SharedPreferences.getInstance();
      _restoreSave(_preferences.getString(_saveKey));
      _buildLevel(areaIndex, resetPlayer: true);
      maxAreaUnlocked = math.max(maxAreaUnlocked, areaIndex);
      // Muat seluruh aset gameplay area awal (background, objek zona, efek, NPC,
      // interaksi, dan skin tersimpan) sebelum menutup layar loading, supaya
      // tidak ada jeda/stutter saat pertama kali mulai bermain.
      await _loadStartupAssets();
      await _finishStartupAssets();
      loading = false;
      _loaded = true;
      mainMenu = true;
      _publishHud(force: true);
    } catch (error) {
      loading = false;
      hud.value = GameHudState(
        loading: false,
        error: 'Aset game gagal dimuat: $error',
      );
    }
  }

  void _restoreSave(String? value) {
    if (value == null) return;
    try {
      final data = jsonDecode(value) as Map<String, dynamic>;
      areaIndex = ((data['area'] as num?)?.toInt() ?? 0).clamp(
        0,
        levelDefinitions.length - 1,
      );
      maxAreaUnlocked = levelDefinitions.length - 1;
      for (final pair in <(String, Set<String>)>[
        ('leaves', leaves),
        ('clues', clues),
        ('carvings', carvings),
        ('actions', actions),
      ]) {
        final list = data[pair.$1];
        if (list is List) pair.$2.addAll(list.whereType<String>());
      }
      final savedAbilities = data['abilities'];
      if (savedAbilities is List) {
        abilities.addAll(savedAbilities.whereType<String>());
      }
      rescued = data['rescued'] == true;
      hearts = ((data['hearts'] as num?)?.toInt() ?? 3).clamp(1, 3);
      bestScore = (data['bestScore'] as num?)?.toInt() ?? 0;
      skinIndex = ((data['skinIndex'] as num?)?.toInt() ?? 0).clamp(
        0,
        skinNames.length - 1,
      );
      checkpointSection = ((data['checkpointSection'] as num?)?.toInt() ?? 0)
          .clamp(0, 2);
    } catch (_) {
      // Ignore corrupt local saves and start a fresh trail.
    }
  }

  Future<void> _save() async {
    if (!_loaded) return;
    final data = <String, Object>{
      'version': 2,
      'area': areaIndex,
      'maxAreaUnlocked': maxAreaUnlocked,
      'leaves': leaves.toList(),
      'clues': clues.toList(),
      'carvings': carvings.toList(),
      'actions': actions.toList(),
      'abilities': abilities.toList(),
      'rescued': rescued,
      'hearts': hearts,
      'bestScore': bestScore,
      'skinIndex': skinIndex,
      'checkpointSection': checkpointSection,
    };
    try {
      await _preferences.setString(_saveKey, jsonEncode(data));
    } catch (_) {
      // Progress saving is optional if the platform storage is unavailable.
    }
  }

  Future<void> _loadPlayerSkin(int index) async {
    final keys = _skinAssetKeys(index);
    for (var attempt = 0; attempt < 2; attempt++) {
      for (final key in keys) {
        await _loadAssetKey(key);
      }
      if (_skinReady(index)) return;
    }
  }

  bool _skinReady(int index) {
    if (index == 0) return true;
    final prefix = 'skin_${(index + 1).toString().padLeft(2, '0')}';
    const slots = <String>[
      'basic',
      'air',
      'tree',
      'traversal_one',
      'traversal_two',
      'abilities',
      'conditions',
      'interactions',
    ];
    for (final slot in slots) {
      if (!_loadedImages.contains('${prefix}_$slot-transparent.webp')) return false;
    }
    return true;
  }

  // Muat semua skin saat menu skin terbuka (game sedang paused) agar memilih
  // skin tidak memicu decode berat di thread utama saat sedang bermain.
  Future<void> _preloadAllSkins() async {
    if (_allSkinsPreloaded) return;
    final token = _skinPreloadToken;
    for (var i = 0; i < skinNames.length; i++) {
      if (token != _skinPreloadToken) return;
      if (_skinReady(i)) continue;
      for (final key in _skinAssetKeys(i)) {
        await _loadAssetKey(key);
        if (token != _skinPreloadToken) return;
        // Beri jeda agar UI/menu tetap responsif.
        await Future<void>.delayed(const Duration(milliseconds: 12));
      }
    }
    _allSkinsPreloaded = true;
  }

  List<String> _skinAssetKeys(int index) {
    if (index == 0) {
      return const [
        'MIMA_BASIC_SHEET',
        'MIMA_AIR_SHEET',
        'MIMA_TREE_SHEET',
        'MIMA_TRAVERSAL_ONE_SHEET',
        'MIMA_TRAVERSAL_TWO_SHEET',
        'MIMA_ABILITIES_SHEET',
        'MIMA_CONDITIONS_SHEET',
        'MIMA_INTERACTIONS_SHEET',
      ];
    }
    final prefix = 'SKIN_${(index + 1).toString().padLeft(2, '0')}';
    return [
      '${prefix}_BASIC',
      '${prefix}_AIR',
      '${prefix}_TREE',
      '${prefix}_TRAVERSAL_ONE',
      '${prefix}_TRAVERSAL_TWO',
      '${prefix}_ABILITIES',
      '${prefix}_CONDITIONS',
      '${prefix}_INTERACTIONS',
    ];
  }

  String _skinKey(String baseKey) {
    if (skinIndex == 0 || !baseKey.startsWith('MIMA_')) return baseKey;
    final slot = switch (baseKey) {
      'MIMA_BASIC_SHEET' => 'BASIC',
      'MIMA_AIR_SHEET' => 'AIR',
      'MIMA_TREE_SHEET' => 'TREE',
      'MIMA_TRAVERSAL_ONE_SHEET' => 'TRAVERSAL_ONE',
      'MIMA_TRAVERSAL_TWO_SHEET' => 'TRAVERSAL_TWO',
      'MIMA_ABILITIES_SHEET' => 'ABILITIES',
      'MIMA_CONDITIONS_SHEET' => 'CONDITIONS',
      'MIMA_INTERACTIONS_SHEET' => 'INTERACTIONS',
      _ => '',
    };
    return slot.isEmpty
        ? baseKey
        : 'SKIN_${(skinIndex + 1).toString().padLeft(2, '0')}_$slot';
  }

  Future<void> selectSkin(int index) async {
    if (index < 0 || index >= skinNames.length) return;
    if (index == skinIndex && !_initialSkinPick) {
      skinMenu = false;
      _skinPreloadToken += 1;
      gamePaused = false;
      AudioManager.instance.playBgm('bgm');
      _publishHud(force: true);
      return;
    }
    final request = ++_skinLoadRequest;
    final isInitialPick = _initialSkinPick;
    final previousIndex = skinIndex;
    gamePaused = true;
    skinMenu = true;
    skinIndex = index;
    _initialSkinPick = false;
    _busy = true;
    _publishHud(force: true);
    await _loadPlayerSkin(index);
    if (request != _skinLoadRequest) {
      // Permintaan ini dibatalkan aksi lain (mis. menutup menu skin sebelum
      // load selesai). Lepas status busy agar overlay loading tidak macet.
      _busy = false;
      _publishHud(force: true);
      return;
    }
    if (!_skinReady(index)) {
      skinIndex = previousIndex;
      await _loadPlayerSkin(previousIndex);
      _busy = false;
      _showToast('Skin gagal dimuat · pakai ${skinNames[skinIndex]}');
      _publishHud(force: true);
      return;
    }
    _busy = false;
    if (!isInitialPick) {
      skinMenu = false;
      _skinPreloadToken += 1;
      gamePaused = false;
      AudioManager.instance.playBgm('bgm');
    }
    AudioManager.instance.playSfx('skin_select');
    _showToast('${skinNames[index]} aktif · seluruh frame gerak diganti');
    await _save();
    _publishHud(force: true);
  }

  Future<void> _loadCurrentAssets() async {
    final keys = <String>{
      level.background,
      level.platform,
      'ZONE_ONE_OBJECTS',
      'ZONE_TWO_OBJECTS',
      'ZONE_THREE_OBJECTS',
      'FINAL_OBJECTS',
      'TRAIL_EFFECTS_SHEET',
      'IMPACT_EFFECTS_SHEET',
      'HAZARD_EFFECTS_SHEET',
      'FIRE_WIND_EFFECTS_SHEET',
      'CAVE_EFFECTS_SHEET',
      'WATER_WEB_EFFECTS_SHEET',
      'UI_ICON_ATLAS',
      ...interactions.map((item) => item.atlas),
      ...npcs.map((npc) => npc.sheet),
    };
    await Future.wait(keys.map(_loadAssetKey));
  }

  // Aset krusial agar frame pertama dan menu skin bisa tampil secepat mungkin.
  Future<void> _loadStartupAssets() async {
    final keys = <String>{
      level.background,
      level.platform,
      'UI_ICON_ATLAS',
      ..._skinAssetKeys(0),
    };
    await Future.wait(keys.map(_loadAssetKey));
  }

  // Sisa aset (objek zona, efek, npc, skin tersimpan) dimuat di background
  // setelah layar loading tertutup, sehingga waktu tunggu awal memendek.
  Future<void> _finishStartupAssets() async {
    if (_startupReady) return;
    _startupLoad ??= Future<void>(() async {
      await _loadCurrentAssets();
      if (skinIndex != 0) {
        await _loadPlayerSkin(skinIndex);
        if (!_skinReady(skinIndex)) {
          skinIndex = 0;
          await _loadPlayerSkin(0);
        }
      }
      _startupReady = true;
    });
    try {
      await _startupLoad;
    } finally {
      _startupReady = true;
      if (_loaded) _publishHud(force: true);
    }
  }

  // Pastikan aset startup lengkap sebelum memulai permainan sungguhan.
  Future<void> _awaitStartupIfNeeded() async {
    if (_startupReady) return;
    _busy = true;
    _publishHud(force: true);
    try {
      await _finishStartupAssets();
    } finally {
      _busy = false;
    }
  }

  Future<void> _loadAssetKey(String key) async {
    final filename = _assetPaths[key];
    if (filename == null) return;
    if (!_atlases.containsKey(key)) {
      final metadataName = filename.replaceFirst(
        RegExp(r'\.(webp|png|jpe?g)$', caseSensitive: false),
        '.frames.json',
      );
      try {
        final text = await rootBundle.loadString('assets/json/$metadataName');
        _atlases[key] = _Atlas(jsonDecode(text) as Map<String, dynamic>);
      } catch (_) {
        // Backgrounds and a small number of unavailable frame manifests use fallbacks.
      }
    }
    if (_loadedImages.contains(filename)) return;
    final existingLoad = _loadingImages[filename];
    if (existingLoad != null) return existingLoad;
    late final Future<void> load;
    load = Future<void>(() async {
      for (var attempt = 0; attempt < 3; attempt++) {
        try {
          if (Flame.images.containsKey(filename)) {
            try {
              final cached = Flame.images.fromCache(filename);
              if (cached.width > 0 && cached.height > 0) {
                _loadedImages.add(filename);
                return;
              }
            } catch (_) {
              Flame.images.clear(filename);
            }
          }
          // Flame resolves a bare name against assets/images/<name> automatically,
          // so loading with the bare filename is correct. A timeout keeps a missing
          // or unresolvable asset from hanging game startup; retry a few times so a
          // slow device under load (e.g. many skins preloading at once) can recover.
          final loaded = await Flame.images
              .load(filename)
              .timeout(const Duration(seconds: 15));
          if (loaded.width <= 0 || loaded.height <= 0) {
            throw StateError('Gambar $filename kosong');
          }
          _loadedImages.add(filename);
          return;
        } catch (_) {
          if (Flame.images.containsKey(filename)) Flame.images.clear(filename);
          // Keep rendering with the per-frame fallback if an asset is unavailable.
        }
      }
    });
    _loadingImages[filename] = load;
    return load;
  }

  void _buildLevel(
    int index, {
    required bool resetPlayer,
    bool fromBack = false,
  }) {
    areaIndex = index.clamp(0, levelDefinitions.length - 1);
    level = levelDefinitions[areaIndex];
    platforms = _makePlatforms(areaIndex);
    interactions = _makeInteractions(areaIndex, level);
    climbables = [];
    zones = _repeatRects(level.zones);
    hazards = _repeatHazards(level.hazards);
    npcs = _makeNpcs(level);
    levelLeaves = [
      (id: 'leaf-$areaIndex-1', x: 142, y: 1150 + sectionHeight * 2),
      (id: 'leaf-$areaIndex-2', x: 522, y: 975 + sectionHeight),
      (id: 'leaf-$areaIndex-3', x: 215, y: 450),
    ];
    abilities.add(upgradeByArea[areaIndex]);
    for (var i = 0; i <= areaIndex; i++) {
      abilities.add(upgradeByArea[i]);
    }
    _projectiles.clear();
    _effects.clear();
    hearts = 3;
    _nearest = null;
    _scentUntil = 0;
    if (resetPlayer || !hasLayout) {
      player = _Player(
        fromBack ? 620 : 92,
        fromBack ? 160 : _checkpointY(checkpointSection),
      );
      _cameraY = 0;
    } else {
      player.x = fromBack ? 620 : 92;
      player.y = fromBack ? 160 : _checkpointY(checkpointSection);
      player.vx = 0;
      player.vy = 0;
      player.grounded = false;
      player.heavy = false;
      player.attachedZip = 0;
      player.climbing = false;
      player.circling = false;
      player.gliding = false;
      player.bodySlamming = false;
      player.stickyUntil = 0;
      player.slidingUntil = 0;
      player.rowingUntil = 0;
      player.bouncingUntil = 0;
    }
    if (hasLayout) {
      final scale = canvasSize.x / worldWidth;
      final viewportHeight = canvasSize.y / scale;
      _cameraY = _clamp(
        player.y - viewportHeight * .56,
        0,
        worldHeight - viewportHeight,
      );
    }
    _areaSolved = _solved();
    _publishHud(force: true);
  }

  double _checkpointY(int section) {
    if (section >= 2) return 1368;
    if (section == 1) return 2818;
    return 4268;
  }

  List<_Platform> _makePlatforms(int index) {
    final result = <_Platform>[];
    for (var section = 0; section < 3; section++) {
      final offset = sectionHeight * (2 - section);
      for (var i = 0; i < _basePlatforms.length; i++) {
        final base = _basePlatforms[i];
        var type = base.$4;
        if (index == 2 && i == 3) type = 'slippery';
        if (index == 3 && i > 1 && i < 6) type = 'crumble';
        if (index == 4 && i == 4) type = 'ghost';
        if (index == 6 && (i == 2 || i == 4)) type = 'cracked';
        if (index == 8 && i == 3) type = 'conveyor';
        final moving = index == 2 && i == 0;
        result.add(
          _Platform(
            x: base.$1,
            y: base.$2 + offset,
            w: base.$3,
            type: type,
            active: type != 'ghost',
            id: type == 'cracked' ? 'pillar-6-$i-section-$section' : null,
            vx: type == 'conveyor' ? 75 : 0,
          ),
        );
        if (moving) {
          result.add(
            _Platform(
              x: 278,
              y: 1190 + offset,
              w: 150,
              type: 'raft',
              vx: 50,
              minX: 250,
              maxX: 430,
            ),
          );
        }
        if (index == 5 && i == 0) {
          result.add(_Platform(x: 255, y: 1120 + offset, w: 210, type: 'web'));
          result.add(_Platform(x: 300, y: 610 + offset, w: 170, type: 'web'));
          if (section == 0) {
            result.add(_Platform(x: 92, y: 4240, w: 180, type: 'normal'));
            result.add(_Platform(x: 300, y: 4190, w: 180, type: 'normal'));
            result.add(_Platform(x: 500, y: 4120, w: 180, type: 'normal'));
            result.add(_Platform(x: 350, y: 4120, w: 190, type: 'normal'));
            result.add(_Platform(x: 560, y: 4000, w: 170, type: 'normal'));
            result.add(_Platform(x: 350, y: 3950, w: 190, type: 'normal'));
            result.add(_Platform(x: 380, y: 3900, w: 180, type: 'normal'));
            result.add(_Platform(x: 230, y: 3800, w: 180, type: 'normal'));
          }
        }
      }
    }
    result.add(
      _Platform(x: 275, y: sectionHeight * 2 + 25, w: 170, type: 'normal'),
    );
    result.add(
      _Platform(x: 275, y: sectionHeight + 25, w: 170, type: 'normal'),
    );
    return result;
  }

  List<InteractionDef> _makeInteractions(int index, LevelDefinition def) {
    final result = <InteractionDef>[];
    for (final item in def.interactions) {
      if (item.type == 'gate' || item.type == 'back') continue;
      var y = item.y + sectionHeight * 2;
      if (index == 9) {
        y = switch (item.id) {
          'lock-9-thermal' => 995 + sectionHeight,
          'lock-9-slam' => 820 + sectionHeight,
          'lock-9-zip' => 645,
          'cage-9' => 235,
          _ => y,
        };
      }
      result.add(_copyInteraction(item, y: y));
    }
    if (index < 9 || (index > 9 && index < levelDefinitions.length - 1)) {
      result.add(
        InteractionDef(
          id: 'gate-$index',
          type: 'gate',
          x: 640,
          y: 126,
          atlas: 'FINAL_OBJECTS',
          frame: 'branch_gate',
          label: index == 8 ? 'Ke Baobab' : 'Naik',
        ),
      );
    }
    if (index > 0) {
      result.add(
        InteractionDef(
          id: 'back-$index',
          type: 'back',
          x: 58,
          y: worldHeight - 125,
          atlas: 'FINAL_OBJECTS',
          frame: 'shortcut_arch',
          label: 'Turun',
        ),
      );
    }
    final puzzles = extraPuzzles[index];
    result.add(
      InteractionDef(
        id: 'puzzle-$index-middle',
        type: 'areaPuzzle',
        x: 520,
        y: 995 + sectionHeight,
        atlas: puzzles[0].atlas,
        frame: puzzles[0].frame,
        label: puzzles[0].label,
        kind: puzzles[0].kind,
        requirement: puzzles[0].requirement,
      ),
    );
    result.add(
      InteractionDef(
        id: 'puzzle-$index-top',
        type: 'areaPuzzle',
        x: 215,
        y: 470,
        atlas: puzzles[1].atlas,
        frame: puzzles[1].frame,
        label: puzzles[1].label,
        kind: puzzles[1].kind,
        requirement: puzzles[1].requirement,
      ),
    );
    return result;
  }

  InteractionDef _copyInteraction(InteractionDef item, {double? y}) =>
      InteractionDef(
        id: item.id,
        type: item.type,
        x: item.x,
        y: y ?? item.y,
        atlas: item.atlas,
        frame: item.frame,
        label: item.label,
        kind: item.kind,
        ability: item.ability,
        requirement: item.requirement,
      );

  List<RectDef> _repeatRects(List<RectDef> input) => [
    for (final offset in <double>[sectionHeight * 2, sectionHeight, 0.0])
      for (final item in input)
        RectDef(item.x, item.y + offset, item.w, item.h, item.type),
  ];

  List<HazardDef> _repeatHazards(List<HazardDef> input) => [
    for (final offset in <double>[sectionHeight * 2, sectionHeight, 0.0])
      for (final item in input)
        HazardDef(item.x, item.y + offset, item.w, item.h, item.type),
  ];

  List<_Npc> _makeNpcs(LevelDefinition def) => [
    for (final npc in def.npcs)
      if (npc.type == 'eagle' || npc.type == 'joey')
        _Npc(npc, 0)
      else
        for (final offset in <double>[sectionHeight * 2, sectionHeight, 0.0])
          _Npc(npc, offset),
  ];

  void setMove(double x, [double y = 0]) {
    moveX = x.clamp(-1, 1);
    moveY = y.clamp(-1, 1);
  }

  void setJumpHeld(bool held) {
    if (held && !_jumpHeld) _jumpPressed = true;
    _jumpHeld = held;
  }

  void triggerJump() => _jumpPressed = true;
  void triggerAction() => _actionPressed = true;
  void triggerScent() => _scentPressed = true;
  void keyDown(LogicalKeyboardKey key, {bool repeat = false}) {
    if (key == LogicalKeyboardKey.arrowLeft || key == LogicalKeyboardKey.keyA) {
      moveX = -1;
    }
    if (key == LogicalKeyboardKey.arrowRight ||
        key == LogicalKeyboardKey.keyD) {
      moveX = 1;
    }
    if (key == LogicalKeyboardKey.arrowUp || key == LogicalKeyboardKey.keyW) {
      moveY = -1;
    }
    if (key == LogicalKeyboardKey.arrowDown || key == LogicalKeyboardKey.keyS) {
      moveY = 1;
    }
    if (key == LogicalKeyboardKey.space || key == LogicalKeyboardKey.arrowUp) {
      setJumpHeld(true);
    }
    if (!repeat &&
        (key == LogicalKeyboardKey.keyE || key == LogicalKeyboardKey.enter)) {
      triggerAction();
    }
    if (!repeat &&
        (key == LogicalKeyboardKey.shiftLeft ||
            key == LogicalKeyboardKey.shiftRight)) {
      triggerScent();
    }
    if (!repeat && key == LogicalKeyboardKey.escape) {
      togglePause();
    }
  }

  void keyUp(LogicalKeyboardKey key, Set<LogicalKeyboardKey> keysPressed) {
    if (key == LogicalKeyboardKey.arrowLeft ||
        key == LogicalKeyboardKey.keyA ||
        key == LogicalKeyboardKey.arrowRight ||
        key == LogicalKeyboardKey.keyD) {
      final left =
          keysPressed.contains(LogicalKeyboardKey.arrowLeft) ||
          keysPressed.contains(LogicalKeyboardKey.keyA);
      final right =
          keysPressed.contains(LogicalKeyboardKey.arrowRight) ||
          keysPressed.contains(LogicalKeyboardKey.keyD);
      moveX = left == right
          ? 0
          : left
          ? -1
          : 1;
    }
    if (key == LogicalKeyboardKey.arrowUp ||
        key == LogicalKeyboardKey.keyW ||
        key == LogicalKeyboardKey.arrowDown ||
        key == LogicalKeyboardKey.keyS) {
      final up =
          keysPressed.contains(LogicalKeyboardKey.arrowUp) ||
          keysPressed.contains(LogicalKeyboardKey.keyW);
      final down =
          keysPressed.contains(LogicalKeyboardKey.arrowDown) ||
          keysPressed.contains(LogicalKeyboardKey.keyS);
      moveY = up == down
          ? 0
          : up
          ? -1
          : 1;
    }
    if (key == LogicalKeyboardKey.space || key == LogicalKeyboardKey.arrowUp) {
      _jumpHeld =
          keysPressed.contains(LogicalKeyboardKey.space) ||
          keysPressed.contains(LogicalKeyboardKey.arrowUp);
    }
  }

  void togglePause() {
    if (!_loaded || mainMenu || skinMenu || areaMenu || victory) return;
    gamePaused = !gamePaused;
    if (gamePaused) {
      AudioManager.instance.pauseBgm();
    } else {
      AudioManager.instance.resumeBgm();
    }
    _publishHud(force: true);
  }

  void resume() {
    unawaited(_awaitStartupIfNeeded().then((_) {
      gamePaused = false;
      skinMenu = false;
      areaMenu = false;
      victory = false;
      AudioManager.instance.resumeBgm();
      _publishHud(force: true);
    }));
  }

  void openMainMenu() {
    mainMenu = true;
    skinMenu = false;
    areaMenu = false;
    victory = false;
    gamePaused = true;
    AudioManager.instance.stopBgm();
    AudioManager.instance.playSfx('menu_open');
    _publishHud(force: true);
  }

  bool get hasProgress =>
      rescued ||
      skinIndex != 0 ||
      areaIndex > 0 ||
      actions.isNotEmpty ||
      leaves.isNotEmpty ||
      clues.isNotEmpty;

  void beginGameplay() {
    mainMenu = false;
    skinMenu = true;
    areaMenu = false;
    _initialSkinPick = true;
    gamePaused = true;
    AudioManager.instance.playSfx('menu_open');
    _showToast(level.tip, tone: 'normal', duration: 8);
    unawaited(_preloadAllSkins());
    _publishHud(force: true);
  }

  void continueGame() {
    unawaited(_awaitStartupIfNeeded().then((_) {
      mainMenu = false;
      skinMenu = false;
      areaMenu = false;
      victory = false;
      gamePaused = false;
      AudioManager.instance.playBgm('bgm');
      _publishHud(force: true);
    }));
  }

  void openSkinMenuFromMain() {
    mainMenu = false;
    _returnToMenu = true;
    openSkinMenu();
  }

  void openAreaMenuFromMain() {
    mainMenu = false;
    _returnToMenu = true;
    openAreaMenu();
  }

  void openSkinMenu() {
    gamePaused = true;
    skinMenu = true;
    areaMenu = false;
    AudioManager.instance.playSfx('menu_open');
    AudioManager.instance.stopBgm();
    unawaited(_preloadAllSkins());
    _publishHud(force: true);
  }

  void closeSkinMenu() {
    _skinLoadRequest += 1;
    _skinPreloadToken += 1;
    _initialSkinPick = false;
    if (_returnToMenu) {
      _returnToMenu = false;
      mainMenu = true;
      gamePaused = true;
      AudioManager.instance.stopBgm();
      _publishHud(force: true);
      return;
    }
    unawaited(_awaitStartupIfNeeded().then((_) {
      skinMenu = false;
      gamePaused = false;
      AudioManager.instance.playBgm('bgm');
      _publishHud(force: true);
    }));
  }

  void openAreaMenu() {
    gamePaused = true;
    areaMenu = true;
    skinMenu = false;
    AudioManager.instance.playSfx('menu_open');
    AudioManager.instance.stopBgm();
    _publishHud(force: true);
  }

  void closeAreaMenu() {
    if (_returnToMenu) {
      _returnToMenu = false;
      mainMenu = true;
      gamePaused = true;
      AudioManager.instance.stopBgm();
      _publishHud(force: true);
      return;
    }
    areaMenu = false;
    gamePaused = false;
    AudioManager.instance.playBgm('bgm');
    _publishHud(force: true);
  }

  void selectArea(int index) {
    if (index < 0 || index >= levelDefinitions.length) return;
    if (index > maxAreaUnlocked) {
      _showToast('Tema terkunci · selesaikan gerbang ujung tema sebelumnya');
      return;
    }
    unawaited(
      _awaitStartupIfNeeded()
          .then((_) => _enterArea(index))
          .then((_) {
        areaMenu = false;
        skinMenu = false;
        victory = false;
        frontierVictory = false;
        checkpointSection = 0;
        gamePaused = false;
        AudioManager.instance.playBgm('bgm');
        _publishHud(force: true);
      }),
    );
  }

  void restartCheckpoint() {
    hearts = 3;
    player.x = 92;
    player.y = _checkpointY(checkpointSection);
    player.vx = 0;
    player.vy = 0;
    player.grounded = false;
    player.bodySlamming = false;
    player.attachedZip = 0;
    player.climbing = false;
    player.circling = false;
    player.gliding = false;
    player.stickyUntil = 0;
    player.slidingUntil = 0;
    player.rowingUntil = 0;
    player.bouncingUntil = 0;
    for (final platform in platforms) {
      if (platform.type == 'crumble') platform.breakAt = 0;
    }
    unawaited(_awaitStartupIfNeeded().then((_) {
      gamePaused = false;
      _showToast('Kembali ke dahan aman');
      _publishHud(force: true);
    }));
  }

  void exploreAfterRescue() {
    victory = false;
    unawaited(
      _awaitStartupIfNeeded()
          .then((_) => _enterArea(rescued ? 10 : 0))
          .then((_) {
        gamePaused = false;
        AudioManager.instance.playBgm('bgm');
        _publishHud(force: true);
      }),
    );
  }

  @override
  void onGameResize(Vector2 size) {
    super.onGameResize(size);
    if (_loaded) {
      final scale = size.x / worldWidth;
      _cameraY = _clamp(
        player.y - size.y / scale * .56,
        0,
        math.max(0, worldHeight - size.y / scale),
      );
    }
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (!_loaded || !hasLayout) return;
    final step = dt.clamp(0, .033).toDouble();
    _elapsed += step;
    if (!gamePaused && !_busy) _step(step);
    final scale = canvasSize.x / worldWidth;
    final viewportHeight = canvasSize.y / scale;
    final maxCamera = math.max(0, worldHeight - viewportHeight);
    final target = _clamp(player.y - viewportHeight * .56, 0, maxCamera);
    _cameraY += (target - _cameraY) * math.min(1, step * 7.5);
    if (_elapsed >= _nextHudAt) {
      _nextHudAt = _elapsed + .15;
      _publishHud();
    }
  }

  void _step(double dt) {
    if (_scentPressed) {
      _scentPressed = false;
      _scentUntil = _elapsed < _scentUntil ? 0 : _elapsed + 5;
      _animate('MIMA_ABILITIES_SHEET', 'scent_cast', .48);
      AudioManager.instance.playSfx('scent');
    }
    _scentActive = _elapsed < _scentUntil;
    final inputX = moveX;
    final inputY = moveY;
    final previousY = player.y;
    final sticky = _elapsed < player.stickyUntil;
    final moveScale = (player.heavy ? .72 : 1.0) * (sticky ? .34 : 1.0);

    if (player.attachedZip > 0) {
      player.attachedZip -= dt;
      player.vx = 420;
      player.vy = -115;
    } else {
      final targetVx = inputX * 330 * moveScale;
      player.vx += (targetVx - player.vx) * math.min(1, dt * 13);
    }
    if (inputX.abs() > .1) player.facing = inputX < 0 ? -1 : 1;

    final playerBox = _playerRect();
    RectDef? climbable;
    for (final item in climbables) {
      if (_overlaps(playerBox, item)) {
        climbable = item;
        break;
      }
    }
    player.climbing =
        climbable != null && inputY.abs() > .12 && player.attachedZip <= 0;
    player.circling =
        climbable != null && inputX.abs() > .4 && inputY.abs() <= .4;
    if (player.climbing || player.circling) {
      player.vy = player.circling ? 0 : inputY * 330 * .72;
      player.x +=
          (climbable!.x + climbable.w / 2 - player.x) * math.min(1, dt * 8);
    } else if (_jumpPressed &&
        inputY > .45 &&
        !player.grounded &&
        abilities.contains('slam')) {
      player.bodySlamming = true;
      player.gliding = false;
      player.vy = math.max(980, player.vy);
      AudioManager.instance.playSfx('slam');
    } else {
      if (_jumpPressed && player.grounded) {
        if (inputY > .45) {
          player.dropThroughY = player.y;
          player.dropThroughUntil = _elapsed + 0.4;
          player.grounded = false;
          player.vy = 260;
          AudioManager.instance.playSfx('jump');
        } else {
          player.vy = -850 * (player.heavy ? .72 : 1);
          player.grounded = false;
          AudioManager.instance.playSfx('jump');
        }
      }
      player.gliding =
          _jumpHeld &&
          abilities.contains('glide') &&
          player.vy > 30 &&
          !player.bodySlamming;
      player.vy += 1750 * (player.gliding ? .28 : 1) * dt;
    }
    _jumpPressed = false;

    final heroRect = _playerRect();
    for (final zone in zones) {
      if (!_overlaps(heroRect, zone)) continue;
      if (zone.type == 'updraft' &&
          _jumpHeld &&
          abilities.contains('glide') &&
          !player.heavy) {
        player.vy -= 1280 * dt;
        player.gliding = true;
      }
      if (zone.type == 'wind' &&
          !player.heavy &&
          math.sin(_elapsed * 3) > -.35) {
        final force = areaIndex == 7
            ? -520
            : areaIndex == 18
            ? -370
            : -280;
        player.vx += force * dt;
      }
    }

    for (final platform in platforms) {
      if ((platform.type == 'raft' || platform.type == 'conveyor') &&
          platform.vx != 0) {
        platform.x += platform.vx * dt;
        if (platform.minX != null && platform.x < platform.minX!) {
          platform.x = platform.minX!;
          platform.vx = platform.vx.abs();
        } else if (platform.maxX != null && platform.x > platform.maxX!) {
          platform.x = platform.maxX!;
          platform.vx = -platform.vx.abs();
        }
      }
    }

    player.x += player.vx * dt;
    player.y += player.vy * dt;
    player.x = _clamp(
      player.x,
      player.width / 2,
      worldWidth - player.width / 2,
    );
    player.grounded = false;
    if (player.vy >= 0 && !player.climbing) {
      for (final platform in platforms) {
        if (!platform.active ||
            platform.broken ||
            (platform.type == 'crumble' &&
                platform.breakAt > 0 &&
                _elapsed > platform.breakAt)) {
          continue;
        }
        final insideX =
            player.x + player.width * .34 > platform.x &&
            player.x - player.width * .34 < platform.x + platform.w;
        if (!insideX || previousY > platform.y + 10 || player.y < platform.y) {
          continue;
        }
        if (_elapsed < player.dropThroughUntil &&
            (platform.y - player.dropThroughY).abs() < 1) {
          continue;
        }
        if (platform.type == 'cracked' && player.bodySlamming) {
          platform.broken = true;
          if (platform.id != null) actions.add(platform.id!);
          _effects.add(
            _Effect(
              'IMPACT_EFFECTS_SHEET',
              'mound_crumble',
              player.x,
              platform.y,
              _elapsed,
              .65,
              120,
            ),
          );
          _shake = 16;
          unawaited(_save());
          continue;
        }
        player.y = platform.y;
        player.vy = 0;
        player.grounded = true;
        if (platform.type == 'web') {
          player.vy = -1080;
          player.grounded = false;
          player.bouncingUntil = _elapsed + .52;
        } else {
          if (platform.type == 'slippery') {
            player.vx += player.facing * 135;
            player.slidingUntil = _elapsed + .32;
          }
          if (platform.type == 'raft') player.rowingUntil = _elapsed + .26;
          if (platform.type == 'conveyor') player.x += platform.vx * dt;
          if (platform.type == 'crumble' && platform.breakAt == 0) {
            platform.breakAt = _elapsed + .92;
          }
        }
        player.bodySlamming = false;
        break;
      }
    }

    for (final hazard in hazards) {
      if (!_overlaps(_playerRect(), hazard)) continue;
      if (hazard.type == 'sap') {
        player.stickyUntil = _elapsed + 1.3;
      } else {
        _damage(hazard.type);
      }
    }
    if (player.y > worldHeight + 160) _damage('fall');

    final section = player.y < 1450
        ? 2
        : player.y < 2900
        ? 1
        : 0;
    if (section > checkpointSection) {
      checkpointSection = section;
      _showToast('Dahan aman · ${_chapter(section)}');
      AudioManager.instance.playSfx('checkpoint');
      _effects.add(
        _Effect(
          'TRAIL_EFFECTS_SHEET',
          'leaf_shimmer',
          92,
          _checkpointY(section),
          _elapsed,
          .62,
          88,
        ),
      );
      unawaited(_save());
    }
    _collectNearby();
    _nearest = _nearestAction();
    if (_actionPressed) {
      _actionPressed = false;
      if (_nearest != null) {
        _performAction(_nearest!);
      } else {
        _throwGumnut();
      }
    }
    _updateNpcs(dt);
    _updateProjectiles(dt);
    _effects.removeWhere(
      (effect) => _elapsed - effect.startedAt >= effect.duration,
    );
    _flash = math.max(0, _flash - dt * 1.8);
    _shake = math.max(0, _shake - dt * 42);
    _scentActive = _elapsed < _scentUntil;
    if (!_areaSolved && _solved()) {
      _areaSolved = true;
      _showToast('Area selesai! Capai gerbang ujung kanopi', tone: 'gold', duration: 3);
      AudioManager.instance.playSfx('area_solved');
    }
    _checkFrontierComplete();
  }

  ui.Rect _playerRect() => ui.Rect.fromLTWH(
    player.x - player.width / 2,
    player.y - player.height,
    player.width,
    player.height,
  );

  bool _overlaps(ui.Rect a, RectDef b) =>
      a.left < b.x + b.w &&
      a.right > b.x &&
      a.top < b.y + b.h &&
      a.bottom > b.y;

  bool _overlapsRects(ui.Rect a, ui.Rect b) =>
      a.left < b.right &&
      a.right > b.left &&
      a.top < b.bottom &&
      a.bottom > b.top;

  void _damage(String type) {
    if (_elapsed < player.invulnerableUntil) return;
    player.invulnerableUntil = _elapsed + 1.35;
    AudioManager.instance.playSfx(
      type == 'water' ? 'splash' : type == 'fire' ? 'fire' : 'hurt',
    );
    hearts -= 1;
    player.vy = -430;
    player.vx = -player.facing * 260;
    _animate('MIMA_CONDITIONS_SHEET', 'hurt_recover', .52);
    _flash = .38;
    _shake = 12;
    _effects.add(
      _Effect(
        'HAZARD_EFFECTS_SHEET',
        'damage_burst',
        player.x,
        player.y - 20,
        _elapsed,
        .48,
        100,
      ),
    );
    if (type == 'fall' || type == 'water' || hearts <= 0) {
      restartCheckpoint();
      _showToast('Mima kembali ke dahan aman');
    }
  }

  void _collectNearby() {
    final centerY = player.y - player.height / 2;
    for (final leaf in levelLeaves) {
      if (leaves.contains(leaf.id) ||
          math.sqrt(
                math.pow(player.x - leaf.x, 2) +
                    math.pow(centerY - leaf.y, 2),
              ) >
              72) {
        continue;
      }
      leaves.add(leaf.id);
      AudioManager.instance.playSfx('pickup_leaf');
      _effects.add(
        _Effect(
          'TRAIL_EFFECTS_SHEET',
          'pickup_burst',
          leaf.x,
          leaf.y,
          _elapsed,
          .47,
          82,
        ),
      );
      _showToast('Golden Leaf ${leaves.length}/60', tone: 'gold');
      unawaited(_save());
    }
  }

  InteractionDef? _nearestAction() {
    final candidates = <InteractionDef>[];
    for (final item in interactions) {
      final completed = actions.contains(item.id);
      if (completed &&
          !const {
            'gate',
            'back',
            'shortcut',
            'pelican',
            'cage',
          }.contains(item.type)) {
        continue;
      }
      candidates.add(item);
    }
    final clueId = 'clue-$areaIndex';
    if (!clues.contains(clueId)) {
      candidates.add(
        InteractionDef(
          id: clueId,
          type: 'clue',
          x: 585,
          y: 245,
          atlas: areaIndex < 3
              ? 'ZONE_ONE_OBJECTS'
              : areaIndex < 6
              ? 'ZONE_TWO_OBJECTS'
              : 'ZONE_THREE_OBJECTS',
          frame: _clueFrame(areaIndex),
          label: 'Ambil jejak Joey',
        ),
      );
    }
    final carvingId = 'carving-$areaIndex';
    if (!carvings.contains(carvingId) && _scentActive) {
      candidates.add(
        InteractionDef(
          id: carvingId,
          type: 'carving',
          x: 72,
          y: 2105,
          atlas: 'FINAL_OBJECTS',
          frame: 'secret_carving',
          label: 'Baca ukiran',
        ),
      );
    }
    InteractionDef? best;
    var distance = double.infinity;
    for (final item in candidates) {
      final value = math.sqrt(
        math.pow(player.x - item.x, 2) + math.pow(player.y - item.y, 2),
      );
      if (value < distance) {
        distance = value;
        best = item;
      }
    }
    return distance <= 118 ? best : null;
  }

  InteractionDef _withClueFrame(InteractionDef clue, int index) {
    return InteractionDef(
      id: clue.id,
      type: clue.type,
      x: clue.x,
      y: clue.y,
      atlas: clue.atlas,
      frame: _clueFrame(index),
      label: clue.label,
    );
  }

  String _clueFrame(int index) => const [
    'fur_tuft',
    'joey_toy',
    'pelican_rope',
    'ash_print',
    'joey_drawing',
    'cocoon_step',
    'scent_ball',
    'joey_cloth',
  ][math.min(index, 7)];

  void _throwGumnut() {
    if (_elapsed - _lastThrowAt < .36) return;
    _lastThrowAt = _elapsed;
    _animate('MIMA_ABILITIES_SHEET', 'gumnut_throw', .36);
    AudioManager.instance.playSfx('throw');
    _projectiles.add(
      _Projectile(
        x: player.x + player.facing * 30,
        y: player.y - 46,
        vx: player.facing * 620,
        vy: -80,
        owner: 'player',
        visual: 'gumnut',
      )..life = 1.5,
    );
  }

  void _updateNpcs(double dt) {
    const hitSizes = <String, ui.Size>{
      'owl': ui.Size(85, 75),
      'dingo': ui.Size(92, 62),
      'eagle': ui.Size(145, 95),
      'spider': ui.Size(85, 55),
      'kookaburra': ui.Size(92, 70),
      'crocodile': ui.Size(120, 54),
      'toad': ui.Size(82, 62),
      'goanna': ui.Size(112, 48),
      'antSentinel': ui.Size(86, 62),
      'fernBat': ui.Size(88, 70),
      'magpie': ui.Size(92, 72),
      'drone': ui.Size(88, 70),
      'moth': ui.Size(100, 82),
      'cassowary': ui.Size(155, 145),
    };
    const ranged = <String, (String, String)>{
      'kookaburra': ('seed_throw', 'seed'),
      'toad': ('bubble_spit', 'bubble'),
      'goanna': ('pebble_throw', 'pebble'),
      'fernBat': ('sonic_cast', 'sonic'),
      'magpie': ('seed_drop', 'seed'),
      'drone': ('blade_shot', 'gear'),
      'moth': ('wind_cast', 'wind'),
    };
    final scale = canvasSize.x / worldWidth;
    final top = _cameraY - 280;
    final bottom = _cameraY + canvasSize.y / scale + 280;
    for (final npc in npcs) {
      if (npc.hidden) continue;
      if (!npc.boss && (npc.y < top || npc.y > bottom)) continue;
      if (_elapsed < npc.hitUntil) {
        npc.anim = 'hit';
        continue;
      }
      if (npc.attackUntil > 0 && _elapsed > npc.attackUntil) {
        npc.anim = npc.baseAnim;
      }
      if (npc.minX != null && npc.maxX != null) {
        if (_elapsed < npc.distractedUntil) {
          npc.anim = 'sniff';
        } else {
          npc.x += npc.facing * npc.speed * dt;
          if (npc.x > npc.maxX!) npc.facing = -1;
          if (npc.x < npc.minX!) npc.facing = 1;
          if (npc.type == 'dingo') npc.anim = 'patrol';
        }
      }
      if (npc.flying) {
        npc.y = npc.homeY + math.sin(_elapsed * 2.5 + npc.homeY) * 36;
      }
      if (npc.type == 'eagle') {
        final phase = (_elapsed * 1000 % 4300);
        if (phase > 2850 && phase < 3450) {
          npc.anim = 'claw_telegraph';
        } else if (phase >= 3450) {
          npc.anim = 'dive';
          npc.x += (player.x - npc.x) * dt * 2.8;
          npc.y += (player.y - 110 - npc.y) * dt * 2.4;
        } else {
          npc.anim = 'circle';
          npc.y = 420 + math.sin(_elapsed * 2) * 60;
        }
      }
      if (npc.type == 'cassowary') {
        if (player.y < 1450) {
          final phase = (_elapsed * 1000 % 3600);
          if (phase > 2650) {
            npc.anim = 'kick';
            npc.attackUntil = _elapsed + .18;
          } else if (phase > 900) {
            npc.anim = 'run';
            npc.x += npc.facing * 185 * dt;
            if (npc.minX != null && npc.x > npc.maxX!) npc.facing = -1;
            if (npc.minX != null && npc.x < npc.minX!) npc.facing = 1;
          } else {
            npc.anim = 'idle';
          }
        } else {
          npc.anim = 'idle';
        }
      }
      final rangedAttack = ranged[npc.type];
      if (rangedAttack != null &&
          npc.nextAttack < _elapsed &&
          (player.y - npc.y).abs() < 520) {
        npc.nextAttack = _elapsed + 1.9 + _random.nextDouble() * .9;
        npc.attackUntil = _elapsed + .52;
        npc.anim = rangedAttack.$1;
        final direction = player.x < npc.x ? -1.0 : 1.0;
        npc.facing = direction;
        _projectiles.add(
          _Projectile(
            owner: 'enemy',
            visual: rangedAttack.$2,
            x: npc.x + direction * 30,
            y: npc.y - 42,
            vx: direction * (npc.type == 'magpie' ? 120 : 290),
            vy: npc.type == 'magpie' ? 210 : (player.y - npc.y) * .22,
          ),
        );
      }
      final size = hitSizes[npc.type];
      if (size == null ||
          (_elapsed < npc.distractedUntil && npc.type == 'dingo')) {
        continue;
      }
      final npcRect = ui.Rect.fromLTWH(
        npc.x - size.width / 2,
        npc.y - size.height,
        size.width,
        size.height,
      );
      if (_overlapsRects(_playerRect(), npcRect)) _damage(npc.type);
    }
  }

  void _updateProjectiles(double dt) {
    for (final projectile in _projectiles) {
      projectile.life -= dt;
      projectile.x += projectile.vx * dt;
      projectile.y += projectile.vy * dt;
      if (projectile.owner == 'player') {
        projectile.vy += 180 * dt;
        for (final npc in npcs) {
          if (npc.hidden || npc.hitUntil > _elapsed) continue;
          final radius = npc.boss ? 78 : 48;
          if (math.sqrt(
                math.pow(projectile.x - npc.x, 2) +
                    math.pow(projectile.y - (npc.y - radius * .55), 2),
              ) >
              radius) {
            continue;
          }
          projectile.life = 0;
          npc.health -= 1;
          npc.hitUntil = _elapsed + .52;
          npc.anim = 'hit';
          AudioManager.instance.playSfx('boss_hit');
          _effects.add(
            _Effect(
              'HAZARD_EFFECTS_SHEET',
              'damage_burst',
              npc.x,
              npc.y - 20,
              _elapsed,
              .48,
              npc.boss ? 135 : 90,
            ),
          );
          if (npc.health <= 0) {
            npc.hidden = true;
            if (npc.boss) {
              actions.add('boss-19');
              _showToast('Raja Kasuari mundur!', tone: 'gold');
              _shake = 18;
              AudioManager.instance.playSfx('boss_defeat');
              unawaited(_save());
            }
          }
          break;
        }
      } else if (_overlapsRects(
        _playerRect(),
        ui.Rect.fromLTWH(projectile.x - 12, projectile.y - 12, 24, 24),
      )) {
        projectile.life = 0;
        _damage(projectile.visual);
      }
    }
    _projectiles.removeWhere(
      (item) =>
          item.life <= 0 ||
          item.x < -80 ||
          item.x > 800 ||
          item.y < -80 ||
          item.y > worldHeight + 80,
    );
  }

  void _animate(String key, String name, double duration) {
    _animOverrideKey = key;
    _animOverride = name;
    _animOverrideUntil = _elapsed + duration;
  }

  void _complete(InteractionDef object) {
    actions.add(object.id);
    unawaited(_save());
  }

  void _performAction(InteractionDef object) {
    AudioManager.instance.playSfx('interact');
    switch (object.type) {
      case 'back':
        _enterArea(areaIndex - 1, fromBack: true);
      case 'gate':
        if (areaIndex == 9 && !rescued) {
          _showToast('Bebaskan Joey sebelum menuju frontier');
        } else if (areaIndex < levelDefinitions.length - 1 && _solved()) {
          _enterArea(areaIndex + 1);
        } else {
          _showToast('Belum selesai · ${_objectiveText()}');
        }
      case 'branch':
        _animate('MIMA_TRAVERSAL_ONE_SHEET', 'branch_launch', .52);
        player.vy = -1120;
        player.grounded = false;
        AudioManager.instance.playSfx('jump');
        _complete(object);
      case 'seed':
        _animate('MIMA_INTERACTIONS_SHEET', 'seed_plant', .68);
        AudioManager.instance.playSfx('seed');
        platforms.add(
          _Platform(
            x: object.x - 68,
            y: object.y - 75,
            w: 155,
            type: 'normal',
            grown: true,
          ),
        );
        _showToast('Gumnut tumbuh menjadi pijakan');
        _complete(object);
      case 'bark':
        _animate('MIMA_TREE_SHEET', 'bark_peel', .65);
        AudioManager.instance.playSfx('bark');
        _effects.add(
          _Effect(
            'IMPACT_EFFECTS_SHEET',
            'bark_break',
            object.x,
            object.y,
            _elapsed,
            .52,
            82,
          ),
        );
        _complete(object);
      case 'pushBlock':
        _animate('MIMA_INTERACTIONS_SHEET', 'push_block', .72);
        _showToast('Blok kayu menyumbat aliran getah');
        _complete(object);
      case 'shortcut':
        if (areaIndex == 1) _enterArea(0, fromBack: true);
      case 'weight':
        player.heavy = !player.heavy;
        heavy = player.heavy;
        if (player.heavy) actions.add(object.id);
        _showToast(
          player.heavy
              ? 'Kantong berat · tahan angin'
              : 'Kantong ringan · lompat lebih tinggi',
        );
        unawaited(_save());
      case 'waterLever':
        _animate('MIMA_INTERACTIONS_SHEET', 'pull_lever', .65);
        _showToast('Arus air berbalik');
        _complete(object);
      case 'pelican':
        if (actions.contains('peli-2')) {
          _showToast('Peli sudah bebas');
        } else if (!actions.contains('lever-2')) {
          _showToast('Arus terlalu deras untuk membebaskan Peli');
        } else {
          _showToast('Peli kini membuka jalur danau');
          _complete(object);
        }
      case 'vine':
        _animate('MIMA_TRAVERSAL_TWO_SHEET', 'vine_swing', .72);
        AudioManager.instance.playSfx('vine');
        player.vx = player.facing * 520;
        player.vy = -780;
        player.grounded = false;
        _complete(object);
      case 'thermal':
        abilities.add('glide');
        _animate('MIMA_TRAVERSAL_ONE_SHEET', 'leaf_glide', .6);
        AudioManager.instance.playSfx('ability');
        AudioManager.instance.playSfx('glide');
        _complete(object);
      case 'crystal':
        _animate('MIMA_ABILITIES_SHEET', 'echo_bellow', .7);
        AudioManager.instance.playSfx('crystal');
        _effects.add(
          _Effect(
            'CAVE_EFFECTS_SHEET',
            'echo_wave',
            player.x,
            player.y - 30,
            _elapsed,
            .65,
            150,
          ),
        );
        _complete(object);
        final count = _actionCount('crystal-4-');
        for (final platform in platforms.where(
          (item) => item.type == 'ghost',
        )) {
          platform.active = count > 0;
        }
      case 'rope':
        AudioManager.instance.playSfx('rope');
        _effects.add(
          _Effect(
            'IMPACT_EFFECTS_SHEET',
            'bark_break',
            object.x,
            object.y,
            _elapsed,
            .5,
            80,
          ),
        );
        _showToast('Kepompong jatuh menjadi pijakan');
        _complete(object);
      case 'scentBall':
        _animate('MIMA_ABILITIES_SHEET', 'gumnut_throw', .58);
        AudioManager.instance.playSfx('scent');
        for (final npc in npcs.where((item) => item.type == 'dingo')) {
          npc.anim = 'sniff';
          npc.distractedUntil = _elapsed + 5;
        }
        _complete(object);
      case 'windAnchor':
        if (!player.heavy) {
          _showToast('Kantong terlalu ringan untuk menahan pijakan');
        } else {
          _animate('MIMA_INTERACTIONS_SHEET', 'pull_lever', .62);
          _showToast('Jangkar badai terkunci');
          _complete(object);
        }
      case 'zipline':
        player.attachedZip = 1.25;
        abilities.add('zipline');
        AudioManager.instance.playSfx('ability');
        AudioManager.instance.playSfx('zip');
        _complete(object);
      case 'crane':
        _animate('MIMA_INTERACTIONS_SHEET', 'pull_lever', .68);
        AudioManager.instance.playSfx('crane');
        platforms.add(
          _Platform(
            x: 285,
            y: object.y - 395,
            w: 205,
            type: 'conveyor',
            vx: 35,
          ),
        );
        _showToast('Gelondongan membentuk tangga');
        _complete(object);
      case 'frontierPuzzle':
      case 'areaPuzzle':
        AudioManager.instance.playSfx('puzzle');
        final requirementMet = object.requirement == 'heavy'
            ? player.heavy
            : object.requirement == null ||
                  abilities.contains(object.requirement);
        if (!requirementMet) {
          _showToast(
            object.requirement == 'heavy'
                ? 'Isi kantong dengan batu dahulu'
                : 'Kemampuan ini belum siap',
          );
          return;
        }
        final animation = _puzzleAnimation(object.kind);
        _animate(animation.$1, animation.$2, .72);
        _showToast('${object.label} selesai');
        _complete(object);
      case 'lock':
        if (!abilities.contains(object.ability)) {
          _showToast('Kemampuan itu belum ditemukan');
        } else {
          AudioManager.instance.playSfx('lock');
          _effects.add(
            _Effect(
              'IMPACT_EFFECTS_SHEET',
              'cage_unlock',
              object.x,
              object.y,
              _elapsed,
              .56,
              86,
            ),
          );
          _complete(object);
        }
      case 'cage':
        if (!_solved()) {
          _showToast('Pengunci atau jalur Baobab masih belum selesai');
        } else {
          AudioManager.instance.playSfx('cage');
          _finishRescue();
        }
      case 'clue':
        clues.add(object.id);
        AudioManager.instance.playSfx('pickup_clue');
        _effects.add(
          _Effect(
            'TRAIL_EFFECTS_SHEET',
            'fur_glint',
            object.x,
            object.y,
            _elapsed,
            .62,
            90,
          ),
        );
        _showToast('Jejak Joey ${clues.length}/20', tone: 'clue');
        unawaited(_save());
      case 'carving':
        carvings.add(object.id);
        AudioManager.instance.playSfx('pickup_carving');
        _showToast('Ukiran rahasia ${carvings.length}/20');
        unawaited(_save());
      default:
        _showToast('Objek ini belum memiliki aksi');
    }
    _publishHud(force: true);
  }

  (String, String) _puzzleAnimation(String? kind) => switch (kind) {
    'branchChain' => ('MIMA_TRAVERSAL_ONE_SHEET', 'branch_pull'),
    'seedCrown' => ('MIMA_INTERACTIONS_SHEET', 'seed_plant'),
    'sapBlock' => ('MIMA_INTERACTIONS_SHEET', 'push_block'),
    'shadowBell' ||
    'shroomChain' ||
    'honeyFork' ||
    'fernMirror' ||
    'moonLantern' => ('MIMA_ABILITIES_SHEET', 'scent_cast'),
    'leafDock' ||
    'vineAnchor' ||
    'mothVane' => ('MIMA_TRAVERSAL_TWO_SHEET', 'leaf_row'),
    'smokeDamper' => ('MIMA_TREE_SHEET', 'bark_peel'),
    'thermalSpire' => ('MIMA_TRAVERSAL_ONE_SHEET', 'leaf_glide'),
    'prismEcho' ||
    'bambooGong' ||
    'echoTelescope' => ('MIMA_ABILITIES_SHEET', 'echo_bellow'),
    'waterFruit' ||
    'termiteSwitch' ||
    'bubbleReed' ||
    'pebbleTarget' ||
    'ironMagnet' ||
    'stormLauncher' => ('MIMA_ABILITIES_SHEET', 'gumnut_throw'),
    'spireBreak' ||
    'rootSeal' ||
    'sawLock' ||
    'arenaSeal' => ('MIMA_ABILITIES_SHEET', 'body_slam'),
    'stormShelter' || 'gorgeWeight' => ('MIMA_CONDITIONS_SHEET', 'heavy_carry'),
    'cableSwitch' ||
    'cableShield' => ('MIMA_TRAVERSAL_TWO_SHEET', 'zipline_crawl'),
    _ => ('MIMA_INTERACTIONS_SHEET', 'pull_lever'),
  };

  void _finishRescue() {
    if (rescued) return;
    rescued = true;
    clues.add('clue-9');
    actions.add('cage-9');
    final score =
        leaves.length * 100 + clues.length * 500 + carvings.length * 250;
    bestScore = math.max(bestScore, score);
    _animate('MIMA_INTERACTIONS_SHEET', 'rescue_hug', 1.7);
    _effects.add(
      _Effect(
        'IMPACT_EFFECTS_SHEET',
        'cage_unlock',
        585,
        245,
        _elapsed,
        .9,
        145,
      ),
    );
    _flash = .75;
    victory = true;
    gamePaused = true;
    _showToast('Joey selamat!', tone: 'gold');
    AudioManager.instance.playSfx('win');
    unawaited(_save());
    _publishHud(force: true);
  }

  void _checkFrontierComplete() {
    if (areaIndex != 19 ||
        !_solved() ||
        actions.contains('frontier-complete')) {
      return;
    }
    actions.add('frontier-complete');
    bestScore = math.max(
      bestScore,
      leaves.length * 100 + clues.length * 500 + carvings.length * 250 + 10000,
    );
    frontierVictory = true;
    victory = true;
    gamePaused = true;
    AudioManager.instance.playSfx('frontier_win');
    unawaited(_save());
  }

  Future<void> _enterArea(int index, {bool fromBack = false}) async {
    if (index < 0 || index >= levelDefinitions.length) return;
    _busy = true;
    _publishHud(force: true);
    checkpointSection = fromBack ? 2 : 0;
    _buildLevel(index, resetPlayer: false, fromBack: fromBack);
    AudioManager.instance.playSfx('gate');
    maxAreaUnlocked = math.max(maxAreaUnlocked, index);
    player.heavy = false;
    heavy = false;
    await _loadCurrentAssets();
    _showToast('${(index + 1).toString().padLeft(2, '0')} · ${level.name}');
    unawaited(_save());
    _busy = false;
    _publishHud(force: true);
  }

  bool _solved() {
    bool coreSolved;
    switch (areaIndex) {
      case 0:
        coreSolved = _areaLeavesCount() >= 3 && actions.contains('seed-0');
      case 1:
        coreSolved = _actionCount('bark-1-') >= 3;
      case 2:
        coreSolved = actions.contains('lever-2');
      case 3:
        coreSolved = clues.contains('clue-3');
      case 4:
        coreSolved = _actionCount('crystal-4-') >= 3;
      case 5:
        coreSolved = _actionCount('rope-5-') >= 3;
      case 6:
        coreSolved = _actionCount('pillar-6-') >= 2;
      case 7:
        coreSolved = actions.contains('anchor-7');
      case 8:
        coreSolved = actions.contains('crane-8');
      case 9:
        coreSolved = _actionCount('lock-9-') >= 4;
      case 19:
        coreSolved = actions.contains('core-19') && actions.contains('boss-19');
      default:
        coreSolved = actions.contains('core-$areaIndex');
    }
    return coreSolved &&
        actions.contains('puzzle-$areaIndex-middle') &&
        actions.contains('puzzle-$areaIndex-top');
  }

  int _areaLeavesCount() =>
      levelLeaves.where((leaf) => leaves.contains(leaf.id)).length;

  int _actionCount(String prefix) =>
      actions.where((id) => id.startsWith(prefix)).length;

  int _routePuzzleCount() =>
      (actions.contains('puzzle-$areaIndex-middle') ? 1 : 0) +
      (actions.contains('puzzle-$areaIndex-top') ? 1 : 0);

  String _objectiveText() {
    switch (areaIndex) {
      case 0:
        return '${_areaLeavesCount()}/3 daun · jalur ${_routePuzzleCount()}/2';
      case 1:
        return '${_actionCount('bark-1-')}/3 kulit terkupas';
      case 2:
        return actions.contains('lever-2')
            ? 'Arus berbalik · menuju atas'
            : 'Temukan tuas aliran';
      case 3:
        return clues.contains('clue-3')
            ? 'Tapak Joey ditemukan'
            : 'Ikuti tapak berjelaga';
      case 4:
        return '${_actionCount('crystal-4-')}/3 kristal menyala';
      case 5:
        return '${_actionCount('rope-5-')}/3 tali terpotong';
      case 6:
        return '${_actionCount('pillar-6-')}/2 pilar runtuh';
      case 7:
        return actions.contains('anchor-7')
            ? 'Jangkar badai terkunci'
            : 'Bawa batu ke jangkar';
      case 8:
        return actions.contains('crane-8')
            ? 'Tangga gelondongan siap'
            : 'Aktifkan derek';
      case 9:
        return '${_actionCount('lock-9-')}/4 pengunci · jalur ${_routePuzzleCount()}/2';
      case 19:
        return '${actions.contains('boss-19') ? 'Boss kalah' : 'Boss 6 hit'} · jalur ${_routePuzzleCount()}/2';
      default:
        return level.objective;
    }
  }

  String _chapter(int section) =>
      const ['Akar', 'Jantung', 'Mahkota'][section.clamp(0, 2)];

  void _showToast(
    String message, {
    String tone = 'normal',
    double duration = 2.1,
  }) {
    _toast = message;
    _toastTone = tone;
    _toastUntil = _elapsed + duration;
    _publishHud(force: true);
  }

  void _publishHud({bool force = false}) {
    if (!_loaded && loading) {
      hud.value = GameHudState(
        loading: true,
        area: areaIndex,
        areaName: levelDefinitions[areaIndex].name,
      );
      return;
    }
    final chapterIndex = player.y < 1450
        ? 2
        : player.y < 2900
        ? 1
        : 0;
    final boss = npcs.where((npc) => npc.boss && !npc.hidden).firstOrNull;
    final toast = _elapsed < _toastUntil ? _toast : '';
    hud.value = GameHudState(
      loading: loading,
      ready: _loaded,
      paused: gamePaused,
      mainMenu: mainMenu,
      skinMenu: skinMenu,
      areaMenu: areaMenu,
      victory: victory,
      frontierVictory: frontierVictory,
      busy: _busy,
      area: areaIndex,
      areaName: level.name,
      chapter: _chapter(chapterIndex),
      hearts: hearts,
      leaves: leaves.length,
      clues: clues.length,
      carvings: carvings.length,
      objective: rescued && areaIndex < 10
          ? 'Joey aman · jalur frontier terbuka'
          : _objectiveText(),
      prompt: _nearest?.label ?? '',
      toast: toast,
      toastTone: _toastTone,
      bossHealth: boss?.health ?? 0,
      bossMaxHealth: boss?.maxHealth ?? 1,
      skinIndex: skinIndex,
      error: '',
    );
  }

  double _clamp(num value, num min, num max) =>
      value.clamp(min, max).toDouble();

  @override
  ui.Color backgroundColor() => const ui.Color(0xff17211d);

  @override
  // ignore: must_call_super
  void render(ui.Canvas canvas) {
    if (!hasLayout) return;
    final width = canvasSize.x;
    final height = canvasSize.y;
    canvas.drawColor(const ui.Color(0xff17211d), ui.BlendMode.srcOver);
    if (!_loaded) {
      _drawCenteredText(
        canvas,
        'Menumbuhkan kanopi…',
        ui.Offset(width / 2, height / 2),
        22,
        const ui.Color(0xfffff1c0),
      );
      return;
    }

    final bg = _image(level.background);
    final screen = ui.Rect.fromLTWH(0, 0, width, height);
    final palette = level.palette.first;
    canvas.drawRect(screen, ui.Paint()..color = palette);
    if (bg != null) {
      final cover = math.max(width / bg.width, height / bg.height);
      final drawW = bg.width * cover;
      final drawH = bg.height * cover;
      canvas.drawImageRect(
        bg,
        ui.Rect.fromLTWH(0, 0, bg.width.toDouble(), bg.height.toDouble()),
        ui.Rect.fromLTWH(
          (width - drawW) / 2,
          (height - drawH) / 2,
          drawW,
          drawH,
        ),
        ui.Paint()..filterQuality = ui.FilterQuality.medium,
      );
    }
    canvas.drawRect(
      screen,
      ui.Paint()
        ..color = _scentActive
            ? const ui.Color(0x94101d2a)
            : const ui.Color(0x14201c16),
    );

    final scale = width / worldWidth;
    final maxCamera = math.max(0, worldHeight - height / scale);
    final shakeX = _shake > 0 ? (_random.nextDouble() - .5) * _shake : 0.0;
    final shakeY = _shake > 0 ? (_random.nextDouble() - .5) * _shake : 0.0;
    canvas.save();
    canvas.clipRect(screen);
    canvas.translate(shakeX, shakeY);
    canvas.scale(scale, scale);
    canvas.translate(0, -_clamp(_cameraY, 0, maxCamera));
    _renderWorld(canvas);
    canvas.restore();
    if (_flash > 0) {
      canvas.drawRect(
        screen,
        ui.Paint()
          ..color = ui.Color.fromARGB(
            (_flash * 255).round().clamp(0, 255),
            255,
            238,
            190,
          ),
      );
    }
  }

  ui.Image? _image(String key) {
    final name = _assetPaths[key];
    if (name == null ||
        !_loadedImages.contains(name) ||
        !Flame.images.containsKey(name)) {
      return null;
    }
    return Flame.images.fromCache(name);
  }

  void _renderWorld(ui.Canvas canvas) {
    final scale = canvasSize.x / worldWidth;
    final viewTop = _cameraY - 180;
    final viewBottom = _cameraY + canvasSize.y / scale + 180;
    _drawZones(canvas);
    for (final platform in platforms) {
      if (platform.y < viewTop || platform.y > viewBottom) continue;
      _drawPlatform(canvas, platform);
    }
    for (final hazard in hazards) {
      if (hazard.y + hazard.h < viewTop || hazard.y > viewBottom) continue;
      _drawHazard(canvas, hazard);
    }
    for (final offset in [0.0, sectionHeight, sectionHeight * 2]) {
      final blossomY = 1285 + offset;
      if (blossomY < viewTop || blossomY > viewBottom) continue;
      _drawFrameCell(
        canvas,
        'FINAL_OBJECTS',
        'checkpoint_blossom',
        ui.Rect.fromLTWH(55, blossomY, 76, 88),
        alpha: .9,
      );
    }

    for (final leaf in levelLeaves) {
      if (leaves.contains(leaf.id)) continue;
      if (leaf.y < viewTop || leaf.y > viewBottom) continue;
      final bob = math.sin(_elapsed * 4 + leaf.x) * 9;
      _drawFrameCell(
        canvas,
        'ZONE_ONE_OBJECTS',
        'golden_leaf',
        ui.Rect.fromLTWH(leaf.x - 30, leaf.y + bob - 52, 60, 60),
      );
    }

    final clueId = 'clue-$areaIndex';
    if (!clues.contains(clueId)) {
      final clue = _withClueFrame(
        InteractionDef(
          id: clueId,
          type: 'clue',
          x: 585,
          y: 245,
          atlas: areaIndex < 3
              ? 'ZONE_ONE_OBJECTS'
              : areaIndex < 6
              ? 'ZONE_TWO_OBJECTS'
              : 'ZONE_THREE_OBJECTS',
          frame: '',
          label: 'Ambil jejak Joey',
        ),
        areaIndex,
      );
      final bob = math.sin(_elapsed * 5) * 5;
      _drawInteraction(canvas, _copyInteraction(clue, y: clue.y + bob), .8, 74);
    }
    final carvingId = 'carving-$areaIndex';
    if (!carvings.contains(carvingId) && _scentActive) {
      _drawFrameCell(
        canvas,
        'FINAL_OBJECTS',
        'secret_carving',
        const ui.Rect.fromLTWH(34, 2067, 76, 76),
        alpha: .95,
      );
    }

    for (final object in interactions) {
      if (object.y < viewTop || object.y > viewBottom) continue;
      final completed = actions.contains(object.id);
      if (completed &&
          !const {
            'gate',
            'back',
            'shortcut',
            'pelican',
            'cage',
          }.contains(object.type)) {
        continue;
      }
      final size = object.type == 'gate'
          ? 112.0
          : object.type == 'cage'
          ? 126.0
          : 84.0;
      _drawInteraction(canvas, object, completed ? .42 : 1, size);
      if (_scentActive &&
          !completed &&
          !const {'back', 'gate'}.contains(object.type)) {
        final pulse = 28 + math.sin(_elapsed * 8) * 6;
        canvas.drawCircle(
          ui.Offset(object.x, object.y - size * .45),
          pulse,
          ui.Paint()
            ..style = ui.PaintingStyle.stroke
            ..strokeWidth = 4
            ..color = const ui.Color(0xdc5beed8),
        );
      }
    }

    for (final npc in npcs) {
      if (npc.hidden) continue;
      if (npc.boss && player.y >= 1450) continue;
      if (!npc.boss && (npc.y < viewTop || npc.y > viewBottom)) continue;
      final size = switch (npc.type) {
        'eagle' => 150.0,
        'joey' => 70.0,
        'termite' => 64.0,
        'crocodile' => 82.0,
        'toad' => 84.0,
        'goanna' => 74.0,
        'antSentinel' => 84.0,
        'fernBat' => 86.0,
        'magpie' => 92.0,
        'kookaburra' => 92.0,
        'drone' => 86.0,
        'moth' => 100.0,
        'cassowary' => 178.0,
        _ => 92.0,
      };
      final frame = _drawAnimation(
        canvas,
        npc.sheet,
        npc.anim,
        (_elapsed * (npc.type == 'eagle' ? 7 : 9)).floor(),
        npc.x,
        npc.y,
        size,
        facing: npc.facing,
      );
      if (!frame) {
        _drawFallbackCharacter(
          canvas,
          npc.x,
          npc.y,
          size * .52,
          npc.type,
          facing: npc.facing,
        );
      }
    }

    for (final effect in _effects) {
      if (effect.y < viewTop || effect.y > viewBottom) continue;
      final fraction = _clamp(
        (_elapsed - effect.startedAt) / effect.duration,
        0,
        .999,
      );
      // Player action effects use MIMA_ sheets; show them with the active skin.
      final effectKey =
          effect.key.startsWith('MIMA_') ? _skinKey(effect.key) : effect.key;
      _drawAnimation(
        canvas,
        effectKey,
        effect.animation,
        (fraction * 5).floor(),
        effect.x,
        effect.y,
        effect.size,
        alpha: 1 - fraction * .2,
      );
    }

    for (final projectile in _projectiles) {
      if (projectile.y < viewTop || projectile.y > viewBottom) continue;
      final color = switch (projectile.visual) {
        'bubble' => const ui.Color(0xbad3ffff),
        'pebble' => const ui.Color(0xffaa9270),
        'gear' => const ui.Color(0xff9ea9a1),
        'sonic' || 'wind' => const ui.Color(0xff65d5cf),
        _ => const ui.Color(0xffd5aa55),
      };
      canvas.drawCircle(
        ui.Offset(projectile.x, projectile.y),
        projectile.owner == 'player' ? 13 : 11,
        ui.Paint()..color = color,
      );
      canvas.drawCircle(
        ui.Offset(projectile.x, projectile.y),
        projectile.owner == 'player' ? 16 : 14,
        ui.Paint()
          ..style = ui.PaintingStyle.stroke
          ..strokeWidth = 2
          ..color = color.withAlpha(150),
      );
    }

    if (_scentActive) {
      final destination = clues.contains(clueId)
          ? interactions.where((item) => item.type == 'gate').firstOrNull
          : null;
      if (destination != null || !clues.contains(clueId)) {
        final targetX = destination?.x ?? 585;
        final targetY = destination?.y ?? 245;
        final start = ui.Offset(player.x, player.y - 35);
        final end = ui.Offset(targetX, targetY - 45);
        final count = 16;
        for (var i = 0; i < count; i++) {
          if (i.isOdd) continue;
          final t1 = i / count;
          final t2 = (i + 1) / count;
          ui.Offset point(double t) {
            final control = ui.Offset(
              (start.dx + end.dx) / 2,
              math.min(start.dy, end.dy) - 70,
            );
            final inverse = 1 - t;
            return start * (inverse * inverse) +
                control * (2 * inverse * t) +
                end * (t * t);
          }

          canvas.drawLine(
            point(t1),
            point(t2),
            ui.Paint()
              ..color = const ui.Color(0xcc47e7d2)
              ..strokeWidth = 6
              ..strokeCap = ui.StrokeCap.round,
          );
        }
      }
    }

    final animation = _playerAnimation();
    final alpha =
        _elapsed < player.invulnerableUntil && (_elapsed * 12).floor().isOdd
        ? .35
        : 1.0;
    final frameIndex = (_elapsed * (animation.$2 == 'idle' ? 5 : 10)).floor();
    var rendered = _drawAnimation(
      canvas,
      _skinKey(animation.$1),
      animation.$2,
      frameIndex,
      player.x,
      player.y,
      92,
      facing: player.facing,
      alpha: alpha,
    );
    // The selected skin may be missing this specific pose (e.g. an action
    // animation). Keep the chosen skin on screen by showing its idle pose
    // rather than reverting to the default Mima koala.
    if (!rendered && skinIndex != 0) {
      rendered = _drawAnimation(
        canvas,
        _skinKey('MIMA_BASIC_SHEET'),
        'idle',
        frameIndex,
        player.x,
        player.y,
        92,
        facing: player.facing,
        alpha: alpha,
      );
    }
    // Still nothing: the skin image itself failed to load. Use the default
    // Mima sprite, and only as a last resort show the gray placeholder.
    if (!rendered) {
      rendered = _drawAnimation(
        canvas,
        'MIMA_BASIC_SHEET',
        'idle',
        frameIndex,
        player.x,
        player.y,
        92,
        facing: player.facing,
        alpha: alpha,
      );
    }
    if (!rendered) {
      _drawFallbackCharacter(
        canvas,
        player.x,
        player.y,
        30,
        'mima',
        facing: player.facing,
        alpha: alpha,
      );
    }
  }

  (String, String) _playerAnimation() {
    if (_elapsed < _animOverrideUntil && _animOverride.isNotEmpty) {
      return (_animOverrideKey, _animOverride);
    }
    if (player.attachedZip > 0) {
      return ('MIMA_TRAVERSAL_TWO_SHEET', 'zipline_crawl');
    }
    if (_elapsed < player.bouncingUntil) {
      return ('MIMA_TRAVERSAL_TWO_SHEET', 'web_bounce');
    }
    if (_elapsed < player.rowingUntil) {
      return ('MIMA_TRAVERSAL_TWO_SHEET', 'leaf_row');
    }
    if (_elapsed < player.slidingUntil) {
      return ('MIMA_TRAVERSAL_ONE_SHEET', 'bark_slide');
    }
    if (_elapsed < player.stickyUntil) {
      return ('MIMA_CONDITIONS_SHEET', 'sap_struggle');
    }
    if (player.circling) return ('MIMA_TREE_SHEET', 'circle_trunk');
    if (player.climbing) return ('MIMA_TREE_SHEET', 'climb');
    if (player.bodySlamming) return ('MIMA_ABILITIES_SHEET', 'body_slam');
    if (player.gliding) return ('MIMA_TRAVERSAL_ONE_SHEET', 'leaf_glide');
    if (!player.grounded) {
      if (player.vy < -90) return ('MIMA_AIR_SHEET', 'jump_rise');
      if (player.vy > 110) return ('MIMA_AIR_SHEET', 'fall');
      return ('MIMA_AIR_SHEET', 'apex');
    }
    if (player.heavy) return ('MIMA_CONDITIONS_SHEET', 'heavy_carry');
    if (player.vx.abs() > 210) return ('MIMA_BASIC_SHEET', 'run');
    if (player.vx.abs() > 20) return ('MIMA_BASIC_SHEET', 'walk');
    return ('MIMA_BASIC_SHEET', 'idle');
  }

  void _drawZones(ui.Canvas canvas) {
    for (final zone in zones) {
      if (zone.type == 'shadow') {
        final rect = ui.Rect.fromLTWH(zone.x, zone.y, zone.w, zone.h);
        final paint = ui.Paint()
          ..shader = ui.Gradient.linear(
            rect.topLeft,
            rect.bottomLeft,
            const [
              ui.Color(0x40101924),
              ui.Color(0x99151924),
            ],
          );
        canvas.drawRRect(
          ui.RRect.fromRectAndRadius(rect, const ui.Radius.circular(18)),
          paint,
        );
      } else if (zone.type == 'updraft') {
        final paint = ui.Paint()
          ..color = const ui.Color(0x8cf4b866)
          ..style = ui.PaintingStyle.stroke
          ..strokeWidth = 4;
        for (
          var y = zone.y + (_elapsed * 90 % 90);
          y < zone.y + zone.h;
          y += 90
        ) {
          canvas.drawArc(
            ui.Rect.fromCircle(
              center: ui.Offset(zone.x + zone.w / 2, y),
              radius: 35,
            ),
            .2,
            2.5,
            false,
            paint,
          );
        }
      } else if (zone.type == 'wind' && math.sin(_elapsed * 3) > -.35) {
        final paint = ui.Paint()
          ..color = const ui.Color(0x80e2f0ef)
          ..strokeWidth = 3;
        for (var y = zone.y + 60; y < zone.y + zone.h; y += 115) {
          final offset = (_elapsed * 25 + y) % 180;
          canvas.drawLine(
            ui.Offset(zone.x + zone.w - offset, y),
            ui.Offset(zone.x + zone.w - offset - 100, y + 12),
            paint,
          );
        }
      } else if (zone.type == 'zipline') {
        canvas.drawLine(
          ui.Offset(zone.x, zone.y + 16),
          ui.Offset(zone.x + zone.w, zone.y - 90),
          ui.Paint()
            ..color = const ui.Color(0xff4d5355)
            ..strokeWidth = 6,
        );
      }
    }
  }

  void _drawPlatform(ui.Canvas canvas, _Platform platform) {
    if (!platform.active ||
        platform.broken ||
        (platform.type == 'crumble' &&
            platform.breakAt > 0 &&
            _elapsed > platform.breakAt)) {
      return;
    }
    if (platform.type == 'ghost' && !platform.active) return;
    if (platform.type == 'web') {
      if (!_drawFrameCell(
        canvas,
        'ZONE_TWO_OBJECTS',
        'web_pad',
        ui.Rect.fromLTWH(platform.x, platform.y - 48, platform.w, 78),
      )) {
        _fallbackPlatform(canvas, platform, const ui.Color(0xffa2dfe2));
      }
      return;
    }
    if (platform.type == 'raft') {
      if (!_drawFrameCell(
        canvas,
        'ZONE_ONE_OBJECTS',
        'leaf_raft',
        ui.Rect.fromLTWH(platform.x, platform.y - 45, platform.w, 74),
      )) {
        _fallbackPlatform(canvas, platform, const ui.Color(0xff7ebd83));
      }
      return;
    }
    if (platform.type == 'ghost') {
      if (!_drawFrameCell(
        canvas,
        'ZONE_TWO_OBJECTS',
        'ghost_root',
        ui.Rect.fromLTWH(platform.x, platform.y - 55, platform.w, 90),
        alpha: .82,
      )) {
        _fallbackPlatform(canvas, platform, const ui.Color(0x997bd0d2));
      }
      return;
    }
    final atlas = _atlases[level.platform];
    final frame = atlas?.frames['center'];
    final content = frame?.content;
    final image = _image(level.platform);
    if (image != null && content != null) {
      final drawHeight = platform.type == 'ground' ? 105.0 : 76.0;
      final opacity = platform.breakAt > 0
          ? .55 + math.sin(_elapsed * 40) * .3
          : 1.0;
      final paint = ui.Paint()
        ..filterQuality = ui.FilterQuality.medium
        ..color = ui.Color.fromARGB((opacity * 255).round(), 255, 255, 255);
      final surfaceY = frame?.surfaceY ?? content.top;
      final drawY =
          platform.y - (surfaceY - content.top) * drawHeight / content.height;
      canvas.drawImageRect(
        image,
        content,
        ui.Rect.fromLTWH(platform.x, drawY, platform.w, drawHeight),
        paint,
      );
    } else {
      _fallbackPlatform(canvas, platform, level.palette[2]);
    }
    if (platform.type == 'cracked') {
      _drawFrameCell(
        canvas,
        'ZONE_THREE_OBJECTS',
        'cracked_mound',
        ui.Rect.fromLTWH(
          platform.x + platform.w / 2 - 36,
          platform.y - 50,
          72,
          72,
        ),
      );
    }
    if (platform.type == 'conveyor') {
      final paint = ui.Paint()
        ..color = const ui.Color(0xffcbe0d9)
        ..strokeWidth = 5;
      for (
        var x = platform.x + (_elapsed * 80 % 34);
        x < platform.x + platform.w;
        x += 34
      ) {
        canvas.drawLine(
          ui.Offset(x, platform.y + 7),
          ui.Offset(x + 16, platform.y + 7),
          paint,
        );
      }
    }
    if (platform.grown) {
      canvas.drawCircle(
        ui.Offset(platform.x + platform.w / 2, platform.y - 10),
        8,
        ui.Paint()..color = const ui.Color(0xffe6c45d),
      );
    }
  }

  void _fallbackPlatform(ui.Canvas canvas, _Platform platform, ui.Color color) {
    final rect = ui.Rect.fromLTWH(platform.x, platform.y - 12, platform.w, 42);
    canvas.drawRRect(
      ui.RRect.fromRectAndRadius(rect, const ui.Radius.circular(16)),
      ui.Paint()..color = color,
    );
    canvas.drawRect(
      ui.Rect.fromLTWH(rect.left, rect.top, rect.width, 9),
      ui.Paint()..color = color.withAlpha(150),
    );
  }

  void _drawHazard(ui.Canvas canvas, HazardDef hazard) {
    final bob = math.sin(_elapsed * 8) * 3;
    if (hazard.type == 'fire') {
      if (!_drawFrameCell(
        canvas,
        'ZONE_TWO_OBJECTS',
        'ember_pit',
        ui.Rect.fromLTWH(
          hazard.x,
          hazard.y - 40 + bob,
          hazard.w,
          hazard.h + 45,
        ),
      )) {
        _drawFire(canvas, hazard);
      }
    } else if (hazard.type == 'sap') {
      if (!_drawFrameCell(
        canvas,
        'ZONE_TWO_OBJECTS',
        'sticky_sap',
        ui.Rect.fromLTWH(hazard.x, hazard.y - 24, hazard.w, hazard.h + 36),
      )) {
        canvas.drawOval(
          ui.Rect.fromLTWH(hazard.x, hazard.y, hazard.w, hazard.h),
          ui.Paint()..color = const ui.Color(0xffd09239),
        );
      }
    } else if (hazard.type == 'saw') {
      canvas.save();
      canvas.translate(hazard.x + hazard.w / 2, hazard.y + hazard.h / 2);
      canvas.rotate(_elapsed * 6);
      if (!_drawFrameCell(
        canvas,
        'ZONE_THREE_OBJECTS',
        'saw_blade',
        ui.Rect.fromLTWH(-hazard.w / 2, -hazard.h / 2, hazard.w, hazard.h),
      )) {
        canvas.drawCircle(
          ui.Offset.zero,
          hazard.h / 2,
          ui.Paint()..color = const ui.Color(0xffc2c8b8),
        );
      }
      canvas.restore();
    } else if (hazard.type == 'water') {
      final rect = ui.Rect.fromLTWH(hazard.x, hazard.y, hazard.w, hazard.h);
      canvas.drawRect(
        rect,
        ui.Paint()
          ..shader = ui.Gradient.linear(
            rect.topCenter,
            rect.bottomCenter,
            const [ui.Color(0xc28cd8dd), ui.Color(0xc2266577)],
          ),
      );
    }
  }

  void _drawFire(ui.Canvas canvas, HazardDef hazard) {
    for (var i = 0; i < 5; i++) {
      final x = hazard.x + hazard.w * (i + .5) / 5;
      final height = 20 + math.sin(_elapsed * 11 + i) * 10;
      final path = ui.Path()
        ..moveTo(x - 13, hazard.y + 5)
        ..quadraticBezierTo(
          x - 20,
          hazard.y - height * .5,
          x,
          hazard.y - height,
        )
        ..quadraticBezierTo(
          x + 18,
          hazard.y - height * .4,
          x + 13,
          hazard.y + 5,
        )
        ..close();
      canvas.drawPath(
        path,
        ui.Paint()
          ..color = i.isEven
              ? const ui.Color(0xffed7a32)
              : const ui.Color(0xffffc351),
      );
    }
  }

  void _drawInteraction(
    ui.Canvas canvas,
    InteractionDef object,
    double alpha,
    double size,
  ) {
    if (!_drawFrameCell(
      canvas,
      object.atlas,
      object.frame,
      ui.Rect.fromLTWH(object.x - size / 2, object.y - size, size, size),
      alpha: alpha,
    )) {
      final color = object.type == 'gate'
          ? const ui.Color(0xffe4c46d)
          : const ui.Color(0xff75ad84);
      canvas.drawCircle(
        ui.Offset(object.x, object.y - size * .48),
        size * .28,
        ui.Paint()..color = color.withAlpha((alpha * 255).round()),
      );
      canvas.drawCircle(
        ui.Offset(object.x, object.y - size * .48),
        size * .35,
        ui.Paint()
          ..color = const ui.Color(0x99fff2c7)
          ..style = ui.PaintingStyle.stroke
          ..strokeWidth = 2,
      );
    }
  }

  bool _drawFrameCell(
    ui.Canvas canvas,
    String atlasKey,
    String frameName,
    ui.Rect destination, {
    double alpha = 1,
  }) {
    final image = _image(atlasKey);
    if (image == null) return false;
    final frame = _atlases[atlasKey]?.frames[frameName];
    ui.Rect? source = frame?.content;
    if (frame?.empty == true) return false;
    source ??= _fallbackFrame(atlasKey, frameName, image);
    if (source == null || source.isEmpty) return false;
    final scale = math.min(
      destination.width / source.width,
      destination.height / source.height,
    );
    final width = source.width * scale;
    final height = source.height * scale;
    final target = ui.Rect.fromLTWH(
      destination.center.dx - width / 2,
      destination.center.dy - height / 2,
      width,
      height,
    );
    canvas.drawImageRect(
      image,
      source,
      target,
      ui.Paint()
        ..filterQuality = ui.FilterQuality.low
        ..color = ui.Color.fromARGB(
          (alpha * 255).round().clamp(0, 255),
          255,
          255,
          255,
        ),
    );
    return true;
  }

  ui.Rect? _fallbackFrame(String atlas, String name, ui.Image image) {
    if (atlas != 'ZONE_TWO_OBJECTS') return null;
    final position = switch (name) {
      'ember_pit' => (0, 0),
      'thermal_vent' => (2, 0),
      'paw_print' || 'ash_print' => (3, 0),
      'crystal_sensor' => (1, 1),
      'web_pad' => (3, 1),
      'water_fruit' => (1, 2),
      'cocoon_step' => (2, 2),
      'joey_drawing' => (3, 2),
      'sticky_sap' => (0, 2),
      _ => null,
    };
    if (position == null) return null;
    final cellW = image.width / 4;
    final cellH = image.height / 3;
    return ui.Rect.fromLTWH(
      position.$1 * cellW,
      position.$2 * cellH,
      cellW,
      cellH,
    );
  }

  bool _drawAnimation(
    ui.Canvas canvas,
    String atlasKey,
    String animationName,
    int frameIndex,
    double x,
    double y,
    double targetHeight, {
    double facing = 1,
    double alpha = 1,
  }) {
    final image = _image(atlasKey);
    final atlas = _atlases[atlasKey];
    final frames = atlas?.animations[animationName];
    if (image == null || frames == null || frames.isEmpty) {
      final numbered = atlas?.frames['${animationName}_1'];
      if (image == null || numbered?.content == null) return false;
      return _drawFrameCell(
        canvas,
        atlasKey,
        '${animationName}_1',
        ui.Rect.fromLTWH(
          x - targetHeight / 2,
          y - targetHeight,
          targetHeight,
          targetHeight,
        ),
        alpha: alpha,
      );
    }
    final frame = frames[frameIndex % frames.length];
    final crop = frame.content ?? frame.source;
    if (crop == null || crop.isEmpty) return false;
    final maxHeight = frames
        .map((item) => (item.content ?? item.source)?.height ?? 0)
        .fold<double>(0, (maximum, height) => math.max(maximum, height));
    if (maxHeight <= 0) return false;
    final scale = targetHeight / maxHeight;
    final anchor =
        frame.anchor ??
        ui.Offset(frame.source!.center.dx, frame.source!.bottom);
    final dest = ui.Rect.fromLTWH(
      -(anchor.dx - crop.left) * scale,
      -(anchor.dy - crop.top) * scale,
      crop.width * scale,
      crop.height * scale,
    );
    canvas.save();
    canvas.translate(x, y);
    canvas.scale(facing, 1);
    canvas.drawImageRect(
      image,
      crop,
      dest,
      ui.Paint()
        ..filterQuality = ui.FilterQuality.low
        ..color = ui.Color.fromARGB(
          (alpha * 255).round().clamp(0, 255),
          255,
          255,
          255,
        ),
    );
    canvas.restore();
    return true;
  }

  void _drawFallbackCharacter(
    ui.Canvas canvas,
    double x,
    double y,
    double radius,
    String type, {
    double facing = 1,
    double alpha = 1,
  }) {
    if (type == 'pelican') {
      _drawFallbackPelican(canvas, x, y, radius, facing, alpha);
      return;
    }
    final color = switch (type) {
      'cassowary' => const ui.Color(0xff293d50),
      'eagle' => const ui.Color(0xff6c675c),
      'joey' => const ui.Color(0xffc98b55),
      'pelican' => const ui.Color(0xffe8e4ce),
      'mima' => const ui.Color(0xff817d72),
      _ => const ui.Color(0xff987249),
    };
    final paint = ui.Paint()
      ..color = color.withAlpha((alpha * 255).round().clamp(0, 255));
    canvas.drawOval(
      ui.Rect.fromCenter(
        center: ui.Offset(x, y - radius),
        width: radius * 1.45,
        height: radius * 2,
      ),
      paint,
    );
    canvas.drawCircle(
      ui.Offset(x + facing * radius * .52, y - radius * 1.65),
      radius * .48,
      paint,
    );
    canvas.drawCircle(
      ui.Offset(x + facing * radius * .65, y - radius * 1.73),
      radius * .07,
      ui.Paint()..color = const ui.Color(0xfff5e9c6),
    );
  }

  void _drawFallbackPelican(
    ui.Canvas canvas,
    double x,
    double y,
    double size,
    double facing,
    double alpha,
  ) {
    ui.Paint fill(ui.Color color) =>
        ui.Paint()
          ..color = color.withAlpha((alpha * 255).round().clamp(0, 255));
    final ivory = fill(const ui.Color(0xffeee7d4));
    final wing = fill(const ui.Color(0xffc9c3b5));
    final beak = fill(const ui.Color(0xffe58d3b));
    final foot = fill(const ui.Color(0xffd97836));
    canvas.drawOval(
      ui.Rect.fromCenter(
        center: ui.Offset(x, y - size * .52),
        width: size * 1.35,
        height: size * .9,
      ),
      ivory,
    );
    canvas.drawOval(
      ui.Rect.fromCenter(
        center: ui.Offset(x - facing * size * .12, y - size * .55),
        width: size * .75,
        height: size * .57,
      ),
      wing,
    );
    canvas.drawCircle(
      ui.Offset(x + facing * size * .38, y - size * 1.05),
      size * .3,
      ivory,
    );
    final beakPath = ui.Path()
      ..moveTo(x + facing * size * .57, y - size * 1.08)
      ..lineTo(x + facing * size * 1.04, y - size * .96)
      ..lineTo(x + facing * size * .62, y - size * .82)
      ..quadraticBezierTo(
        x + facing * size * .52,
        y - size * .89,
        x + facing * size * .57,
        y - size * 1.08,
      )
      ..close();
    canvas.drawPath(beakPath, beak);
    canvas.drawCircle(
      ui.Offset(x + facing * size * .45, y - size * 1.12),
      size * .045,
      fill(const ui.Color(0xff332a22)),
    );
    for (final footOffset in [-.25, .25]) {
      final footX = x + size * footOffset;
      canvas.drawLine(
        ui.Offset(footX, y - size * .15),
        ui.Offset(footX, y + size * .02),
        ui.Paint()
          ..color = foot.color
          ..strokeWidth = size * .07,
      );
      canvas.drawLine(
        ui.Offset(footX, y + size * .02),
        ui.Offset(footX + facing * size * .16, y + size * .02),
        ui.Paint()
          ..color = foot.color
          ..strokeWidth = size * .06
          ..strokeCap = ui.StrokeCap.round,
      );
    }
  }

  void _drawCenteredText(
    ui.Canvas canvas,
    String text,
    ui.Offset center,
    double size,
    ui.Color color,
  ) {
    final painter = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          color: color,
          fontSize: size,
          fontWeight: FontWeight.w700,
        ),
      ),
      textDirection: TextDirection.ltr,
      textAlign: TextAlign.center,
    )..layout(maxWidth: canvasSize.x - 40);
    painter.paint(
      canvas,
      ui.Offset(center.dx - painter.width / 2, center.dy - painter.height / 2),
    );
  }
}
