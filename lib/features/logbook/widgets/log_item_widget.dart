import 'package:flutter/material.dart';
import '../models/log_model.dart';
import 'package:intl/intl.dart';
import 'package:logbook_app/services/access_control_service.dart';

class LogItemCard extends StatelessWidget {
  final LogModel log;
  final Color categoryColor;
  final Color primaryColor;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final Function(DismissDirection)? onDismissed;
  final String Function(String) formatTimestamp;
  final String userId;
  final String userRole;

  const LogItemCard({
    super.key,
    required this.log,
    required this.categoryColor,
    required this.primaryColor,
    required this.onEdit,
    required this.onDelete,
    this.onDismissed,
    required this.formatTimestamp,
    required this.userId,
    required this.userRole,
  });

  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key: Key(log.date),
      direction: DismissDirection.endToStart,
      background: Container(
        decoration: BoxDecoration(
          color: Colors.red,
          borderRadius: BorderRadius.circular(12),
        ),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      confirmDismiss: (direction) async {
        final isOwner = log.authorId == userId;
        final canDelete = AccessControlService.canPerform(
          userRole,
          AccessControlService.actionDelete,
          isOwner: isOwner,
        );
        if (!canDelete) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Anda tidak memiliki izin untuk menghapus catatan ini',
              ),
              duration: Duration(seconds: 2),
              backgroundColor: Colors.red,
            ),
          );
          return false;
        }
        return await _showDeleteConfirmDialog(context);
      },
      onDismissed: (direction) {
        onDismissed?.call(direction);
      },
      child: Card(
        elevation: 4,
        color: categoryColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: categoryColor, width: 2),
        ),
        margin: const EdgeInsets.only(bottom: 12),
        child: ListTile(
          contentPadding: const EdgeInsets.all(16),
          leading: Container(
            decoration: BoxDecoration(
              color: log.cloudId != null
                  ? const Color.fromARGB(255, 76, 175, 80)
                  : const Color.fromARGB(255, 255, 193, 7),
              borderRadius: BorderRadius.circular(8),
            ),
            padding: const EdgeInsets.all(8),
            child: Icon(
              log.cloudId != null ? Icons.cloud_done : Icons.cloud_upload,
              color: Colors.white,
              size: 24,
            ),
          ),

          title: Text(
            log.title,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
              color: Colors.white,
            ),
          ),

          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 8),

              Text(
                log.description,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: Colors.white, height: 1.4),
              ),
              const SizedBox(height: 8),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: categoryColor,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        log.category,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),

                  Text(
                    formatTimestamp(log.date),
                    style: const TextStyle(fontSize: 12, color: Colors.white),
                  ),
                ],
              ),
            ],
          ),

          trailing: Wrap(
            spacing: 0,
            children: [
              if (AccessControlService.canPerform(
                userRole,
                AccessControlService.actionUpdate,
                isOwner: log.authorId == userId,
              ))
                IconButton(
                  icon: const Icon(Icons.edit),
                  color: Colors.white,
                  onPressed: onEdit,
                )
              else
                Tooltip(
                  message: 'Anda tidak bisa mengedit catatan ini',
                  child: IconButton(
                    icon: const Icon(Icons.edit),
                    color: Colors.white30,
                    onPressed: null,
                  ),
                ),

              if (AccessControlService.canPerform(
                userRole,
                AccessControlService.actionDelete,
                isOwner: log.authorId == userId,
              ))
                IconButton(
                  icon: const Icon(Icons.delete),
                  color: Colors.red,
                  onPressed: onDelete,
                )
              else
                Tooltip(
                  message: 'Anda tidak bisa menghapus catatan ini',
                  child: IconButton(
                    icon: const Icon(Icons.delete),
                    color: const Color.fromARGB(255, 255, 128, 171),
                    onPressed: null,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Future<bool?> _showDeleteConfirmDialog(BuildContext context) {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Hapus Catatan"),
        content: Text("Yakin ingin menghapus \"${log.title}\"?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("Batal"),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text("Hapus", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}

Color getCategoryColor(String category) {
  switch (category) {
    case "Pekerjaan":
      return const Color.fromARGB(255, 246, 148, 191);
    case "Urgent":
      return const Color.fromARGB(255, 232, 94, 145);
    case "Pribadi":
    default:
      return const Color.fromARGB(255, 248, 198, 222);
  }
}

Color getCategoryBackgroundColor(String category) {
  switch (category) {
    case "Pekerjaan":
      return const Color.fromARGB(255, 240, 250, 255);
    case "Urgent":
      return const Color.fromARGB(255, 255, 245, 245);
    case "Pribadi":
    default:
      return const Color.fromARGB(255, 252, 240, 248);
  }
}

String formatTimestamp(String dateString) {
  try {
    DateTime parsedDate = DateTime.parse(dateString);
    DateTime now = DateTime.now();
    Duration diff = now.difference(parsedDate);

    if (diff.inSeconds < 60) {
      return "baru saja";
    } else if (diff.inMinutes < 60) {
      final mins = diff.inMinutes;
      return "$mins ${mins == 1 ? 'menit' : 'menit'} yang lalu";
    } else if (diff.inHours < 24) {
      final hours = diff.inHours;
      return "$hours ${hours == 1 ? 'jam' : 'jam'} yang lalu";
    } else if (diff.inDays < 7) {
      final days = diff.inDays;
      return "$days ${days == 1 ? 'hari' : 'hari'} yang lalu";
    }

    if (parsedDate.year == now.year) {
      return DateFormat('d MMMM', 'id_ID').format(parsedDate);
    } else {
      return DateFormat('d MMMM yyyy', 'id_ID').format(parsedDate);
    }
  } catch (e) {
    return dateString;
  }
}
