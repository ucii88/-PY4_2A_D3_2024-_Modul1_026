import 'package:flutter/material.dart';
import 'log_controller.dart';
import 'log_editor_page.dart';
import 'models/log_model.dart';
import 'package:logbook_app/features/onboarding/onboarding_view.dart';
import 'package:logbook_app/features/vision/vision_view.dart';
import 'package:intl/intl.dart';
import 'package:logbook_app/services/access_control_service.dart';
import 'package:logbook_app/services/connectivity_service.dart';
import 'widgets/empty_state_widget.dart';

class LogView extends StatefulWidget {
  final String username;
  final String userId;
  final String userRole;
  final String teamId;

  const LogView({
    super.key,
    required this.username,
    required this.userId,
    this.userRole = 'Anggota',
    required this.teamId,
  });

  @override
  State<LogView> createState() => _LogViewState();
}

class _LogViewState extends State<LogView> {
  late final LogController _controller;
  final TextEditingController _searchController = TextEditingController();
  bool _isRefreshing = false;
  static const Color primaryColor = Color.fromARGB(255, 254, 166, 209);

  @override
  void initState() {
    super.initState();
    _controller = LogController(
      currentUsername: widget.username,
      currentUserId: widget.userId,
      currentUserRole: widget.userRole,
      teamId: widget.teamId,
    );
  }

  void _goToEditor({LogModel? log, int? index}) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => LogEditorPage(
          log: log,
          index: index,
          controller: _controller,
          userId: widget.userId,
          userRole: widget.userRole,
        ),
      ),
    ).then((_) {
      setState(() {});
    });
  }

  String _formatTime(String dateString) {
    try {
      DateTime parsedDate = DateTime.parse(dateString);
      DateTime now = DateTime.now();
      Duration diff = now.difference(parsedDate);
      if (diff.inSeconds < 60) return "baru saja";
      if (diff.inMinutes < 60) return "${diff.inMinutes} menit lalu";
      if (diff.inHours < 24) return "${diff.inHours} jam lalu";
      if (diff.inDays < 7) return "${diff.inDays} hari lalu";
      return DateFormat('d MMMM yyyy', 'id_ID').format(parsedDate);
    } catch (e) {
      return dateString;
    }
  }

  Color _getCategoryColor(String category) {
    switch (category) {
      case "Mechanical":
        return const Color.fromARGB(255, 138, 199, 140); // Hijau
      case "Electronic":
        return const Color.fromARGB(255, 111, 175, 227); // Biru
      case "Software":
        return const Color.fromARGB(255, 229, 129, 63); // Oranye
      default:
        return const Color.fromARGB(255, 158, 158, 158); // Abu-abu fallback
    }
  }

  String _stripMarkdown(String text) {
    text = text.replaceAll(RegExp(r'^#+\s+', multiLine: true), '');
    text = text.replaceAll(RegExp(r'\*\*(.+?)\*\*'), '\$1');
    text = text.replaceAll(RegExp(r'\*(.+?)\*'), '\$1');
    text = text.replaceAll(RegExp(r'__(.+?)__'), '\$1');
    text = text.replaceAll(RegExp(r'_(.+?)_'), '\$1');
    text = text.replaceAll(RegExp(r'`(.+?)`'), '\$1');
    text = text.replaceAll(RegExp(r'\[(.+?)\]\(.+?\)'), '\$1');
    text = text.replaceAll(RegExp(r'^\s*[-*+]\s+', multiLine: true), '');
    text = text.replaceAll(RegExp(r'^\s*\d+\.\s+', multiLine: true), '');
    return text.trim();
  }

  Widget _buildSyncStatusIndicator() {
    return ValueListenableBuilder<bool>(
      valueListenable: _controller.isLoading,
      builder: (context, isLoading, _) {
        return ValueListenableBuilder<String?>(
          valueListenable: _controller.errorMessage,
          builder: (context, errorMessage, _) {
            if (errorMessage != null && errorMessage.isNotEmpty) {
              return Row(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.cloud_off, size: 14, color: Colors.orange),
                  const SizedBox(width: 4),
                  Text(
                    '⚠️ Sync Error',
                    style: const TextStyle(fontSize: 12, color: Colors.orange),
                  ),
                ],
              );
            } else if (isLoading) {
              return Row(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  ),
                  const SizedBox(width: 4),
                  const Text(
                    ' Syncing...',
                    style: TextStyle(fontSize: 12, color: Colors.white),
                  ),
                ],
              );
            } else {
              return Row(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: const [
                  Icon(Icons.cloud_done, size: 14, color: Colors.white),
                  SizedBox(width: 4),
                  Text(
                    'Synced',
                    style: TextStyle(fontSize: 12, color: Colors.white),
                  ),
                ],
              );
            }
          },
        );
      },
    );
  }

  Widget _buildNetworkStatusIndicator() {
    return ValueListenableBuilder<bool>(
      valueListenable: ConnectivityService().isConnected,
      builder: (context, isOnline, _) {
        if (isOnline) {
          return Row(
            mainAxisSize: MainAxisSize.min,
            children: const [
              Icon(Icons.wifi, size: 14, color: Colors.white),
              SizedBox(width: 4),
              Text(
                'Online',
                style: TextStyle(fontSize: 12, color: Colors.white),
              ),
            ],
          );
        } else {
          return Row(
            mainAxisSize: MainAxisSize.min,
            children: const [
              Icon(Icons.wifi_off, size: 14, color: Colors.red),
              SizedBox(width: 4),
              Text(
                'Offline',
                style: TextStyle(fontSize: 12, color: Colors.red),
              ),
            ],
          );
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        centerTitle: true,
        title: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              "Logbook (${widget.username})",
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildNetworkStatusIndicator(),
                const SizedBox(width: 12),
                _buildSyncStatusIndicator(),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: _isRefreshing
                ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : const Icon(Icons.refresh),
            onPressed: _isRefreshing
                ? null
                : () async {
                    setState(() {
                      _isRefreshing = true;
                    });
                    try {
                      await _controller.loadLogs(widget.teamId);
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('✅ Data disinkronkan'),
                            backgroundColor: Colors.green,
                          ),
                        );
                      }
                    } catch (e) {
                      if (mounted) {
                        ScaffoldMessenger.of(
                          context,
                        ).showSnackBar(SnackBar(content: Text('⚠️ Error: $e')));
                      }
                    } finally {
                      if (mounted) {
                        setState(() {
                          _isRefreshing = false;
                        });
                      }
                    }
                  },
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert),
            itemBuilder: (context) => [
              PopupMenuItem<String>(
                child: const Row(
                  children: [
                    Icon(Icons.cleaning_services, size: 20),
                    SizedBox(width: 8),
                    Text('Cleanup Duplicates'),
                  ],
                ),
                onTap: () async {
                  final confirmed = await showDialog<bool>(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text("🧹 Cleanup Existing Duplicates?"),
                      content: const Text(
                        "Ini akan mendeteksi dan menghapus catatan duplikat EXISTING di MongoDB Atlas.\n\n"
                        "• Copy lama akan DIHAPUS\n"
                        "• Copy paling baru akan DISIMPAN\n"
                        "• Duplikat BARU dicegah otomatis via UPSERT\n\n"
                        "Aman untuk dijalankan kapan saja!",
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context, false),
                          child: const Text("Batal"),
                        ),
                        TextButton(
                          onPressed: () => Navigator.pop(context, true),
                          child: const Text(
                            "Cleanup Sekarang",
                            style: TextStyle(color: Colors.blue),
                          ),
                        ),
                      ],
                    ),
                  );

                  if (confirmed == true) {
                    if (context.mounted) {
                      try {
                        await _controller.cleanupDuplicatesInCloud();
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                ' Cleanup selesai! Duplikat dihapus.',
                              ),
                              backgroundColor: Colors.green,
                            ),
                          );
                        }
                      } catch (e) {
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('❌ Error: $e'),
                              backgroundColor: Colors.red,
                            ),
                          );
                        }
                      }
                    }
                  }
                },
              ),
              PopupMenuItem<String>(
                child: const Row(
                  children: [
                    Icon(Icons.logout, size: 20, color: Colors.red),
                    SizedBox(width: 8),
                    Text('Logout', style: TextStyle(color: Colors.red)),
                  ],
                ),
                onTap: () {
                  showDialog(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text("Konfirmasi Logout"),
                      content: const Text("Apakah Anda yakin ingin keluar?"),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text("Batal"),
                        ),
                        TextButton(
                          onPressed: () {
                            Navigator.pop(context);
                            Navigator.pushAndRemoveUntil(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const OnboardingView(),
                              ),
                              (route) => false,
                            );
                          },
                          child: const Text(
                            "Ya",
                            style: TextStyle(color: Colors.red),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ],
          ),
        ],
      ),
      body: FutureBuilder<void>(
        future: _controller.initializationFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return Center(
              child: Container(
                width: 120,
                height: 140,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 8,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const CircularProgressIndicator(
                      color: primaryColor,
                      strokeWidth: 3,
                    ),
                    const SizedBox(height: 12),
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 8.0),
                      child: Text(
                        "Sinkronisasi dengan MongoDB Atlas...",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: primaryColor,
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }

          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.error_outline, size: 64, color: Colors.red),
                  const SizedBox(height: 16),
                  const Text("Terjadi kesalahan saat memuat data"),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    icon: const Icon(Icons.refresh),
                    label: const Text("Coba Lagi"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryColor,
                    ),
                    onPressed: () {
                      setState(() {
                        _controller = LogController(
                          currentUsername: widget.username,
                          currentUserId: widget.userId,
                          currentUserRole: widget.userRole,
                          teamId: widget.teamId,
                        );
                      });
                    },
                  ),
                ],
              ),
            );
          }

          return ValueListenableBuilder<List<LogModel>>(
            valueListenable: _controller.filteredLogsNotifier,
            builder: (context, filteredLogs, _) {
              var displayLogs = filteredLogs.where((log) {
                final isOwner = log.authorId == widget.userId;
                return isOwner || log.isPublic == true;
              }).toList();

              final searchQuery = _controller.searchQueryNotifier.value;

              return displayLogs.isEmpty
                  ? (searchQuery.isEmpty
                        ? EmptyStateWidget.noLogs(
                            onCreateLog: () => _goToEditor(),
                            primaryColor: primaryColor,
                          )
                        : EmptyStateWidget.noSearchResults(
                            searchQuery: searchQuery,
                            onClearSearch: () {
                              _searchController.clear();
                              _controller.updateSearchQuery('');
                            },
                            primaryColor: primaryColor,
                          ))
                  : RefreshIndicator(
                      onRefresh: () async {
                        await _controller.loadLogs(widget.teamId);
                      },
                      color: primaryColor,
                      backgroundColor: Colors.white,
                      child: Column(
                        children: [
                          Padding(
                            padding: const EdgeInsets.all(12),
                            child: TextField(
                              controller: _searchController,
                              onChanged: (value) {
                                _controller.updateSearchQuery(value);
                              },
                              decoration: InputDecoration(
                                hintText: 'Cari catatan...',
                                prefixIcon: const Icon(
                                  Icons.search,
                                  color: primaryColor,
                                ),
                                suffixIcon: searchQuery.isNotEmpty
                                    ? IconButton(
                                        icon: const Icon(Icons.clear),
                                        onPressed: () {
                                          _searchController.clear();
                                          _controller.updateSearchQuery('');
                                        },
                                      )
                                    : null,
                                filled: true,
                                fillColor: const Color(0xFFFFF0F6),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide.none,
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: const BorderSide(
                                    color: primaryColor,
                                    width: 2,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          Expanded(
                            child: ListView.builder(
                              padding: const EdgeInsets.all(12),
                              itemCount: displayLogs.length,
                              itemBuilder: (context, index) {
                                final log = displayLogs[index];
                                final originalIndex = _controller
                                    .logsNotifier
                                    .value
                                    .indexOf(log);
                                final isOwner = log.authorId == widget.userId;
                                final canUpdate = isOwner;
                                final canDelete = isOwner;

                                return Dismissible(
                                  key: Key(log.id ?? log.title),
                                  direction: DismissDirection.endToStart,
                                  confirmDismiss: (direction) async {
                                    final canDelete =
                                        AccessControlService.canPerform(
                                          widget.userRole,
                                          AccessControlService.actionDelete,
                                          isOwner: isOwner,
                                        );
                                    if (!canDelete) {
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
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

                                    return await showDialog<bool?>(
                                          context: context,
                                          builder: (context) => AlertDialog(
                                            title: const Text("Hapus Catatan?"),
                                            content: Text(
                                              'Hapus "${log.title}"?\n\nTindakan ini tidak dapat dibatalkan.',
                                            ),
                                            actions: [
                                              TextButton(
                                                onPressed: () => Navigator.pop(
                                                  context,
                                                  false,
                                                ),
                                                child: const Text("Batal"),
                                              ),
                                              TextButton(
                                                onPressed: () => Navigator.pop(
                                                  context,
                                                  true,
                                                ),
                                                child: const Text(
                                                  "Hapus",
                                                  style: TextStyle(
                                                    color: Colors.red,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ) ??
                                        false;
                                  },
                                  onDismissed: (direction) {
                                    _controller.removeLog(originalIndex);
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text('Catatan dihapus'),
                                        duration: Duration(seconds: 2),
                                      ),
                                    );
                                  },
                                  background: Container(
                                    margin: const EdgeInsets.only(bottom: 12),
                                    decoration: BoxDecoration(
                                      color: Colors.red.withOpacity(0.8),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    alignment: Alignment.centerRight,
                                    padding: const EdgeInsets.only(right: 20),
                                    child: const Icon(
                                      Icons.delete,
                                      color: Colors.white,
                                    ),
                                  ),
                                  child: Card(
                                    margin: const EdgeInsets.only(bottom: 12),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    color: const Color.fromARGB(
                                      255,
                                      246,
                                      180,
                                      212,
                                    ),
                                    child: ListTile(
                                      contentPadding: const EdgeInsets.all(16),
                                      leading: Icon(
                                        log.id != null
                                            ? Icons.cloud_done
                                            : Icons.cloud_upload_outlined,
                                        color: log.id != null
                                            ? Colors.green
                                            : Colors.orange,
                                        size: 24,
                                      ),
                                      title: Row(
                                        children: [
                                          Expanded(
                                            child: Text(
                                              log.title,
                                              style: const TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 16,
                                                color: Colors.white,
                                              ),
                                            ),
                                          ),
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 8,
                                              vertical: 4,
                                            ),
                                            decoration: BoxDecoration(
                                              color: log.isPublic
                                                  ? Colors.blue.withOpacity(0.8)
                                                  : Colors.grey.withOpacity(
                                                      0.8,
                                                    ),
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                            ),
                                            child: Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Icon(
                                                  log.isPublic
                                                      ? Icons.public
                                                      : Icons.lock,
                                                  size: 12,
                                                  color: Colors.white,
                                                ),
                                                const SizedBox(width: 4),
                                                Text(
                                                  log.isPublic
                                                      ? "Publik"
                                                      : "Privat",
                                                  style: const TextStyle(
                                                    fontSize: 11,
                                                    color: Colors.white,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                      subtitle: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          const SizedBox(height: 8),
                                          Text(
                                            _stripMarkdown(log.description),
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                            style: const TextStyle(
                                              color: Colors.white,
                                            ),
                                          ),
                                          const SizedBox(height: 8),
                                          Row(
                                            children: [
                                              Container(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                      horizontal: 8,
                                                      vertical: 2,
                                                    ),
                                                decoration: BoxDecoration(
                                                  color: _getCategoryColor(
                                                    log.category,
                                                  ),
                                                  borderRadius:
                                                      BorderRadius.circular(4),
                                                ),
                                                child: Text(
                                                  log.category,
                                                  style: const TextStyle(
                                                    fontSize: 11,
                                                    color: Colors.white,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                              ),
                                              const SizedBox(width: 8),
                                              if (log.authorId != widget.userId)
                                                Container(
                                                  padding:
                                                      const EdgeInsets.symmetric(
                                                        horizontal: 8,
                                                        vertical: 2,
                                                      ),
                                                  decoration: BoxDecoration(
                                                    color: Colors.black
                                                        .withOpacity(0.25),
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                          4,
                                                        ),
                                                  ),
                                                  child: Text(
                                                    "by ${log.authorId}",
                                                    style: const TextStyle(
                                                      fontSize: 11,
                                                      color: Colors.white,
                                                      fontStyle:
                                                          FontStyle.italic,
                                                    ),
                                                  ),
                                                ),
                                              const Spacer(),
                                              Text(
                                                _formatTime(log.date),
                                                style: const TextStyle(
                                                  fontSize: 12,
                                                  color: Colors.white,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                      trailing: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          if (canUpdate)
                                            IconButton(
                                              icon: const Icon(
                                                Icons.edit,
                                                color: Colors.white,
                                              ),
                                              onPressed: () => _goToEditor(
                                                log: log,
                                                index: originalIndex,
                                              ),
                                            ),
                                          if (canDelete)
                                            IconButton(
                                              icon: const Icon(
                                                Icons.delete,
                                                color: Colors.red,
                                              ),
                                              onPressed: () {
                                                showDialog(
                                                  context: context,
                                                  builder: (context) => AlertDialog(
                                                    title: const Text("Hapus?"),
                                                    content: Text(
                                                      'Hapus "${log.title}"?',
                                                    ),
                                                    actions: [
                                                      TextButton(
                                                        onPressed: () =>
                                                            Navigator.pop(
                                                              context,
                                                            ),
                                                        child: const Text(
                                                          "Batal",
                                                        ),
                                                      ),
                                                      TextButton(
                                                        onPressed: () {
                                                          Navigator.pop(
                                                            context,
                                                          );
                                                          _controller.removeLog(
                                                            originalIndex,
                                                          );
                                                          ScaffoldMessenger.of(
                                                            context,
                                                          ).showSnackBar(
                                                            const SnackBar(
                                                              content: Text(
                                                                'Dihapus',
                                                              ),
                                                            ),
                                                          );
                                                        },
                                                        child: const Text(
                                                          "Hapus",
                                                          style: TextStyle(
                                                            color: Colors.red,
                                                          ),
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                );
                                              },
                                            ),
                                        ],
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                    );
            },
          );
        },
      ),
      floatingActionButton: ValueListenableBuilder<bool>(
        valueListenable: ConnectivityService().isConnected,
        builder: (context, isOnline, _) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 16, right: 16),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.end,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                // ==================== TOMBOL BUKA KAMERA ====================
                FloatingActionButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const VisionView(),
                      ),
                    );
                  },
                  backgroundColor: Colors.pink.shade300,
                  foregroundColor: Colors.white,
                  tooltip: 'Buka Kamera',
                  child: const Icon(Icons.camera_alt),
                ),
                const SizedBox(height: 12),

                // ==================== TOMBOL CATATAN BARU ====================
                FloatingActionButton(
                  onPressed: () {
                    if (!isOnline) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            ' Catatan akan disimpan lokal. Sync otomatis saat online.',
                          ),
                          backgroundColor: Colors.blue,
                          duration: Duration(seconds: 2),
                        ),
                      );
                    }
                    _goToEditor();
                  },
                  backgroundColor: isOnline
                      ? primaryColor
                      : Colors.blue.shade300,
                  foregroundColor: Colors.white,
                  tooltip: 'Catatan Baru',
                  child: const Icon(Icons.add),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    _controller.dispose();
    super.dispose();
  }
}
