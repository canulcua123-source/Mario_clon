import 'package:flutter/material.dart';
import '../progress_manager.dart';
import '../supabase_client.dart';

class GameEndScreen extends StatefulWidget {
  const GameEndScreen({
    super.key,
    required this.message,
    required this.isNewRecord,
    this.score,
    this.playerName,
    required this.levelId,
    required this.onClose,
  });

  final String message;
  final bool isNewRecord;
  final int? score;
  final String? playerName;
  final String levelId;
  final VoidCallback onClose;

  @override
  State<GameEndScreen> createState() => _GameEndScreenState();
}

class _GameEndScreenState extends State<GameEndScreen> {
  late final TextEditingController _nameController;
  bool _isSubmitting = false;
  bool _isSubmitted = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.playerName);
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  String _calculateNextLevelId(String currentLevelId) {
    final parts = currentLevelId.split('-');
    int world = int.parse(parts[0]);
    int level = int.parse(parts[1]);

    if (level < 5) {
      level++;
    } else {
      world++;
      level = 1;
    }
    // Assuming max world is 3 for now, loop back to start
    if (world > 3) {
      return '1-1';
    }
    return '$world-$level';
  }

  void _goToNextLevel() async {
    final nextLevelId = _calculateNextLevelId(widget.levelId);
    await ProgressManager.saveHighestUnlockedLevel(nextLevelId);
    if (!mounted) return;

    Navigator.of(context).pushReplacementNamed('/game', arguments: {
      'playerName': widget.playerName ?? 'Player',
      'levelId': nextLevelId,
    });
  }

  Future<void> _submitScore() async {
    if (_nameController.text.isEmpty || widget.score == null) return;

    setState(() {
      _isSubmitting = true;
    });

    try {
      await SupabaseManager().submitScore(
        playerName: _nameController.text,
        score: widget.score!,
        levelId: widget.levelId,
      );
      if (mounted) {
        setState(() {
          _isSubmitted = true;
        });
      }
    } catch (e) {
      // Optionally show an error message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to submit score.')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final titleColor =
        widget.isNewRecord ? Colors.orangeAccent : Colors.white;
    final didWin = widget.score != null;

    return Center(
      child: Card(
        color: Colors.black.withAlpha((255 * 0.8).round()),
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  widget.message,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: titleColor),
                ),
                const SizedBox(height: 24),
                if (widget.isNewRecord) ...[
                  if (_isSubmitted)
                    const Text('Score Submitted!',
                        style: TextStyle(color: Colors.green, fontSize: 16))
                  else ...[
                    SizedBox(
                      width: 200,
                      child: TextField(
                        controller: _nameController,
                        decoration: const InputDecoration(
                          labelText: 'Your Name',
                          labelStyle: TextStyle(color: Colors.white),
                          enabledBorder: OutlineInputBorder(
                            borderSide: BorderSide(color: Colors.white),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderSide: BorderSide(color: Colors.orangeAccent),
                          ),
                        ),
                        style: const TextStyle(color: Colors.white),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    const SizedBox(height: 16),
                    if (_isSubmitting)
                      const CircularProgressIndicator()
                    else
                      ElevatedButton(
                        onPressed: _submitScore,
                        child: const Text('Submit Score'),
                      ),
                  ],
                  const SizedBox(height: 24),
                ],
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      ElevatedButton(
                        onPressed: widget.onClose,
                        child: const Text('Main Menu'),
                      ),
                      if (didWin) ...[
                        const SizedBox(width: 16),
                        ElevatedButton(
                          onPressed: _goToNextLevel,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                          ),
                          child: const Text('Next Level'),
                        ),
                      ]
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
