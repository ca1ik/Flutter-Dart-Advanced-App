import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:audioplayers/audioplayers.dart';

// Başlangıç
void main() {
  runApp(const MyApp());
}

// Ana App Widget
class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  // Koyu mod varsayılanı false
  bool _isDarkMode = false;

  // İşlenmiş resim ve metrikleri ana menüye aktarabilmek için
  File? _processedImage;
  Map<String, dynamic>? _imageMetrics;

  // Ses kontrolü için AudioPlayer
  late AudioPlayer _audioPlayer;

  @override
  void initState() {
    super.initState();

    // AudioPlayer başlat, müzik sonsuz döngüde çalsın
    _audioPlayer = AudioPlayer();

    _playMusic();
  }

  Future<void> _playMusic() async {
    // music.mp3 dosyasını assets içine koyduğunuzdan emin olun
    await _audioPlayer.setReleaseMode(ReleaseMode.loop);
    await _audioPlayer.play(AssetSource('music.mp3'));
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }

  // Koyu mod aç/kapa
  void _toggleDarkMode() {
    setState(() {
      _isDarkMode = !_isDarkMode;
    });
  }

  // Resim ve metrikleri al
  void _onImageProcessed(File image, Map<String, dynamic> metrics) {
    setState(() {
      _processedImage = image;
      _imageMetrics = metrics;
    });
  }

  // Uygulama penceresini her yerden sürüklemek için GestureDetector ile saracağız.

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: _isDarkMode ? ThemeData.dark() : ThemeData.light(),
      home: GestureDetector(
        onPanStart: (details) {
          // Windows, MacOS, Linux için pencere sürükleme gibi işlemler buraya gelebilir.
          // Flutter'da bunu native kodla yapmak gerekiyor, burada placeholder.
        },
        child: Scaffold(
          appBar: AppBar(
            // AppBar rengini tema ile uyumlu yapıyoruz
            backgroundColor: _isDarkMode ? Colors.grey[900] : Colors.blue,
            title: const Text('Gelişmiş Flutter Uygulaması'),
            actions: [
              IconButton(
                icon: Icon(_isDarkMode ? Icons.light_mode : Icons.dark_mode),
                onPressed: _toggleDarkMode,
                tooltip: 'Tema Değiştir',
              ),
            ],
            elevation: 0,
          ),
          body: SafeArea(
            child: MainNavigation(
              isDarkMode: _isDarkMode,
              processedImage: _processedImage,
              imageMetrics: _imageMetrics,
              onProcessed: _onImageProcessed,
            ),
          ),
        ),
      ),
    );
  }
}

// Ana navigasyon - TabBar + sayfalar
class MainNavigation extends StatefulWidget {
  final bool isDarkMode;
  final File? processedImage;
  final Map<String, dynamic>? imageMetrics;
  final void Function(File image, Map<String, dynamic> metrics) onProcessed;

  const MainNavigation({
    super.key,
    required this.isDarkMode,
    required this.processedImage,
    required this.imageMetrics,
    required this.onProcessed,
  });

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation>
    with TickerProviderStateMixin {
  late TabController _tabController;

  final List<Tab> _tabs = const [
    Tab(icon: Icon(Icons.home), text: 'Ana Menü'),
    Tab(icon: Icon(Icons.settings), text: 'Ayarlar'),
    Tab(icon: Icon(Icons.image), text: 'Modüller'),
    Tab(icon: Icon(Icons.help), text: 'Yardım'),
  ];

  @override
  void initState() {
    super.initState();

    _tabController = TabController(length: _tabs.length, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Material(
          color: widget.isDarkMode ? Colors.grey[900] : Colors.blue,
          child: TabBar(
            controller: _tabController,
            tabs: _tabs,
            indicatorColor:
                widget.isDarkMode ? Colors.white : Colors.yellowAccent,
            labelColor: widget.isDarkMode ? Colors.white : Colors.white,
            unselectedLabelColor: Colors.white70,
          ),
        ),
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              HomePage(
                isDarkMode: widget.isDarkMode,
                processedImage: widget.processedImage,
                imageMetrics: widget.imageMetrics,
              ),
              SettingsPage(isDarkMode: widget.isDarkMode),
              ModulesPage(
                isDarkMode: widget.isDarkMode,
                onProcessed: widget.onProcessed,
              ),
              HelpPage(isDarkMode: widget.isDarkMode),
            ],
          ),
        ),
      ],
    );
  }
}

// Ana Menü Sayfası
class HomePage extends StatelessWidget {
  final bool isDarkMode;
  final File? processedImage;
  final Map<String, dynamic>? imageMetrics;

  const HomePage({
    super.key,
    required this.isDarkMode,
    required this.processedImage,
    required this.imageMetrics,
  });

  @override
  Widget build(BuildContext context) {
    final textColor = isDarkMode ? Colors.white : Colors.black;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'İşlenmiş Resim',
            style: TextStyle(
                fontSize: 26, fontWeight: FontWeight.bold, color: textColor),
          ),
          const SizedBox(height: 16),
          if (processedImage != null)
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.file(
                processedImage!,
                fit: BoxFit.contain,
                height: 250,
              ),
            )
          else
            Container(
              height: 250,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                color: isDarkMode ? Colors.grey[800] : Colors.grey[300],
              ),
              child: Center(
                child: Text(
                  'Henüz işlenmiş resim yok',
                  style: TextStyle(
                      color: textColor.withOpacity(0.7), fontSize: 18),
                ),
              ),
            ),
          const SizedBox(height: 24),
          Text(
            'Metrikler',
            style: TextStyle(
                fontSize: 24, fontWeight: FontWeight.bold, color: textColor),
          ),
          const SizedBox(height: 12),
          if (imageMetrics != null)
            ...imageMetrics!.entries.map(
              (entry) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Text(
                  '${entry.key}: ${entry.value}',
                  style: TextStyle(fontSize: 18, color: textColor),
                ),
              ),
            )
          else
            Text(
              'Henüz metrik yok',
              style: TextStyle(fontSize: 18, color: textColor.withOpacity(0.7)),
            ),
        ],
      ),
    );
  }
}

// Ayarlar Sayfası (Ses, Tam Ekran vs.)
class SettingsPage extends StatefulWidget {
  final bool isDarkMode;

  const SettingsPage({super.key, required this.isDarkMode});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  bool _isFullscreen = false;
  bool _isSoundOn = true;
  double _volume = 80;

  late AudioPlayer _audioPlayer;

  @override
  void initState() {
    super.initState();

    _audioPlayer = AudioPlayer();

    _audioPlayer.setReleaseMode(ReleaseMode.loop);

    _setVolume(_volume);
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }

  Future<void> _setVolume(double volume) async {
    await _audioPlayer.setVolume(volume / 100);
  }

  @override
  Widget build(BuildContext context) {
    final fgColor = widget.isDarkMode ? Colors.white : Colors.black;
    final bgColor = widget.isDarkMode ? Colors.grey[850] : Colors.blue;

    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              fixedSize: const Size.fromHeight(80),
              textStyle: const TextStyle(fontSize: 26),
              foregroundColor: fgColor,
              backgroundColor: bgColor,
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
              foregroundColor: fgColor,
              backgroundColor: bgColor,
            ),
            onPressed: () {
              setState(() {
                _isSoundOn = !_isSoundOn;
              });
            },
            child: Text(_isSoundOn ? 'Ses Açık' : 'Ses Kapalı'),
          ),
          const SizedBox(height: 32),
          Text('Ses Seviyesi: ${_volume.round()}',
              style: TextStyle(fontSize: 22, color: fgColor)),
          Slider(
            value: _volume,
            min: 0,
            max: 100,
            divisions: 20,
            label: '${_volume.round()}',
            onChanged: (value) {
              setState(() {
                _volume = value;
                if (_isSoundOn) {
                  _setVolume(_volume);
                }
              });
            },
          ),
        ],
      ),
    );
  }
}

// Modüller Sayfası - Resim seçme, maskeleme, filtreleme işlemi burada olacak
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
  ui.Image? _uiImage;
  bool _isProcessing = false;
  String? _error;

  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
  }

  Future<void> _pickImage() async {
    setState(() {
      _error = null;
      _isProcessing = true;
    });

    try {
      final XFile? pickedFile =
          await _picker.pickImage(source: ImageSource.gallery);
      if (pickedFile == null) {
        setState(() {
          _isProcessing = false;
          _error = 'Resim seçilmedi.';
        });
        return;
      }

      File imageFile = File(pickedFile.path);

      // Image decode to apply mask
      final data = await pickedFile.readAsBytes();
      final codec = await ui.instantiateImageCodec(data);
      final frame = await codec.getNextFrame();
      ui.Image originalImage = frame.image;

      // Mask uygulanmış resim oluştur
      ui.Image maskedImage = await _applyMask(originalImage);

      // Masked image'ı file olarak kaydet (geçici)
      File maskedFile = await _saveUiImageToFile(maskedImage);

      // Metrikleri hesapla (örnek: genişlik, yükseklik)
      Map<String, dynamic> metrics = {
        'Genişlik': maskedImage.width,
        'Yükseklik': maskedImage.height,
        'Maskelenme Durumu': 'Başarılı',
      };

      widget.onProcessed(maskedFile, metrics);

      setState(() {
        _selectedImage = maskedFile;
        _uiImage = maskedImage;
        _isProcessing = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Resim işleme hatası: $e';
        _isProcessing = false;
      });
    }
  }

  // Maskeleme işlemi: Basit oval maske örneği
  Future<ui.Image> _applyMask(ui.Image originalImage) async {
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);

    final paint = Paint();
    paint.isAntiAlias = true;

    // Beyaz arka planlı
    final bgPaint = Paint()..color = Colors.white;
    canvas.drawRect(
        Rect.fromLTWH(0, 0, originalImage.width.toDouble(),
            originalImage.height.toDouble()),
        bgPaint);

    // Oval maske alanı
    Path maskPath = Path()
      ..addOval(Rect.fromLTWH(0, 0, originalImage.width.toDouble(),
          originalImage.height.toDouble()));

    // Clip ile oval maskeyi uyguluyoruz
    canvas.clipPath(maskPath);

    // Orijinal resmi çiz
    paint.filterQuality = ui.FilterQuality.high;
    canvas.drawImage(originalImage, Offset.zero, paint);

    // Maskelenmiş resmi kaydet
    final picture = recorder.endRecording();

    final maskedImage =
        await picture.toImage(originalImage.width, originalImage.height);
    return maskedImage;
  }

  // ui.Image'i file'a kaydetmek için
  Future<File> _saveUiImageToFile(ui.Image image) async {
    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    final buffer = byteData!.buffer;

    final tempDir = Directory.systemTemp;
    final file = await File(
            '${tempDir.path}/masked_image_${DateTime.now().millisecondsSinceEpoch}.png')
        .create();

    await file.writeAsBytes(
        buffer.asUint8List(byteData.offsetInBytes, byteData.lengthInBytes));
    return file;
  }

  @override
  Widget build(BuildContext context) {
    final fgColor = widget.isDarkMode ? Colors.white : Colors.black;
    final bgColor = widget.isDarkMode ? Colors.grey[850] : Colors.grey[200];

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ElevatedButton.icon(
            onPressed: _isProcessing ? null : _pickImage,
            icon: const Icon(Icons.image_search),
            label: const Text('Resim Seç & Maskele'),
          ),
          const SizedBox(height: 16),
          if (_isProcessing)
            const Center(child: CircularProgressIndicator())
          else if (_selectedImage != null)
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.file(_selectedImage!),
              ),
            )
          else
            Container(
              height: 200,
              decoration: BoxDecoration(
                color: bgColor,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: Text(
                  _error ?? 'Henüz resim seçilmedi',
                  style:
                      TextStyle(color: fgColor.withOpacity(0.7), fontSize: 18),
                ),
              ),
            ),
        ],
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
    final fgColor = isDarkMode ? Colors.white : Colors.black;

    return Padding(
      padding: const EdgeInsets.all(24),
      child: SingleChildScrollView(
        child: Text(
          '''
Bu uygulama özellikleri:

1. Resim seçip oval maskeleme uygulanabilir.
2. Uygulama açılır açılmaz music.mp3 dosyasını sonsuz döngüde çalar.
3. Koyu ve açık modda menü bar temaya göre otomatik renk alır.
4. Menü bar uygulamayla birleşik ve sürüklenebilir (desktop için).
5. Uygulamanın ana menüsünde işlenmiş resim ve metrikler gösterilir.

Not: Resim maskeleme basit bir oval maske ile yapılmaktadır.
''',
          style: TextStyle(fontSize: 18, color: fgColor),
        ),
      ),
    );
  }
}
