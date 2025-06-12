import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import 'moduller_page.dart';
import 'dart:typed_data';

typedef ImageProcessedCallback = void Function(
    Uint8List original, Uint8List masked, Map<String, dynamic> metrics);

class MenuPage extends StatefulWidget {
  final AudioPlayer audioPlayer;
  final bool isDarkMode;
  final double volume;
  final ValueChanged<bool> onThemeChanged;
  final ValueChanged<double> onVolumeChanged;

  const MenuPage({
    Key? key,
    required this.audioPlayer,
    required this.isDarkMode,
    required this.volume,
    required this.onThemeChanged,
    required this.onVolumeChanged,
  }) : super(key: key);

  @override
  State<MenuPage> createState() => _MenuPageState();
}

class _MenuPageState extends State<MenuPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  Uint8List? _originalBytes;
  Uint8List? _maskedBytes;
  Map<String, dynamic>? _metrics;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _handleImageProcessed(
      Uint8List original, Uint8List masked, Map<String, dynamic> metrics) {
    setState(() {
      _originalBytes = original;
      _maskedBytes = masked;
      _metrics = metrics;
    });
    // İşlemden sonra Ana Menü'ye dön
    _tabController.animateTo(0);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Gelişmiş Flutter Uygulaması'),
      ),
      body: Column(
        children: [
          Material(
            color: widget.isDarkMode ? Colors.grey[900] : Colors.blue,
            child: TabBar(
              controller: _tabController,
              labelColor: Colors.white,
              unselectedLabelColor: Colors.white70,
              indicatorColor: widget.isDarkMode ? Colors.white : Colors.yellowAccent,
              tabs: const [
                Tab(text: 'Ana Menü'),
                Tab(text: 'Modüller'),
                Tab(text: 'Ayarlar'),
              ],
            ),
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                // Ana Menü
                SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        'Sonuçlar',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 16),
                      if (_originalBytes != null && _maskedBytes != null) ...[
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            // Orijinal Görsel
                            Container(
                              decoration: BoxDecoration(
                                border: Border.all(color: Colors.blue, width: 2),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              padding: const EdgeInsets.all(8),
                              child: Column(
                                children: [
                                  Text(
                                    'Orijinal',
                                    style:
                                        Theme.of(context).textTheme.titleSmall,
                                  ),
                                  const SizedBox(height: 8),
                                  Image.memory(_originalBytes!,
                                      width: 256, height: 256),
                                ],
                              ),
                            ),
                            const SizedBox(width: 16),
                            // Maskeli Görsel
                            Container(
                              decoration: BoxDecoration(
                                border: Border.all(color: Colors.green, width: 2),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              padding: const EdgeInsets.all(8),
                              child: Column(
                                children: [
                                  Text(
                                    'Maske',
                                    style:
                                        Theme.of(context).textTheme.titleSmall,
                                  ),
                                  const SizedBox(height: 8),
                                  Image.memory(_maskedBytes!,
                                      width: 256, height: 256),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        if (_metrics != null) ..._metrics!.entries.map(
                          (e) => Text(
                            '${e.key}: ${e.value}',
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                        ),
                      ] else
                        Center(
                          child: Text(
                            'Henüz resim işlenmedi.',
                            style: Theme.of(context)
                                .textTheme
                                .bodyMedium!
                                .copyWith(color: Colors.grey),
                          ),
                        ),
                    ],
                  ),
                ),
                // Modüller
                ModulesPage(
                  isDarkMode: widget.isDarkMode,
                  onProcessed: _handleImageProcessed,
                ),
                // Ayarlar
                Padding(
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
                      const SizedBox(height: 24),
                      Row(
                        children: [
                          const Text('Müzik Sesi'),
                          Expanded(
                            child: Slider(
                              min: 0,
                              max: 1,
                              value: widget.volume,
                              onChanged: (v) {
                                widget.onVolumeChanged(v);
                                widget.audioPlayer.setVolume(v);
                              },
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
