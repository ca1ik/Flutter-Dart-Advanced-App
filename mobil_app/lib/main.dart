import 'dart:async';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:audioplayers/audioplayers.dart';

void main() {
  runApp(const MyApp());
}

/// Ana Uygulama Widget'ı
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Birleşik Mobil Uygulama',
      theme: ThemeData.light(useMaterial3: true),
      darkTheme: ThemeData.dark(useMaterial3: true),
      themeMode: ThemeMode.system,
      home: const HomeScreen(),
    );
  }
}

/// Ana Sayfa: Alt sekmelerle Settings - Modules - Help sayfalarını yönetir
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;

  // Pages: Her biri ayrı widget olarak tanımlanacak
  static const List<Widget> _pages = [
    SettingsPage(),
    ModulesPage(),
    HelpPage(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(child: _pages[_currentIndex]),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        selectedItemColor: Theme.of(context).colorScheme.primary,
        unselectedItemColor: Colors.grey,
        onTap: (index) => setState(() => _currentIndex = index),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.settings), label: 'Ayarlar'),
          BottomNavigationBarItem(icon: Icon(Icons.image), label: 'Modüller'),
          BottomNavigationBarItem(icon: Icon(Icons.help), label: 'Yardım'),
        ],
      ),
    );
  }
}

/// ---------------------------
/// Ayarlar Sayfası
/// ---------------------------
class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  bool _isFullscreen = false;
  bool _isSoundOn = false;
  double _volume = 50;
  late AudioPlayer _audioPlayer;

  @override
  void initState() {
    super.initState();
    _audioPlayer = AudioPlayer();
    _audioPlayer.setReleaseMode(ReleaseMode.loop);
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }

  void _toggleFullscreen() {
    setState(() {
      _isFullscreen = !_isFullscreen;
      // fullscreen toggling logic platform specific, burada simule ediliyor
    });
  }

  void _toggleSound() async {
    setState(() => _isSoundOn = !_isSoundOn);
    if (_isSoundOn) {
      await _audioPlayer.play(AssetSource('music.mp3'));
      await _audioPlayer.setVolume(_volume / 100);
    } else {
      await _audioPlayer.pause();
    }
  }

  void _setVolume(double val) async {
    setState(() {
      _volume = val;
    });
    if (_isSoundOn) {
      await _audioPlayer.setVolume(_volume / 100);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      appBar: AppBar(title: const Text('Ayarlar')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: SizedBox(
          height: screenHeight * 0.8,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Tam Ekran Modu: ${_isFullscreen ? "Açık" : "Kapalı"}',
                style: theme.textTheme.titleLarge,
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _toggleFullscreen,
                child: Text(_isFullscreen ? 'Tam Ekran Kapat' : 'Tam Ekran Aç'),
              ),
              const SizedBox(height: 32),
              Text('Ses Durumu: ${_isSoundOn ? "Açık" : "Kapalı"}',
                  style: theme.textTheme.titleLarge),
              const SizedBox(height: 8),
              ElevatedButton(
                onPressed: _toggleSound,
                child: Text(_isSoundOn ? 'Sesi Kapat' : 'Sesi Aç'),
              ),
              const SizedBox(height: 24),
              Text('Ses Seviyesi: ${_volume.round()}',
                  style: theme.textTheme.titleLarge),
              Slider(
                value: _volume,
                min: 0,
                max: 100,
                divisions: 20,
                label: _volume.round().toString(),
                onChanged: _setVolume,
              ),
              const Spacer(),
              Text(
                'Bu sayfada uygulama ayarları bulunur. Ses ve tam ekran modunu yönetebilirsiniz.',
                style: theme.textTheme.bodyMedium,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// ---------------------------
/// Modüller Sayfası
/// ---------------------------
class ModulesPage extends StatefulWidget {
  const ModulesPage({super.key});

  @override
  State<ModulesPage> createState() => _ModulesPageState();
}

class _ModulesPageState extends State<ModulesPage> {
  final ImagePicker _picker = ImagePicker();

  File? _selectedFile;
  ui.Image? _uiImage;
  bool _isProcessing = false;
  String? _error;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      appBar: AppBar(title: const Text('Modüller')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ElevatedButton.icon(
              icon: const Icon(Icons.photo_library),
              label: const Text('Resim Seç ve Maskele'),
              onPressed: _isProcessing ? null : _pickAndMaskImage,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                textStyle: const TextStyle(fontSize: 18),
              ),
            ),
            const SizedBox(height: 20),
            if (_isProcessing) const Center(child: CircularProgressIndicator()),
            if (_error != null) _buildErrorBox(_error!, theme),
            if (_selectedFile != null)
              Container(
                height: screenHeight * 0.4,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black26,
                      blurRadius: 6,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.file(_selectedFile!, fit: BoxFit.contain),
                ),
              ),
            if (_selectedFile == null && _error == null)
              Container(
                height: screenHeight * 0.25,
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceVariant,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: Text(
                    'Henüz resim seçilmedi.',
                    style: theme.textTheme.bodyLarge,
                  ),
                ),
              ),
            const SizedBox(height: 16),
            if (_uiImage != null)
              CustomPaint(
                size: Size(double.infinity, screenHeight * 0.3),
                painter: ImageMaskPainter(_uiImage!),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorBox(String message, ThemeData theme) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.errorContainer,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        message,
        style: theme.textTheme.bodyMedium
            ?.copyWith(color: theme.colorScheme.onErrorContainer),
      ),
    );
  }

  Future<void> _pickAndMaskImage() async {
    try {
      setState(() {
        _isProcessing = true;
        _error = null;
        _uiImage = null;
      });

      final XFile? picked =
          await _picker.pickImage(source: ImageSource.gallery);
      if (picked == null) {
        setState(() {
          _isProcessing = false;
          _error = "Resim seçilmedi.";
        });
        return;
      }

      final File file = File(picked.path);
      final data = await file.readAsBytes();
      final codec = await ui.instantiateImageCodec(data);
      final frame = await codec.getNextFrame();

      setState(() {
        _selectedFile = file;
        _uiImage = frame.image;
        _isProcessing = false;
      });
    } catch (e) {
      setState(() {
        _isProcessing = false;
        _error = "Resim yüklenirken hata oluştu: $e";
      });
    }
  }
}

/// Custom Painter: Basit maskeleme efekti çizimi
class ImageMaskPainter extends CustomPainter {
  final ui.Image image;

  ImageMaskPainter(this.image);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint();

    // Resmi tam ekrana sığdırmak için ölçek hesapla
    final scale = size.width / image.width;
    final scaledHeight = image.height * scale;

    // Resmi ölçekli olarak çiz
    final dst = Rect.fromLTWH(
        0, (size.height - scaledHeight) / 2, size.width, scaledHeight);
    canvas.drawImageRect(
        image,
        Rect.fromLTWH(0, 0, image.width.toDouble(), image.height.toDouble()),
        dst,
        paint);

    // Maske olarak yarım saydam siyah bir katman çiz
    final maskPaint = Paint()..color = Colors.black.withOpacity(0.5);
    canvas.drawRect(dst, maskPaint);

    // Maske alanını daha karmaşık yapabiliriz, şimdilik basit siyah yarı saydam
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// ---------------------------
/// Yardım Sayfası
/// ---------------------------
class HelpPage extends StatelessWidget {
  const HelpPage({super.key});

  @override
  Widget build(BuildContext context) {
    final fgColor = Theme.of(context).colorScheme.onBackground;
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      appBar: AppBar(title: const Text('Yardım')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: SizedBox(
          height: screenHeight * 0.85,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Uygulama Kullanımı',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 12),
              const Text(
                '''
1. Modüller sayfasından resim seçip üzerine maskeleme yapabilirsiniz.
2. Ayarlar sayfasında ses ve tam ekran modunu kontrol edebilirsiniz.
3. Ses seviyesi slider ile ayarlanabilir.
4. Yardım sayfasında bu kullanım bilgileri görüntülenir.
5. Modüller sayfasında seçilen resim ekranda gösterilir.
6. Yardım kısmında uygulama kullanımına dair bilgiler bulunur.
7. Ses seviyesi kaydırıcıyla kolayca ayarlanır.
''',
                style: TextStyle(fontSize: 18, height: 1.4),
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                icon: const Icon(Icons.contact_support),
                label: const Text('İletişim'),
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      title: const Text('İletişim'),
                      content: const Text(
                          'E-posta: destek@ornekapp.com\nTelefon: 0123 456 7890'),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.of(ctx).pop(),
                          child: const Text('Kapat'),
                        ),
                      ],
                    ),
                  );
                },
              ),
              const Spacer(),
              Text(
                '© 2025 OrnekApp. Tüm hakları saklıdır.',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
