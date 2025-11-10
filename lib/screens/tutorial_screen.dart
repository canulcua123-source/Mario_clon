import 'package:flutter/material.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';

class TutorialScreen extends StatefulWidget {
  final String playerName;
  final String levelId;

  const TutorialScreen({
    super.key,
    required this.playerName,
    required this.levelId,
  });

  @override
  State<TutorialScreen> createState() => _TutorialScreenState();
}

class _TutorialScreenState extends State<TutorialScreen> {
  late final YoutubePlayerController _controller;

  @override
  void initState() {
    super.initState();
    // A video explaining the physics of Angry Birds, as a placeholder.
    const videoId = 'bNn1J2B4Z_w';
    _controller = YoutubePlayerController(
      initialVideoId: videoId,
      flags: const YoutubePlayerFlags(
        autoPlay: true,
        mute: false,
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _startGame() {
    Navigator.of(context).pushReplacementNamed('/game', arguments: {
      'playerName': widget.playerName,
      'levelId': widget.levelId,
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Game Tutorial'),
        backgroundColor: Colors.black,
      ),
      body: Column(
        children: [
          YoutubePlayer(
            controller: _controller,
            showVideoProgressIndicator: true,
            progressIndicatorColor: Colors.amber,
          ),
          const SizedBox(height: 20),
          const Padding(
            padding: EdgeInsets.all(16.0),
            child: Text(
              'Watch this video to learn the basics of the game physics, then press "Start Game" to begin!',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 18),
            ),
          ),
          const Spacer(),
          Padding(
            padding: const EdgeInsets.only(bottom: 40.0),
            child: ElevatedButton(
              onPressed: _startGame,
              style: ElevatedButton.styleFrom(
                padding:
                    const EdgeInsets.symmetric(horizontal: 50, vertical: 20),
              ),
              child: const Text('Start Game'),
            ),
          ),
        ],
      ),
    );
  }
}
