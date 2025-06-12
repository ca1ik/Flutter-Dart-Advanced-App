import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

/// Callback türü: orijinal, maskeli ve metrikler
typedef ImageProcessedCallback = void Function(
  Uint8List original,
  Uint8List masked,
  Map<String, dynamic> metrics,
);

class ModulesPage extends StatefulWidget {
  final bool isDarkMode;
  final ImageProcessedCallback onProcessed;

  const ModulesPage({
    Key? key,
    required this.isDarkMode,
    required this.onProcessed,
  }) : super(key: key);

  @override
  _ModulesPageState createState() => _ModulesPageState();
}

class _ModulesPageState extends State<ModulesPage> {
  ui.Image? _uiImage;
  Uint8List? _originalBytes;
  List<Offset> _maskPoints = [];
  double _brushSize = 20.0;
  final ImagePicker _picker = ImagePicker();

  /// 1) Galeriden resim seç ve 256×256'e ölçekle
  Future<void> _pickAndPrepareImage() async {
    final xfile = await _picker.pickImage(source: ImageSource.gallery);
    if (xfile == null) return;

    // Ham byte'ları oku
    final bytes = await xfile.readAsBytes();

    // Codec ile 256×256 ölçekle
    final codec = await ui.instantiateImageCodec(
      bytes,
      targetWidth: 256,
      targetHeight: 256,
    );
    final frame = await codec.getNextFrame();
    final scaledImage = frame.image;

    // Ölçeklenmiş resmi PNG’ye dönüştür
    final bd = await scaledImage.toByteData(format: ui.ImageByteFormat.png);
    final scaledBytes = bd!.buffer.asUint8List();

    setState(() {
      _uiImage = scaledImage;
      _originalBytes = scaledBytes;
      _maskPoints.clear();
    });
  }

  /// 2) Dokunduğun her noktaya beyaz daire ekle
  void _addPoint(Offset pos) {
    if (_uiImage == null) return;
    // Pozisyonu sınırla
    final dx = pos.dx.clamp(0.0, 256.0);
    final dy = pos.dy.clamp(0.0, 256.0);
    setState(() {
      _maskPoints.add(Offset(dx, dy));
    });
  }

  /// 3) Bitir: Maskeli resmi oluştur ve callback’le gönder
  Future<void> _finish() async {
    if (_uiImage == null || _originalBytes == null) return;

    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder, Rect.fromLTWH(0, 0, 256, 256));

    // Orijinal resmi çiz
    canvas.drawImage(_uiImage!, Offset.zero, Paint());

    // Beyaz daireleri çiz
    final paintCircle = Paint()..color = Colors.white;
    for (var pt in _maskPoints) {
      canvas.drawCircle(pt, _brushSize / 2, paintCircle);
    }

    // Resmi kaydet
    final picture = recorder.endRecording();
    final img = await picture.toImage(256, 256);
    final bd = await img.toByteData(format: ui.ImageByteFormat.png);
    final maskedBytes = bd!.buffer.asUint8List();

    // Metrikler
    final metrics = {
      'Nokta Sayısı': _maskPoints.length,
      'Fırça Boyutu': _brushSize.toInt(),
    };

    // Callback
    widget.onProcessed(_originalBytes!, maskedBytes, metrics);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          ElevatedButton.icon(
            icon: const Icon(Icons.image),
            label: const Text('Resim Seç ve Maskele'),
            onPressed: _pickAndPrepareImage,
          ),
          const SizedBox(height: 16),
          if (_uiImage != null) ...[
            // 256×256 Canvas
            SizedBox(
              width: 256,
              height: 256,
              child: GestureDetector(
                onPanDown: (e) => _addPoint(e.localPosition),
                onPanUpdate: (e) => _addPoint(e.localPosition),
                child: CustomPaint(
                  painter: _ImageMaskPainter(
                    image: _uiImage!,
                    points: _maskPoints,
                    brushSize: _brushSize,
                  ),
                  size: const Size(256, 256),
                ),
              ),
            ),
            // Fırça boyutu slider
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
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
            // Bitir düğmesi
            ElevatedButton(
              onPressed: _finish,
              child: const Text('Bitir'),
            ),
          ] else
            // Henüz resim seçilmedi
            Expanded(
              child: Center(
                child: Text(
                  'Henüz resim seçilmedi.',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Maskeyi çizen CustomPainter
class _ImageMaskPainter extends CustomPainter {
  final ui.Image image;
  final List<Offset> points;
  final double brushSize;

  _ImageMaskPainter({
    required this.image,
    required this.points,
    required this.brushSize,
  });

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawImage(image, Offset.zero, Paint());
    final paintCircle = Paint()..color = Colors.white;
    for (var pt in points) {
      canvas.drawCircle(pt, brushSize / 2, paintCircle);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => true;
}
