import 'package:flutter/material.dart';
import '../../services/storage_service.dart';

class EditFlashcardsScreen extends StatefulWidget {
  final String notebookName;
  final int folderIndex;

  const EditFlashcardsScreen({
    super.key,
    required this.notebookName,
    required this.folderIndex,
  });

  @override
  State<EditFlashcardsScreen> createState() => _EditFlashcardsScreenState();
}

class _EditFlashcardsScreenState extends State<EditFlashcardsScreen> {
  late List<Map<String, dynamic>> _folders;
  late List<Map<String, dynamic>> _cards;
  late String _folderName;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  void _loadData() {
    _folders = StorageService.getFolders(widget.notebookName);
    final folder = _folders[widget.folderIndex];
    _folderName = folder['name'] ?? '';
    _cards = List<Map<String, dynamic>>.from(
      (folder['cards'] as List).map((c) => Map<String, dynamic>.from(c)),
    );
  }

  void _saveChanges() {
    _folders[widget.folderIndex]['cards'] = _cards;
    _folders[widget.folderIndex]['count'] = _cards.length;
    StorageService.saveFolders(widget.notebookName, _folders);
    Navigator.pop(context, true); // Return true to signal refresh
  }

  void _addNewCard() {
    setState(() {
      _cards.add({'front': '', 'back': '', 'explanation': ''});
    });
  }

  void _deleteCard(int index) {
    setState(() {
      _cards.removeAt(index);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FB),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Edit Flashcards',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        actions: [
          TextButton(
            onPressed: _saveChanges,
            child: const Text(
              'SAVE',
              style: TextStyle(color: Colors.blue, fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Column(
        children: [
          _buildHeader(),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: _cards.length,
              itemBuilder: (context, index) {
                return _buildCardEditor(index);
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addNewCard,
        backgroundColor: Colors.blue,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      color: Colors.white,
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.blue.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.folder, color: Colors.blue, size: 24),
          ),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _folderName,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                '${_cards.length} flashcards',
                style: TextStyle(color: Colors.grey[600], fontSize: 13),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCardEditor(int index) {
    final card = _cards[index];
    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: const Color(0xFFF1F3F5).withOpacity(0.5),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(16),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Card ${index + 1}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                    color: Colors.black87,
                  ),
                ),
                GestureDetector(
                  onTap: () => _deleteCard(index),
                  child: const Icon(
                    Icons.delete,
                    color: Color(0xFFE57373),
                    size: 22,
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                _buildTextField(
                  label: 'Question',
                  initialValue: card['front'],
                  onChanged: (val) => card['front'] = val,
                ),
                const SizedBox(height: 20),
                _buildTextField(
                  label: 'Answer',
                  initialValue: card['back'],
                  onChanged: (val) => card['back'] = val,
                ),
                const SizedBox(height: 20),
                _buildTextField(
                  label: 'Explanation (Optional)',
                  initialValue: card['explanation'] ?? '',
                  onChanged: (val) => card['explanation'] = val,
                ),
                const SizedBox(height: 20),
                _buildImageButton(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required String label,
    required String initialValue,
    required Function(String) onChanged,
  }) {
    return TextFormField(
      initialValue: initialValue,
      onChanged: onChanged,
      maxLines: null,
      style: const TextStyle(fontSize: 15, color: Colors.black87),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.grey, fontSize: 13),
        floatingLabelBehavior: FloatingLabelBehavior.always,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 12,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFCFD8DC)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFCFD8DC)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.blue, width: 1.5),
        ),
      ),
    );
  }

  Widget _buildImageButton() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        border: Border.all(color: Colors.blue.withOpacity(0.5)),
        borderRadius: BorderRadius.circular(12),
      ),
      child: TextButton.icon(
        onPressed: () {},
        icon: const Icon(Icons.image_outlined, size: 20, color: Colors.blue),
        label: const Text(
          'Image',
          style: TextStyle(color: Colors.blue, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}
