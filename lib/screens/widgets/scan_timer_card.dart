import 'package:flutter/material.dart';

class ScanTimerCard extends StatelessWidget {
  final bool isScanningActive;
  final String formattedTime;
  final bool isExceeding3Hours; // Thêm biến này

  const ScanTimerCard({
    super.key,
    required this.isScanningActive,
    required this.formattedTime,
    required this.isExceeding3Hours, // Thêm vào constructor
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Colors.deepPurple.shade900.withValues(alpha: 0.5),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: isExceeding3Hours 
              ? Colors.redAccent 
              : (isScanningActive ? Colors.greenAccent : Colors.transparent),
          width: 2,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.timer_outlined,
                  size: 40,
                  color: isExceeding3Hours
                      ? Colors.redAccent
                      : (isScanningActive ? Colors.greenAccent : Colors.grey),
                ),
                const SizedBox(width: 16),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Thời gian Scan', style: TextStyle(fontSize: 14, color: Colors.grey)),
                    const SizedBox(height: 4),
                    Text(
                      formattedTime,
                      style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, letterSpacing: 2),
                    ),
                  ],
                ),
              ],
            ),
            
            // Dòng cảnh báo xuất hiện khi vượt quá 3 giờ
            if (isExceeding3Hours) ...[
              const SizedBox(height: 12),
              const Divider(color: Colors.redAccent, thickness: 0.5),
              const SizedBox(height: 8),
              const Row(
                children: [
                  Icon(Icons.warning_amber_rounded, color: Colors.amber, size: 20),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Chơi game quá 3h / 1 ngày sẽ ảnh hưởng đến sức khỏe',
                      style: TextStyle(
                        color: Colors.amber,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}