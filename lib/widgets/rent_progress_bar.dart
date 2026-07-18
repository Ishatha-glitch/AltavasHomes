import 'package:flutter/material.dart';

class RentProgressBar extends StatelessWidget {
  final double percent;
  const RentProgressBar({super.key, required this.percent});

  @override
  Widget build(BuildContext context) {
    final clamped = percent.clamp(0, 100).toDouble();
    final color = clamped >= 100
        ? const Color(0xFF16A34A)
        : clamped >= 50
            ? const Color(0xFFF59E0B)
            : const Color(0xFFEF4444);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(7),
          child: LinearProgressIndicator(
            value: clamped / 100,
            minHeight: 14,
            backgroundColor: const Color(0xFFEEEEEE),
            valueColor: AlwaysStoppedAnimation<Color>(color),
          ),
        ),
        const SizedBox(height: 6),
        Text('${clamped.toStringAsFixed(0)}% of this month\'s rent paid',
            style: const TextStyle(fontSize: 13, color: Color(0xFF555555))),
      ],
    );
  }
}
