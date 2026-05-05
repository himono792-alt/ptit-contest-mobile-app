import 'package:flutter/material.dart';
import '../theme.dart';

class Pill extends StatelessWidget {
  final String label;
  final Color color;
  final Color? bg;
  const Pill({super.key, required this.label, this.color = textMuted, this.bg});

  factory Pill.status(String status) {
    switch (status) {
      case 'REG_OPEN':
      case 'PUBLISHED':
      case 'APPROVED':
      case 'COMPLETED':
      case 'SUCCESS':
        return Pill(label: status, color: successGreen, bg: successSoft);
      case 'ONGOING':
      case 'PENDING':
      case 'SUBMITTED':
      case 'PROPOSED':
      case 'LATE':
        return Pill(label: status, color: warnOrange, bg: warnSoft);
      case 'FINISHED':
      case 'CHECKED_IN':
        return Pill(label: status, color: infoBlue, bg: infoSoft);
      case 'CANCELLED':
      case 'REJECTED':
      case 'LOCKED':
        return Pill(label: status, color: ptitRed, bg: ptitRedSoft);
      default:
        return Pill(label: status, color: textMuted, bg: const Color(0xFFF3F4F6));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bg ?? color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        label,
        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: color),
      ),
    );
  }
}
