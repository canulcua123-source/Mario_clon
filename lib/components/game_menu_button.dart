import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flutter/material.dart';

class GameMenuButton extends TextComponent with TapCallbacks {
  GameMenuButton({
    required String text,
    required this.onPressed,
    super.position,
  }) : super(
          text: text,
          anchor: Anchor.center,
          textRenderer: TextPaint(
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
        );

  final VoidCallback onPressed;

  @override
  void onTapDown(TapDownEvent event) {
    onPressed();
  }
}
