import 'package:flutter/material.dart';
import 'log_controller.dart';
import 'models/log_model.dart';
import 'widgets/log_item_widget.dart';
import 'package:logbook_app/features/onboarding/onboarding_view.dart';
import 'package:logbook_app/services/connectivity_service.dart';

class LogView extends StatefulWidget {
  final String username;
  final String userId; // ID unik pengguna
  final String userRole; // Role pengguna untuk RBAC

  const LogView({
    super.key,
    required this.username,
    required this.userId,
    this.userRole = 'Anggota', // Default role
  });

  @override
  State<LogView> createState() => _LogViewState();
}

class _LogViewState extends State<LogView> {
  late final LogController _controller;
  String _selectedCategory = "Pribadi";
  final TextEditingController _searchController = TextEditingController();

  late UniqueKey _refreshKey;

  static const Color primaryColor = Color.fromARGB(255, 254, 166, 209);
  static const Color accentColor = Color.fromARGB(255, 254, 166, 209);
  static const Color greyBgColor = Color(0xFFFFF0F6);

  @override
  void initState() {
    super.initState();
    _controller = LogController(
      currentUsername: widget.username,
      currentUserId: widget.userId,
      currentUserRole: widget.userRole,
    );
    _refreshKey = UniqueKey();
  }

  Future<void> _triggerRefresh() async {
    setState(() {
      _refreshKey = UniqueKey();
    });

    await Future.delayed(const Duration(milliseconds: 500));
  }

  String _getConnectionErrorMessage(dynamic error) {
    final errorString = error.toString().toLowerCase();

    if (errorString.contains('tidak ada koneksi internet') ||
        errorString.contains('koneksi terputus')) {
      return "Tidak ada koneksi internet saat ini.\n\n"
          "Pastikan WiFi atau data seluler aktif, lalu coba lagi.";
    }

    if (errorString.contains('auth') ||
        errorString.contains('unauthorized') ||
        errorString.contains('invalid credential')) {
      return " Error Autentikasi\n\n"
          "Gagal autentikasi ke MongoDB. "
          "Periksa kredensial di .env file.";
    }

    if (errorString.contains('database') ||
        errorString.contains('collection') ||
        errorString.contains('namespace not found')) {
      return " Error Database\n\n"
          "Gagal mengakses database atau collection. "
          "Periksa konfigurasi MongoDB Atlas.";
    }

    if (errorString.contains('timeout') ||
        errorString.contains('took too long')) {
      return "⏱ Koneksi Timeout\n\n"
          "Terlalu lama menunggu response dari server. "
          "Server mungkin sedang down atau jaringan lambat.";
    }

    return " Terjadi Kesalahan Saat Sinkronisasi\n\n"
        "Gagal memuat data dari cloud. "
        "Coba lagi dalam beberapa saat atau periksa koneksi internet.";
  }

  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _contentController = TextEditingController();

  void _showAddLogDialog() {
    _selectedCategory = "Pribadi";
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setStateDialog) => AlertDialog(
          title: const Text(
            "Tambah Catatan Baru",
            style: TextStyle(color: primaryColor, fontWeight: FontWeight.bold),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _titleController,
                cursorColor: primaryColor,
                decoration: InputDecoration(
                  hintText: "Judul Catatan",
                  hintStyle: const TextStyle(color: primaryColor),
                  filled: true,
                  fillColor: greyBgColor,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: primaryColor, width: 2),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _contentController,
                cursorColor: primaryColor,
                maxLines: 3,
                decoration: InputDecoration(
                  hintText: "Isi Deskripsi",
                  hintStyle: const TextStyle(color: primaryColor),
                  filled: true,
                  fillColor: greyBgColor,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: primaryColor, width: 2),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              DropdownButton<String>(
                value: _selectedCategory,
                isExpanded: true,
                items: const [
                  DropdownMenuItem(value: "Pribadi", child: Text("Pribadi")),
                  DropdownMenuItem(
                    value: "Pekerjaan",
                    child: Text("Pekerjaan"),
                  ),
                  DropdownMenuItem(value: "Urgent", child: Text("Urgent")),
                ],
                onChanged: (value) {
                  setStateDialog(() {
                    _selectedCategory = value ?? "Pribadi";
                  });
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Batal", style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: accentColor,
                foregroundColor: Colors.white,
              ),
              onPressed: () {
                if (_titleController.text.isNotEmpty &&
                    _contentController.text.isNotEmpty) {
                  _controller.addLog(
                    _titleController.text,
                    _contentController.text,
                    _selectedCategory,
                  );
                  _titleController.clear();
                  _contentController.clear();
                  Navigator.pop(context);

                  Future.delayed(const Duration(milliseconds: 500), () {
                    _triggerRefresh();
                  });
                }
              },
              child: const Text("Simpan"),
            ),
          ],
        ),
      ),
    );
  }

  void _showEditLogDialog(int index, LogModel log) {
    _titleController.text = log.title;
    _contentController.text = log.description;
    _selectedCategory = log.category;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setStateDialog) => AlertDialog(
          title: const Text(
            "Edit Catatan",
            style: TextStyle(color: primaryColor, fontWeight: FontWeight.bold),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _titleController,
                cursorColor: primaryColor,
                decoration: InputDecoration(
                  hintText: "Judul Catatan",
                  hintStyle: const TextStyle(color: primaryColor),
                  filled: true,
                  fillColor: greyBgColor,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: primaryColor, width: 2),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _contentController,
                cursorColor: primaryColor,
                maxLines: 3,
                decoration: InputDecoration(
                  hintText: "Deskripsi",
                  hintStyle: const TextStyle(color: primaryColor),
                  filled: true,
                  fillColor: greyBgColor,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: primaryColor, width: 2),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              DropdownButton<String>(
                value: _selectedCategory,
                isExpanded: true,
                items: const [
                  DropdownMenuItem(value: "Pribadi", child: Text("Pribadi")),
                  DropdownMenuItem(
                    value: "Pekerjaan",
                    child: Text("Pekerjaan"),
                  ),
                  DropdownMenuItem(value: "Urgent", child: Text("Urgent")),
                ],
                onChanged: (value) {
                  setStateDialog(() {
                    _selectedCategory = value ?? "Pribadi";
                  });
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Batal", style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: accentColor,
                foregroundColor: Colors.white,
              ),
              onPressed: () {
                _controller.updateLog(
                  index,
                  _titleController.text,
                  _contentController.text,
                  _selectedCategory,
                );
                _titleController.clear();
                _contentController.clear();
                Navigator.pop(context);

                Future.delayed(const Duration(milliseconds: 500), () {
                  _triggerRefresh();
                });
              },
              child: const Text("Update"),
            ),
          ],
        ),
      ),
    );
  }

  void _showDeleteConfirmationDialog(int index, LogModel log) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Hapus Catatan"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 16),
            Text(
              "Apakah Anda yakin ingin menghapus catatan \"${log.title}\"?",
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 8),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Batal", style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Color.fromARGB(255, 211, 65, 55),
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              Navigator.pop(context);
              _controller.removeLog(index);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text("Catatan dihapus"),
                  duration: Duration(seconds: 2),
                  backgroundColor: Color.fromARGB(255, 211, 65, 55),
                ),
              );

              Future.delayed(const Duration(milliseconds: 500), () {
                _triggerRefresh();
              });
            },
            child: const Text("Hapus"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        centerTitle: true,
        title: Text(
          "Logbook (${widget.username})",
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
              showDialog(
                context: context,
                builder: (BuildContext context) {
                  return AlertDialog(
                    title: const Text("Konfirmasi Logout"),
                    content: const Text(
                      "Apakah Anda yakin ingin keluar? Data tetap tersimpan.",
                    ),
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
                          "Ya, Keluar",
                          style: TextStyle(color: Colors.red),
                        ),
                      ),
                    ],
                  );
                },
              );
            },
          ),
        ],
      ),

      body: Column(
        children: [
          ValueListenableBuilder<bool>(
            valueListenable: ConnectivityService().isConnected,
            builder: (context, isOnline, _) {
              if (isOnline) return const SizedBox.shrink();
              return Container(
                color: const Color.fromARGB(255, 255, 193, 7),
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                child: Row(
                  children: const [
                    Icon(Icons.wifi_off, color: Colors.white, size: 20),
                    SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        "⚠️ Offline Mode - Perubahan tidak akan ter-sync ke cloud",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),

          Expanded(
            child: FutureBuilder<List<LogModel>>(
              key: _refreshKey,
              future: _controller.getLogsFromCloud(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Stack(
                    children: [
                      Column(
                        children: [
                          Padding(
                            padding: const EdgeInsets.all(16),
                            child: TextField(
                              controller: _searchController,
                              onChanged: (value) => setState(() {}),
                              cursorColor: primaryColor,
                              decoration: InputDecoration(
                                hintText: "Cari Catatan...",
                                prefixIcon: const Icon(
                                  Icons.search,
                                  color: primaryColor,
                                ),
                                filled: true,
                                fillColor: greyBgColor,
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
                        ],
                      ),
                      Center(
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
                          child: const Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              CircularProgressIndicator(
                                color: Color.fromARGB(255, 254, 166, 209),
                                strokeWidth: 3,
                              ),
                              SizedBox(height: 12),
                              Padding(
                                padding: EdgeInsets.symmetric(horizontal: 8.0),
                                child: Text(
                                  "Sinkronisasi dengan MongoDB Atlas...",
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    color: Color.fromARGB(255, 254, 166, 209),
                                    fontSize: 11,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  );
                }

                if (snapshot.hasError) {
                  final friendlyMessage = _getConnectionErrorMessage(
                    snapshot.error,
                  );

                  return ValueListenableBuilder<bool>(
                    valueListenable: ConnectivityService().isConnected,
                    builder: (context, isOnline, _) {
                      if (!isOnline) {
                        return Column(
                          children: [
                            Padding(
                              padding: const EdgeInsets.all(16),
                              child: TextField(
                                controller: _searchController,
                                onChanged: (value) => setState(() {}),
                                cursorColor: primaryColor,
                                decoration: InputDecoration(
                                  hintText: "Cari Catatan...",
                                  prefixIcon: const Icon(
                                    Icons.search,
                                    color: primaryColor,
                                  ),
                                  filled: true,
                                  fillColor: greyBgColor,
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
                              child: Center(
                                child: SingleChildScrollView(
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 24.0,
                                    ),
                                    child: Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                          Icons.cloud_off_outlined,
                                          size: 80,
                                          color: Colors.grey[300],
                                        ),
                                        const SizedBox(height: 24),
                                        const Text(
                                          "Data tidak tersedia saat offline",
                                          style: TextStyle(
                                            fontSize: 22,
                                            fontWeight: FontWeight.bold,
                                            color: Color.fromARGB(
                                              255,
                                              100,
                                              100,
                                              100,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(height: 12),
                                        const Text(
                                          "Hubungkan ke internet untuk melihat catatan",
                                          style: TextStyle(
                                            fontSize: 14,
                                            color: Colors.grey,
                                            height: 1.5,
                                          ),
                                          textAlign: TextAlign.center,
                                        ),
                                        const SizedBox(height: 24),
                                        ElevatedButton.icon(
                                          onPressed: _triggerRefresh,
                                          icon: const Icon(Icons.refresh),
                                          label: const Text("Coba Lagi"),
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: primaryColor,
                                            foregroundColor: Colors.white,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        );
                      }

                      // Jika online, tampilkan error message
                      return RefreshIndicator(
                        onRefresh: () async => _triggerRefresh(),
                        child: ListView(
                          children: [
                            Padding(
                              padding: const EdgeInsets.all(16),
                              child: TextField(
                                controller: _searchController,
                                onChanged: (value) => setState(() {}),
                                cursorColor: primaryColor,
                                decoration: InputDecoration(
                                  hintText: "Cari Catatan...",
                                  prefixIcon: const Icon(
                                    Icons.search,
                                    color: primaryColor,
                                  ),
                                  filled: true,
                                  fillColor: greyBgColor,
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
                            Container(
                              margin: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 8,
                              ),
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: const Color.fromARGB(255, 255, 248, 225),
                                border: Border.all(
                                  color: const Color.fromARGB(255, 255, 193, 7),
                                ),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                friendlyMessage,
                                style: const TextStyle(
                                  color: Color.fromARGB(255, 255, 193, 7),
                                  fontSize: 13,
                                  height: 1.5,
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),
                            Center(
                              child: ElevatedButton.icon(
                                onPressed: _triggerRefresh,
                                icon: const Icon(Icons.refresh),
                                label: const Text("Coba Lagi"),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: primaryColor,
                                  foregroundColor: Colors.white,
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),
                          ],
                        ),
                      );
                    },
                  );
                }

                final logs = snapshot.data ?? [];
                final filteredLogs = _searchController.text.isEmpty
                    ? logs
                    : logs
                          .where(
                            (log) =>
                                log.title.toLowerCase().contains(
                                  _searchController.text.toLowerCase(),
                                ) ||
                                log.description.toLowerCase().contains(
                                  _searchController.text.toLowerCase(),
                                ),
                          )
                          .toList();

                return RefreshIndicator(
                  onRefresh: () async => _triggerRefresh(),
                  color: primaryColor,
                  backgroundColor: Colors.white,
                  strokeWidth: 2.5,
                  child: Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: TextField(
                          controller: _searchController,
                          onChanged: (value) => setState(() {}),
                          cursorColor: primaryColor,
                          decoration: InputDecoration(
                            hintText: "Cari Catatan...",
                            prefixIcon: const Icon(
                              Icons.search,
                              color: primaryColor,
                            ),
                            filled: true,
                            fillColor: greyBgColor,
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
                      if (filteredLogs.isEmpty)
                        Expanded(
                          child: ValueListenableBuilder<bool>(
                            valueListenable: ConnectivityService().isConnected,
                            builder: (context, isOnline, _) {
                              return Center(
                                child: SingleChildScrollView(
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 24.0,
                                    ),
                                    child: Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                          Icons.cloud_off_outlined,
                                          size: 80,
                                          color: Colors.grey[300],
                                        ),
                                        const SizedBox(height: 24),
                                        Text(
                                          !isOnline &&
                                                  _searchController.text.isEmpty
                                              ? "Data tidak tersedia saat offline"
                                              : _searchController.text.isEmpty
                                              ? "Data Kosong"
                                              : "Catatan Tidak Ditemukan",
                                          style: const TextStyle(
                                            fontSize: 22,
                                            fontWeight: FontWeight.bold,
                                            color: Color.fromARGB(
                                              255,
                                              100,
                                              100,
                                              100,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(height: 12),
                                        Text(
                                          !isOnline &&
                                                  _searchController.text.isEmpty
                                              ? "Hubungkan ke internet untuk melihat catatan"
                                              : _searchController.text.isEmpty
                                              ? "Mulai mencatat hal-hal penting hari ini"
                                              : "Coba gunakan kata kunci lain",
                                          style: TextStyle(
                                            fontSize: 14,
                                            color: Colors.grey[600],
                                            height: 1.5,
                                          ),
                                          textAlign: TextAlign.center,
                                        ),
                                        const SizedBox(height: 24),
                                        if (!isOnline &&
                                            _searchController.text.isEmpty)
                                          ElevatedButton.icon(
                                            onPressed: _triggerRefresh,
                                            icon: const Icon(Icons.refresh),
                                            label: const Text("Coba Lagi"),
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: primaryColor,
                                              foregroundColor: Colors.white,
                                            ),
                                          )
                                        else if (_searchController.text.isEmpty)
                                          ElevatedButton.icon(
                                            onPressed: _showAddLogDialog,
                                            icon: const Icon(Icons.add),
                                            label: const Text(
                                              "Buat Catatan Pertama",
                                            ),
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: primaryColor,
                                              foregroundColor: Colors.white,
                                            ),
                                          ),
                                      ],
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                        )
                      else
                        Expanded(
                          child: ListView.builder(
                            padding: const EdgeInsets.all(16),
                            itemCount: filteredLogs.length,
                            itemBuilder: (context, index) {
                              final log = filteredLogs[index];
                              final originalIndex = logs.indexOf(log);
                              final categoryColor = getCategoryColor(
                                log.category,
                              );

                              return LogItemCard(
                                log: log,
                                categoryColor: categoryColor,
                                primaryColor: primaryColor,
                                userId: widget.userId,
                                userRole: widget.userRole,
                                onEdit: () =>
                                    _showEditLogDialog(originalIndex, log),
                                onDelete: () => _showDeleteConfirmationDialog(
                                  originalIndex,
                                  log,
                                ),
                                onDismissed: (direction) {
                                  _controller.removeLog(originalIndex);
                                  Future.delayed(
                                    const Duration(milliseconds: 500),
                                    () => _triggerRefresh(),
                                  );
                                },
                                formatTimestamp: formatTimestamp,
                              );
                            },
                          ),
                        ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),

      floatingActionButton: FloatingActionButton(
        onPressed: _showAddLogDialog,
        backgroundColor: primaryColor,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    _searchController.dispose();
    super.dispose();
  }
}
