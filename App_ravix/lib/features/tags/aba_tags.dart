import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ravix/app/dependencias.dart';
import 'package:ravix/core/tema/capra_tokens.dart';
import 'package:ravix/core/tema/icones.dart';
import 'package:ravix/core/tema/tema.dart';
import 'package:ravix/data/banco.dart';
import 'package:ravix/data/tag_repository.dart';
import 'package:ravix/features/shell/estados_tela.dart';
import 'package:ravix/features/tags/dialogo_nome_tag.dart';
import 'package:ravix/features/tags/tags_providers.dart';

/// Abre o diálogo de criação de tag.
Future<void> criarTag(BuildContext context, WidgetRef ref) =>
    mostrarDialogoNomeTag(
      context,
      titulo: 'Nova tag',
      rotuloSalvar: 'Criar',
      aoSalvar: (nome) => ref.read(tagRepositoryProvider).criar(nome),
    );

/// Aba Tags da Configuração (E01-F07-T09, T10): listar, criar, renomear e
/// remover. Tocar na tag renomeia; o botão da linha ou deslizar remove.
class AbaTags extends ConsumerWidget {
  /// Cria a aba.
  const new({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ConteudoAssincrono<List<Tag>>(
      valor: ref.watch(tagsAtivasProvider),
      estaVazio: (tags) => tags.isEmpty,
      aoTentarDeNovo: () => ref.invalidate(tagsAtivasProvider),
      vazio: EstadoVazio(
        titulo: 'Nenhuma tag',
        mensagem:
            'Tags marcam o contexto de um gasto, como uma viagem ou um rolê.',
        rotuloAcao: 'Criar tag',
        aoAgir: () => criarTag(context, ref),
      ),
      conteudo: (tags) => ListView.separated(
        // Espaço para o botão flutuante não cobrir a última tag.
        padding: const EdgeInsets.only(bottom: 96),
        itemCount: tags.length,
        separatorBuilder: (_, _) => const Divider(indent: CapraTokens.spaceMd),
        itemBuilder: (context, i) => _LinhaTag(tag: tags[i]),
      ),
    );
  }
}

class _LinhaTag extends ConsumerWidget {
  const new({required this.tag});

  final Tag tag;

  Future<void> _renomear(BuildContext context, WidgetRef ref) =>
      mostrarDialogoNomeTag(
        context,
        titulo: 'Renomear tag',
        rotuloSalvar: 'Salvar',
        nomeInicial: tag.nome,
        aoSalvar: (nome) =>
            ref.read(tagRepositoryProvider).renomear(tag.uuidTag, nome),
      );

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final paleta = context.temaRavix.paleta;
    return Dismissible(
      key: ValueKey(tag.uuidTag),
      direction: DismissDirection.endToStart,
      confirmDismiss: (_) => removerTag(context, ref, tag),
      background: ColoredBox(
        color: paleta.danger,
        child: Align(
          alignment: Alignment.centerRight,
          child: Padding(
            padding: const EdgeInsets.only(right: CapraTokens.spaceLg),
            child: Icon(Icones.trash2, color: paleta.onAccent),
          ),
        ),
      ),
      child: ListTile(
        leading: const Icon(Icones.tag),
        title: Text(tag.nome),
        onTap: () => _renomear(context, ref),
        trailing: IconButton(
          tooltip: 'Remover ${tag.nome}',
          icon: const Icon(Icones.trash2),
          onPressed: () => removerTag(context, ref, tag),
        ),
      ),
    );
  }
}

/// Confirma e remove [tag]: exclui se nenhum gasto a usa; senão, arquiva.
/// Devolve `true` se removeu.
Future<bool> removerTag(BuildContext context, WidgetRef ref, Tag tag) async {
  final repositorio = ref.read(tagRepositoryProvider);
  final usos = await repositorio.contarUsos(tag.uuidTag);
  if (!context.mounted) return false;

  final arquivar = usos > 0;
  final gastos = usos == 1 ? '1 gasto' : '$usos gastos';
  final confirmou = await showDialog<bool>(
    context: context,
    builder: (contexto) => AlertDialog(
      title: Text(arquivar ? 'Arquivar a tag?' : 'Excluir a tag?'),
      content: Text(
        arquivar
            ? '"${tag.nome}" está em $gastos. Ela sai das opções do '
                  'formulário, mas continua nos gastos antigos.'
            : '"${tag.nome}" não está em nenhum gasto e será excluída.',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(contexto).pop(false),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          style: FilledButton.styleFrom(
            backgroundColor: contexto.temaRavix.paleta.danger,
            foregroundColor: contexto.temaRavix.paleta.onAccent,
          ),
          onPressed: () => Navigator.of(contexto).pop(true),
          child: Text(arquivar ? 'Arquivar' : 'Excluir'),
        ),
      ],
    ),
  );
  if (confirmou != true) return false;

  final resultado = await repositorio.remover(tag.uuidTag);
  if (context.mounted) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(
            resultado == RemocaoTag.arquivada
                ? 'Tag "${tag.nome}" arquivada.'
                : 'Tag "${tag.nome}" excluída.',
          ),
        ),
      );
  }
  return true;
}
