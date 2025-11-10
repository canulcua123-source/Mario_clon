import 'package:flutter/material.dart';
import '../components/game.dart';
import '../components/power_ups.dart';

class ShopScreen extends StatelessWidget {
  final MyPhysicsGame game;

  const ShopScreen({super.key, required this.game});

  void _showPaymentDialog(BuildContext context, PowerUpType powerUp) {
    final formKey = GlobalKey<FormState>();
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Buy ${powerUp.name}'),
          content: SingleChildScrollView(
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    decoration: const InputDecoration(labelText: 'Card Number'),
                    keyboardType: TextInputType.number,
                    validator: (value) {
                      if (value == null || value.length != 16) {
                        return 'Enter a 16-digit card number';
                      }
                      return null;
                    },
                  ),
                  TextFormField(
                    decoration: const InputDecoration(labelText: 'MM/YY'),
                    validator: (value) {
                      if (value == null ||
                          !RegExp(r'^\d{2}\/\d{2}$').hasMatch(value)) {
                        return 'Enter a valid date';
                      }
                      return null;
                    },
                  ),
                  TextFormField(
                    decoration: const InputDecoration(labelText: 'CVC'),
                    keyboardType: TextInputType.number,
                    validator: (value) {
                      if (value == null || value.length != 3) {
                        return 'Enter a 3-digit CVC';
                      }
                      return null;
                    },
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                if (formKey.currentState!.validate()) {
                  // Payment successful
                  game.applyPowerUp(powerUp);
                  Navigator.of(context).pop(); // Close dialog
                  game.overlays.remove('ShopMenu');
                  game.resumeEngine();
                }
              },
              child: const Text('Pay \$0.99'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Card(
        color: Colors.black.withAlpha(220),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Power-Up Shop',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 20),
              SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: PowerUpType.values.map((powerUp) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8.0),
                      child: Row(
                        children: [
                          const Icon(Icons.flash_on, color: Colors.yellow),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(powerUp.name,
                                    style:
                                        const TextStyle(color: Colors.white)),
                                Text('A temporary boost!',
                                    style: TextStyle(
                                        color: Colors.grey.shade400)),
                              ],
                            ),
                          ),
                          const SizedBox(width: 16),
                          ElevatedButton(
                            onPressed: () => _showPaymentDialog(context, powerUp),
                            child: const Text('Buy'),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () {
                  game.overlays.remove('ShopMenu');
                  game.resumeEngine();
                },
                child: const Text('Close'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
