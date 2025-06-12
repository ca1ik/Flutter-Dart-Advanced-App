import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import 'Menu.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final AudioPlayer audioPlayer = AudioPlayer();
  bool isDarkMode = true;
  double volume = 1.0;

  @override
  void initState() {
    super.initState();
    // Müzik döngüsel çalsın ve hemen başlasın
    audioPlayer.setReleaseMode(ReleaseMode.loop);
    audioPlayer.play(AssetSource('music.mp3'), volume: volume);
  }

  @override
  void dispose() {
    audioPlayer.dispose();
    super.dispose();
  }

  void onThemeChanged(bool dark) {
    setState(() => isDarkMode = dark);
  }

  void onVolumeChanged(double vol) {
    setState(() => volume = vol);
    audioPlayer.setVolume(vol);
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Gelişmiş Flutter Uygulaması',
      debugShowCheckedModeBanner: false,
      theme: isDarkMode ? ThemeData.dark() : ThemeData.light(),
      home: MenuPage(
        audioPlayer: audioPlayer,
        isDarkMode: isDarkMode,
        volume: volume,
        onThemeChanged: onThemeChanged,
        onVolumeChanged: onVolumeChanged,
      ),
    );
  }
}
