import 'package:flutter/material.dart';
import '../../services/storage_service.dart';
import 'notebook_details_screen.dart';

class AiScreen extends StatefulWidget {
  const AiScreen({super.key});

  @override
  State<AiScreen> createState() => _AiScreenState();
}

class _AiScreenState extends State<AiScreen> {
  List<Map<String, dynamic>> _notebooks = [];
  final TextEditingController _nameController = TextEditingController();
  int _selectedColorIndex = 0;

  @override
  void initState() {
    super.initState();
    _loadNotebooks();
  }

  void _loadNotebooks() {
    final notebooks = StorageService.getNotebooks();
    for (var notebook in notebooks) {
      final folders = StorageService.getFolders(notebook['name']);
      notebook['chapters'] = folders.length;
    }
    setState(() {
      _notebooks = notebooks;
    });
  }

  void _saveNotebooks() {
    StorageService.saveNotebooks(_notebooks);
  }

  final List<Color> _availableColors = [
    Colors.blue,
    Colors.teal,
    Colors.green,
    Colors.lightGreen,
    Colors.orange,
    Colors.redAccent,
    Colors.purpleAccent,
    Colors.lightBlueAccent,
  ];

  void _showCreateNotebookDialog({
    Map<String, dynamic>? editingNotebook,
    int? index,
  }) {
    if (editingNotebook != null) {
      _nameController.text = editingNotebook['name'];
      _selectedColorIndex = _availableColors.indexOf(
        Color(editingNotebook['colorValue']),
      );
    } else {
      _nameController.clear();
      _selectedColorIndex = 0;
    }

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return Dialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          editingNotebook == null
                              ? 'Create Notebook'
                              : 'Edit Notebook',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        IconButton(
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                          icon: const Icon(Icons.close, size: 20),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    TextField(
                      controller: _nameController,
                      onChanged: (val) => setDialogState(() {}),
                      decoration: InputDecoration(
                        labelText: 'Notebook name',
                        hintText: 'Name',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: Colors.blue),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: Colors.blue),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      'Color',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      height: 40,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: _availableColors.length,
                        separatorBuilder: (context, index) =>
                            const SizedBox(width: 10),
                        itemBuilder: (context, i) {
                          return GestureDetector(
                            onTap: () {
                              setDialogState(() {
                                _selectedColorIndex = i;
                              });
                            },
                            child: CircleAvatar(
                              radius: 18,
                              backgroundColor: _availableColors[i],
                              child: _selectedColorIndex == i
                                  ? const Icon(
                                      Icons.check,
                                      color: Colors.white,
                                      size: 18,
                                    )
                                  : null,
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: _nameController.text.trim().isEmpty
                            ? null
                            : () {
                                setState(() {
                                  if (editingNotebook != null &&
                                      index != null) {
                                    _notebooks[index] = {
                                      'name': _nameController.text.trim(),
                                      'colorValue':
                                          _availableColors[_selectedColorIndex]
                                              .value,
                                      'chapters': editingNotebook['chapters'],
                                    };
                                  } else {
                                    _notebooks.add({
                                      'name': _nameController.text.trim(),
                                      'colorValue':
                                          _availableColors[_selectedColorIndex]
                                              .value,
                                      'chapters': 0,
                                    });
                                  }
                                  _saveNotebooks();
                                });
                                Navigator.pop(context);
                              },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                          foregroundColor: Colors.white,
                          disabledBackgroundColor: Colors.grey[300],
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 0,
                        ),
                        child: Text(
                          editingNotebook == null ? 'Create' : 'Save',
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: _notebooks.isEmpty
          ? null
          : AppBar(
              backgroundColor: Colors.white,
              elevation: 0,
              title: const Text(
                'Notebook AI',
                style: TextStyle(
                  color: Colors.black,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              actions: [
                IconButton(
                  icon: const Icon(Icons.add, color: Colors.black, size: 28),
                  onPressed: () => _showCreateNotebookDialog(),
                ),
              ],
            ),
      body: _notebooks.isEmpty ? _buildEmptyState() : _buildNotebookList(),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: const BoxDecoration(
                color: Color(0xFFE3F2FD),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.copy, color: Colors.blue, size: 60),
            ),
            const SizedBox(height: 30),
            const Text(
              'No Subjects Yet',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Create your first subject to start organizing your learning materials',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: Colors.grey[600]),
            ),
            const SizedBox(height: 30),
            SizedBox(
              width: 200,
              height: 54,
              child: ElevatedButton.icon(
                onPressed: () => _showCreateNotebookDialog(),
                icon: const Icon(Icons.add_circle_outline),
                label: const Text(
                  'Add Subject',
                  style: TextStyle(fontSize: 16),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1D4ED8),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 4,
                  shadowColor: Colors.blue.withOpacity(0.4),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNotebookList() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(12),
            ),
            child: const TextField(
              decoration: InputDecoration(
                icon: Icon(Icons.search, color: Colors.grey),
                hintText: 'Search study sets',
                border: InputBorder.none,
              ),
            ),
          ),
        ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: _notebooks.length,
            itemBuilder: (context, index) {
              final notebook = _notebooks[index];
              return Container(
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: ListTile(
                  onTap: () async {
                    await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => NotebookDetailsScreen(
                          notebookName: notebook['name'],
                        ),
                      ),
                    );
                    _loadNotebooks();
                  },
                  contentPadding: const EdgeInsets.all(12),
                  leading: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Color(notebook['colorValue'] ?? Colors.blue.value),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.description, color: Colors.white),
                  ),
                  title: Text(
                    notebook['name'],
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  subtitle: Text(
                    '${notebook['chapters']} Chapters',
                    style: TextStyle(color: Colors.grey[600], fontSize: 13),
                  ),
                  trailing: PopupMenuButton<String>(
                    icon: const Icon(Icons.more_vert, color: Colors.grey),
                    onSelected: (value) {
                      if (value == 'edit') {
                        _showCreateNotebookDialog(
                          editingNotebook: notebook,
                          index: index,
                        );
                      } else if (value == 'delete') {
                        setState(() {
                          _notebooks.removeAt(index);
                          _saveNotebooks();
                        });
                      }
                    },
                    itemBuilder: (BuildContext context) => [
                      const PopupMenuItem(
                        value: 'edit',
                        child: Row(
                          children: [
                            Icon(Icons.edit, color: Colors.blue, size: 20),
                            SizedBox(width: 12),
                            Text('Edit name'),
                          ],
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'delete',
                        child: Row(
                          children: [
                            Icon(Icons.delete, color: Colors.red, size: 20),
                            SizedBox(width: 12),
                            Text('Delete'),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
