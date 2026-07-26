import 'package:flutter/material.dart';

class AiScanToggleCard extends StatelessWidget {
  final bool isScanningActive;
  final ValueChanged<bool> onChanged;
  final VoidCallback onOpenSettings; // 👈 Thêm callback mở Cài đặt

  const AiScanToggleCard({
    super.key,
    required this.isScanningActive,
    required this.onChanged,
    required this.onOpenSettings,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
        child: Row(
          children: [
            const Icon(Icons.crop_free, size: 28),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Tự động AI quét (ONNX)',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  Text(
                    isScanningActive ? 'Đang quét AI...' : 'Tắt quét AI',
                    style: TextStyle(
                      fontSize: 12,
                      color: isScanningActive ? Colors.green : Colors.grey,
                    ),
                  ),
                ],
              ),
            ),
            
            // ⚙️ Nút Setting Trigger
            IconButton(
              icon: const Icon(Icons.settings_outlined),
              tooltip: 'Cấu hình Trigger',
              onPressed: onOpenSettings,
            ),
            
            const SizedBox(width: 4),

            // Switch Bật/Tắt
            Switch(
              value: isScanningActive,
              onChanged: onChanged,
            ),
          ],
        ),
      ),
    );
  }
}