import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:ravix/app/dependencias.dart';
import 'package:ravix/core/tema/tokens.dart';
import 'package:ravix/core/valor.dart';
import 'package:ravix/data/banco.dart';
import 'package:ravix/data/cartao_repository.dart';
import 'package:ravix/features/compra_avista/mascara_valor.dart';
import 'package:ravix/features/shell/estados_tela.dart';

/// Cadastro e edição de cartão (E01-F07-T06, T07). Com [uuid], edita.
class TelaCartao extends ConsumerStatefulWidget {
  /// Cria a tela; sem [uuid], cadastra um cartão novo.
  const new({this.uuid, super.key});

  /// Cartão em edição.
  final String? uuid;

  @override
  ConsumerState<TelaCartao> createState() => _TelaCartaoState();
}

class _TelaCartaoState extends ConsumerState<TelaCartao> {
  // Buscado uma vez: refazer a busca a cada build recriaria o formulário.
  late final Future<CartaoCredito?>? _cartao = widget.uuid == null
      ? null
      : ref.read(cartaoRepositoryProvider).buscar(widget.uuid!);

  @override
  Widget build(BuildContext context) {
    if (_cartao == null) return const _FormularioCartao();
    return FutureBuilder<CartaoCredito?>(
      future: _cartao,
      builder: (context, foto) => switch (foto) {
        AsyncSnapshot(:final error?) => Scaffold(
          appBar: AppBar(),
          body: EstadoErro(mensagem: '$error'),
        ),
        AsyncSnapshot(connectionState: ConnectionState.done, :final data) =>
          data == null
              ? Scaffold(
                  appBar: AppBar(),
                  body: const EstadoVazio(
                    titulo: 'Cartão não encontrado',
                    mensagem: 'Ele pode ter sido excluído.',
                  ),
                )
              : _FormularioCartao(cartao: data),
        _ => const Scaffold(body: EstadoCarregando()),
      },
    );
  }
}

class _FormularioCartao extends ConsumerStatefulWidget {
  const new({this.cartao});

  final CartaoCredito? cartao;

  @override
  ConsumerState<_FormularioCartao> createState() => _FormularioCartaoState();
}

class _FormularioCartaoState extends ConsumerState<_FormularioCartao> {
  late final CartaoCredito? _cartao = widget.cartao;
  late final _nome = TextEditingController(text: _cartao?.nomeCartao);
  late final _limite = TextEditingController(
    text: _cartao == null
        ? ''
        : formatarCentavosSemSimbolo(_cartao.limiteCartao),
  );
  late final _fechamento = TextEditingController(
    text: _cartao?.diaFechamento?.toString(),
  );
  late final _vencimento = TextEditingController(
    text: _cartao?.diaVencimento?.toString(),
  );
  late final _final = TextEditingController(text: _cartao?.finalCartao);
  late final _cnpj = TextEditingController(text: _cartao?.cnpjEmissor);
  Map<CampoCartao, String> _erros = const {};
  bool _salvando = false;

  bool get _editando => _cartao != null;

  @override
  void dispose() {
    for (final c in [_nome, _limite, _fechamento, _vencimento, _final, _cnpj]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _salvar() async {
    setState(() => _salvando = true);
    final dados = (
      nome: _nome.text,
      limiteCentavos: centavosDeDigitos(_limite.text),
      diaFechamento: int.tryParse(_fechamento.text),
      diaVencimento: int.tryParse(_vencimento.text),
      finalCartao: _final.text,
      cnpjEmissor: _cnpj.text,
    );
    final repositorio = ref.read(cartaoRepositoryProvider);
    final mensageiro = ScaffoldMessenger.of(context);
    try {
      if (_editando) {
        await repositorio.editar(_cartao!.uuidCartaoCredito, dados);
      } else {
        await repositorio.criar(dados);
      }
      mensageiro
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text(_editando ? 'Cartão salvo.' : 'Cartão cadastrado.'),
          ),
        );
      if (mounted) context.pop();
    } on CartaoInvalido catch (e) {
      setState(() {
        _erros = e.erros;
        _salvando = false;
      });
    }
  }

  Widget _campo({
    required TextEditingController controle,
    required String rotulo,
    required CampoCartao campo,
    String? ajuda,
    String? prefixo,
    TextInputType teclado = TextInputType.number,
    List<TextInputFormatter> formatos = const [],
  }) => TextField(
    controller: controle,
    keyboardType: teclado,
    textInputAction: TextInputAction.next,
    inputFormatters: formatos,
    onChanged: (_) => setState(() => _erros = {..._erros}..remove(campo)),
    decoration: InputDecoration(
      labelText: rotulo,
      helperText: ajuda,
      helperMaxLines: 2,
      prefixText: prefixo,
      errorText: _erros[campo],
    ),
  );

  List<TextInputFormatter> _digitos(int maximo) => [
    FilteringTextInputFormatter.digitsOnly,
    LengthLimitingTextInputFormatter(maximo),
  ];

  @override
  Widget build(BuildContext context) {
    const espaco = SizedBox(height: TokensRavix.spaceMd);
    return Scaffold(
      appBar: AppBar(title: Text(_editando ? 'Editar cartão' : 'Novo cartão')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(TokensRavix.spaceMd),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _campo(
              controle: _nome,
              rotulo: 'Nome',
              campo: CampoCartao.nome,
              teclado: TextInputType.text,
              formatos: [LengthLimitingTextInputFormatter(40)],
            ),
            espaco,
            _campo(
              controle: _limite,
              rotulo: 'Limite',
              campo: CampoCartao.limite,
              prefixo: r'R$ ',
              formatos: [MascaraValor()],
            ),
            espaco,
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: _campo(
                    controle: _fechamento,
                    rotulo: 'Dia de fechamento',
                    campo: CampoCartao.diaFechamento,
                    formatos: _digitos(2),
                  ),
                ),
                const SizedBox(width: TokensRavix.spaceMd),
                Expanded(
                  child: _campo(
                    controle: _vencimento,
                    rotulo: 'Dia de vencimento',
                    campo: CampoCartao.diaVencimento,
                    formatos: _digitos(2),
                  ),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.only(top: TokensRavix.spaceXs),
              child: Text(
                'Opcionais. Servem para sugerir o mês da fatura no '
                'formulário; o dia real pode variar de um mês para outro.',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ),
            espaco,
            _campo(
              controle: _final,
              rotulo: 'Final do cartão',
              campo: CampoCartao.finalCartao,
              ajuda: 'Opcional: os 4 últimos dígitos.',
              formatos: _digitos(4),
            ),
            espaco,
            _campo(
              controle: _cnpj,
              rotulo: 'CNPJ do emissor',
              campo: CampoCartao.cnpjEmissor,
              ajuda:
                  'Opcional, só números. Mais tarde vai servir para '
                  'reconhecer o pagamento da fatura.',
              formatos: _digitos(14),
            ),
            const SizedBox(height: TokensRavix.spaceLg),
            FilledButton(
              onPressed: _salvando ? null : _salvar,
              child: Text(_editando ? 'Salvar cartão' : 'Cadastrar cartão'),
            ),
          ],
        ),
      ),
    );
  }
}
