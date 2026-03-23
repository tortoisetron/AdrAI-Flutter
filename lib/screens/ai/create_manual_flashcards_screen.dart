import 'package:flutter/material.dart';
import '../../services/ai_service.dart';
import '../../services/storage_service.dart';
import 'dart:async';

class CreateManualFlashcardsScreen extends StatefulWidget {
  final String notebookName;
  final String? initialFolderName;
  final String? initialTopic;

  const CreateManualFlashcardsScreen({
    super.key,
    required this.notebookName,
    this.initialFolderName,
    this.initialTopic,
  });

  @override
  State<CreateManualFlashcardsScreen> createState() =>
      _CreateManualFlashcardsScreenState();
}

class _CreateManualFlashcardsScreenState
    extends State<CreateManualFlashcardsScreen> {
  final TextEditingController _folderController = TextEditingController();
  final TextEditingController _topicController = TextEditingController();
  final AiService _aiService = AiService();

  bool _isAiEnabled = true;
  AiSettings _aiSettings = AiSettings();

  List<Map<String, dynamic>> _cards = [];

  @override
  void initState() {
    super.initState();
    _folderController.text = widget.initialFolderName ?? '';
    _topicController.text = widget.initialTopic ?? '';

    // Initialize first card
    _addCard();

    if (_topicController.text.isNotEmpty) {
      _fetchSuggestions();
    }
  }

  List<String> _suggestions = [];
  bool _isLoadingSuggestions = false;
  Timer? _debounceTimer;

  @override
  void dispose() {
    _folderController.dispose();
    _topicController.dispose();
    _debounceTimer?.cancel();
    for (var card in _cards) {
      card['frontController'].dispose();
      card['backController'].dispose();
      card['explanationController'].dispose();
    }
    super.dispose();
  }

  void _onTopicChanged(String value) {
    _debounceFetch();
  }

  void _onQuestionChanged() {
    _debounceFetch();
  }

  void _debounceFetch() {
    if (_debounceTimer?.isActive ?? false) _debounceTimer!.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 1000), () {
      final hasTopic = _topicController.text.trim().isNotEmpty;
      final hasQuestion = _cards.any(
        (c) => (c['frontController'] as TextEditingController).text
            .trim()
            .isNotEmpty,
      );

      debugPrint(
        'Debounce Fetch: hasTopic=$hasTopic, hasQuestion=$hasQuestion',
      );
      if (hasTopic || hasQuestion) {
        _fetchSuggestions();
      }
    });
  }

  Future<void> _fetchSuggestions() async {
    setState(() => _isLoadingSuggestions = true);
    try {
      final questions = _cards
          .map(
            (c) => (c['frontController'] as TextEditingController).text.trim(),
          )
          .where((q) => q.isNotEmpty)
          .toList();

      String topicToUse = _topicController.text.trim();
      if (topicToUse.isEmpty && questions.isNotEmpty) {
        topicToUse = questions.first;
      }

      if (topicToUse.isEmpty) {
        setState(() => _isLoadingSuggestions = false);
        return;
      }

      debugPrint('Fetching suggestions for topic: $topicToUse');
      final suggestions = await _aiService.suggestNextQuestions(
        topic: topicToUse,
        subject: 'Medical',
        existingQuestions: questions,
        settings: _aiSettings,
      );
      debugPrint('Fetched suggestions: ${suggestions.length} items');
      setState(() {
        _suggestions = suggestions;
        _isLoadingSuggestions = false;
      });
    } catch (e) {
      debugPrint('Fetch Suggestions Error: $e');
      setState(() => _isLoadingSuggestions = false);
    }
  }

  Future<void> _generateAnswer(int index) async {
    final front =
        (_cards[index]['frontController'] as TextEditingController).text;
    if (front.isEmpty) return;

    setState(() {
      _cards[index]['isGenerating'] = true;
    });

    try {
      final result = await _aiService.generateAnswer(
        question: front,
        topic: _topicController.text,
        subject: 'Medical',
        settings: _aiSettings,
      );

      setState(() {
        (_cards[index]['backController'] as TextEditingController).text =
            result['back'] ?? '';
        (_cards[index]['explanationController'] as TextEditingController).text =
            result['explanation'] ?? '';
        _cards[index]['isGenerating'] = false;
        _cards[index]['showExplanation'] = true;
      });
    } catch (e) {
      setState(() => _cards[index]['isGenerating'] = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error generating answer: $e')));
    }
  }

  void _addCard([String? question]) {
    final frontController = TextEditingController(text: question ?? '');
    frontController.addListener(_onQuestionChanged);

    setState(() {
      _cards.add({
        'frontController': frontController,
        'backController': TextEditingController(),
        'explanationController': TextEditingController(),
        'showExplanation': false,
        'isGenerating': false,
      });
    });
    if (question != null) {
      _fetchSuggestions();
    }
  }

  Future<void> _saveAll() async {
    if (_folderController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a folder title')),
      );
      return;
    }

    final validCards = _cards
        .where((c) {
          final front = (c['frontController'] as TextEditingController).text;
          final back = (c['backController'] as TextEditingController).text;
          return front.isNotEmpty && back.isNotEmpty;
        })
        .map((c) {
          return {
            'front': (c['frontController'] as TextEditingController).text,
            'back': (c['backController'] as TextEditingController).text,
            'explanation':
                (c['explanationController'] as TextEditingController).text,
          };
        })
        .toList();

    if (validCards.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please add at least one complete flashcard'),
        ),
      );
      return;
    }

    final folders = StorageService.getFolders(widget.notebookName);
    folders.add({
      'name': _folderController.text,
      'count': validCards.length,
      'isExpanded': false,
      'cards': validCards,
      'date': DateTime.now().toString(),
      'metadata': {
        'topic': _topicController.text,
        'subject': 'Medical',
        'examType': _aiSettings.targetExam,
        'difficulty': _aiSettings.complexity == 'Basic'
            ? 0.3
            : _aiSettings.complexity == 'Advanced'
            ? 0.6
            : 0.9,
        'contentType': 'Factual',
      },
    });

    await StorageService.saveFolders(widget.notebookName, folders);
    Navigator.pop(context, true);
  }

  void _showAiSettings() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _AiSettingsSheet(
        initialSettings: _aiSettings,
        onSave: (newSettings) {
          setState(() => _aiSettings = newSettings);
          _fetchSuggestions();
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FB),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Create Flashcards',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        actions: [
          TextButton(
            onPressed: _saveAll,
            child: const Text(
              'Save',
              style: TextStyle(
                color: Colors.blue,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildInputGroup('Folder Title', _folderController, Icons.folder),
          const SizedBox(height: 12),
          _buildInputGroup(
            'Topic',
            _topicController,
            Icons.school,
            onChanged: _onTopicChanged,
          ),
          const SizedBox(height: 20),
          _buildAiToggle(),
          const SizedBox(height: 24),
          ...List.generate(_cards.length, (index) => _buildCardEditor(index)),
          if (_suggestions.isNotEmpty || _isLoadingSuggestions)
            _buildSuggestions(),
          const SizedBox(height: 80),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _addCard(),
        backgroundColor: Colors.blue,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildInputGroup(
    String label,
    TextEditingController controller,
    IconData icon, {
    Function(String)? onChanged,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF1F3F5),
        borderRadius: BorderRadius.circular(12),
      ),
      child: TextField(
        controller: controller,
        onChanged: onChanged,
        decoration: InputDecoration(
          prefixIcon: Icon(icon, color: Colors.blue, size: 20),
          labelText: label,
          labelStyle: const TextStyle(color: Colors.grey, fontSize: 14),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 12,
          ),
        ),
      ),
    );
  }

  Widget _buildAiToggle() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.blue.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.auto_awesome, color: Colors.blue),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'AI Auto-Complete',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                ),
                Text(
                  'Generate answers & explanations with AI',
                  style: TextStyle(color: Colors.grey, fontSize: 12),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.settings, color: Colors.grey),
            onPressed: _showAiSettings,
          ),
          Switch(
            value: _isAiEnabled,
            onChanged: (val) => setState(() => _isAiEnabled = val),
            activeColor: Colors.blue,
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
          BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: const BoxDecoration(
              color: Color(0xFFF8F9FA),
              borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Card ${index + 1}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                if (_cards.length > 1)
                  IconButton(
                    icon: const Icon(
                      Icons.delete_outline,
                      color: Colors.red,
                      size: 20,
                    ),
                    onPressed: () => setState(() => _cards.removeAt(index)),
                  ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                _buildCardTextField(
                  'Question',
                  card['frontController'] as TextEditingController,
                ),
                const SizedBox(height: 16),
                Stack(
                  alignment: Alignment.centerRight,
                  children: [
                    _buildCardTextField(
                      'Answer',
                      card['backController'] as TextEditingController,
                      hint: _isAiEnabled ? 'AI will generate answer...' : null,
                      isLoading: card['isGenerating'] ?? false,
                    ),
                    if (_isAiEnabled)
                      Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: IconButton(
                          icon: const Icon(
                            Icons.auto_awesome,
                            color: Colors.blue,
                          ),
                          onPressed: () => _generateAnswer(index),
                        ),
                      ),
                  ],
                ),
                if (card['showExplanation']) ...[
                  const SizedBox(height: 16),
                  _buildCardTextField(
                    'Explanation',
                    card['explanationController'] as TextEditingController,
                  ),
                ],
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: _buildActionButton(
                        Icons.image_outlined,
                        'Image',
                        () {},
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildActionButton(
                        Icons.add_circle_outline,
                        'Explanation',
                        () => setState(
                          () => card['showExplanation'] =
                              !card['showExplanation'],
                        ),
                        isActive: card['showExplanation'],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCardTextField(
    String label,
    TextEditingController controller, {
    String? hint,
    bool isLoading = false,
  }) {
    return TextFormField(
      controller: controller,
      maxLines: null,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        hintStyle: const TextStyle(color: Colors.grey, fontSize: 13),
        labelStyle: const TextStyle(color: Colors.grey, fontSize: 13),
        floatingLabelBehavior: FloatingLabelBehavior.always,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 12,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.blue),
        ),
        suffix: isLoading
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : null,
      ),
    );
  }

  Widget _buildActionButton(
    IconData icon,
    String label,
    VoidCallback onTap, {
    bool isActive = false,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          border: Border.all(
            color: isActive ? Colors.blue : Colors.blue.withOpacity(0.3),
          ),
          borderRadius: BorderRadius.circular(12),
          color: isActive ? Colors.blue.withOpacity(0.05) : null,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 18, color: Colors.blue),
            const SizedBox(width: 8),
            Text(
              label,
              style: const TextStyle(
                color: Colors.blue,
                fontWeight: FontWeight.bold,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSuggestions() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F3F5).withOpacity(0.5),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.auto_awesome, color: Colors.blue, size: 16),
              const SizedBox(width: 8),
              const Text(
                'Suggested Next Cards',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              if (_isLoadingSuggestions)
                const Padding(
                  padding: EdgeInsets.only(left: 8),
                  child: SizedBox(
                    width: 12,
                    height: 12,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          if (_suggestions.isEmpty && _isLoadingSuggestions)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 20),
              child: Center(
                child: Text(
                  'Searching for next topics...',
                  style: TextStyle(
                    color: Colors.black54,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
            )
          else
            ..._suggestions.map((s) => _buildSuggestionItem(s)),
        ],
      ),
    );
  }

  Widget _buildSuggestionItem(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        onTap: () => _addCard(text),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.blue.withOpacity(0.1)),
          ),
          child: Row(
            children: [
              Expanded(child: Text(text, style: const TextStyle(fontSize: 13))),
              const Icon(Icons.add_circle, color: Colors.blue, size: 20),
            ],
          ),
        ),
      ),
    );
  }
}

class _AiSettingsSheet extends StatefulWidget {
  final AiSettings initialSettings;
  final Function(AiSettings) onSave;

  const _AiSettingsSheet({required this.initialSettings, required this.onSave});

  @override
  State<_AiSettingsSheet> createState() => _AiSettingsSheetState();
}

class _AiSettingsSheetState extends State<_AiSettingsSheet> {
  late AiSettings _settings;

  @override
  void initState() {
    super.initState();
    _settings = widget.initialSettings;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildHeader(),
          _buildSection(
            'Answer Length',
            ['Short', 'Medium', 'Detailed'],
            _settings.answerLength,
            (v) => setState(() => _settings.answerLength = v),
          ),
          _buildSection(
            'Complexity Level',
            ['Basic', 'Advanced', 'Expert'],
            _settings.complexity,
            (v) => setState(() => _settings.complexity = v),
          ),
          _buildMultiSection(
            'Focus Areas',
            ['Key Facts', 'Mechanisms', 'Clinical Relevance'],
            _settings.focusAreas,
            (v) {
              setState(() {
                if (_settings.focusAreas.contains(v)) {
                  _settings.focusAreas.remove(v);
                } else {
                  _settings.focusAreas.add(v);
                }
              });
            },
          ),
          _buildSection(
            'Target Medical Exam',
            ['General', 'NEET UG', 'USMLE'],
            _settings.targetExam,
            (v) => setState(() => _settings.targetExam = v),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: const Icon(Icons.close),
            onPressed: () => Navigator.pop(context),
          ),
          const Text(
            'AI Settings',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
          ),
          TextButton(
            onPressed: () {
              widget.onSave(_settings);
              Navigator.pop(context);
            },
            child: const Text(
              'Done',
              style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blue),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSection(
    String title,
    List<String> options,
    String current,
    Function(String) onChanged,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Text(
            title,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
        ),
        ...options.map(
          (opt) => RadioListTile(
            title: Text(opt),
            value: opt,
            groupValue: current,
            onChanged: (val) => onChanged(val!),
            activeColor: Colors.blue,
            dense: true,
          ),
        ),
      ],
    );
  }

  Widget _buildMultiSection(
    String title,
    List<String> options,
    List<String> current,
    Function(String) onChanged,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Text(
            title,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
        ),
        ...options.map(
          (opt) => CheckboxListTile(
            title: Text(opt),
            value: current.contains(opt),
            onChanged: (val) => onChanged(opt),
            activeColor: Colors.blue,
            dense: true,
          ),
        ),
      ],
    );
  }
}
