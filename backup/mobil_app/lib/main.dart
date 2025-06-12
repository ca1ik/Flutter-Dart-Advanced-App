import 'dart:async';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:audioplayers/audioplayers.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});
  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final AudioPlayer _audioPlayer = AudioPlayer();
  bool _isDarkMode = false;
  double _volume = 1.0;

  @override
  void initState() {
    super.initState();
    _initMusic();
  }

  Future<void> _initMusic() async {
    // Müzik döngüsel oynasın
    _audioPlayer.setReleaseMode(ReleaseMode.loop);
    // assets/background.mp3 yolunu pubspec.yaml'de eklediğine emin ol
    await _audioPlayer.play(AssetSource('background.mp3'), volume: _volume);
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Birleşik Mobil Uygulama',
      debugShowCheckedModeBanner: false,
      theme: _isDarkMode ? ThemeData.dark() : ThemeData.light(),
      home: MainPage(
        audioPlayer: _audioPlayer,
        isDarkMode: _isDarkMode,
        volume: _volume,
        onThemeChanged: (dark) => setState(() => _isDarkMode = dark),
        onVolumeChanged: (vol) {
          setState(() => _volume = vol);
          _audioPlayer.setVolume(vol);
        },
      ),
    );
  }
}

enum _Mode { menu, mask, settings }

class MainPage extends StatefulWidget {
  final AudioPlayer audioPlayer;
  final bool isDarkMode;
  final double volume;
  final ValueChanged<bool> onThemeChanged;
  final ValueChanged<double> onVolumeChanged;

  const MainPage({
    required this.audioPlayer,
    required this.isDarkMode,
    required this.volume,
    required this.onThemeChanged,
    required this.onVolumeChanged,
    super.key,
  });

  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  _Mode _mode = _Mode.menu;
  ui.Image? _originalImage;
  List<Offset> _maskPoints = [];
  double _brushSize = 20.0;
  Uint8List? _displayBytes;
  final ImagePicker _picker = ImagePicker();

  Future<void> _pickAndResizeImage() async {
    final xfile = await _picker.pickImage(source: ImageSource.gallery);
    if (xfile == null) return;
    final bytes = await xfile.readAsBytes();
    final codec = await ui.instantiateImageCodec(
      bytes,
      targetWidth: 256,
      targetHeight: 256,
    );
    final frame = await codec.getNextFrame();
    setState(() {
      _originalImage = frame.image;
      _displayBytes = bytes;
      _maskPoints.clear();
      _mode = _Mode.mask;
    });
  }

  void _addMaskPoint(Offset pos) {
    setState(() {
      _maskPoints.add(pos);
    });
  }

  void _finishMask() {
    // Burada metrik hesaplama ve maskeli görsel oluşturma ekleyebilirsin
    setState(() {
      _mode = _Mode.menu;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          _mode == _Mode.menu
              ? 'Ana Menü'
              : _mode == _Mode.mask
                  ? 'Maske Oluştur'
                  : 'Ayarlar',
        ),
      ),
      drawer: Drawer(
        child: ListView(
          children: [
            DrawerHeader(
              child: Text(
                'Menü',
                style: Theme.of(context).textTheme.titleLarge,
              ),
            ),
            ListTile(
              leading: const Icon(Icons.image),
              title: const Text('Resim Seç ve Maskele'),
              onTap: () {
                Navigator.pop(context);
                _pickAndResizeImage();
              },
            ),
            ListTile(
              leading: const Icon(Icons.settings),
              title: const Text('Ayarlar'),
              onTap: () {
                Navigator.pop(context);
                setState(() {
                  _mode = _Mode.settings;
                });
              },
            ),
          ],
        ),
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    switch (_mode) {
      case _Mode.menu:
        return _buildMenu();
      case _Mode.mask:
        return _buildMaskPage();
      case _Mode.settings:
        return _buildSettingsPage();
    }
  }

  Widget _buildMenu() {
    return SingleChildScrollView(
      child: Center(
        child: Column(
          children: [
            const SizedBox(height: 24),
            ElevatedButton.icon(
              icon: const Icon(Icons.image),
              label: const Text('Resim Seç ve Maskele'),
              onPressed: _pickAndResizeImage,
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              icon: const Icon(Icons.settings),
              label: const Text('Ayarlar'),
              onPressed: () => setState(() => _mode = _Mode.settings),
            ),
            const SizedBox(height: 32),
            if (_displayBytes != null) ...[
              const Text('Son Maskeli Görsel ve Metrikler'),
              const SizedBox(height: 8),
              Image.memory(_displayBytes!, width: 256, height: 256),
              const SizedBox(height: 8),
              const Text('Metrik 1: ...'),
              const Text('Metrik 2: ...'),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildMaskPage() {
    if (_originalImage == null) {
      return const Center(child: Text('Lütfen önce bir resim seçin.'));
    }
    return Column(
      children: [
        Expanded(
          child: Center(
            child: GestureDetector(
              onPanDown: (e) => _addMaskPoint(e.localPosition),
              onPanUpdate: (e) => _addMaskPoint(e.localPosition),
              child: CustomPaint(
                painter: ImageMaskPainter(
                  image: _originalImage!,
                  points: _maskPoints,
                  brushSize: _brushSize,
                ),
                child: const SizedBox(width: 256, height: 256),
              ),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              const Text('Fırça Boyutu'),
              Expanded(
                child: Slider(
                  min: 5,
                  max: 100,
                  value: _brushSize,
                  onChanged: (v) => setState(() => _brushSize = v),
                ),
              ),
              Text(_brushSize.toInt().toString()),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: ElevatedButton(
            onPressed: _finishMask,
            child: const Text('Bitir'),
          ),
        ),
      ],
    );
  }

  Widget _buildSettingsPage() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Row(
            children: [
              const Text('Gece Modu'),
              const Spacer(),
              Switch(
                value: widget.isDarkMode,
                onChanged: widget.onThemeChanged,
              ),
            ],
          ),
          Row(
            children: [
              const Text('Müzik Sesi'),
              Expanded(
                child: Slider(
                  min: 0,
                  max: 1,
                  value: widget.volume,
                  onChanged: widget.onVolumeChanged,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class ImageMaskPainter extends CustomPainter {
  final ui.Image image;
  final List<Offset> points;
  final double brushSize;

  ImageMaskPainter({
    required this.image,
    required this.points,
    required this.brushSize,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Orijinal resmi çiz
    canvas.drawImage(image, Offset.zero, Paint());
    // Maskeyi çiz
    final p = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;
    for (var pt in points) {
      canvas.drawCircle(pt, brushSize / 2, p);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => true;
}
