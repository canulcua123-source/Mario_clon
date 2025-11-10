import 'dart:async';
import 'dart:math';

import 'package:flame/components.dart';
import 'package:flame_forge2d/flame_forge2d.dart';
import 'package:flame_kenney_xml/flame_kenney_xml.dart';
import 'package:flame_audio/flame_audio.dart';
import 'package:flutter/material.dart';

import '../supabase_client.dart';
import 'background.dart';
import 'brick.dart';
import 'enemy.dart';
import 'ground.dart';
import 'pause_button.dart';
import 'player.dart';
import 'power_ups.dart';

class MyPhysicsGame extends Forge2DGame with WidgetsBindingObserver {
  MyPhysicsGame({
    required this.playerName,
    required this.levelId,
  }) : super(
          gravity: Vector2(0, 10),
          camera: CameraComponent.withFixedResolution(width: 800, height: 600),
        );

  final String playerName;
  final String levelId;
  final List<PowerUpType> activePowerUps = [];
  int shots = 6;

  final PlayerColor _playerColor = PlayerColor.pink;

  late final XmlSpriteSheet aliens;
  late final XmlSpriteSheet elements;
  late final XmlSpriteSheet tiles;
  late final TimerComponent timer;
  bool isGameOver = false;
  var enemiesFullyAdded = false;

  // New state variables for game end
  bool isNewRecord = false;
  int? finalScore;
  String gameOverMessage = '';

  final _random = Random();

  static final Map<String, List<({EnemyColor color, bool isBoss})>>
      _levelEnemyConfigurations = {
    '1-1': [
      (color: EnemyColor.pink, isBoss: false),
      (color: EnemyColor.pink, isBoss: false),
      (color: EnemyColor.pink, isBoss: false),
    ],
    '1-2': [
      (color: EnemyColor.pink, isBoss: false),
      (color: EnemyColor.pink, isBoss: false),
      (color: EnemyColor.pink, isBoss: false),
      (color: EnemyColor.pink, isBoss: false),
    ],
    '1-3': [
      (color: EnemyColor.pink, isBoss: false),
      (color: EnemyColor.pink, isBoss: false),
      (color: EnemyColor.pink, isBoss: false),
      (color: EnemyColor.pinkBoss, isBoss: true),
    ],
    '1-4': [
      (color: EnemyColor.pink, isBoss: false),
      (color: EnemyColor.pink, isBoss: false),
      (color: EnemyColor.pinkBoss, isBoss: true),
      (color: EnemyColor.blue, isBoss: false),
    ],
    '1-5': [
      (color: EnemyColor.pinkBoss, isBoss: true),
      (color: EnemyColor.blue, isBoss: false),
      (color: EnemyColor.blue, isBoss: false),
      (color: EnemyColor.blueBoss, isBoss: true),
    ],
    '2-1': [
      (color: EnemyColor.blueBoss, isBoss: true),
      (color: EnemyColor.blueBoss, isBoss: true),
      (color: EnemyColor.green, isBoss: false),
    ],
    '2-2': [
      (color: EnemyColor.blueBoss, isBoss: true),
      (color: EnemyColor.blueBoss, isBoss: true),
      (color: EnemyColor.green, isBoss: false),
      (color: EnemyColor.green, isBoss: false),
    ],
    '2-3': [
      (color: EnemyColor.blueBoss, isBoss: true),
      (color: EnemyColor.green, isBoss: false),
      (color: EnemyColor.green, isBoss: false),
      (color: EnemyColor.greenBoss, isBoss: true),
    ],
    '2-4': [
      (color: EnemyColor.green, isBoss: false),
      (color: EnemyColor.green, isBoss: false),
      (color: EnemyColor.greenBoss, isBoss: true),
      (color: EnemyColor.greenBoss, isBoss: true),
    ],
    '2-5': [
      (color: EnemyColor.greenBoss, isBoss: true),
      (color: EnemyColor.greenBoss, isBoss: true),
      (color: EnemyColor.yellow, isBoss: false),
      (color: EnemyColor.yellow, isBoss: false),
    ],
    '3-1': [
      (color: EnemyColor.greenBoss, isBoss: true),
      (color: EnemyColor.yellow, isBoss: false),
      (color: EnemyColor.yellow, isBoss: false),
      (color: EnemyColor.yellow, isBoss: false),
    ],
    '3-2': [
      (color: EnemyColor.yellow, isBoss: false),
      (color: EnemyColor.yellow, isBoss: false),
      (color: EnemyColor.yellow, isBoss: false),
      (color: EnemyColor.beige, isBoss: false),
    ],
    '3-3': [
      (color: EnemyColor.yellow, isBoss: false),
      (color: EnemyColor.yellow, isBoss: false),
      (color: EnemyColor.beige, isBoss: false),
      (color: EnemyColor.beige, isBoss: false),
    ],
    '3-4': [
      (color: EnemyColor.yellow, isBoss: false),
      (color: EnemyColor.beige, isBoss: false),
      (color: EnemyColor.beige, isBoss: false),
      (color: EnemyColor.beigeBoss, isBoss: true),
    ],
    '3-5': [
      (color: EnemyColor.beige, isBoss: false),
      (color: EnemyColor.beige, isBoss: false),
      (color: EnemyColor.beigeBoss, isBoss: true),
      (color: EnemyColor.beigeBoss, isBoss: true),
    ],
  };

  void applyPowerUp(PowerUpType powerUp) {
    activePowerUps.add(powerUp);
    switch (powerUp) {
      case PowerUpType.extraTime:
        timer.timer.limit += 30;
        break;
      case PowerUpType.eliminateBlocks:
        world.children
            .whereType<Brick>()
            .forEach((brick) => brick.removeFromParent());
        break;
      case PowerUpType.duplicateBall:
        // Will be handled in collision logic
        break;
    }
  }

  @override
  FutureOr<void> onLoad() async {
    WidgetsBinding.instance.addObserver(this);

    final level = int.parse(levelId.split('-')[0]);
    final backgroundPath = switch (level) {
      1 => 'colored_grass.png',
      2 => 'colored_desert.png',
      3 => 'colored_shroom.png',
      _ => 'colored_grass.png',
    };
    final backgroundImage = await images.load(backgroundPath);
    final spriteSheets = await Future.wait([
      XmlSpriteSheet.load(
        imagePath: 'spritesheet_aliens.png',
        xmlPath: 'spritesheet_aliens.xml',
      ),
      XmlSpriteSheet.load(
        imagePath: 'spritesheet_elements.png',
        xmlPath: 'spritesheet_elements.xml',
      ),
      XmlSpriteSheet.load(
        imagePath: 'spritesheet_tiles.png',
        xmlPath: 'spritesheet_tiles.xml',
      ),
    ]);

    aliens = spriteSheets[0];
    elements = spriteSheets[1];
    tiles = spriteSheets[2];

    await world.add(Background(sprite: Sprite(backgroundImage)));
    await addGround();
    unawaited(addBricks().then((_) => addEnemies()));
    await addPlayer();

    final pauseButton = PauseButton(
      position: Vector2(camera.viewport.size.x - 50, 50),
      size: Vector2.all(60),
    );
    await camera.viewport.add(pauseButton);

    timer = TimerComponent(
        period: 60,
        onTick: () {
          if (world.children.whereType<Enemy>().isNotEmpty && !isGameOver) {
            endGame(won: false);
          }
        });
    add(timer);

    final timerText = TextComponent(
      text: 'Time: 60',
      position: Vector2(10, 10),
      textRenderer: TextPaint(
        style: const TextStyle(color: Colors.white, fontSize: 24),
      ),
    );
    await camera.viewport.add(timerText);

    add(TimerComponent(
        period: 1,
        repeat: true,
        onTick: () {
          if (isGameOver) return;
          final remaining = timer.timer.limit - timer.timer.current.floor();
          timerText.text = 'Time: $remaining';
          if (remaining < 10) {
            FlameAudio.bgm.audioPlayer.setPlaybackRate(1.5);
          }
        }));

    final shotsText = TextComponent(
      text: 'Shots: $shots',
      position: Vector2(10, 40),
      textRenderer: TextPaint(
        style: const TextStyle(color: Colors.white, fontSize: 24),
      ),
    );
    await camera.viewport.add(shotsText);

    FlameAudio.bgm.play('background_music.mp3');

    return super.onLoad();
  }

  @override
  void onRemove() {
    WidgetsBinding.instance.removeObserver(this);
    FlameAudio.bgm.stop();
    super.onRemove();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (state == AppLifecycleState.paused) {
      if (isGameOver) return;
      FlameAudio.bgm.stop();
      pauseEngine();
      overlays.add('PauseMenu');
    }
  }

  Future<void> addGround() {
    final worldRect = camera.visibleWorldRect;
    return world.addAll([
      // Ground
      for (var x = worldRect.left;
          x < worldRect.right + groundSize;
          x += groundSize)
        Ground(
          Vector2(x, (worldRect.height - groundSize) / 2),
          tiles.getSprite('grass.png'),
        ),
      // Left wall
      for (var y = worldRect.top; y < worldRect.bottom; y += groundSize)
        Ground(
          Vector2(worldRect.left - groundSize / 2, y),
          tiles.getSprite('grass.png'),
        ),
      // Right wall
      for (var y = worldRect.top; y < worldRect.bottom; y += groundSize)
        Ground(
          Vector2(worldRect.right + groundSize / 2, y),
          tiles.getSprite('grass.png'),
        ),
      // Top wall
      for (var x = worldRect.left;
          x < worldRect.right + groundSize;
          x += groundSize)
        Ground(
          Vector2(x, worldRect.top - groundSize / 2),
          tiles.getSprite('grass.png'),
        ),
    ]);
  }

  Future<void> addBricks() async {
    for (var i = 0; i < 5; i++) {
      final type = BrickType.randomType;
      final size = BrickSize.randomSize;
      await world.add(
        Brick(
          type: type,
          size: size,
          damage: BrickDamage.some,
          position: Vector2(
            camera.visibleWorldRect.right / 3 +
                (_random.nextDouble() * 5 - 2.5),
            0,
          ),
          sprites: brickFileNames(
            type,
            size,
          ).map((key, filename) => MapEntry(key, elements.getSprite(filename))),
        ),
      );
      await Future<void>.delayed(const Duration(milliseconds: 500));
    }
  }

  Future<void> addPlayer() async {
    await world.add(
      Player(
        Vector2(camera.visibleWorldRect.left * 2 / 3, 0),
        aliens.getSprite(_playerColor.fileName),
        color: _playerColor,
      ),
    );
  }

  Future<void> addEnemies() async {
    await Future<void>.delayed(const Duration(seconds: 2));
    final enemiesToSpawn = _levelEnemyConfigurations[levelId] ?? [];

    var i = 0;
    for (final enemyConfig in enemiesToSpawn) {
      await world.add(
        Enemy(
          Vector2(
            camera.visibleWorldRect.right / 3 +
                (_random.nextDouble() * 7 - 3.5),
            (_random.nextDouble() * 3) +
                (i * enemySize * 1.2), // Adjust position to avoid overlap
          ),
          aliens.getSprite(enemyConfig.color.fileName),
          health: enemyConfig.color.health,
          boss: enemyConfig.isBoss,
        ),
      );
      await Future<void>.delayed(const Duration(seconds: 1));
      i++;
    }
    enemiesFullyAdded = true;
  }

  Future<void> endGame({required bool won}) async {
    if (isGameOver) return;
    isGameOver = true;
    FlameAudio.bgm.stop();

    if (won) {
      finalScore = timer.timer.current.floor();
      final bestScore = await SupabaseManager().getBestScore(levelId);

      if (bestScore == null || finalScore! < bestScore) {
        isNewRecord = true;
        gameOverMessage = '¡Felicidades, acabas de hacer un nuevo récord!';
        FlameAudio.play('win.wav');
      } else {
        isNewRecord = false;
        gameOverMessage = '¡Nivel completado!';
        FlameAudio.play('win.wav');
      }
    } else {
      isNewRecord = false;
      gameOverMessage = 'Game Over, juego perdido';
      FlameAudio.play('lose.wav');
    }

    overlays.add('GameEnd');
    pauseEngine();
  }

  @override
  void update(double dt) {
    super.update(dt);

    if (isGameOver) {
      return;
    }

    final shotsText = camera.viewport.children
        .whereType<TextComponent>()
        .firstWhere((c) => c.text.startsWith('Shots'));
    shotsText.text = 'Shots: $shots';

    if (isMounted &&
        world.children
            .whereType<Player>()
            .where((p) => p.body.bodyType == BodyType.static)
            .isEmpty &&
        world.children.whereType<Enemy>().isNotEmpty &&
        shots > 0) {
      addPlayer();
    }
    if (shots == 0 && world.children.whereType<Player>().isEmpty) {
      endGame(won: false);
    }

    if (isMounted &&
        enemiesFullyAdded &&
        world.children.whereType<Enemy>().isEmpty) {
      endGame(won: true);
    }
  }
}


