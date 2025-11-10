// Copyright 2024 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:math';

import 'package:flame/components.dart';
import 'package:flame/effects.dart';
import 'package:flame/events.dart';
import 'package:flame_forge2d/flame_forge2d.dart';
import 'package:flame_audio/flame_audio.dart';
import 'package:flutter/material.dart';

import 'body_component_with_user_data.dart';
import 'game.dart';
import 'power_ups.dart';

const playerSize = 5.0;

enum PlayerColor {
  pink(Colors.pink, damage: 1),
  blue(Colors.blue, damage: 2),
  green(Colors.green, damage: 3),
  yellow(Colors.yellow, damage: 4),
  beige(
    Colors.red,
    damage: 5,
  ); // Using Colors.red for beige as per user's instruction "El botón de rojo, ahora será de color Beige"

  const PlayerColor(this.color, {required this.damage});

  final Color color;
  final int damage;

  static PlayerColor get randomColor =>
      PlayerColor.values[Random().nextInt(PlayerColor.values.length)];

  String get fileName {
    return 'alien${toString().split('.').last.capitalize}_round.png';
  }
}

class Player extends BodyComponentWithUserData
    with DragCallbacks, ContactCallbacks {
  Player(Vector2 position, this._sprite, {this.color = PlayerColor.pink})
    : super(
        renderBody: false,
        bodyDef: BodyDef()
          ..position = position
          ..type = BodyType.static
          ..angularDamping = 0.1
          ..linearDamping = 0.1,
        fixtureDefs: [
          FixtureDef(CircleShape()..radius = playerSize / 2)
            ..restitution = 0.4
            ..density = 0.75
            ..friction = 0.5,
        ],
      );

  final Sprite _sprite;
  final PlayerColor color;
  late final MyPhysicsGame myGame;

  Vector2 _dragStart = Vector2.zero();
  Vector2 _dragDelta = Vector2.zero();
  @override
  Future<void> onLoad() async {
    myGame = findGame()! as MyPhysicsGame;
    print('Player onLoad: sprite filename = ${_sprite.src}');
    await addAll([
      CustomPainterComponent(
        painter: _DragPainter(this),
        anchor: Anchor.center,
        size: Vector2(playerSize, playerSize),
        position: Vector2(0, 0),
      ),
      SpriteComponent(
        anchor: Anchor.center,
        sprite: _sprite,
        size: Vector2(playerSize, playerSize),
        position: Vector2(0, 0),
      ),
    ]);
    await super.onLoad();
  }

  Vector2 get dragDelta => _dragDelta;

  @override
  void onDragStart(DragStartEvent event) {
    super.onDragStart(event);
    if (body.bodyType == BodyType.static && myGame.shots > 0) {
      _dragStart = event.localPosition;
    }
  }

  @override
  void onDragUpdate(DragUpdateEvent event) {
    if (body.bodyType == BodyType.static && myGame.shots > 0) {
      _dragDelta = event.localEndPosition - _dragStart;
    }
  }

  @override
  void onDragEnd(DragEndEvent event) {
    super.onDragEnd(event);
    if (body.bodyType == BodyType.static && myGame.shots > 0) {
      FlameAudio.play('shot.wav');
      myGame.shots--;
      children
          .whereType<CustomPainterComponent>()
          .firstOrNull
          ?.removeFromParent();
      body.setType(BodyType.dynamic);
      var impulse = _dragDelta * -50.0;
            body.applyLinearImpulse(impulse);
            add(RemoveEffect(delay: 5.0));
          }
        }

  @override
  void beginContact(Object other, Contact contact) {
    super.beginContact(other, contact);
    if (myGame.activePowerUps.contains(PowerUpType.duplicateBall)) {
      myGame.activePowerUps.remove(PowerUpType.duplicateBall);
      myGame.shots++;

      final newPlayer = Player(body.position.clone(), _sprite, color: color);
      myGame.world.add(newPlayer);
      newPlayer.mounted.then((_) {
        newPlayer.body.setType(BodyType.dynamic);
        newPlayer.body.linearVelocity = body.linearVelocity * -1;
        newPlayer.add(RemoveEffect(delay: 5.0)); // Add RemoveEffect to the duplicated ball
      });
    }
  }
}

extension on String {
  String get capitalize =>
      characters.first.toUpperCase() + characters.skip(1).toLowerCase().join();
}

class _DragPainter extends CustomPainter {
  _DragPainter(this.player);

  final Player player;

  @override
  void paint(Canvas canvas, Size size) {
    if (player.dragDelta != Vector2.zero()) {
      var center = size.center(Offset.zero);
      canvas.drawLine(
        center,
        center + (player.dragDelta * -1).toOffset(),
        Paint()
          ..color = Colors.orange.withAlpha(180)
          ..strokeWidth = 0.4
          ..strokeCap = StrokeCap.round,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
