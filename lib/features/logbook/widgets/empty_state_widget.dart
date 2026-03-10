import 'package:flutter/material.dart';

class EmptyStateWidget extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color? primaryColor;
  final VoidCallback? onActionPressed;
  final String actionButtonText;
  final bool showAnimation;

  const EmptyStateWidget({
    super.key,
    required this.title,
    required this.subtitle,
    this.icon = Icons.note_alt_outlined,
    this.primaryColor,
    this.onActionPressed,
    this.actionButtonText = 'Mulai Sekarang',
    this.showAnimation = true,
  });

  static EmptyStateWidget noLogs({
    required VoidCallback onCreateLog,
    Color primaryColor = const Color.fromARGB(255, 254, 166, 209),
  }) {
    return EmptyStateWidget(
      title: 'Belum Ada Catatan',
      subtitle:
          'Belum ada aktivitas hari ini? Mulai catat kemajuan proyek Anda sekarang!',
      icon: Icons.edit_note,
      primaryColor: primaryColor,
      onActionPressed: onCreateLog,
      actionButtonText: 'Buat Catatan Baru',
      showAnimation: true,
    );
  }

  static EmptyStateWidget noSearchResults({
    required String searchQuery,
    required VoidCallback onClearSearch,
    Color primaryColor = const Color.fromARGB(255, 254, 166, 209),
  }) {
    return EmptyStateWidget(
      title: 'Catatan Tidak Ditemukan',
      subtitle:
          'Oops! Tidak ada catatan yang cocok dengan "$searchQuery".\nCoba gunakan kata kunci lain atau buat catatan baru.',
      icon: Icons.search_off,
      primaryColor: primaryColor,
      onActionPressed: onClearSearch,
      actionButtonText: 'Bersihkan Pencarian',
      showAnimation: true,
    );
  }

  @override
  Widget build(BuildContext context) {
    final color = primaryColor ?? Colors.grey;

    return Center(
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (showAnimation)
                Container(
                  width: 160,
                  height: 160,
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(80),
                  ),
                  child: _buildAnimationOrIcon(color),
                )
              else
                Icon(icon, size: 120, color: color.withOpacity(0.6)),
              const SizedBox(height: 24),

              Text(
                title,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 12),

              Text(
                subtitle,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                  height: 1.5,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 32),

              if (onActionPressed != null)
                ElevatedButton.icon(
                  onPressed: onActionPressed,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: color,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 32,
                      vertical: 14,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 2,
                  ),
                  icon: const Icon(Icons.add_circle_outline),
                  label: Text(
                    actionButtonText,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAnimationOrIcon(Color color) {
    return Stack(
      alignment: Alignment.center,
      children: [
        Positioned(child: Icon(icon, size: 140, color: color.withOpacity(0.3))),

        TweenAnimationBuilder<double>(
          tween: Tween(begin: 0, end: 1),
          duration: const Duration(milliseconds: 1500),
          builder: (context, value, child) {
            return Transform.scale(
              scale: 0.9 + (0.1 * value),
              child: Icon(icon, size: 80, color: color),
            );
          },
        ),
      ],
    );
  }
}
