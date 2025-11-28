import 'package:flutter/material.dart';

/// Minimal UI demo placeholder page used for debug-only route.
class UiDemoPage extends StatelessWidget {
  const UiDemoPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('UI Demo'),
      ),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: const [
            Icon(Icons.palette, size: 64),
            SizedBox(height: 16),
            Text('UI Demo - placeholder page'),
          ],
        ),
      ),
    );
  }
}