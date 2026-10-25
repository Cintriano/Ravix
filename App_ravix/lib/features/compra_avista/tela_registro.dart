import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ravix/data/banco.dart';
import 'package:ravix/features/compra_avista/formulario_compra.dart';
import 'package:ravix/features/compra_avista/formulario_providers.dart';
import 'package:ravix/features/shell/estados_tela.dart';

/// Rota do formulário (E01-F03). Sem [uuid], cria um gasto; com [uuid],
/// carrega e edita.
class TelaRegistro extends ConsumerWidget {
  /// Cria a tela.
  const new({this.uuid, super.key});

  /// Gasto a editar.
  final String? uuid;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final uuid = this.uuid;
    if (uuid == null) return const FormularioCompra();
    final valor = ref.watch(compraParaEditarProvider(uuid));
    if (valor case AsyncData(value: final compra?)) {
      return FormularioCompra(compra: compra);
    }
    return Scaffold(
      appBar: AppBar(title: const Text('Editar gasto')),
      body: ConteudoAssincrono<CompraAvista?>(
        valor: valor,
        aoTentarDeNovo: () => ref.invalidate(compraParaEditarProvider(uuid)),
        // Só chega aqui com dados quando o gasto não existe.
        conteudo: (_) => const EstadoErro(
          titulo: 'Gasto não encontrado',
          mensagem: 'Ele pode ter sido excluído.',
        ),
      ),
    );
  }
}
