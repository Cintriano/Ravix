import 'package:flutter/material.dart';
import 'package:ravix/features/shell/estados_tela.dart';

/// Configuração (E01-F07). Na v1 terá só a aba Tags, que entra no M4.
class TelaConfiguracao extends StatelessWidget {
  /// Cria a tela.
  const new({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Configuração')),
      body: const EstadoVazio(
        titulo: 'Configuração em construção',
        mensagem: 'A gestão de tags chega na próxima etapa.',
      ),
    );
  }
}
