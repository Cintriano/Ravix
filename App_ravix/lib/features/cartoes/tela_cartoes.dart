import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:ravix/app/dependencias.dart';
import 'package:ravix/core/tema/icones.dart';
import 'package:ravix/core/tema/tema.dart';
import 'package:ravix/core/tema/tokens.dart';
import 'package:ravix/core/valor.dart';
import 'package:ravix/data/banco.dart';
import 'package:ravix/data/cartao_repository.dart';
import 'package:ravix/features/cartoes/cartoes_providers.dart';
import 'package:ravix/features/shell/estados_tela.dart';

/// Nome do cartão com o final, se houver: "Itaú •••• 9827".
String nomeComFinal(CartaoCredito cartao) => cartao.finalCartao == null
    ? cartao.nomeCartao
    : '${cartao.nomeCartao} •••• ${cartao.finalCartao}';

/// Resumo do cartão: "Limite R$ 5.900,00 · fecha dia 29 · vence dia 5".
String resumoDoCartao(CartaoCredito cartao) => [
  'Limite ${formatarCentavos(cartao.limiteCartao)}',
  if (cartao.diaFechamento != null) 'fecha dia ${cartao.diaFechamento}',
  if (cartao.diaVencimento != null) 'vence dia ${cartao.diaVencimento}',
].join(' · ');

/// Configuração > Cartões (E01-F07-T03, T08): lista os cartões ativos.
/// Tocar abre a edição; o botão da linha remove (ou arquiva, se o cartão
/// já tem registros).
class TelaCartoes extends ConsumerWidget {
  /// Cria a tela.
  const new({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(title: const Text('Cartões')),
      body: ConteudoAssincrono<List<CartaoCredito>>(
        valor: ref.watch(cartoesAtivosProvider),
        estaVazio: (cartoes) => cartoes.isEmpty,
        aoTentarDeNovo: () => ref.invalidate(cartoesAtivosProvider),
        vazio: EstadoVazio(
          titulo: 'Nenhum cartão',
          mensagem:
              'Cadastre seus cartões de crédito para registrar compras '
              'faturadas.',
          rotuloAcao: 'Cadastrar cartão',
          aoAgir: () => context.push('/configuracao/cartoes/novo'),
        ),
        conteudo: (cartoes) => ListView.separated(
          padding: const EdgeInsets.only(bottom: 96),
          itemCount: cartoes.length,
          separatorBuilder: (_, _) =>
              const Divider(indent: TokensRavix.spaceMd),
          itemBuilder: (context, i) {
            final cartao = cartoes[i];
            return ListTile(
              leading: const Icon(Icones.creditCard),
              title: Text(nomeComFinal(cartao)),
              subtitle: Text(resumoDoCartao(cartao)),
              onTap: () => context.push(
                '/configuracao/cartoes/${cartao.uuidCartaoCredito}',
              ),
              trailing: IconButton(
                tooltip: 'Remover ${cartao.nomeCartao}',
                icon: const Icon(Icones.trash2),
                onPressed: () => removerCartao(context, ref, cartao),
              ),
            );
          },
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/configuracao/cartoes/novo'),
        icon: const Icon(Icones.plus),
        label: const Text('Novo cartão'),
      ),
    );
  }
}

/// Confirma e remove [cartao]: exclui se nada o usa; senão, arquiva
/// (DP-29). Devolve `true` se removeu.
Future<bool> removerCartao(
  BuildContext context,
  WidgetRef ref,
  CartaoCredito cartao,
) async {
  final repositorio = ref.read(cartaoRepositoryProvider);
  final usos = await repositorio.contarUsos(cartao.uuidCartaoCredito);
  if (!context.mounted) return false;

  final arquivar = usos > 0;
  final registros = usos == 1 ? '1 registro' : '$usos registros';
  final confirmou = await showDialog<bool>(
    context: context,
    builder: (contexto) => AlertDialog(
      title: Text(arquivar ? 'Arquivar o cartão?' : 'Excluir o cartão?'),
      content: Text(
        arquivar
            ? '"${cartao.nomeCartao}" tem $registros. Ele sai das opções do '
                  'formulário, mas continua no histórico.'
            : '"${cartao.nomeCartao}" não tem registros e será excluído.',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(contexto).pop(false),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          style: FilledButton.styleFrom(
            backgroundColor: contexto.temaRavix.paleta.danger,
            foregroundColor: contexto.temaRavix.paleta.onDanger,
          ),
          onPressed: () => Navigator.of(contexto).pop(true),
          child: Text(arquivar ? 'Arquivar' : 'Excluir'),
        ),
      ],
    ),
  );
  if (confirmou != true) return false;

  final resultado = await repositorio.remover(cartao.uuidCartaoCredito);
  if (context.mounted) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(
            resultado == RemocaoCartao.arquivado
                ? 'Cartão "${cartao.nomeCartao}" arquivado.'
                : 'Cartão "${cartao.nomeCartao}" excluído.',
          ),
        ),
      );
  }
  return true;
}
