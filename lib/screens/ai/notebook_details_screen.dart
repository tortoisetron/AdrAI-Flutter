import 'package:flutter/material.dart';
import 'dart:convert';
import '../../services/ai_service.dart';
import '../../services/storage_service.dart';
import 'flashcard_study_screen.dart';
import 'edit_flashcards_screen.dart';
import 'create_manual_flashcards_screen.dart';

class NotebookDetailsScreen extends StatefulWidget {
  final String notebookName;

  const NotebookDetailsScreen({super.key, required this.notebookName});

  @override
  State<NotebookDetailsScreen> createState() => _NotebookDetailsScreenState();
}

class _NotebookDetailsScreenState extends State<NotebookDetailsScreen> {
  final AiService _aiService = AiService();
  List<Map<String, dynamic>> _folders = [];

  @override
  void initState() {
    super.initState();
    _loadFolders();
  }

  void _loadFolders() {
    setState(() {
      _folders = StorageService.getFolders(widget.notebookName);
    });
  }

  void _saveFolders() {
    StorageService.saveFolders(widget.notebookName, _folders);
  }

  void _showGenerateWithAiBottomSheet() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'Generate with AI',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text(
                'Choose what you want to create',
                style: TextStyle(color: Colors.grey),
              ),
              const SizedBox(height: 24),
              _buildAiOption(
                icon: Icons.bolt,
                color: Colors.blue,
                title: 'Flashcards AI',
                subtitle: 'Create flashcards on any topic in seconds',
                onTap: () {
                  Navigator.pop(context);
                  _showCreateFlashcardsBottomSheet();
                },
              ),
              _buildAiOption(
                icon: Icons.help_outline,
                color: Colors.purple,
                title: 'MCQ AI',
                subtitle: 'Create MCQs on any topic in seconds',
                onTap: () {},
              ),
              _buildAiOption(
                icon: Icons.picture_as_pdf,
                color: Colors.green,
                title: 'Notes AI',
                subtitle: 'Upload PDFs & chat with AI',
                onTap: () {},
              ),
            ],
          ),
        );
      },
    );
  }

  void _showCreateFlashcardsBottomSheet() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'Create Flashcards',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text(
                'Choose how you want to create',
                style: TextStyle(color: Colors.grey),
              ),
              const SizedBox(height: 24),
              _buildAiOption(
                icon: Icons.bolt,
                color: Colors.blue,
                title: 'Create Manually',
                subtitle: 'Manually create flashcards with AI assistance',
                onTap: () async {
                  Navigator.pop(context);
                  final result = await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => CreateManualFlashcardsScreen(
                        notebookName: widget.notebookName,
                      ),
                    ),
                  );
                  if (result == true) {
                    _loadFolders();
                  }
                },
              ),
              _buildAiOption(
                icon: Icons.auto_awesome,
                color: Colors.blue,
                title: 'Create with AI',
                subtitle: 'Generate flashcards using AI prompts',
                onTap: () {
                  Navigator.pop(context);
                  _showGenerateFlashcardsDialog();
                },
              ),
              _buildAiOption(
                icon: Icons.picture_as_pdf,
                color: Colors.redAccent,
                title: 'Create with PDF',
                subtitle: 'Convert PDFs to Flashcards',
                onTap: () {},
              ),
            ],
          ),
        );
      },
    );
  }

  void _showGenerateFlashcardsDialog() {
    final TextEditingController folderController = TextEditingController();
    final TextEditingController topicController = TextEditingController();
    final TextEditingController subjectController = TextEditingController();
    String examType = 'General';
    int flashcardCount = 5;
    double difficulty = 0.5;
    String contentType = 'Factual';

    final List<String> examTypes = [
      'General',
      'CUET',
      'USMLE',
      'NEET PG',
      'NEET UG',
      'INICET',
      'PLAB',
      'AMC',
      'FMGE',
      'MCCQE',
      'MRCP',
      'MRCS',
      'FCPS',
      'DNB',
      'NBDE',
      'NBME',
    ];

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return Dialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
              ),
              insetPadding: const EdgeInsets.all(16),
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Generate Flashcards',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            letterSpacing: -0.5,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close, color: Colors.grey),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    TextField(
                      controller: folderController,
                      onChanged: (_) => setDialogState(() {}),
                      decoration: InputDecoration(
                        labelText: 'Folder Title',
                        hintText: 'e.g., Cardiology',
                        prefixIcon: const Icon(Icons.folder_outlined, size: 20),
                        floatingLabelBehavior: FloatingLabelBehavior.auto,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide(color: Colors.grey[300]!),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide(color: Colors.grey[300]!),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: const BorderSide(
                            color: Colors.blue,
                            width: 2,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    TextField(
                      controller: topicController,
                      onChanged: (_) => setDialogState(() {}),
                      maxLines: 3,
                      decoration: InputDecoration(
                        labelText: 'Topic name or paste text',
                        hintText: 'e.g., Cardiac Physiology',
                        alignLabelWithHint: true,
                        prefixIcon: const Icon(
                          Icons.edit_note_outlined,
                          size: 20,
                        ),
                        floatingLabelBehavior: FloatingLabelBehavior.auto,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide(color: Colors.grey[300]!),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide(color: Colors.grey[300]!),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: const BorderSide(
                            color: Colors.blue,
                            width: 2,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    TextField(
                      controller: subjectController,
                      onChanged: (_) => setDialogState(() {}),
                      decoration: InputDecoration(
                        labelText: 'Subject',
                        hintText: 'Enter subject name',
                        prefixIcon: const Icon(
                          Icons.subject_outlined,
                          size: 20,
                        ),
                        floatingLabelBehavior: FloatingLabelBehavior.auto,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide(color: Colors.grey[300]!),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide(color: Colors.grey[300]!),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: const BorderSide(
                            color: Colors.blue,
                            width: 2,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    DropdownButtonFormField<String>(
                      value: examType,
                      decoration: InputDecoration(
                        labelText: 'Exam Type',
                        prefixIcon: const Icon(Icons.school_outlined, size: 20),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      items: examTypes
                          .map(
                            (type) => DropdownMenuItem(
                              value: type,
                              child: Text(type),
                            ),
                          )
                          .toList(),
                      onChanged: (val) => setDialogState(() => examType = val!),
                    ),
                    const SizedBox(height: 20),
                    DropdownButtonFormField<String>(
                      value: flashcardCount.toString(),
                      decoration: InputDecoration(
                        labelText: 'Number of Flashcards',
                        prefixIcon: const Icon(
                          Icons.filter_none_outlined,
                          size: 20,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      items: ['5', '8', '10']
                          .map(
                            (count) => DropdownMenuItem(
                              value: count,
                              child: Text(count),
                            ),
                          )
                          .toList(),
                      onChanged: (val) => setDialogState(
                        () => flashcardCount = int.parse(val!),
                      ),
                    ),
                    const SizedBox(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Difficulty Level',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                        Text(
                          difficulty < 0.33
                              ? 'Basic'
                              : difficulty < 0.66
                              ? 'Intermediate'
                              : 'Expert Level',
                          style: TextStyle(
                            color: Colors.blue,
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                    Slider(
                      value: difficulty,
                      divisions: 2,
                      activeColor: Colors.blue,
                      onChanged: (val) =>
                          setDialogState(() => difficulty = val),
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      value: contentType,
                      decoration: InputDecoration(
                        labelText: 'Content Type',
                        prefixIcon: const Icon(
                          Icons.category_outlined,
                          size: 20,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      items: ['Factual', 'Conceptual', 'Procedural']
                          .map(
                            (type) => DropdownMenuItem(
                              value: type,
                              child: Text(type),
                            ),
                          )
                          .toList(),
                      onChanged: (val) =>
                          setDialogState(() => contentType = val!),
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed:
                            topicController.text.isEmpty ||
                                subjectController.text.isEmpty
                            ? null
                            : () async {
                                Navigator.pop(context);
                                _handleGenerate(
                                  topic: topicController.text,
                                  subject: subjectController.text,
                                  folderTitle: folderController.text,
                                  examType: examType,
                                  count: flashcardCount,
                                  difficulty: difficulty,
                                  contentType: contentType,
                                );
                              },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text('Generate Flashcards'),
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

  void _showEditFolderDialog(int index) {
    final TextEditingController editController = TextEditingController(
      text: _folders[index]['name'],
    );

    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Edit Folder Name',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 24),
                TextField(
                  controller: editController,
                  autofocus: true,
                  decoration: InputDecoration(
                    labelText: 'Folder Name',
                    hintText: 'e.g., Cardiology',
                    prefixIcon: const Icon(Icons.folder_outlined, size: 20),
                    floatingLabelBehavior: FloatingLabelBehavior.auto,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide(color: Colors.grey[300]!),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide(color: Colors.grey[300]!),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: const BorderSide(
                        color: Colors.blue,
                        width: 2,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text(
                        'Cancel',
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton(
                      onPressed: () {
                        if (editController.text.trim().isNotEmpty) {
                          setState(() {
                            _folders[index]['name'] = editController.text
                                .trim();
                            _saveFolders();
                          });
                          Navigator.pop(context);
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 12,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text('Save Changes'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showHamsterLoadingDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(
                  width: 40,
                  height: 40,
                  child: CircularProgressIndicator(
                    strokeWidth: 3,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
                  ),
                ),
                const SizedBox(height: 24),
                const Text(
                  'Training AI hamsters to run faster...',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                Text(
                  'This might take a moment',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _handleGenerate({
    required String topic,
    required String subject,
    required String folderTitle,
    required String examType,
    required int count,
    required double difficulty,
    required String contentType,
  }) async {
    _showHamsterLoadingDialog();

    final result = await _aiService.generateFlashcards(
      topic: topic,
      subject: subject,
      folderTitle: folderTitle,
      examType: examType,
      count: count,
      difficulty: difficulty,
      contentType: contentType,
    );

    Navigator.pop(context); // Close loading dialog

    if (result['success']) {
      try {
        debugPrint('AI Response to parse: ${result['answer']}');
        final decoded = jsonDecode(result['answer']);

        List rawCards;
        if (decoded is List) {
          rawCards = decoded;
        } else if (decoded is Map) {
          rawCards = [decoded];
        } else {
          throw FormatException('Response is not a valid flashcard format');
        }

        if (rawCards.isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'AI could not generate cards for this topic. Please try a different or more specific topic.',
              ),
              backgroundColor: Colors.orange,
            ),
          );
          return;
        }

        final List<Map<String, dynamic>> decodedCards = rawCards
            .map((item) => Map<String, dynamic>.from(item))
            .toList();

        setState(() {
          _folders.insert(0, {
            'name': folderTitle,
            'count': decodedCards.length,
            'isExpanded': false,
            'cards': decodedCards,
            'metadata': {
              'topic': topic,
              'subject': subject,
              'examType': examType,
              'difficulty': difficulty,
              'contentType': contentType,
            },
          });
          _saveFolders();
        });
      } catch (e, stack) {
        debugPrint('JSON Parse Error: $e');
        debugPrint('Stack Trace: $stack');
        debugPrint('Failed content: ${result['answer']}');

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'AI Parsing Error (v5): ${e.toString().split('\n').first}',
            ),
            backgroundColor: Colors.red,
            action: SnackBarAction(
              label: 'Details',
              textColor: Colors.white,
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('Parse Error Details'),
                    content: SingleChildScrollView(
                      child: Text(
                        'Error: $e\n\nResponse:\n${result['answer']}',
                      ),
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Close'),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        );
      }
    } else {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: ${result['error']}')));
    }
  }

  Widget _buildFlashcardTab() {
    if (_folders.isEmpty) {
      return _buildEmptyState(
        'No flashcards yet',
        'Tap the ✨ button to create your first set of flashcards ↘️',
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _folders.length,
      itemBuilder: (context, index) {
        final folder = _folders[index];
        return Container(
          margin: const EdgeInsets.only(bottom: 16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        folder['name'],
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey[300]!),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: PopupMenuButton<String>(
                        icon: const Icon(Icons.more_vert, color: Colors.grey),
                        onSelected: (value) async {
                          if (value == 'Edit folder name') {
                            _showEditFolderDialog(index);
                          } else if (value == 'Edit Flashcards') {
                            final result = await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => EditFlashcardsScreen(
                                  notebookName: widget.notebookName,
                                  folderIndex: index,
                                ),
                              ),
                            );
                            if (result == true) {
                              _loadFolders();
                            }
                          } else if (value == 'Delete folder') {
                            setState(() {
                              _folders.removeAt(index);
                              _saveFolders();
                            });
                          }
                        },
                        itemBuilder: (context) => [
                          _buildPopupItem(Icons.edit, 'Edit folder name'),
                          _buildPopupItem(Icons.edit_note, 'Edit Flashcards'),
                          _buildPopupItem(
                            Icons.merge_type,
                            'Merge with another folder',
                          ),
                          _buildPopupItem(
                            Icons.delete,
                            'Delete folder',
                            isDestructive: true,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => FlashcardStudyScreen(
                              notebookName: widget.notebookName,
                              folderName: folder['name'],
                              cards: (folder['cards'] as List)
                                  .map(
                                    (item) => Map<String, dynamic>.from(item),
                                  )
                                  .toList(),
                              metadata: Map<String, dynamic>.from(
                                folder['metadata'] ??
                                    {
                                      'topic': folder['name'],
                                      'subject': 'Medical',
                                      'examType': 'General',
                                      'difficulty': 0.6,
                                      'contentType': 'Factual',
                                    },
                              ),
                            ),
                          ),
                        );
                      },
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey[300]!),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.play_arrow, color: Colors.blue),
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              InkWell(
                onTap: () {
                  setState(() {
                    folder['isExpanded'] = !(folder['isExpanded'] ?? false);
                  });
                },
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  child: Row(
                    children: [
                      Text(
                        'View Cards',
                        style: TextStyle(color: Colors.grey[600], fontSize: 14),
                      ),
                      const Spacer(),
                      Icon(
                        (folder['isExpanded'] ?? false)
                            ? Icons.expand_less
                            : Icons.expand_more,
                        color: Colors.grey[600],
                      ),
                    ],
                  ),
                ),
              ),
              if (folder['isExpanded'] ?? false)
                Container(
                  padding: const EdgeInsets.all(16),
                  color: Colors.grey[50],
                  child:
                      (folder['cards'] == null ||
                          (folder['cards'] as List).isEmpty)
                      ? const Center(
                          child: Padding(
                            padding: EdgeInsets.all(20.0),
                            child: Text(
                              'No cards found in this folder. Try generating them again.',
                              textAlign: TextAlign.center,
                              style: TextStyle(color: Colors.grey),
                            ),
                          ),
                        )
                      : Column(
                          children: (folder['cards'] as List).map<Widget>((
                            card,
                          ) {
                            return Container(
                              margin: const EdgeInsets.only(bottom: 16),
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: Colors.blue.withOpacity(0.1),
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.02),
                                    blurRadius: 10,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 10,
                                          vertical: 4,
                                        ),
                                        decoration: BoxDecoration(
                                          color: Colors.blue.withOpacity(0.1),
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                        ),
                                        child: const Text(
                                          'Q',
                                          style: TextStyle(
                                            color: Colors.blue,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 12,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Text(
                                          card['front'] ?? '',
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 16,
                                            height: 1.4,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const Padding(
                                    padding: EdgeInsets.symmetric(vertical: 12),
                                    child: Divider(height: 1),
                                  ),
                                  _buildCardDetailSection(
                                    icon: Icons.check_circle_outline,
                                    color: Colors.green,
                                    label: 'ANSWER',
                                    content: card['back'] ?? '',
                                  ),
                                  if (card['explanation'] != null &&
                                      card['explanation']
                                          .toString()
                                          .isNotEmpty) ...[
                                    const SizedBox(height: 12),
                                    _buildCardDetailSection(
                                      icon: Icons.info_outline,
                                      color: Colors.orange,
                                      label: 'EXPLANATION',
                                      content: card['explanation'] ?? '',
                                    ),
                                  ],
                                ],
                              ),
                            );
                          }).toList(),
                        ),
                ),
            ],
          ),
        );
      },
    );
  }

  PopupMenuItem<String> _buildPopupItem(
    IconData icon,
    String title, {
    bool isDestructive = false,
  }) {
    return PopupMenuItem<String>(
      value: title,
      child: Row(
        children: [
          Icon(icon, color: isDestructive ? Colors.red : Colors.blue, size: 20),
          const SizedBox(width: 12),
          Text(
            title,
            style: TextStyle(
              color: isDestructive ? Colors.red : Colors.black87,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAiOption({
    required IconData icon,
    required Color color,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return ListTile(
      onTap: onTap,
      leading: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, color: color),
      ),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
      subtitle: Text(subtitle, style: const TextStyle(fontSize: 12)),
      trailing: const Icon(Icons.chevron_right, color: Colors.grey),
    );
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.black),
            onPressed: () => Navigator.pop(context),
          ),
          title: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFF007AFF),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Text(
              'Notebook',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          centerTitle: true,
          actions: [
            IconButton(
              icon: const Icon(
                Icons.help_outline,
                color: Color(0xFF007AFF),
                size: 28,
              ),
              onPressed: () {},
            ),
          ],
          bottom: const TabBar(
            labelColor: Color(0xFF007AFF),
            unselectedLabelColor: Colors.grey,
            indicatorColor: Color(0xFF007AFF),
            indicatorWeight: 3,
            tabs: [
              Tab(icon: Icon(Icons.description), text: 'FlashCards'),
              Tab(icon: Icon(Icons.help_outline), text: 'MCQs'),
              Tab(icon: Icon(Icons.note_alt_outlined), text: 'Notes'),
            ],
          ),
        ),
        body: Column(
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
                    hintText: 'Search your content...',
                    border: InputBorder.none,
                  ),
                ),
              ),
            ),
            Expanded(
              child: TabBarView(
                children: [
                  _buildFlashcardTab(),
                  _buildEmptyState(
                    'No MCQs yet',
                    'Tap the ✨ button to create your first set of MCQs ↘️',
                  ),
                  _buildEmptyState(
                    'No PDFs yet',
                    'Tap the ✨ button to upload your first PDF for chat ↘️',
                  ),
                ],
              ),
            ),
          ],
        ),
        floatingActionButton: Container(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: const LinearGradient(
              colors: [Color(0xFF007AFF), Color(0xFF00C6FF)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.blue.withOpacity(0.4),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: FloatingActionButton(
            onPressed: _showGenerateWithAiBottomSheet,
            backgroundColor: Colors.transparent,
            elevation: 0,
            child: const Icon(Icons.auto_awesome, color: Colors.white),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(String title, String subtitle) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.eco, color: Colors.blue, size: 100),
            const SizedBox(height: 20),
            Text(
              title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 15, color: Colors.grey[600]),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCardDetailSection({
    required IconData icon,
    required Color color,
    required String label,
    required String content,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 14, color: color),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 11,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Text(
          content,
          style: TextStyle(color: Colors.grey[800], fontSize: 14, height: 1.4),
        ),
      ],
    );
  }
}
