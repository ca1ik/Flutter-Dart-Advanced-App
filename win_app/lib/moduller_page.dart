import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class ModullerPage extends StatefulWidget {
  final bool isDarkMode;
  const ModullerPage({super.key, required this.isDarkMode});

  @override
  State<ModullerPage> createState() => _ModullerPageState();
}

class _ModullerPageState extends State<ModullerPage> {
  File? _selectedImage;
  bool _isProcessing = false;
  String _metrics = '';

  final ImagePicker _picker = ImagePicker();

  Future<void> _pickImage() async {
    final XFile? pickedFile =
        await _picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      setState(() {
        _selectedImage = File(pickedFile.path);
        _metrics = '';
      });
    }
  }

  void _processImage() async {
    if (_selectedImage == null) return;

    setState(() {
      _isProcessing = true;
      _metrics = '';
    });

    // Burada gerçek işlem kodu olacak, şimdilik delay simülasyonu
    await Future.delayed(const Duration(seconds: 2));

    // Örnek çıktı metrikleri (işleme göre güncelle)
    setState(() {
      _isProcessing = false;
      _metrics = 'Brightness: 0.75\nContrast: 1.2\nSharpness: 0.85';
    });
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          ElevatedButton.icon(
            onPressed: _pickImage,
            icon: const Icon(Icons.image),
            label: const Text('Resim Seç'),
          ),
          const SizedBox(height: 20),
          if (_selectedImage != null)
            Stack(
              children: [
                Image.file(_selectedImage!),
                Container(
                  // Yarı saydam beyaz maske
                  color: Colors.white.withOpacity(0.3),
                  width: double.infinity,
                  height: 300,
                ),
              ],
            )
          else
            Container(
              height: 300,
              width: double.infinity,
              color: widget.isDarkMode ? Colors.grey[700] : Colors.grey[300],
              child: const Center(
                child: Text('Resim Seçilmedi'),
              ),
            ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed:
                _selectedImage != null && !_isProcessing ? _processImage : null,
            child: _isProcessing
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Process the Image'),
          ),
          const SizedBox(height: 20),
          if (_metrics.isNotEmpty)
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Metrikler:',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(_metrics, style: const TextStyle(fontSize: 16)),
              ],
            ),
        ],
      ),
    );
  }
}
