import 'package:flutter/material.dart';
import 'package:ravix/features/shell/estados_tela.dart';

/// Formulário de registro (E01-F03). O formulário entra no M5; por ora a
/// rota existe para o botão flutuante do shell.
class TelaRegistro extends StatelessWidget {
  /// Cria a tela.
  const new({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Novo gasto')),
      body: const EstadoVazio(
        titulo: 'Formulário em construção',
        mensagem: 'O cadastro de gastos chega na próxima etapa.',
      ),
    );
  }
}
