import 'package:flutter/material.dart';
import '../../core/di/service_locator.dart';
import '../../core/l10n/locale_controller.dart';
import '../../domain/ports/audio_service.dart';
import '../../domain/ports/haptics_service.dart';
import '../../domain/ports/music_service.dart';
import '../../l10n/app_localizations.dart';

/// SettingsScreen — one screen to control the three feedback channels
/// (background music, sound effects, haptics) and the app language.
/// Feedback mutes persist via each service's setMuted; the language
/// choice persists via the LocaleController and rebuilds the app
/// immediately.
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final IMusicService _music = getIt<IMusicService>();
  final IAudioService _audio = getIt<IAudioService>();
  final IHapticsService _haptics = getIt<IHapticsService>();
  final LocaleController _locale = getIt<LocaleController>();

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

  Future<void> _setLocale(String code) async {
    await _locale.setLocale(Locale(code));
    if (!mounted) return;
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    const sectionStyle = TextStyle(
      fontWeight: FontWeight.bold,
      color: Colors.grey,
    );

    return Scaffold(
      appBar: AppBar(title: Text(l10n.settings)),
      body: _loaded
          ? ListView(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                  child: Text(l10n.settingsFeedbackSection, style: sectionStyle),
                ),
                SwitchListTile(
                  secondary: const Icon(Icons.music_note),
                  title: Text(l10n.backgroundMusic),
                  subtitle: Text(l10n.backgroundMusicSubtitle),
                  value: !_musicMuted,
                  onChanged: (on) => _setMusic(!on),
                ),
                SwitchListTile(
                  secondary: const Icon(Icons.volume_up),
                  title: Text(l10n.soundEffects),
                  subtitle: Text(l10n.soundEffectsSubtitle),
                  value: !_audioMuted,
                  onChanged: (on) => _setAudio(!on),
                ),
                SwitchListTile(
                  secondary: const Icon(Icons.vibration),
                  title: Text(l10n.haptics),
                  subtitle: Text(l10n.hapticsSubtitle),
                  value: !_hapticsMuted,
                  onChanged: (on) => _setHaptics(!on),
                ),
                const Divider(),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                  child: Text(l10n.settingsLanguageSection, style: sectionStyle),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                  child: SegmentedButton<String>(
                    segments: [
                      ButtonSegment<String>(
                        value: 'en',
                        label: Text(l10n.languageEnglish),
                        icon: const Icon(Icons.language),
                      ),
                      ButtonSegment<String>(
                        value: 'es',
                        label: Text(l10n.languageSpanish),
                      ),
                    ],
                    selected: {_locale.locale.languageCode},
                    onSelectionChanged: (selection) =>
                        _setLocale(selection.first),
                  ),
                ),
                const Divider(),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                  child: Text(l10n.settingsAboutSection, style: sectionStyle),
                ),
                ListTile(
                  leading: const Icon(Icons.info_outline),
                  title: Text(l10n.appTitle),
                  subtitle: const Text('v1.0.0'),
                ),
              ],
            )
          : const Center(child: CircularProgressIndicator()),
    );
  }
}
