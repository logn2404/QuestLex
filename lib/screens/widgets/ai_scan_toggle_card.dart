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
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Icon(
                  Icons.document_scanner_rounded,
                  color: isScanningActive ? Colors.deepPurpleAccent : Colors.grey,
                  size: 28,
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Tự động AI quét (ONNX)',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      isScanningActive ? 'Đang chạy quét AI ngầm...' : 'Tắt quét AI',
                      style: TextStyle(
                        color: isScanningActive ? Colors.greenAccent : Colors.grey,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            Switch(
              value: isScanningActive,
              activeColor: Colors.deepPurpleAccent,
              onChanged: onChanged,
            ),
          ],
        ),
      ),
    );
  }
}