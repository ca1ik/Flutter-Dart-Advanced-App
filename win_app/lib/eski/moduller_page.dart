import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

typedef ImageProcessedCallback = void Function(
    Uint8List original, Uint8List masked, Map<String, dynamic> metrics);

class ModulesPage extends StatefulWidget {
  final bool isDarkMode;
  final ImageProcessedCallback onProcessed;

  const ModulesPage({
    Key? key,
    required this.isDarkMode,
    required this.onProcessed,
  }) : super(key: key);

  @override
  State<ModulesPage> createState() => _ModulesPageState();
}

class _ModulesPageState extends State<ModulesPage> {
  ui.Image? _uiImage;
  Uint8List? _originalBytes;
  List<Offset> _maskPoints = [];
  double _brushSize = 20.0;
  final ImagePicker _picker = ImagePicker();

  Future<void> _pickAndPrepareImage() async {
    final xfile = await _picker.pickImage(source: ImageSource.gallery);
    if (xfile == null) return;
    final bytes = await xfile.readAsBytes();
    // 256×256 ölçekle
    final codec = await ui.instantiateImageCodec(
      bytes,
      targetWidth: 256,
      targetHeight: 256,
    );
    final frame = await codec.getNextFrame();
    setState(() {
      _uiImage = frame.image;
      _originalBytes = bytes;
      _maskPoints.clear();
    });
  }

  void _addPoint(Offset pos) {
    setState(() {
      _maskPoints.add(pos);
    });
  }

  Future<void> _finish() async {
    if (_uiImage == null || _originalBytes == null) return;
    // Maskeli image oluştur
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder, Rect.fromLTWH(0, 0, 256, 256));
    // Önce arka plan
    canvas.drawImage(_uiImage!, Offset.zero, Paint());
    // Maskeyi
    final p = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;
    for (var pt in _maskPoints) {
      canvas.drawCircle(pt, _brushSize / 2, p);
    }
    final picture = recorder.endRecording();
    final img = await picture.toImage(256, 256);
    final bd = await img.toByteData(format: ui.ImageByteFormat.png);
    final maskedBytes = bd!.buffer.asUint8List();

    // Metrikleri hazırla
    final metrics = {
      'Nokta Sayısı': _maskPoints.length,
      'Fırça Boyutu': _brushSize.toInt(),
    };
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
            Expanded(
              child: GestureDetector(
                onPanDown: (e) => _addPoint(e.localPosition),
                onPanUpdate: (e) => _addPoint(e.localPosition),
                child: CustomPaint(
                  painter: ImageMaskPainter(
                    image: _uiImage!,
                    points: _maskPoints,
                    brushSize: _brushSize,
                  ),
                  child: const SizedBox(width: 256, height: 256),
                ),
              ),
            ),
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 0, vertical: 8),
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
            ElevatedButton(
              onPressed: _finish,
              child: const Text('Bitir'),
            ),
          ] else
            Expanded(
              child: Center(
                child: Text(
                  'Henüz resim seçilmedi.',
                  style: Theme.of(context)
                      .textTheme
                      .bodyMedium,
                ),
              ),
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
    canvas.drawImage(image, Offset.zero, Paint());
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
