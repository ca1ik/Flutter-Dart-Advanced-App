import 'package:flutter/material.dart';

void main() {
  runApp(const HalreApp());
}

class HalreApp extends StatelessWidget {
  const HalreApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Halre App',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const MainMenu(),
    );
  }
}

class MainMenu extends StatefulWidget {
  const MainMenu({super.key});

  @override
  State<MainMenu> createState() => _MainMenuState();
}

class _MainMenuState extends State<MainMenu> {
  int _selectedIndex = 0;
  int _counter = 0;

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  Widget _buildAnaMenu() {
    return Center(
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          fixedSize: const Size(250, 80),
          textStyle: const TextStyle(fontSize: 24),
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

  Widget _buildAyarlar() {
    return const Center(
      child: Text(
        'Ayarlar Sayfası',
        style: TextStyle(fontSize: 24),
      ),
    );
  }

  Widget _buildModuller() {
    return const Center(
      child: Text(
        'Modüller Sayfası',
        style: TextStyle(fontSize: 24),
      ),
    );
  }

  Widget _buildYardim() {
    return const Center(
      child: Text(
        'Yardım Sayfası',
        style: TextStyle(fontSize: 24),
      ),
    );
  }

  Widget _getSelectedPage() {
    switch (_selectedIndex) {
      case 0:
        return _buildAnaMenu();
      case 1:
        return _buildAyarlar();
      case 2:
        return _buildModuller();
      case 3:
        return _buildYardim();
      default:
        return _buildAnaMenu();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Halre App'),
        centerTitle: true,
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
