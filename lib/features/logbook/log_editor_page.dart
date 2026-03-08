import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'models/log_model.dart';
import 'log_controller.dart';

/// Halaman editor full-page untuk membuat/mengedit catatan dengan Markdown support
class LogEditorPage extends StatefulWidget {
  final LogModel? log; // Jika null = Create, jika ada = Edit
  final int? index; // Index di list (hanya untuk update)
  final LogController controller;
  final String userId; // ID pengguna yang sedang login
  final String userRole; // Role untuk RBAC check

  const LogEditorPage({
    super.key,
    this.log,
    this.index,
    required this.controller,
    required this.userId,
    required this.userRole,
  });

  @override
  State<LogEditorPage> createState() => _LogEditorPageState();
}

class _LogEditorPageState extends State<LogEditorPage> {
  late TextEditingController _titleController;
  late TextEditingController _descController;
  late TextEditingController _categoryController;
  bool _isSaving = false;
  bool _isPublic =
      false; // Privacy control: false = Private (default), true = Public

  @override
  void initState() {
    super.initState();
    // ========== INISIALISASI CONTROLLER DENGAN DATA EXISTING ==========
    _titleController = TextEditingController(text: widget.log?.title ?? '');
    _descController = TextEditingController(
      text: widget.log?.description ?? '',
    );
    _categoryController = TextEditingController(
      text: widget.log?.category ?? 'Pribadi',
    );
    _isPublic = widget.log?.isPublic ?? false; // Initialize from existing log

    // Listener untuk real-time update preview
    _descController.addListener(() {
      setState(() {});
    });

    _titleController.addListener(() {
      setState(() {});
    });
  }

  /// Simpan catatan (Create atau Update)
  Future<void> _save() async {
    // Validasi input
    if (_titleController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Judul tidak boleh kosong'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (_descController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Deskripsi tidak boleh kosong'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      if (widget.log == null) {
        // ========== CREATE LOG BARU ==========
        await widget.controller.addLog(
          _titleController.text,
          _descController.text,
          _categoryController.text,
          isPublic: _isPublic,
        );

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('✅ Catatan berhasil disimpan'),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 2),
            ),
          );
          Navigator.pop(context);
        }
      } else {
        // ========== UPDATE LOG EXISTING ==========
        await widget.controller.updateLog(
          widget.index!,
          _titleController.text,
          _descController.text,
          _categoryController.text,
          isPublic: _isPublic,
        );

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('✅ Catatan berhasil diupdate'),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 2),
            ),
          );
          Navigator.pop(context);
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('❌ Error: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      setState(() => _isSaving = false);
    }
  }

  @override
  void dispose() {
    // ========== CLEANUP CONTROLLER UNTUK PREVENT MEMORY LEAK ==========
    _titleController.dispose();
    _descController.dispose();
    _categoryController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEditMode = widget.log != null;
    const tabColor = Color.fromARGB(255, 254, 166, 209);

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: Text(isEditMode ? "Edit Catatan" : "Catatan Baru"),
          backgroundColor: tabColor,
          foregroundColor: Colors.white,
          elevation: 0,
          bottom: const TabBar(
            indicatorColor: Colors.white,
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white70,
            tabs: [
              Tab(icon: Icon(Icons.edit), text: "Editor"),
              Tab(icon: Icon(Icons.preview), text: "Pratinjau"),
            ],
          ),
          actions: [
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Center(
                child: _isSaving
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Colors.white,
                          ),
                          strokeWidth: 2,
                        ),
                      )
                    : ElevatedButton.icon(
                        icon: const Icon(Icons.save),
                        label: const Text("Simpan"),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: tabColor,
                        ),
                        onPressed: _isSaving ? null : _save,
                      ),
              ),
            ),
          ],
        ),
        body: TabBarView(
          children: [
            // ========== TAB 1: EDITOR ==========
            _buildEditorTab(),

            // ========== TAB 2: MARKDOWN PREVIEW ==========
            _buildPreviewTab(),
          ],
        ),
      ),
    );
  }

  /// Widget Tab Editor dengan TextField untuk Title, Category, dan Description
  Widget _buildEditorTab() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          // ========== FIELD: TITLE ==========
          TextField(
            controller: _titleController,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            decoration: InputDecoration(
              labelText: "Judul Catatan",
              hintText: "Masukkan judul catatan Anda",
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(
                  color: Color.fromARGB(255, 254, 166, 209),
                  width: 2,
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),

          // ========== FIELD: CATEGORY ==========
          DropdownButtonFormField<String>(
            initialValue: _categoryController.text.isEmpty
                ? 'Pribadi'
                : _categoryController.text,
            decoration: InputDecoration(
              labelText: "Kategori",
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(
                  color: Color.fromARGB(255, 254, 166, 209),
                  width: 2,
                ),
              ),
            ),
            items: ['Pribadi', 'Pekerjaan', 'Urgent']
                .map((cat) => DropdownMenuItem(value: cat, child: Text(cat)))
                .toList(),
            onChanged: (value) {
              _categoryController.text = value ?? 'Pribadi';
            },
          ),
          const SizedBox(height: 12),

          // ========== FIELD: PRIVACY CONTROL ==========
          Container(
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey[300]!),
              borderRadius: BorderRadius.circular(8),
            ),
            child: ListTile(
              title: const Text(
                "Visibilitas Catatan",
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: Text(
                _isPublic
                    ? "🌐 Publik (Semua bisa lihat)"
                    : "🔒 Privat (Hanya kamu yang lihat)",
              ),
              trailing: Switch(
                value: _isPublic,
                activeThumbColor: const Color.fromARGB(255, 254, 166, 209),
                onChanged: (value) {
                  setState(() {
                    _isPublic = value;
                  });
                },
              ),
            ),
          ),
          const SizedBox(height: 12),

          // ========== FIELD: DESCRIPTION (MARKDOWN) ==========
          Expanded(
            child: TextField(
              controller: _descController,
              maxLines: null,
              expands: true,
              keyboardType: TextInputType.multiline,
              style: const TextStyle(fontSize: 14),
              decoration: InputDecoration(
                hintText:
                    "Tulis catatan dengan format Markdown...\n\n# Heading 1\n## Heading 2\n**Bold** | *Italic* | `Code`\n- List item\n1. Numbered item",
                hintStyle: const TextStyle(color: Colors.grey),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(
                    color: Color.fromARGB(255, 254, 166, 209),
                    width: 2,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Widget Tab Pratinjau Markdown
  Widget _buildPreviewTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ========== PREVIEW: TITLE ==========
          if (_titleController.text.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 16.0),
              child: Text(
                _titleController.text,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),

          // ========== PREVIEW: CATEGORY BADGE ==========
          if (_categoryController.text.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 12.0),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: const Color.fromARGB(255, 254, 166, 209),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  _categoryController.text,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),

          // ========== PREVIEW: MARKDOWN CONTENT ==========
          if (_descController.text.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 48.0),
                child: Text(
                  "Belum ada konten. Mulai tulis di tab Editor.",
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
            )
          else
            MarkdownBody(
              data: _descController.text,
              selectable: true,
              styleSheet: MarkdownStyleSheet(
                h1: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                h2: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                p: const TextStyle(fontSize: 14, height: 1.5),
                code: TextStyle(
                  backgroundColor: Colors.grey[200],
                  fontFamily: 'monospace',
                  fontSize: 12,
                ),
                codeblockDecoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
