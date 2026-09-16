import 'package:flutter/material.dart';

class EmptyState extends StatelessWidget {
  final VoidCallback onAdd;
  const EmptyState({super.key, required this.onAdd});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.shield_outlined, size: 68),
            const SizedBox(height: 18),
            Text('No accounts yet', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            const Text('Add your first TOTP account by scanning a QR code or entering a setup key.'),
            const SizedBox(height: 20),
            FilledButton.icon(onPressed: onAdd, icon: const Icon(Icons.add), label: const Text('Add account')),
          ],
        ),
      ),
    );
  }
}
