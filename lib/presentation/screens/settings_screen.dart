import 'package:flutter/material.dart';

import '../../core/di/service_locator.dart';
import '../../domain/ports/audio_service.dart';
import '../../domain/ports/haptics_service.dart';
import '../../domain/ports/music_service.dart';

/// SettingsScreen — one screen to control all three feedback channels
/// (background music, sound effects, haptics). Loads the persisted
/// mute state on init via each service's readMuted; toggles persist
/// immediately via setMuted.
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final IMusicService _music = getIt<IMusicService>();
  final IAudioService _audio = getIt<IAudioService>();
  final IHapticsService _haptics = getIt<IHapticsService>();

  bool _loaded = false;
  bool _musicMuted = false;
  bool _audioMuted = false;
  bool _hapticsMuted = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final results = await Future.wait([
      _music.readMuted(),
      _audio.readMuted(),
      _haptics.readMuted(),
    ]);
    if (!mounted) return;
    setState(() {
      _musicMuted = results[0];
      _audioMuted = results[1];
      _hapticsMuted = results[2];
      _loaded = true;
    });
  }

  Future<void> _setMusic(bool muted) async {
    await _music.setMuted(muted);
    if (!mounted) return;
    setState(() => _musicMuted = muted);
  }

  Future<void> _setAudio(bool muted) async {
    await _audio.setMuted(muted);
    if (!mounted) return;
    setState(() => _audioMuted = muted);
  }

  Future<void> _setHaptics(bool muted) async {
    await _haptics.setMuted(muted);
    if (!mounted) return;
    setState(() => _hapticsMuted = muted);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: _loaded
          ? ListView(
              children: [
                const Padding(
                  padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
                  child: Text(
                    'Feedback',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.grey,
                    ),
                  ),
                ),
                SwitchListTile(
                  secondary: const Icon(Icons.music_note),
                  title: const Text('Background music'),
                  subtitle: const Text('Loops during play'),
                  value: !_musicMuted,
                  onChanged: (on) => _setMusic(!on),
                ),
                SwitchListTile(
                  secondary: const Icon(Icons.volume_up),
                  title: const Text('Sound effects'),
                  subtitle: const Text('Tap and event feedback'),
                  value: !_audioMuted,
                  onChanged: (on) => _setAudio(!on),
                ),
                SwitchListTile(
                  secondary: const Icon(Icons.vibration),
                  title: const Text('Haptics'),
                  subtitle: const Text('Vibration on tap and events'),
                  value: !_hapticsMuted,
                  onChanged: (on) => _setHaptics(!on),
                ),
                const Divider(),
                const Padding(
                  padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
                  child: Text(
                    'About',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.grey,
                    ),
                  ),
                ),
                const ListTile(
                  leading: Icon(Icons.info_outline),
                  title: Text('Arrow Maze'),
                  subtitle: Text('v1.0.0'),
                ),
              ],
            )
          : const Center(child: CircularProgressIndicator()),
    );
  }
}
