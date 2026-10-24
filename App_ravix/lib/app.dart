import 'package:flutter/material.dart';

/// Raiz do app. Shell, rotas e tema entram no M3.
class RavixApp extends StatelessWidget {
  /// Cria a raiz do app.
  const new({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      title: 'Ravix',
      home: Scaffold(
        body: Center(child: Text('Ravix')),
      ),
    );
  }
}
