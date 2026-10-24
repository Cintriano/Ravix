import 'package:drift/drift.dart';
import 'package:ravix/core/ambiente.dart';
import 'package:ravix/core/datas.dart';
import 'package:ravix/core/texto.dart';
import 'package:ravix/data/banco.dart';

/// Formas de pagamento do à vista, com o código gravado no banco (DP-30).
enum TipoPagamento {
  /// Pix.
  pix('pix'),

  /// Cartão de débito.
  debito('debito'),

  /// Dinheiro físico.
  dinheiro('dinheiro'),

  /// Voucher (benefícios).
  voucher('voucher');

  new(this.codigo);

  /// Código sem acento gravado em `tipo_pagamento`.
  final String codigo;

  /// Tipo correspondente a [codigo]. Lança [ArgumentError] se não existir.
  static TipoPagamento deCodigo(String codigo) => values.firstWhere(
    (t) => t.codigo == codigo,
    orElse: () => throw ArgumentError.value(codigo, 'codigo'),
  );
}

/// O que o formulário informa ao criar ou editar um gasto à vista.
///
/// UUID, fuso, descrição normalizada e auditoria são preenchidos pelo
/// repositório.
typedef DadosCompraAvista = ({
  DateTime momento,
  String descricao,
  int valorCentavos,
  TipoPagamento tipoPagamento,
  int idSubcategoria,
  String? uuidTag,
});

/// Filtros da tabela do mês (E01-F04-T05). `null` = sem filtro.
typedef FiltroCompras = ({
  int? idCategoria,
  int? idSubcategoria,
  String? uuidTag,
});

/// Sem nenhum filtro.
const FiltroCompras semFiltro = (
  idCategoria: null,
  idSubcategoria: null,
  uuidTag: null,
);

/// Gastos à vista (E01-F03, E01-F04).
final class CompraAvistaRepository {
  /// Cria o repositório sobre o banco do app.
  new(
    this._banco, {
    required this._relogio,
    required this._uuid,
    required this._fuso,
  });

  /// Mínimo de caracteres (já normalizados) para consultar a sugestão.
  static const minimoParaSugestao = 3;

  final BancoRavix _banco;
  final Relogio _relogio;
  final GeradorUuid _uuid;
  final Fuso _fuso;

  /// Grava um gasto novo e devolve o UUID dele.
  Future<String> criar(DadosCompraAvista dados) async {
    final uuid = _uuid.gerar();
    final agora = paraIsoUtc(_relogio.agora());
    await _banco
        .into(_banco.tblCompraAvista)
        .insert(
          TblCompraAvistaCompanion.insert(
            uuidCompraAvista: uuid,
            timestampCompraAvista: paraIsoLocal(dados.momento),
            fusoMinutos: _fuso.minutosAtuais(),
            descricao: dados.descricao.trim(),
            descricaoNormalizada: normalizarTexto(dados.descricao),
            valorCompraAvista: dados.valorCentavos,
            tipoPagamento: dados.tipoPagamento.codigo,
            idSubcategoria: dados.idSubcategoria,
            uuidTag: Value(dados.uuidTag),
            criadoEm: agora,
            atualizadoEm: agora,
          ),
        );
    return uuid;
  }

  /// Gasto pelo UUID, ou `null` se não existir.
  Future<CompraAvista?> buscar(String uuid) => (_banco.select(
    _banco.tblCompraAvista,
  )..where((c) => c.uuidCompraAvista.equals(uuid))).getSingleOrNull();

  /// Substitui os dados do gasto [uuid].
  ///
  /// Mantém `criado_em`. Mantém o fuso gravado se a data não mudou; se mudou,
  /// usa o fuso atual do aparelho (DP-33). Lança [StateError] se o gasto não
  /// existir.
  Future<void> editar(String uuid, DadosCompraAvista dados) async {
    final atual = await buscar(uuid);
    if (atual == null) {
      throw StateError('Gasto $uuid não existe');
    }
    final timestamp = paraIsoLocal(dados.momento);
    final fuso = timestamp == atual.timestampCompraAvista
        ? atual.fusoMinutos
        : _fuso.minutosAtuais();
    await (_banco.update(
      _banco.tblCompraAvista,
    )..where((c) => c.uuidCompraAvista.equals(uuid))).write(
      TblCompraAvistaCompanion(
        timestampCompraAvista: Value(timestamp),
        fusoMinutos: Value(fuso),
        descricao: Value(dados.descricao.trim()),
        descricaoNormalizada: Value(normalizarTexto(dados.descricao)),
        valorCompraAvista: Value(dados.valorCentavos),
        tipoPagamento: Value(dados.tipoPagamento.codigo),
        idSubcategoria: Value(dados.idSubcategoria),
        uuidTag: Value(dados.uuidTag),
        atualizadoEm: Value(paraIsoUtc(_relogio.agora())),
      ),
    );
  }

  /// Apaga o gasto [uuid] (exclusão física na v1, DP-34).
  Future<void> excluir(String uuid) => (_banco.delete(
    _banco.tblCompraAvista,
  )..where((c) => c.uuidCompraAvista.equals(uuid))).go();

  /// Gastos de [mes] com [filtro], mais recentes primeiro. Emite de novo a
  /// cada alteração na tabela.
  Stream<List<CompraDoMes>> observarMes(
    Mes mes, {
    FiltroCompras filtro = semFiltro,
  }) => _banco
      .comprasDoMes(
        inicio: mes.inicioIso,
        fim: mes.fimIso,
        idCategoria: filtro.idCategoria,
        idSubcategoria: filtro.idSubcategoria,
        uuidTag: filtro.uuidTag,
      )
      .watch();

  /// Soma dos gastos de [mes] em centavos. Não depende dos filtros.
  Stream<int> observarAcumulado(Mes mes) => _banco
      .acumuladoDoMes(inicio: mes.inicioIso, fim: mes.fimIso)
      .watchSingle();

  /// Subcategoria mais usada nos gastos cuja descrição contém
  /// [descricaoDigitada] (desempate pela mais recente), ou `null` sem
  /// histórico ou com menos de [minimoParaSugestao] caracteres (DP-36).
  Future<int?> sugerirSubcategoria(String descricaoDigitada) async {
    final texto = normalizarTexto(descricaoDigitada);
    if (texto.length < minimoParaSugestao) {
      return null;
    }
    return await _banco.sugestaoDeSubcategoria(texto: texto).getSingleOrNull();
  }
}
