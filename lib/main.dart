import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';

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

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false, // <--- DEBUG BANNER KALDIRILDI
      title: 'Halre App',
      theme: _isDarkMode ? ThemeData.dark() : ThemeData.light(),
      home: MainMenu(
        isDarkMode: _isDarkMode,
        toggleTheme: toggleTheme,
      ),
    );
  }
}

class MainMenu extends StatefulWidget {
  final bool isDarkMode;
  final VoidCallback toggleTheme;

  const MainMenu(
      {super.key, required this.isDarkMode, required this.toggleTheme});

  @override
  State<MainMenu> createState() => _MainMenuState();
}

class _MainMenuState extends State<MainMenu> {
  int _selectedIndex = 0;
  int _counter = 0;

  // Ses ve fullscreen için state
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
    // assets dizinindeki music.mp3'yi çalmak için path düzeltilmeli:
    await _audioPlayer.setReleaseMode(ReleaseMode.loop);
    await _audioPlayer
        .play(AssetSource('music.mp3')); // path'ten "assets/" kaldırıldı
  }

  void _setVolume(double vol) {
    final volNormalized = vol / 100;
    _audioPlayer.setVolume(volNormalized);
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  Widget _buildAnaMenu() {
    return Center(
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          fixedSize: const Size(350, 100),
          textStyle: const TextStyle(fontSize: 28),
          foregroundColor: widget.isDarkMode ? Colors.white : Colors.black,
          backgroundColor: widget.isDarkMode ? Colors.grey[800] : Colors.blue,
        ),
        onPressed: () {
          setState(() {
            _counter++;
          });
        },
        child: Text('Butona Basıldı: $_counter kere'),
      ),
    );
  }

  Widget _buildSettings() {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Tam Ekran Toggle
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

          // Ses Toggle
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

          // Ses Slider
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

  Widget _buildModuller() {
    return Center(
      child: Text(
        'Modüller Sayfası',
        style: TextStyle(
          fontSize: 28,
          color: widget.isDarkMode ? Colors.white : Colors.black,
        ),
      ),
    );
  }

  Widget _buildYardim() {
    return Center(
      child: Text(
        'Yardım Sayfası',
        style: TextStyle(
          fontSize: 28,
          color: widget.isDarkMode ? Colors.white : Colors.black,
        ),
      ),
    );
  }

  Widget _getSelectedPage() {
    switch (_selectedIndex) {
      case 0:
        return _buildAnaMenu();
      case 1:
        return _buildSettings();
      case 2:
        return _buildModuller();
      case 3:
        return _buildYardim();
      default:
        return _buildAnaMenu();
    }
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Halre App'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(
                widget.isDarkMode ? Icons.nightlight_round : Icons.wb_sunny),
            onPressed: widget.toggleTheme,
            tooltip: widget.isDarkMode ? 'Açık Mod' : 'Karanlık Mod',
          ),
        ],
      ),
      body: _getSelectedPage(),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        selectedFontSize: 16,
        unselectedFontSize: 14,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Ana Menü'),
          BottomNavigationBarItem(icon: Icon(Icons.settings), label: 'Ayarlar'),
          BottomNavigationBarItem(icon: Icon(Icons.apps), label: 'Modüller'),
          BottomNavigationBarItem(icon: Icon(Icons.help), label: 'Yardım'),
        ],
      ),
    );
  }
}
