import 'package:flutter/material.dart';

class RentProgressBar extends StatelessWidget {
  /// Percentage paid (0–100)
  final double percent;

  /// Amount already paid
  final double? amountPaid;

  /// Total monthly rent
  final double? totalRent;

  /// Show percentage label
  final bool showPercentage;

  const RentProgressBar({
    super.key,
    required this.percent,
    this.amountPaid,
    this.totalRent,
    this.showPercentage = true,
  });

  @override
  Widget build(BuildContext context) {
    final value = percent.clamp(0.0, 100.0);

    Color progressColor;

    if (value >= 100) {
      progressColor = Colors.green;
    } else if (value >= 75) {
      progressColor = Colors.lightGreen;
    } else if (value >= 50) {
      progressColor = Colors.orange;
    } else if (value >= 25) {
      progressColor = Colors.deepOrange;
    } else {
      progressColor = Colors.red;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (showPercentage)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                "Rent Progress",
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                "${value.toStringAsFixed(0)}%",
                style: TextStyle(
                  color: progressColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),

        if (showPercentage) const SizedBox(height: 8),

        ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: LinearProgressIndicator(
            value: value / 100,
            minHeight: 14,
            backgroundColor: Colors.grey.shade300,
            valueColor: AlwaysStoppedAnimation(progressColor),
          ),
        ),

        if (amountPaid != null && totalRent != null) ...[
          const SizedBox(height: 10),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "Paid: ${amountPaid!.toStringAsFixed(2)}",
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                "Rent: ${totalRent!.toStringAsFixed(2)}",
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),

          const SizedBox(height: 6),

          Text(
            value >= 100
                ? "✅ Rent fully paid for this month."
                : "Remaining: ${(totalRent! - amountPaid!).clamp(0, totalRent!).toStringAsFixed(2)}",
            style: TextStyle(
              color: progressColor,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ],
    );
  }
}
