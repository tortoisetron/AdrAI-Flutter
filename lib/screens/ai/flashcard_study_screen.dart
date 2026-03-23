import 'package:flutter/material.dart';
import 'dart:math';
import '../../services/ai_service.dart';
import '../../services/storage_service.dart';
import 'dart:convert';

class FlashcardStudyScreen extends StatefulWidget {
  final String notebookName;
  final String folderName;
  final List<Map<String, dynamic>> cards;
  final Map<String, dynamic>? metadata; // Add metadata for endless mode

  const FlashcardStudyScreen({
    super.key,
    required this.notebookName,
    required this.folderName,
    required this.cards,
    this.metadata,
  });

  @override
  State<FlashcardStudyScreen> createState() => _FlashcardStudyScreenState();
}

class _FlashcardStudyScreenState extends State<FlashcardStudyScreen> {
  late PageController _pageController;
  late List<Map<String, dynamic>> _currentCards;
  int _currentPage = 0;
  bool _showAnswer = false;
  bool _isEndlessMode = false;
  bool _isGenerating = false;
  final AiService _aiService = AiService();

  @override
  void initState() {
    super.initState();
    _currentCards = List.from(widget.cards);
    _pageController = PageController();
    debugPrint('FlashcardStudyScreen Init: Metadata = ${widget.metadata}');
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _generateMoreCards() async {
    if (_isGenerating || widget.metadata == null) {
      if (widget.metadata == null) {
        debugPrint('Endless Mode Error: No metadata found for this folder.');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Endless Mode requires a newly created folder with AI metadata. Please create a new folder to test.',
            ),
            duration: Duration(seconds: 3),
          ),
        );
        setState(() => _isEndlessMode = false);
      }
      return;
    }

    debugPrint('Endless Mode: Starting generation of 2 more cards...');
    setState(() {
      _isGenerating = true;
    });

    final result = await _aiService.generateFlashcards(
      topic: widget.metadata!['topic'] ?? '',
      subject: widget.metadata!['subject'] ?? '',
      folderTitle: widget.folderName,
      examType: widget.metadata!['examType'] ?? 'General',
      count: 2, // Generate 2 more cards
      difficulty: widget.metadata!['difficulty'] ?? 0.5,
      contentType: widget.metadata!['contentType'] ?? 'Factual',
    );

    if (result['success']) {
      try {
        final List rawCards = jsonDecode(result['answer']);
        final List<Map<String, dynamic>> newCards = rawCards
            .map((item) => Map<String, dynamic>.from(item))
            .toList();

        debugPrint(
          'Endless Mode: Successfully generated ${newCards.length} cards.',
        );
        setState(() {
          _currentCards.addAll(newCards);
          _isGenerating = false;
        });

        // Save progress to StorageService
        try {
          final folders = StorageService.getFolders(widget.notebookName);
          final folderIndex = folders.indexWhere(
            (f) => f['name'] == widget.folderName,
          );

          if (folderIndex != -1) {
            folders[folderIndex]['cards'] = _currentCards;
            folders[folderIndex]['count'] = _currentCards.length;
            await StorageService.saveFolders(widget.notebookName, folders);
            debugPrint(
              'Endless Mode: Saved ${newCards.length} new cards to storage (Total: ${_currentCards.length})',
            );
          } else {
            debugPrint(
              'Endless Mode Error: Could not find folder "${widget.folderName}" in notebook "${widget.notebookName}" to save cards.',
            );
          }
        } catch (saveError) {
          debugPrint('Endless Mode Save Error: $saveError');
        }
      } catch (e) {
        debugPrint('Endless Mode JSON Parse Error: $e');
        setState(() => _isGenerating = false);
      }
    } else {
      debugPrint('Endless Mode Generation Error: ${result['error']}');
      setState(() => _isGenerating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_currentCards.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: Text(widget.folderName)),
        body: const Center(child: Text('No cards available')),
      );
    }

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.black, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          widget.folderName,
          style: const TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.description, color: Colors.black54),
            onPressed: () {},
          ),
          IconButton(
            icon: const Icon(Icons.access_time, color: Colors.black54),
            onPressed: () {},
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Column(
        children: [
          _buildHeaderProgress(),

          // HUD Loader moved inside Column for better visibility
          _buildHudLoader(),

          Expanded(
            child: PageView.builder(
              controller: _pageController,
              itemCount: _currentCards.length,
              onPageChanged: (index) {
                setState(() {
                  _currentPage = index;
                  _showAnswer = false;
                });

                // Proximity detection for Endless Mode
                if (_isEndlessMode && index >= _currentCards.length - 2) {
                  _generateMoreCards();
                }
              },
              itemBuilder: (context, index) {
                return _buildFlashcard(_currentCards[index]);
              },
            ),
          ),
          _buildBottomAction(),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildHudLoader() {
    return AnimatedPadding(
      duration: const Duration(milliseconds: 300),
      padding: EdgeInsets.only(bottom: _isGenerating ? 10 : 0),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        height: _isGenerating ? 40 : 0,
        curve: Curves.easeInOut,
        child: _isGenerating
            ? Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
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
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Colors.blue,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        'Generating more cards...',
                        style: TextStyle(
                          color: Colors.blue[700],
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              )
            : const SizedBox.shrink(),
      ),
    );
  }

  Widget _buildHeaderProgress() {
    double progress = (_currentPage + 1) / _currentCards.length;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      child: Row(
        children: [
          Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                width: 45,
                height: 45,
                child: CircularProgressIndicator(
                  value: progress,
                  strokeWidth: 4,
                  backgroundColor: Colors.grey[200],
                  valueColor: const AlwaysStoppedAnimation<Color>(Colors.blue),
                ),
              ),
              Text(
                '${_currentPage + 1}/${_currentCards.length}',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Flashcard ${_currentPage + 1} of ${_currentCards.length}',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
              Text(
                '${_currentPage} viewed • ${((_currentPage) / _currentCards.length * 100).toInt()}% complete',
                style: TextStyle(color: Colors.grey[600], fontSize: 12),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFlashcard(Map<String, dynamic> card) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 400),
      transitionBuilder: (Widget child, Animation<double> animation) {
        final rotate = Tween(begin: pi, end: 0.0).animate(animation);
        return AnimatedBuilder(
          animation: rotate,
          child: child,
          builder: (context, child) {
            final isBack = (ValueKey(_showAnswer) == child?.key);
            final value = isBack ? min(rotate.value, pi / 2) : rotate.value;
            return Transform(
              transform: Matrix4.rotationY(value),
              alignment: Alignment.center,
              child: child,
            );
          },
        );
      },
      child: _showAnswer ? _buildCardBack(card) : _buildCardFront(card),
    );
  }

  Widget _buildCardFront(Map<String, dynamic> card) {
    return Container(
      key: const ValueKey(false),
      margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.blue.withOpacity(0.2), width: 2),
        boxShadow: [
          BoxShadow(
            color: Colors.blue.withOpacity(0.05),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          const SizedBox(height: 30),
          _buildBadge('QUESTION', Colors.blue),
          Expanded(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 30),
                child: Text(
                  card['front'] ?? '',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    height: 1.4,
                  ),
                ),
              ),
            ),
          ),
          _buildRevealButton('Tap to reveal answer', Icons.front_hand, () {
            setState(() => _showAnswer = true);
          }),
          const SizedBox(height: 30),
        ],
      ),
    );
  }

  Widget _buildCardBack(Map<String, dynamic> card) {
    return Container(
      key: const ValueKey(true),
      margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.green.withOpacity(0.2), width: 2),
        boxShadow: [
          BoxShadow(
            color: Colors.green.withOpacity(0.05),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          const SizedBox(height: 30),
          _buildBadge('ANSWER', Colors.green),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 20),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    card['back'] ?? '',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      height: 1.5,
                    ),
                  ),
                  if (card['explanation'] != null) ...[
                    const SizedBox(height: 20),
                    const Text(
                      'Explanation:',
                      style: TextStyle(
                        color: Colors.grey,
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      card['explanation'],
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.grey[700],
                        fontSize: 14,
                        height: 1.4,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
          _buildRevealButton('Tap to see question', Icons.question_mark, () {
            setState(() => _showAnswer = false);
          }, color: Colors.green),
          const SizedBox(height: 30),
        ],
      ),
    );
  }

  Widget _buildBadge(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.bold,
          fontSize: 11,
          letterSpacing: 1,
        ),
      ),
    );
  }

  Widget _buildRevealButton(
    String text,
    IconData icon,
    VoidCallback onTap, {
    Color color = Colors.blue,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(15),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(15),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: color),
            const SizedBox(width: 8),
            Text(
              text,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.bold,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomAction() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: GestureDetector(
        onTap: () {
          setState(() {
            _isEndlessMode = !_isEndlessMode;
          });
          debugPrint('Endless Mode Toggled: $_isEndlessMode');
          if (_isEndlessMode) {
            debugPrint(
              'Endless Mode: Manual trigger. Current cards: ${_currentCards.length}',
            );
            _generateMoreCards();
          }
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          decoration: BoxDecoration(
            color: _isEndlessMode
                ? Colors.green.withOpacity(0.2)
                : Colors.grey[100],
            borderRadius: BorderRadius.circular(15),
            border: Border.all(
              color: _isEndlessMode
                  ? Colors.green.withOpacity(0.3)
                  : Colors.transparent,
              width: 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.refresh,
                size: 20,
                color: _isEndlessMode ? Colors.green[700] : Colors.black54,
              ),
              const SizedBox(width: 8),
              Text(
                'Endless Mode',
                style: TextStyle(
                  color: _isEndlessMode ? Colors.green[700] : Colors.black87,
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (_isEndlessMode) ...[
                const SizedBox(width: 8),
                Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: Colors.green,
                    shape: BoxShape.circle,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
