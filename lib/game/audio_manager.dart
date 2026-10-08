import 'dart:async';

import 'package:audioplayers/audioplayers.dart';

class AudioManager {
  AudioManager._();
  static final AudioManager instance = AudioManager._();

  final AudioPlayer bgmPlayer = AudioPlayer();
  final List<AudioPlayer> _sfxPool = [];
  int _sfxIndex = 0;
  static const int _poolSize = 6;
  final Set<String> _broken = {};
  final double _sfxVolume = 0.55;
  final double _bgmVolume = 0.6;

  bool sfxEnabled = true;
  bool musicEnabled = true;

  AudioContext _noFocusContext() => AudioContext(
        android: AudioContextAndroid(
          isSpeakerphoneOn: false,
          stayAwake: false,
          contentType: AndroidContentType.music,
          usageType: AndroidUsageType.media,
          audioFocus: AndroidAudioFocus.none,
        ),
        iOS: AudioContextIOS(
          category: AVAudioSessionCategory.playback,
          options: const <AVAudioSessionOptions>{
            AVAudioSessionOptions.mixWithOthers,
          },
        ),
      );

  Future<void> init() async {
    try {
      await bgmPlayer.setAudioContext(_noFocusContext());
      await bgmPlayer.setReleaseMode(ReleaseMode.loop);
    } catch (_) {
      // Audio context is optional; keep going even if it fails.
    }
    // Async native errors (mis. MEDIA_ERROR_SERVER_DIED) datang lewat event
    // stream, bukan dari Future play(); tangkap di sini agar tidak jadi
    // unhandled exception yang mematikan game.
    bgmPlayer.eventStream.listen((_) {}, onError: (_) {});
    // Pakai sekumpulan player tetap yang dipakai ulang. Membuat AudioPlayer
    // baru tiap SFX membuat MediaCodec Android kehabisan resource dan crash
    // fatal saat asset gagal diputar.
    for (var i = 0; i < _poolSize; i++) {
      final player = AudioPlayer();
      try {
        await player.setAudioContext(_noFocusContext());
        await player.setReleaseMode(ReleaseMode.release);
      } catch (_) {
        // Lanjutkan; player tetap bisa dipakai tanpa context khusus.
      }
      player.eventStream.listen((_) {}, onError: (_) {});
      _sfxPool.add(player);
    }
  }

  Future<void> playSfx(String name) async {
    if (!sfxEnabled || _broken.contains(name) || _sfxPool.isEmpty) return;
    final player = _sfxPool[_sfxIndex];
    _sfxIndex = (_sfxIndex + 1) % _sfxPool.length;
    try {
      await player.stop();
      await player.setVolume(_sfxVolume);
      await player.play(AssetSource('audio/$name.mp3'));
    } catch (_) {
      // Asset audio masih dummy/kosong; tandai agar tidak terus dicoba.
      _broken.add(name);
    }
  }

  Future<void> playBgm(String name) async {
    if (!musicEnabled) return;
    try {
      await bgmPlayer.stop();
      await bgmPlayer.setReleaseMode(ReleaseMode.loop);
      await bgmPlayer.setVolume(_bgmVolume);
      for (var attempt = 0; attempt < 2; attempt++) {
        try {
          await bgmPlayer.play(AssetSource('audio/$name.mp3'));
          return;
        } catch (_) {
          // stop/play beruntun terkadang terlewat; coba lagi sebentar.
          await Future<void>.delayed(const Duration(milliseconds: 60));
        }
      }
    } catch (_) {
      // Asset BGM masih dummy/kosong; abaikan.
    }
  }

  Future<void> pauseBgm() async {
    try {
      await bgmPlayer.pause();
    } catch (_) {
      // Abaikan jika belum diputar.
    }
  }

  Future<void> resumeBgm() async {
    if (!musicEnabled) return;
    try {
      if (bgmPlayer.state == PlayerState.stopped) {
        await playBgm('bgm');
      } else {
        await bgmPlayer.resume();
      }
    } catch (_) {
      // Abaikan.
    }
  }

  Future<void> stopBgm() async {
    try {
      await bgmPlayer.stop();
    } catch (_) {
      // Abaikan.
    }
  }
}
