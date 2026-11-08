import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:ravix/core/tema/icones.dart';
import 'package:ravix/core/tema/tema.dart';
import 'package:ravix/core/tema/tokens.dart';
import 'package:ravix/features/shell/estados_tela.dart';

/// Tipos do formulário de registro (E01-F03).
enum TipoRegistro {
  /// Gasto à vista (T04).
  avista('avista', 'Gasto à vista', 'Novo gasto'),

  /// Compra no cartão, à vista ou parcelada (T06).
  faturado('faturado', 'Compra no cartão', 'Nova compra no cartão'),

  /// Pagamento de fatura (T13).
  pagamento('pagamento', 'Pagamento de fatura', 'Novo pagamento de fatura'),

  /// Estorno de cartão (T17).
  estorno('estorno', 'Estorno', 'Novo estorno');

  new(this.codigo, this.rotulo, this.tituloNovo);

  /// Código usado na rota (`/registro/novo?tipo=`).
  final String codigo;

  /// Nome no menu de tipos.
  final String rotulo;

  /// Título do formulário ao criar.
  final String tituloNovo;

  /// Tipo pelo [codigo]; desconhecido ou nulo vira à vista.
  static TipoRegistro deCodigo(String? codigo) => values.firstWhere(
    (t) => t.codigo == codigo,
    orElse: () => TipoRegistro.avista,
  );
}

/// Título do formulário ao criar: tocar troca o tipo do registro.
class TituloNovoRegistro extends StatelessWidget {
  /// Cria o título para [tipo].
  const new(this.tipo, {super.key});

  /// Tipo atual.
  final TipoRegistro tipo;

  @override
  Widget build(BuildContext context) => PopupMenuButton<TipoRegistro>(
    tooltip: 'Trocar o tipo de registro',
    initialValue: tipo,
    onSelected: (novo) {
      if (novo != tipo) {
        context.pushReplacement('/registro/novo?tipo=${novo.codigo}');
      }
    },
    itemBuilder: (_) => [
      for (final t in TipoRegistro.values)
        PopupMenuItem(value: t, child: Text(t.rotulo)),
    ],
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Flexible(child: Text(tipo.tituloNovo, overflow: TextOverflow.ellipsis)),
        const SizedBox(width: TokensRavix.spaceXs),
        const Icon(Icones.chevronDown),
      ],
    ),
  );
}

/// Estrutura comum dos formulários: título, excluir (ao editar), campos e o
/// botão de salvar no pé.
class EsqueletoFormulario extends StatelessWidget {
  /// Cria a estrutura.
  const new({
    required this.titulo,
    required this.rotuloSalvar,
    required this.salvando,
    required this.aoSalvar,
    required this.campos,
    this.aoExcluir,
    this.rotuloExcluir = 'Excluir',
    super.key,
  });

  /// Título da barra.
  final Widget titulo;

  /// Texto do botão de salvar.
  final String rotuloSalvar;

  /// Salvando: o botão fica desabilitado.
  final bool salvando;

  /// Ação de salvar.
  final VoidCallback aoSalvar;

  /// Campos, de cima para baixo.
  final List<Widget> campos;

  /// Ação de excluir; sem ela, não há botão.
  final VoidCallback? aoExcluir;

  /// Dica do botão de excluir.
  final String rotuloExcluir;

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: titulo,
      actions: [
        if (aoExcluir != null)
          IconButton(
            tooltip: rotuloExcluir,
            icon: Icon(Icones.trash2, color: context.temaRavix.paleta.danger),
            onPressed: aoExcluir,
          ),
      ],
    ),
    // Tudo construído de uma vez, para os avisos de validação existirem
    // mesmo fora da tela.
    body: SingleChildScrollView(
      padding: const EdgeInsets.all(TokensRavix.spaceMd),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: campos,
      ),
    ),
    bottomNavigationBar: SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          TokensRavix.spaceMd,
          TokensRavix.spaceSm,
          TokensRavix.spaceMd,
          TokensRavix.spaceMd,
        ),
        child: FilledButton(
          onPressed: salvando ? null : aoSalvar,
          child: Text(rotuloSalvar),
        ),
      ),
    ),
  );
}

/// Pede confirmação para excluir; devolve `true` se o usuário confirmou.
Future<bool> confirmarExclusao(
  BuildContext context, {
  required String titulo,
  String mensagem = 'O registro será apagado e não dá para desfazer.',
}) async {
  final paleta = context.temaRavix.paleta;
  final confirmou = await showDialog<bool>(
    context: context,
    builder: (contexto) => AlertDialog(
      title: Text(titulo),
      content: Text(mensagem),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(contexto).pop(false),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          style: FilledButton.styleFrom(
            backgroundColor: paleta.danger,
            foregroundColor: paleta.onDanger,
          ),
          onPressed: () => Navigator.of(contexto).pop(true),
          child: const Text('Excluir'),
        ),
      ],
    ),
  );
  return confirmou ?? false;
}

/// Carrega um registro pelo UUID uma vez e mostra o formulário de edição.
class CarregarParaEditar<T> extends ConsumerStatefulWidget {
  /// Cria o carregador.
  const new({
    required this.titulo,
    required this.buscar,
    required this.formulario,
    super.key,
  });

  /// Título enquanto carrega.
  final String titulo;

  /// Busca o registro.
  final Future<T?> Function(WidgetRef ref) buscar;

  /// Formulário com o registro carregado.
  final Widget Function(T registro) formulario;

  @override
  ConsumerState<CarregarParaEditar<T>> createState() =>
      _CarregarParaEditarState<T>();
}

class _CarregarParaEditarState<T> extends ConsumerState<CarregarParaEditar<T>> {
  // Buscado uma vez: refazer a busca a cada build recriaria o formulário.
  late final Future<T?> _registro = widget.buscar(ref);

  @override
  Widget build(BuildContext context) => FutureBuilder<T?>(
    future: _registro,
    builder: (context, foto) => switch (foto) {
      AsyncSnapshot(connectionState: ConnectionState.done, :final data?) =>
        widget.formulario(data),
      AsyncSnapshot(connectionState: ConnectionState.done, :final error) =>
        Scaffold(
          appBar: AppBar(title: Text(widget.titulo)),
          body: error == null
              ? const EstadoErro(
                  titulo: 'Registro não encontrado',
                  mensagem: 'Ele pode ter sido excluído.',
                )
              : EstadoErro(mensagem: '$error'),
        ),
      _ => Scaffold(
        appBar: AppBar(title: Text(widget.titulo)),
        body: const EstadoCarregando(),
      ),
    },
  );
}
