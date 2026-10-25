import 'package:ravix/data/banco.dart';
import 'package:ravix/data/compra_avista_repository.dart';

/// Campos validados do formulário de gasto à vista.
enum CampoCompra {
  /// Descrição.
  descricao,

  /// Valor.
  valor,

  /// Forma de pagamento.
  tipoPagamento,

  /// Categoria.
  categoria,

  /// Subcategoria.
  subcategoria,
}

/// Estado editável do formulário (E01-F03). Todos os campos são
/// obrigatórios, exceto a tag (T14); datas futuras são aceitas (DP-15).
final class RascunhoCompra {
  /// Rascunho de um gasto novo em [momento].
  new({required this.momento});

  /// Rascunho com os dados de [compra], para editar.
  new deCompra(CompraAvista compra)
    : momento = DateTime.parse(compra.timestampCompraAvista),
      descricao = compra.descricao,
      valorCentavos = compra.valorCompraAvista,
      tipoPagamento = TipoPagamento.deCodigo(compra.tipoPagamento),
      // ID da subcategoria = categoria × 100 + sequência (CHECK do banco).
      idCategoria = compra.idSubcategoria ~/ 100,
      idSubcategoria = compra.idSubcategoria,
      uuidTag = compra.uuidTag;

  /// Data e hora do gasto.
  DateTime momento;

  /// Descrição digitada.
  String descricao = '';

  /// Valor em centavos; 0 = vazio.
  int valorCentavos = 0;

  /// Forma de pagamento.
  TipoPagamento? tipoPagamento;

  /// Categoria escolhida.
  int? idCategoria;

  /// Subcategoria escolhida.
  int? idSubcategoria;

  /// Tag opcional.
  String? uuidTag;

  /// Mensagem de cada campo inválido; vazio = pode salvar.
  Map<CampoCompra, String> validar() => {
    if (descricao.trim().isEmpty) CampoCompra.descricao: 'Informe a descrição.',
    if (valorCentavos <= 0)
      CampoCompra.valor: 'Informe um valor maior que zero.',
    if (tipoPagamento == null)
      CampoCompra.tipoPagamento: 'Escolha a forma de pagamento.',
    if (idCategoria == null) CampoCompra.categoria: 'Escolha a categoria.',
    if (idSubcategoria == null)
      CampoCompra.subcategoria: 'Escolha a subcategoria.',
  };

  /// Dados para o repositório. Só chame com [validar] vazio.
  DadosCompraAvista paraDados() {
    assert(validar().isEmpty, 'Rascunho inválido');
    return (
      momento: momento,
      descricao: descricao,
      valorCentavos: valorCentavos,
      tipoPagamento: tipoPagamento!,
      idSubcategoria: idSubcategoria!,
      uuidTag: uuidTag,
    );
  }
}
