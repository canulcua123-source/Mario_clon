import 'package:flutter/material.dart';
import 'package:flame/game.dart';
import '../components/game.dart';
import 'game_end_screen.dart';
import 'shop_screen.dart';

class GameScreen extends StatefulWidget {
  final String playerName;
  final String levelId;

  const GameScreen({
    super.key,
    required this.playerName,
    required this.levelId,
  });

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  late final MyPhysicsGame _game;

  @override
  void initState() {
    super.initState();
    _game = MyPhysicsGame(
      playerName: widget.playerName,
      levelId: widget.levelId,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          GameWidget.controlled(
            gameFactory: () => _game,
            overlayBuilderMap: {
              'PauseMenu': (context, _) {
                return Container(
                  color: const Color.fromARGB(128, 0, 0, 0),
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        ElevatedButton(
                          onPressed: () {
                            _game.resumeEngine();
                            _game.overlays.remove('PauseMenu');
                          },
                          child: const Text('Continue'),
                        ),
                        const SizedBox(height: 20),
                        ElevatedButton(
                          onPressed: () {
                            _game.resumeEngine();
                            _game.overlays.remove('PauseMenu');
                            Navigator.of(context).pushReplacement(
                              MaterialPageRoute(
                                builder: (context) => GameScreen(
                                  playerName: widget.playerName,
                                  levelId: widget.levelId,
                                ),
                              ),
                            );
                          },
                          child: const Text('Restart'),
                        ),
                        const SizedBox(height: 20),
                        ElevatedButton(
                          onPressed: () {
                            _game.overlays.remove('PauseMenu');
                            Navigator.of(context).pop();
                          },
                          child: const Text('Main Menu'),
                        ),
                      ],
                    ),
                  ),
                );
              },
              'GameEnd': (context, _) {
                if (!_game.isGameOver) {
                  return const SizedBox.shrink();
                }
                return GameEndScreen(
                  message: _game.gameOverMessage,
                  isNewRecord: _game.isNewRecord,
                  score: _game.finalScore,
                  playerName: _game.playerName,
                  levelId: _game.levelId,
                  onClose: () {
                    _game.resumeEngine();
                    _game.overlays.remove('GameEnd');
                    Navigator.of(context).pop();
                  },
                );
              },
              'ShopMenu': (context, _) {
                return ShopScreen(game: _game);
              },
            },
          ),
          Positioned(
            top: 10,
            right: 10,
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.refresh, color: Colors.white),
                  onPressed: () {
                    Navigator.of(context).pushReplacement(
                      MaterialPageRoute(
                        builder: (context) => GameScreen(
                          playerName: widget.playerName,
                          levelId: widget.levelId,
                        ),
                      ),
                    );
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.shopping_cart, color: Colors.white),
                  onPressed: () {
                    _game.pauseEngine();
                    _game.overlays.add('ShopMenu');
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.home, color: Colors.white),
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
