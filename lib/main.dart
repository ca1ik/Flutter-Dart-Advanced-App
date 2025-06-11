import 'dart:io';
import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:image_picker/image_picker.dart';

void main() {
  runApp(const HalreApp());
}

class HalreApp extends StatefulWidget {
  const HalreApp({super.key});

  @override
  State<HalreApp> createState() => _HalreAppState();
}

class _HalreAppState extends State<HalreApp> {
  bool _isDarkMode = false;

  void toggleTheme() {
    setState(() {
      _isDarkMode = !_isDarkMode;
    });
  }

  // Modüllerden gelen işlenmiş resmi ve metrikleri tutmak için
  File? _processedImage;
  Map<String, dynamic>? _metrics;

  void _setProcessedData(File image, Map<String, dynamic> metrics) {
    setState(() {
      _processedImage = image;
      _metrics = metrics;
      _selectedIndex = 0; // işlendikten sonra Ana Menüye yönlendirebiliriz
    });
  }

  int _selectedIndex = 0;

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    Widget body;
    switch (_selectedIndex) {
      case 0:
        body = MainMenu(
          isDarkMode: _isDarkMode,
          toggleTheme: toggleTheme,
          processedImage: _processedImage,
          metrics: _metrics,
        );
        break;
      case 1:
        body = SettingsPage(isDarkMode: _isDarkMode);
        break;
      case 2:
        body = ModulesPage(
          isDarkMode: _isDarkMode,
          onProcessed: _setProcessedData,
        );
        break;
      case 3:
        body = HelpPage(isDarkMode: _isDarkMode);
        break;
      default:
        body = MainMenu(
          isDarkMode: _isDarkMode,
          toggleTheme: toggleTheme,
          processedImage: _processedImage,
          metrics: _metrics,
        );
    }

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Halre App',
      theme: _isDarkMode ? ThemeData.dark() : ThemeData.light(),
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Halre App'),
          centerTitle: true,
          actions: [
            IconButton(
              icon: Icon(_isDarkMode ? Icons.nightlight_round : Icons.wb_sunny),
              onPressed: toggleTheme,
              tooltip: _isDarkMode ? 'Açık Mod' : 'Karanlık Mod',
            ),
          ],
        ),
        body: body,
        bottomNavigationBar: BottomNavigationBar(
          type: BottomNavigationBarType.fixed,
          currentIndex: _selectedIndex,
          onTap: _onItemTapped,
          selectedFontSize: 16,
          unselectedFontSize: 14,
          items: const [
            BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Ana Menü'),
            BottomNavigationBarItem(
                icon: Icon(Icons.settings), label: 'Ayarlar'),
            BottomNavigationBarItem(icon: Icon(Icons.apps), label: 'Modüller'),
            BottomNavigationBarItem(icon: Icon(Icons.help), label: 'Yardım'),
          ],
        ),
      ),
    );
  }
}

// Ana Menü
class MainMenu extends StatelessWidget {
  final bool isDarkMode;
  final VoidCallback toggleTheme;
  final File? processedImage;
  final Map<String, dynamic>? metrics;

  const MainMenu({
    super.key,
    required this.isDarkMode,
    required this.toggleTheme,
    this.processedImage,
    this.metrics,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (processedImage != null) ...[
              Text(
                'İşlenmiş Resim:',
                style: TextStyle(
                    fontSize: 24,
                    color: isDarkMode ? Colors.white : Colors.black),
              ),
              const SizedBox(height: 12),
              Image.file(processedImage!),
              const SizedBox(height: 16),
              if (metrics != null) ...[
                Text(
                  'Metrikler:',
                  style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: isDarkMode ? Colors.white : Colors.black),
                ),
                const SizedBox(height: 8),
                ...metrics!.entries.map((e) => Text(
                      '${e.key}: ${e.value}',
                      style: TextStyle(
                          fontSize: 18,
                          color: isDarkMode ? Colors.white70 : Colors.black87),
                    )),
              ],
            ] else
              Text(
                'Henüz işlenmiş bir resim yok.',
                style: TextStyle(
                    fontSize: 20,
                    color: isDarkMode ? Colors.white : Colors.black),
              ),
          ],
        ),
      ),
    );
  }
}

// Ayarlar Sayfası (kendi eski ayarlar kodundan sadeleştirilmiş)
class SettingsPage extends StatefulWidget {
  final bool isDarkMode;

  const SettingsPage({super.key, required this.isDarkMode});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  bool _isFullscreen = false;
  bool _isSoundOn = true;
  double _volume = 50;
  final AudioPlayer _audioPlayer = AudioPlayer();

  @override
  void initState() {
    super.initState();
    _setVolume(_volume);
    _playMusic();
  }

  void _playMusic() async {
    await _audioPlayer.setReleaseMode(ReleaseMode.loop);
    await _audioPlayer.play(AssetSource('music.mp3'));
  }

  void _setVolume(double vol) {
    final volNormalized = vol / 100;
    _audioPlayer.setVolume(volNormalized);
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              fixedSize: const Size.fromHeight(80),
              textStyle: const TextStyle(fontSize: 26),
              foregroundColor: widget.isDarkMode ? Colors.white : Colors.black,
              backgroundColor:
                  widget.isDarkMode ? Colors.grey[800] : Colors.blue,
            ),
            onPressed: () {
              setState(() {
                _isFullscreen = !_isFullscreen;
              });
              final msg = _isFullscreen ? 'Tam Ekran Açıldı' : 'Varsayılan Mod';
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(msg)),
              );
            },
            child:
                Text(_isFullscreen ? 'Tam Ekran Modu Aktif' : 'Varsayılan Mod'),
          ),
          const SizedBox(height: 32),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              fixedSize: const Size.fromHeight(80),
              textStyle: const TextStyle(fontSize: 26),
              foregroundColor: widget.isDarkMode ? Colors.white : Colors.black,
              backgroundColor:
                  widget.isDarkMode ? Colors.grey[800] : Colors.blue,
            ),
            onPressed: () {
              setState(() {
                _isSoundOn = !_isSoundOn;
              });
              _audioPlayer.setVolume(_isSoundOn ? _volume / 100 : 0);
            },
            child: Text(_isSoundOn ? 'Ses Açık' : 'Ses Kapalı'),
          ),
          const SizedBox(height: 16),
          Opacity(
            opacity: _isSoundOn ? 1 : 0.5,
            child: Slider(
              value: _volume,
              min: 0,
              max: 100,
              divisions: 100,
              label: _volume.round().toString(),
              onChanged: _isSoundOn
                  ? (value) {
                      setState(() {
                        _volume = value;
                      });
                      _setVolume(_volume);
                    }
                  : null,
            ),
          ),
        ],
      ),
    );
  }
}

// Modüller Sayfası
class ModulesPage extends StatefulWidget {
  final bool isDarkMode;
  final void Function(File image, Map<String, dynamic> metrics) onProcessed;

  const ModulesPage({
    super.key,
    required this.isDarkMode,
    required this.onProcessed,
  });

  @override
  State<ModulesPage> createState() => _ModulesPageState();
}

class _ModulesPageState extends State<ModulesPage> {
  File? _selectedImage;
  bool _isProcessing = false;

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery);

    if (picked != null) {
      setState(() {
        _selectedImage = File(picked.path);
      });
    }
  }

  Future<void> _processImage() async {
    if (_selectedImage == null) return;

    setState(() {
      _isProcessing = true;
    });

    // Simüle edilmiş işleme ve metrik üretimi
    await Future.delayed(const Duration(seconds: 2));

    final metrics = {
      'Genişlik': 200,
      'Yükseklik': 300,
      'Algılanan Nesne': 'Yüz',
    };

    widget.onProcessed(_selectedImage!, metrics);

    setState(() {
      _isProcessing = false;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Resim işlendi ve Ana Menüye aktarıldı!')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton.icon(
              icon: const Icon(Icons.image),
              label: const Text('Resim Seç'),
              onPressed: _pickImage,
            ),
            const SizedBox(height: 16),
            if (_selectedImage != null)
              Image.file(_selectedImage!, height: 200),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              icon: const Icon(Icons.play_arrow),
              label: const Text('İşle'),
              onPressed: _selectedImage == null || _isProcessing
                  ? null
                  : _processImage,
            ),
            if (_isProcessing) const CircularProgressIndicator(),
          ],
        ),
      ),
    );
  }
}

// Yardım Sayfası
class HelpPage extends StatelessWidget {
  final bool isDarkMode;

  const HelpPage({super.key, required this.isDarkMode});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        Text(
          'Yardım ve Bilgilendirme',
          style: TextStyle(
            fontSize: 26,
            fontWeight: FontWeight.bold,
            color: isDarkMode ? Colors.white : Colors.black,
          ),
        ),
        const SizedBox(height: 16),
        Text(
          '• Ana Menü: İşlenmiş resimleri ve metriklerini burada görebilirsiniz.',
          style: TextStyle(
              fontSize: 18,
              color: isDarkMode ? Colors.white70 : Colors.black87),
        ),
        const SizedBox(height: 12),
        Text(
          '• Ayarlar: Tema, ses, ekran ayarlarını buradan yapabilirsiniz.',
          style: TextStyle(
              fontSize: 18,
              color: isDarkMode ? Colors.white70 : Colors.black87),
        ),
        const SizedBox(height: 12),
        Text(
          '• Modüller: Resim işleyici modülleri kullanarak resim seçebilir ve metrik çıkarabilirsiniz.',
          style: TextStyle(
              fontSize: 18,
              color: isDarkMode ? Colors.white70 : Colors.black87),
        ),
        const SizedBox(height: 12),
        Text(
          '• Yardım: Uygulama hakkında temel bilgileri ve yönlendirmeleri içerir.',
          style: TextStyle(
              fontSize: 18,
              color: isDarkMode ? Colors.white70 : Colors.black87),
        ),
      ],
    );
  }
}
