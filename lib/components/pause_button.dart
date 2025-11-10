import 'package:flame/components.dart';
import 'package:flame/input.dart';
import 'package:flutter/material.dart';

class PauseButton extends PositionComponent with HasGameReference {
  PauseButton({super.position, super.size});

  @override
  Future<void> onLoad() async {
    await add(
      ButtonComponent(
        button: CircleComponent(
          radius: 30,
          paint: Paint()..color = Colors.white,
        ),
        onPressed: () {
          game.pauseEngine();
          game.overlays.add('PauseMenu');
        },
      ),
    );
  }
}
