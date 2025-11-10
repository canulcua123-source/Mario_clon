// Copyright 2024 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flame/components.dart';
import 'package:flame_audio/flame_audio.dart';
import 'package:flame_forge2d/flame_forge2d.dart';
import 'package:flutter/material.dart';
import 'package:vibration/vibration.dart';

import 'body_component_with_user_data.dart';
import 'player.dart'; // Added import

const enemySize = 5.0;

enum EnemyColor {
  pink(color: 'pink', boss: false, health: 1),
  blue(color: 'blue', boss: false, health: 2),
  green(color: 'green', boss: false, health: 3),
  yellow(color: 'yellow', boss: false, health: 4),
  beige(color: 'beige', boss: false, health: 5),
  pinkBoss(color: 'pink', boss: true, health: 5),
  blueBoss(color: 'blue', boss: true, health: 10),
  greenBoss(color: 'green', boss: true, health: 15),
  yellowBoss(color: 'yellow', boss: true, health: 20),
  beigeBoss(color: 'beige', boss: true, health: 25);

  final bool boss;
  final String color;
  final int health;

  const EnemyColor({
    required this.color,
    required this.boss,
    required this.health,
  });

  String get fileName =>
      'alien${color.capitalize}_${boss ? 'suit' : 'square'}.png';
}

class Enemy extends BodyComponentWithUserData with ContactCallbacks {
  Enemy(Vector2 position, this.sprite, {this.health = 1, this.boss = false})
    : super(
        renderBody: false,
        bodyDef: BodyDef()
          ..position = position
          ..type = BodyType.dynamic,
        fixtureDefs: [
          FixtureDef(
            PolygonShape()..setAsBoxXY(enemySize / 2, enemySize / 2),
            friction: 0.3,
          ),
        ],
        children: [
          SpriteComponent(
            anchor: Anchor.center,
            sprite: sprite,
            size: Vector2.all(enemySize),
            position: Vector2(0, 0),
          ),
        ],
      );

  final Sprite sprite;
  int health;
  final bool boss;

  @override
  void beginContact(Object other, Contact contact) {
    if (other is Player) {
      health -= other.color.damage;
    } else {
      var interceptVelocity =
          (contact.bodyA.linearVelocity - contact.bodyB.linearVelocity).length
              .abs();
      if (interceptVelocity > 35) {
        health--;
      }
    }

    if (health <= 0) {
      Vibration.vibrate(duration: 100);
      if (boss) {
        FlameAudio.play('boss_defeated.wav');
      } else {
        FlameAudio.play('block.wav');
      }
      removeFromParent();
    }

    super.beginContact(other, contact);
  }

  @override
  void update(double dt) {
    super.update(dt);

    if (position.x > camera.visibleWorldRect.right + 10 ||
        position.x < camera.visibleWorldRect.left - 10) {
      removeFromParent();
    }
  }
}

extension on String {
  String get capitalize =>
      characters.first.toUpperCase() + characters.skip(1).toLowerCase().join();
}
