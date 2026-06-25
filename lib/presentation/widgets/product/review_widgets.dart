import 'package:flutter/material.dart';
import 'package:pastryshop/core/theme/app_theme.dart';
import 'package:pastryshop/presentation/providers/review_provider.dart';

// ============================================================
//  StarRatingWidget — Muestra y selecciona estrellas
// ============================================================
class StarRatingWidget extends StatelessWidget {
  final int value;        // 1-5
  final double size;
  final Color? color;
  final ValueChanged<int>? onChanged; // null = solo lectura

  const StarRatingWidget({
    super.key,
    required this.value,
    this.size = 20,
    this.color,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (i) {
        final filled = i < value;
        return GestureDetector(
          onTap: onChanged == null ? null : () => onChanged!(i + 1),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 1.5),
            child: Icon(
              filled ? Icons.star_rounded : Icons.star_outline_rounded,
              color: color ?? (filled ? Colors.amber : Colors.grey.shade300),
              size: size,
            ),
          ),
        );
      }),
    );
  }
}

// ============================================================
//  ReviewCard — Tarjeta individual de reseña
// ============================================================
class ReviewCard extends StatelessWidget {
  final ReviewEntity review;
  final bool canDelete;
  final VoidCallback? onDelete;

  const ReviewCard({
    super.key,
    required this.review,
    this.canDelete = false,
    this.onDelete,
  });

  String _formatDate(String raw) {
    try {
      final dt = DateTime.parse(raw);
      final months = ['ene','feb','mar','abr','may','jun','jul','ago','sep','oct','nov','dic'];
      return '${dt.day} ${months[dt.month - 1]}. ${dt.year}';
    } catch (_) {
      return raw;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(.05), blurRadius: 8, offset: const Offset(0, 3))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // Avatar
              CircleAvatar(
                radius: 18,
                backgroundColor: AppTheme.primary.withOpacity(.15),
                child: Text(
                  review.autor.isNotEmpty ? review.autor[0].toUpperCase() : '?',
                  style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.primary),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(review.autor, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                    Text(_formatDate(review.createdAt), style: const TextStyle(color: Colors.grey, fontSize: 12)),
                  ],
                ),
              ),
              StarRatingWidget(value: review.calificacion, size: 16),
              if (canDelete)
                IconButton(
                  icon: const Icon(Icons.delete_outline, color: AppTheme.error, size: 20),
                  tooltip: 'Eliminar',
                  onPressed: onDelete,
                ),
            ],
          ),
          const SizedBox(height: 10),
          Text(review.comentario, style: const TextStyle(fontSize: 14, height: 1.5, color: Colors.black87)),
        ],
      ),
    );
  }
}

// ============================================================
//  ReviewSummaryBar — Barra de promedio + distribución
// ============================================================
class ReviewSummaryBar extends StatelessWidget {
  final double promedio;
  final int total;
  final List<ReviewEntity> reviews;

  const ReviewSummaryBar({
    super.key,
    required this.promedio,
    required this.total,
    required this.reviews,
  });

  @override
  Widget build(BuildContext context) {
    // Contar distribución por estrella
    final dist = List.generate(5, (i) {
      final star = 5 - i;
      return reviews.where((r) => r.calificacion == star).length;
    });

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(.05), blurRadius: 8)],
      ),
      child: Row(
        children: [
          // Promedio grande
          Column(
            children: [
              Text(
                promedio.toStringAsFixed(1),
                style: const TextStyle(fontSize: 44, fontWeight: FontWeight.w900, color: AppTheme.primaryDark),
              ),
              StarRatingWidget(value: promedio.round(), size: 18),
              const SizedBox(height: 4),
              Text('$total reseñas', style: const TextStyle(color: Colors.grey, fontSize: 12)),
            ],
          ),
          const SizedBox(width: 20),
          // Barras de distribución
          Expanded(
            child: Column(
              children: List.generate(5, (i) {
                final star = 5 - i;
                final count = dist[i];
                final pct   = total > 0 ? count / total : 0.0;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Row(
                    children: [
                      Text('$star', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                      const Icon(Icons.star_rounded, color: Colors.amber, size: 12),
                      const SizedBox(width: 6),
                      Expanded(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: pct,
                            backgroundColor: Colors.grey.shade200,
                            valueColor: const AlwaysStoppedAnimation<Color>(Colors.amber),
                            minHeight: 8,
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      SizedBox(
                        width: 20,
                        child: Text('$count', style: const TextStyle(fontSize: 11, color: Colors.grey)),
                      ),
                    ],
                  ),
                );
              }),
            ),
          ),
        ],
      ),
    );
  }
}
