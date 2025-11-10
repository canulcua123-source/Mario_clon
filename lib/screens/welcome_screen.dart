import 'package:flutter/material.dart';
import 'leaderboard_screen.dart';
import '../progress_manager.dart';
import 'tutorial_screen.dart';

class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> {
  final _nameController = TextEditingController();
  bool _wantsTutorial = false;
  final _formKey = GlobalKey<FormState>();

  void _startGame() async {
    if (_formKey.currentState!.validate()) {
      final levelId = await ProgressManager.getHighestUnlockedLevel();
      if (!mounted) return;

      if (_wantsTutorial) {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => TutorialScreen(
              playerName: _nameController.text,
              levelId: levelId,
            ),
          ),
        );
      } else {
        Navigator.pushNamed(context, '/game', arguments: {
          'playerName': _nameController.text,
          'levelId': levelId,
        });
      }
    }
  }

  void _showLeaderboard() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const LeaderboardScreen(),
      ),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.lightBlue.shade200,
      body: Center(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Card(
              elevation: 8,
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        'Welcome to Flutter Mario!',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 24),
                      TextFormField(
                        controller: _nameController,
                        decoration: const InputDecoration(
                          labelText: 'Enter Your Name',
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Please enter your name';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      SwitchListTile(
                        title: const Text('Show Interactive Tutorial?'),
                        value: _wantsTutorial,
                        onChanged: (value) {
                          setState(() {
                            _wantsTutorial = value;
                          });
                        },
                      ),
                      const SizedBox(height: 24),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          ElevatedButton(
                            onPressed: _startGame,
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 40, vertical: 16),
                            ),
                            child: const Text('Start Game'),
                          ),
                          const SizedBox(width: 16),
                          IconButton(
                            icon: const Icon(Icons.leaderboard),
                            onPressed: _showLeaderboard,
                            tooltip: 'High Scores',
                            iconSize: 32,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
