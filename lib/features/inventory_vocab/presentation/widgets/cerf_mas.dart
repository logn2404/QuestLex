import 'package:flutter/material.dart';

class CerfMas extends StatelessWidget {
  final int overallScore;
  final int starRating;
  final double expPercentage;

  const CerfMas({
    super.key,
    required this.overallScore,
    required this.starRating,
    this.expPercentage = 0.65, // Mặc định 65% nếu chưa truyền
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primaryColor = theme.colorScheme.primary;

    return Column(
      children: [
        // Vòng tròn EXP tiến trình
        SizedBox(
          width: 110,
          height: 110,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Vòng nền mờ
              SizedBox(
                width: 100,
                height: 100,
                child: CircularProgressIndicator(
                  value: 1.0,
                  strokeWidth: 8,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    primaryColor.withOpacity(0.15),
                  ),
                ),
              ),
              // Vòng EXP thực tế theo phần trăm
              SizedBox(
                width: 100,
                height: 100,
                child: CircularProgressIndicator(
                  value: expPercentage,
                  strokeWidth: 8,
                  strokeCap: StrokeCap.round,
                  valueColor: const AlwaysStoppedAnimation<Color>(Colors.greenAccent),
                ),
              ),
              // Lõi hiển thị điểm số
              Container(
                width: 82,
                height: 82,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: primaryColor,
                  boxShadow: [
                    BoxShadow(
                      color: primaryColor.withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Center(
                  child: Text(
                    '$overallScore',
                    style: theme.textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Dãy 6 Ngôi sao
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(6, (index) {
            bool isFilled = index < starRating;
            return Icon(
              isFilled ? Icons.star_rounded : Icons.star_border_rounded,
              color: isFilled ? Colors.amber : theme.disabledColor,
              size: 28,
            );
          }),
        ),
      ],
    );
  }
}