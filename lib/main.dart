// ignore_for_file: unused_element_parameter

import 'package:flutter/material.dart';

import 'database_service.dart';
import 'note.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const SecureNotesApp());
}

class SecureNotesApp extends StatelessWidget {
  const SecureNotesApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Secure Notes',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigo),
        scaffoldBackgroundColor: const Color(0xFFF6F7FB),
      ),
      home: const HomeScreen(),
    );
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<Note> notes = [];
  final searchController = TextEditingController();

  bool loading = true;

  @override
  void initState() {
    super.initState();
    loadNotes();
  }

  Future<void> loadNotes() async {
    try {
      final result = await DatabaseService.instance.getNotes(
        search: searchController.text,
      );

      if (!mounted) return;

      setState(() {
        notes = result;
        loading = false;
      });
    } catch (error) {
      if (!mounted) return;

      setState(() => loading = false);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Could not load notes. Check database setup.'),
        ),
      );
    }
  }

  Future<void> showNoteForm({Note? note}) async {
    final result = await showDialog<Note>(
      context: context,
      builder: (dialogContext) => _NoteFormDialog(note: note),
    );

    if (result == null) return;

    try {
      if (note == null) {
        await DatabaseService.instance.addNote(result);
      } else {
        await DatabaseService.instance.updateNote(result);
      }

      await loadNotes();

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            note == null
                ? 'Note added successfully'
                : 'Note updated successfully',
          ),
        ),
      );
    } catch (error) {
      if (!mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Could not save note.')));
    }
  }

  Future<void> confirmDelete(Note note) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete Note?'),
        content: Text('Delete "${note.title}" permanently?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed != true || note.id == null) return;

    try {
      await DatabaseService.instance.deleteNote(note.id!);
      await loadNotes();

      if (!mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Note deleted')));
    } catch (error) {
      if (!mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Could not delete note')));
    }
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Row(
          children: [
            Icon(Icons.lock_outline),
            SizedBox(width: 10),
            Text('Secure Notes'),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Refresh',
            onPressed: loadNotes,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: TextField(
                controller: searchController,
                onChanged: (_) => loadNotes(),
                decoration: InputDecoration(
                  hintText: 'Search notes by title...',
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: IconButton(
                    onPressed: () {
                      searchController.clear();
                      loadNotes();
                    },
                    icon: const Icon(Icons.clear),
                  ),
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ),
            Expanded(
              child: loading
                  ? const Center(child: CircularProgressIndicator())
                  : notes.isEmpty
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.note_alt_outlined,
                              size: 72,
                              color: Colors.indigo,
                            ),
                            const SizedBox(height: 12),
                            Text(
                              searchController.text.isEmpty
                                  ? 'No notes yet'
                                  : 'No matching notes',
                              style: Theme.of(context).textTheme.titleLarge,
                            ),
                            const SizedBox(height: 6),
                            const Text('Tap + to create your first note.'),
                          ],
                        ),
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 90),
                      itemCount: notes.length,
                      itemBuilder: (context, index) {
                        final note = notes[index];

                        return Card(
                          color: Colors.white,
                          margin: const EdgeInsets.only(bottom: 12),
                          child: ListTile(
                            contentPadding: const EdgeInsets.all(12),
                            leading: const CircleAvatar(
                              child: Icon(Icons.description_outlined),
                            ),
                            title: Text(
                              note.title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            subtitle: Padding(
                              padding: const EdgeInsets.only(top: 6),
                              child: Text(
                                note.description,
                                maxLines: 3,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            onTap: () => showNoteForm(note: note),
                            trailing: PopupMenuButton<String>(
                              onSelected: (value) {
                                if (value == 'edit') {
                                  showNoteForm(note: note);
                                } else if (value == 'delete') {
                                  confirmDelete(note);
                                }
                              },
                              itemBuilder: (context) => const [
                                PopupMenuItem(
                                  value: 'edit',
                                  child: Text('Edit'),
                                ),
                                PopupMenuItem(
                                  value: 'delete',
                                  child: Text('Delete'),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => showNoteForm(),
        icon: const Icon(Icons.add),
        label: const Text('Add Note'),
      ),
    );
  }
}

class _NoteFormDialog extends StatefulWidget {
  final Note? note;

  const _NoteFormDialog({super.key, this.note});

  @override
  State<_NoteFormDialog> createState() => _NoteFormDialogState();
}

class _NoteFormDialogState extends State<_NoteFormDialog> {
  late final TextEditingController titleController;
  late final TextEditingController descriptionController;
  final formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    titleController = TextEditingController(text: widget.note?.title ?? '');
    descriptionController = TextEditingController(
      text: widget.note?.description ?? '',
    );
  }

  @override
  void dispose() {
    titleController.dispose();
    descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.note != null;

    return AlertDialog(
      title: Text(isEditing ? 'Edit Note' : 'Add Note'),
      content: Form(
        key: formKey,
        child: SingleChildScrollView(
          child: SizedBox(
            width: 400,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: titleController,
                  maxLength: 80,
                  decoration: const InputDecoration(
                    labelText: 'Title',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.title),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter a title';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: descriptionController,
                  maxLines: 4,
                  maxLength: 2000,
                  decoration: const InputDecoration(
                    labelText: 'Description',
                    alignLabelWithHint: true,
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter a description';
                    }
                    return null;
                  },
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () {
            if (!formKey.currentState!.validate()) return;

            final savedNote = Note(
              id: widget.note?.id,
              title: titleController.text.trim(),
              description: descriptionController.text.trim(),
              createdAt:
                  widget.note?.createdAt ?? DateTime.now().toIso8601String(),
            );

            Navigator.pop(context, savedNote);
          },
          child: const Text('Save'),
        ),
      ],
    );
  }
}
