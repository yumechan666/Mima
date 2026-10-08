import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flame/game.dart';

import 'game_data.dart';
import 'mima_game.dart';
import 'audio_manager.dart';

class GameScreen extends StatefulWidget {
  const GameScreen({super.key});

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  late final MimaGame game;

  @override
  void initState() {
    super.initState();
    game = MimaGame();
    HardwareKeyboard.instance.addHandler(_handleKey);
  }

  @override
  void dispose() {
    HardwareKeyboard.instance.removeHandler(_handleKey);
    game.hud.dispose();
    super.dispose();
  }

  bool _handleKey(KeyEvent event) {
    if (event is KeyDownEvent) {
      game.keyDown(event.logicalKey);
    } else if (event is KeyRepeatEvent) {
      game.keyDown(event.logicalKey, repeat: true);
    } else if (event is KeyUpEvent) {
      game.keyUp(
        event.logicalKey,
        HardwareKeyboard.instance.logicalKeysPressed,
      );
    }
    return false;
  }

  void _tap(VoidCallback action) {
    AudioManager.instance.playSfx('ui_click');
    action();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xff17211d),
      body: ValueListenableBuilder<GameHudState>(
          valueListenable: game.hud,
          builder: (context, state, _) => Stack(
            fit: StackFit.expand,
            children: [
              GameWidget<MimaGame>(game: game),
              if (state.ready && !state.error.isNotEmpty && !state.mainMenu) ...[
                _buildHud(state),
                _buildControls(state),
                if (state.toast.isNotEmpty) _toast(state),
                if (state.prompt.isNotEmpty && !state.paused)
                  _prompt(state.prompt),
              ],
              if (state.loading) _loadingOverlay(),
              if (state.busy && state.error.isEmpty) _busyOverlay(),
              if (state.error.isNotEmpty) _errorOverlay(state.error),
              if (state.mainMenu && state.error.isEmpty) _mainMenuOverlay(state),
              if (state.skinMenu && state.error.isEmpty) _skinOverlay(state),
              if (state.areaMenu && state.error.isEmpty) _themeOverlay(state),
              if (state.paused &&
                  !state.mainMenu &&
                  !state.skinMenu &&
                  !state.areaMenu &&
                  !state.victory &&
                  state.error.isEmpty)
                _pauseOverlay(state),
              if (state.victory) _victoryOverlay(state),
            ],
          ),
        ),
    );
  }

  Widget _buildHud(GameHudState state) {
    return SafeArea(
      child: Align(
        alignment: Alignment.topCenter,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(10, 8, 10, 0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Flexible(
                    fit: FlexFit.tight,
                    child: _badge(
                      child: Row(
                        children: [
                          Text(
                            (state.area + 1).toString().padLeft(2, '0'),
                            style: const TextStyle(
                              color: Color(0xfff4c75d),
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Flexible(
                            child: Text(
                              '${state.areaName}${state.chapter.isEmpty ? '' : ' · ${state.chapter}'}',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  _badge(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text(
                          '◆',
                          style: TextStyle(color: Color(0xffffd35c)),
                        ),
                        const SizedBox(width: 4),
                        Text('${state.leaves}/60'),
                        Text(
                          ' · ${state.clues}/20',
                          style: const TextStyle(color: Color(0xffbce7de)),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 6),
                  _badge(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        for (var index = 0; index < 3; index++)
                          Padding(
                            padding: EdgeInsets.only(right: index == 2 ? 0 : 3),
                            child: Icon(
                              Icons.favorite,
                              size: 17,
                              color: index < state.hearts
                                  ? const Color(0xffe98669)
                                  : const Color(0xff786f60),
                            ),
                          ),
                        const SizedBox(width: 3),
                        _iconButton(
                          Icons.public,
                          'Pilih tema/area',
                          game.openAreaMenu,
                        ),
                        _iconButton(
                          Icons.checkroom,
                          'Pilih skin',
                          game.openSkinMenu,
                        ),
                        _iconButton(
                          state.paused ? Icons.play_arrow : Icons.pause,
                          'Jeda',
                          game.togglePause,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 7),
              if (state.bossHealth > 0) ...[
                Container(
                  width: math.min(MediaQuery.sizeOf(context).width * .72, 420),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xe82f2627),
                    border: Border.all(color: const Color(0xbfffe198)),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Column(
                    children: [
                      const Text(
                        'Raja Kasuari',
                        style: TextStyle(
                          color: Color(0xffffe7a4),
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 4),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: LinearProgressIndicator(
                          value: state.bossHealth / state.bossMaxHealth,
                          minHeight: 8,
                          color: const Color(0xffe99a4c),
                          backgroundColor: Colors.white24,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 5),
              ],
              Container(
                constraints: BoxConstraints(
                  maxWidth: MediaQuery.sizeOf(context).width * .78,
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xd92c3024),
                  border: Border.all(color: const Color(0x73fff6cf)),
                  borderRadius: BorderRadius.circular(22),
                  boxShadow: const [
                    BoxShadow(color: Color(0x55302219), offset: Offset(0, 3)),
                  ],
                ),
                child: Text(
                  state.objective,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Color(0xfffff5cf),
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _badge({required Widget child}) => Container(
    constraints: const BoxConstraints(minHeight: 40),
    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 7),
    decoration: BoxDecoration(
      color: const Color(0xd92c3024),
      border: Border.all(color: const Color(0x73fff6cf)),
      borderRadius: BorderRadius.circular(15),
      boxShadow: const [
        BoxShadow(color: Color(0x55302219), offset: Offset(0, 3)),
      ],
    ),
    child: DefaultTextStyle(
      style: const TextStyle(
        color: Color(0xfffff8dc),
        fontSize: 11,
        fontWeight: FontWeight.w800,
      ),
      child: child,
    ),
  );

  Widget _iconButton(IconData icon, String label, VoidCallback onPressed) =>
      Tooltip(
        message: label,
        child: InkResponse(
          onTap: () => _tap(onPressed),
          radius: 22,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 3),
            child: Icon(icon, size: 21, color: const Color(0xfffff8dc)),
          ),
        ),
      );

  Widget _buildControls(GameHudState state) {
    if (state.paused ||
        state.mainMenu ||
        state.skinMenu ||
        state.areaMenu ||
        state.victory) {
      return const SizedBox.shrink();
    }
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(18, 0, 18, 18),
        child: Align(
          alignment: Alignment.bottomCenter,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _joystick(),
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  _gameButton(
                    '◎',
                    'Insting',
                    onTap: game.triggerScent,
                    accent: const Color(0xff547f72),
                  ),
                  const SizedBox(width: 10),
                  _gameButton(
                    '✦',
                    'Aksi',
                    onTap: game.triggerAction,
                    accent: const Color(0xff68704d),
                  ),
                  const SizedBox(width: 10),
                  GestureDetector(
                    onTapDown: (_) => game.setJumpHeld(true),
                    onTapUp: (_) => game.setJumpHeld(false),
                    onTapCancel: () => game.setJumpHeld(false),
                    child: _gameButton(
                      '↑',
                      'Lompat',
                      accent: const Color(0xffe4c46d),
                      foreground: const Color(0xff3e3221),
                      size: 78,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _joystick() {
    return SizedBox(
      width: 116,
      height: 116,
      child: GestureDetector(
        onPanStart: (details) => _moveJoystick(details.localPosition),
        onPanUpdate: (details) => _moveJoystick(details.localPosition),
        onPanEnd: (_) => game.setMove(0, 0),
        onPanCancel: () => game.setMove(0, 0),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: const Color(0x70404d3c),
            shape: BoxShape.circle,
            border: Border.all(color: const Color(0x8afff6cf), width: 2),
            boxShadow: const [
              BoxShadow(
                color: Color(0x3340261b),
                blurRadius: 8,
                offset: Offset(0, 5),
              ),
            ],
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: const Color(0x55fff6cf)),
                ),
              ),
              ValueListenableBuilder<GameHudState>(
                valueListenable: game.hud,
                builder: (context, state, child) => Transform.translate(
                  offset: Offset(game.moveX * 23, game.moveY * 23),
                  child: Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: const Color(0xffd6c58e),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: const Color(0xff5b4a35),
                        width: 3,
                      ),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x6640261b),
                          offset: Offset(0, 4),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _moveJoystick(Offset position) {
    const center = Offset(58, 58);
    final dx = position.dx - center.dx;
    final dy = position.dy - center.dy;
    final magnitude = math.max(1, math.sqrt(dx * dx + dy * dy));
    final scale = math.min(1, 42 / magnitude);
    game.setMove(dx * scale / 42, dy * scale / 42);
  }

  Widget _gameButton(
    String icon,
    String label, {
    VoidCallback? onTap,
    Color accent = const Color(0xff547f72),
    Color foreground = const Color(0xfffff8dd),
    double size = 64,
  }) => GestureDetector(
    onTap: onTap,
    child: Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: accent.withValues(alpha: .93),
        shape: BoxShape.circle,
        border: Border.all(color: const Color(0x99fff5cf), width: 2),
        boxShadow: const [
          BoxShadow(color: Color(0x66442f20), offset: Offset(0, 5)),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            icon,
            style: TextStyle(
              color: foreground,
              fontSize: size == 78 ? 28 : 22,
              fontWeight: FontWeight.w900,
              height: 1,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: foreground,
              fontSize: 9,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    ),
  );

  Widget _toast(GameHudState state) => Positioned(
    top: MediaQuery.sizeOf(context).height * .19,
    left: 20,
    right: 20,
    child: IgnorePointer(
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
          decoration: BoxDecoration(
            color: const Color(0xe82d2a1f),
            border: Border.all(
              color: state.toastTone == 'gold'
                  ? const Color(0xccffd35e)
                  : state.toastTone == 'clue'
                  ? const Color(0xcc5de9d6)
                  : const Color(0x80fff5d0),
            ),
            borderRadius: BorderRadius.circular(22),
          ),
          child: Text(
            state.toast,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: state.toastTone == 'gold'
                  ? const Color(0xffffe38a)
                  : state.toastTone == 'clue'
                  ? const Color(0xffaef0e5)
                  : const Color(0xfffff6d9),
              fontSize: 13,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ),
    ),
  );

  Widget _prompt(String prompt) => Positioned(
    bottom: 150,
    left: 0,
    right: 0,
    child: IgnorePointer(
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 8),
          decoration: BoxDecoration(
            color: const Color(0xe82d2a1f),
            border: Border.all(color: const Color(0x99fff5d0)),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xfff0c96c),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Text(
                  'AKSI',
                  style: TextStyle(
                    color: Color(0xff3c3425),
                    fontSize: 9,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                prompt,
                style: const TextStyle(
                  color: Color(0xfffff6d9),
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );

  Widget _busyOverlay() => Container(
    color: const Color(0xc816231f),
    child: const Center(
      child: CircularProgressIndicator(
        color: Color(0xffd5b652),
        strokeWidth: 4,
      ),
    ),
  );

  Widget _loadingOverlay() => Container(
    color: const Color(0xee16231f),
    child: const Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 48,
            height: 48,
            child: CircularProgressIndicator(
              color: Color(0xffd5b652),
              strokeWidth: 4,
            ),
          ),
          SizedBox(height: 18),
          Text(
            'Menumbuhkan kanopi…',
            style: TextStyle(
              color: Color(0xfffff1c0),
              fontSize: 18,
              fontWeight: FontWeight.w900,
            ),
          ),
          SizedBox(height: 6),
          Text('Memuat dunia Mima', style: TextStyle(color: Color(0xffa9d2bd))),
        ],
      ),
    ),
  );

  Widget _errorOverlay(String message) => _modal(
    kicker: 'ASSET GAME',
    title: 'Kanopi belum tumbuh',
    body: message,
    actions: [
      FilledButton(
        onPressed: () => _tap(() => setState(() {})),
        child: const Text('Coba lagi'),
      ),
    ],
  );

  Widget _skinOverlay(GameHudState state) => _modal(
    kicker: 'PILIH PETUALANG',
    title: 'Pilih kulit Mima',
    body:
        'Semua 10 skin terbuka. Frame gerak, lompat, dan aksi mengikuti skin yang dipilih.',
    actions: [
      SizedBox(
        height: math.min(MediaQuery.sizeOf(context).height * .45, 340),
        width: 440,
        child: GridView.builder(
          padding: const EdgeInsets.all(2),
          itemCount: skinNames.length,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            mainAxisSpacing: 8,
            crossAxisSpacing: 8,
            childAspectRatio: 2.25,
          ),
          itemBuilder: (context, index) {
            final selected = index == state.skinIndex;
            return OutlinedButton(
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xfffff2c7),
                backgroundColor: selected
                    ? const Color(0xff5b694e)
                    : const Color(0xff455746),
                side: BorderSide(
                  color: selected
                      ? const Color(0xfff1d36f)
                      : const Color(0x66ebdaa2),
                  width: selected ? 2 : 1,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              onPressed: selected ? null : () => game.selectSkin(index),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (selected) ...[
                    const Icon(
                      Icons.check_circle,
                      size: 16,
                      color: Color(0xfff1d36f),
                    ),
                    const SizedBox(width: 5),
                  ],
                  Flexible(
                    child: Text(
                      skinNames[index],
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: selected ? 13 : 12,
                        fontWeight: selected
                            ? FontWeight.w900
                            : FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
      if (state.ready)
        TextButton(
          onPressed: () => _tap(game.closeSkinMenu),
          child: const Text(
            'Tutup dan lanjut bermain',
            style: TextStyle(color: Color(0xffc8e4d4)),
          ),
        ),
    ],
  );

  Widget _themeOverlay(GameHudState state) => _modal(
    kicker: 'PETA PETUALANGAN',
    title: 'Pilih tema / area',
    body: 'Semua 20 tema terbuka. Pilih area untuk langsung memainkannya.',
    actions: [
      SizedBox(
        height: math.min(MediaQuery.sizeOf(context).height * .52, 390),
        width: 440,
        child: GridView.builder(
          padding: const EdgeInsets.all(2),
          itemCount: levelDefinitions.length,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            mainAxisSpacing: 8,
            crossAxisSpacing: 8,
            childAspectRatio: 2.05,
          ),
          itemBuilder: (context, index) {
            final level = levelDefinitions[index];
            final selected = index == state.area;
            final locked = index > game.maxAreaUnlocked;
            return OutlinedButton(
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xfffff2c7),
                backgroundColor: locked
                    ? const Color(0xff33392f)
                    : selected
                    ? const Color(0xff5b694e)
                    : const Color(0xff455746),
                side: BorderSide(
                  color: locked
                      ? const Color(0x44ebdaa2)
                      : selected
                      ? const Color(0xfff1d36f)
                      : const Color(0x66ebdaa2),
                  width: selected ? 2 : 1,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(13),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 5),
              ),
              onPressed: locked ? null : () => game.selectArea(index),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    '${(index + 1).toString().padLeft(2, '0')} · ${level.name}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 3),
                  if (locked)
                    const Text(
                      'Terkunci',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 9,
                        color: Color(0xffd98c8c),
                      ),
                    )
                  else
                    Text(
                      level.subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 9,
                        color: Color(0xffc8e4d4),
                      ),
                    ),
                ],
              ),
            );
          },
        ),
      ),
      TextButton(
        onPressed: () => _tap(game.closeAreaMenu),
        child: const Text(
          'Tutup dan lanjut bermain',
          style: TextStyle(color: Color(0xffc8e4d4)),
        ),
      ),
    ],
  );

  Widget _pauseOverlay(GameHudState state) => _modal(
    kicker: 'PETUALANGAN DIJEDA',
    title: 'Dahan yang aman',
    body:
        '${state.leaves}/60 daun · ${state.clues}/20 jejak · ${state.carvings}/20 ukiran',
    actions: [
      FilledButton(onPressed: () => _tap(game.resume), child: const Text('Lanjut')),
      OutlinedButton(
        onPressed: () => _tap(game.openAreaMenu),
        child: const Text('Pilih tema / area'),
      ),
      OutlinedButton(
        onPressed: () => _tap(game.restartCheckpoint),
        child: const Text('Ulang dari dahan aman'),
      ),
      TextButton(
        onPressed: () => _tap(game.openSkinMenu),
        child: const Text('Pilih kulit Mima'),
      ),
      TextButton(
        onPressed: () => _tap(game.openMainMenu),
        child: const Text('Menu utama'),
      ),
    ],
  );

  Widget _mainMenuOverlay(GameHudState state) => _modal(
    kicker: 'PETUALANGAN OUTBACK',
    title: 'Mima & The Lost Outback',
    body:
        'Bantu Mima menembus dua puluh kanopi yang layu untuk menemukan Joey yang hilang.',
    actions: [
      FilledButton(
        onPressed: () => _tap(game.beginGameplay),
        child: const Text('Mulai petualangan'),
      ),
      if (game.hasProgress)
        OutlinedButton(
          onPressed: () => _tap(game.continueGame),
          child: const Text('Lanjut bermain'),
        ),
      OutlinedButton(
        onPressed: () => _tap(game.openAreaMenuFromMain),
        child: const Text('Pilih tema / area'),
      ),
      OutlinedButton(
        onPressed: () => _tap(game.openSkinMenuFromMain),
        child: const Text('Pilih kulit Mima'),
      ),
    ],
  );

  Widget _victoryOverlay(GameHudState state) => _modal(
    kicker: state.frontierVictory
        ? 'BADAI TELAH REDA'
        : 'PETUALANGAN BERLANJUT',
    title: state.frontierVictory ? 'Mahkota badai tenang' : 'Joey selamat',
    body: state.frontierVictory
        ? 'Raja Kasuari mundur. Dua puluh kawasan kini terhubung.'
        : 'Mima dan Joey selamat. Wilayah baru terbuka di balik Baobab.\n\n${state.leaves}/60 daun · ${state.clues}/20 jejak · ${state.carvings}/20 ukiran',
    actions: [
      FilledButton(
        onPressed: () => _tap(game.exploreAfterRescue),
        child: Text(
          state.frontierVictory ? 'Jelajahi ulang' : 'Lanjut ke wilayah baru',
        ),
      ),
    ],
  );

  Widget _modal({
    required String kicker,
    required String title,
    required String body,
    required List<Widget> actions,
  }) => Container(
    color: const Color(0xe816231f),
    padding: const EdgeInsets.all(22),
    child: Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 520, maxHeight: 620),
        child: Container(
          padding: const EdgeInsets.fromLTRB(24, 23, 24, 20),
          decoration: BoxDecoration(
            color: const Color(0xff374638),
            border: Border.all(color: const Color(0xffc7b57c), width: 2),
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(25),
              topRight: Radius.circular(12),
              bottomLeft: Radius.circular(14),
              bottomRight: Radius.circular(28),
            ),
            boxShadow: const [
              BoxShadow(
                color: Color(0x88412d20),
                blurRadius: 8,
                offset: Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                kicker,
                style: const TextStyle(
                  color: Color(0xffd9c98e),
                  fontSize: 10,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 2,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Color(0xfffff3cd),
                  fontSize: 25,
                  fontWeight: FontWeight.w900,
                  height: 1.1,
                ),
              ),
              const SizedBox(height: 9),
              Text(
                body,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Color(0xffdce4cf),
                  fontSize: 13,
                  height: 1.35,
                ),
              ),
              const SizedBox(height: 17),
              ...actions.map(
                (action) => Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: SizedBox(width: double.infinity, child: action),
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}
