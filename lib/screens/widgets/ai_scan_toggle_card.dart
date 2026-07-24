import 'package:flutter/material.dart';

class AiScanToggleCard extends StatelessWidget {
  final bool isScanningActive;
  final ValueChanged<bool> onChanged;

  const AiScanToggleCard({
    super.key,
    required this.isScanningActive,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: SwitchListTile(
        title: const Text('Sử dụng AI quét (ONNX)', style: TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(
          isScanningActive ? 'Đang chạy ngầm để phát hiện từ vựng...' : 'Tắt quét AI',
          style: TextStyle(color: isScanningActive ? Colors.greenAccent : Colors.grey),
        ),
        value: isScanningActive,
        activeThumbColor: Colors.greenAccent,
        onChanged: onChanged,
        secondary: const Icon(Icons.psychology_outlined, size: 30),
      ),
    );
  }
}