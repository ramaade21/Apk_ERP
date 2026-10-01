import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Kartu angka ringkas untuk dashboard.
class MetricCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color? color;

  const MetricCard({
    super.key,
    required this.label,
    required this.value,
    required this.icon,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final c = color ?? Theme.of(context).colorScheme.primary;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Row(
              children: [
                Icon(icon, size: 18, color: c),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(label,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodySmall),
                ),
              ],
            ),
            const SizedBox(height: 6),
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(
                value,
                style: Theme.of(context)
                    .textTheme
                    .titleLarge
                    ?.copyWith(fontWeight: FontWeight.bold, color: c),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Baris label - nilai untuk laporan.
class SummaryRow extends StatelessWidget {
  final String label;
  final String value;
  final bool bold;
  final Color? color;

  const SummaryRow({
    super.key,
    required this.label,
    required this.value,
    this.bold = false,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final style = TextStyle(
      fontWeight: bold ? FontWeight.bold : null,
      color: color,
    );
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          Expanded(child: Text(label, style: style)),
          const SizedBox(width: 12),
          Text(value, style: style),
        ],
      ),
    );
  }
}

/// Kartu berisi grafik batang sederhana (mendukung nilai negatif).
class BarChartCard extends StatelessWidget {
  final String title;
  final List<double> values;
  final List<String> labels;
  final Color color;
  final Color? negativeColor;
  final String? footer;

  const BarChartCard({
    super.key,
    required this.title,
    required this.values,
    required this.labels,
    required this.color,
    this.negativeColor,
    this.footer,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: 8),
            SizedBox(
              height: 150,
              width: double.infinity,
              child: CustomPaint(
                painter: _BarPainter(
                  values: values,
                  labels: labels,
                  color: color,
                  negativeColor: negativeColor ?? color,
                  textColor: scheme.onSurfaceVariant,
                  axisColor: scheme.outlineVariant,
                ),
              ),
            ),
            if (footer != null) ...[
              const SizedBox(height: 6),
              Text(footer!, style: Theme.of(context).textTheme.bodySmall),
            ],
          ],
        ),
      ),
    );
  }
}

class _BarPainter extends CustomPainter {
  final List<double> values;
  final List<String> labels;
  final Color color;
  final Color negativeColor;
  final Color textColor;
  final Color axisColor;

  _BarPainter({
    required this.values,
    required this.labels,
    required this.color,
    required this.negativeColor,
    required this.textColor,
    required this.axisColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (values.isEmpty) return;
    const labelHeight = 16.0;
    final chartHeight = size.height - labelHeight;
    final maxV = values.fold<double>(0, math.max);
    final minV = values.fold<double>(0, math.min);
    final range = maxV - minV;
    final zeroY = range == 0 ? chartHeight : chartHeight * (maxV / range);
    final barWidth = size.width / values.length;

    canvas.drawLine(
      Offset(0, zeroY),
      Offset(size.width, zeroY),
      Paint()
        ..color = axisColor
        ..strokeWidth = 1,
    );

    final step = (values.length / 8).ceil();
    for (var i = 0; i < values.length; i++) {
      final v = values[i];
      final h = range == 0 ? 0.0 : (v.abs() / range) * chartHeight;
      if (h > 0) {
        final top = v >= 0 ? zeroY - h : zeroY;
        final rect = Rect.fromLTWH(
            i * barWidth + barWidth * 0.15, top, barWidth * 0.7, math.max(h, 1));
        canvas.drawRRect(
          RRect.fromRectAndRadius(rect, const Radius.circular(2)),
          Paint()..color = v >= 0 ? color : negativeColor,
        );
      }
      if (i % step == 0 && i < labels.length) {
        final tp = TextPainter(
          text: TextSpan(
            text: labels[i],
            style: TextStyle(fontSize: 10, color: textColor),
          ),
          textDirection: TextDirection.ltr,
        )..layout();
        tp.paint(
          canvas,
          Offset(i * barWidth + (barWidth - tp.width) / 2, chartHeight + 3),
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant _BarPainter old) =>
      old.values != values ||
      old.labels != labels ||
      old.color != color ||
      old.negativeColor != negativeColor;
}
