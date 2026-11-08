import 'package:drift/drift.dart';
import 'package:ravix/core/ambiente.dart';
import 'package:ravix/core/datas.dart';
import 'package:ravix/core/texto.dart';
import 'package:ravix/data/banco.dart';

/// Formas de pagamento de uma fatura (DP-14).
enum FormaPagamentoFatura {
  /// Pix.
  pix('pix'),

  /// Débito em conta.
  debito('debito'),

  /// Boleto.
  boleto('boleto');

  new(this.codigo);

  /// Código gravado em `tipo_pagamento`.
  final String codigo;

  /// Forma correspondente a [codigo]. Lança [ArgumentError] se não existir.
  static FormaPagamentoFatura deCodigo(String codigo) => values.firstWhere(
    (f) => f.codigo == codigo,
    orElse: () => throw ArgumentError.value(codigo, 'codigo'),
  );
}

/// O que o formulário informa ao criar ou editar uma compra no cartão
/// (E01-F03-T06). `vencimento` é a fatura da 1ª parcela.
typedef DadosCompraFaturada = ({
  DateTime momento,
  String descricao,
  int valorTotalCentavos,
  int parcelas,
  String uuidCartao,
  Mes vencimento,
  int idSubcategoria,
  String? uuidTag,
});

/// O que o formulário informa sobre um pagamento de fatura (E01-F03-T13).
typedef DadosPagamentoFatura = ({
  DateTime momento,
  int valorCentavos,
  FormaPagamentoFatura forma,
  String uuidCartao,
  Mes fatura,
});

/// O que o formulário informa sobre um estorno (E01-F03-T17).
typedef DadosEstorno = ({
  DateTime momento,
  String descricao,
  int valorCentavos,
  String uuidCartao,
  Mes fatura,
  int idSubcategoria,
  String? uuidTag,
  String? uuidCompraOriginal,
});

/// Divide [total] centavos em [parcelas]. O resto da divisão vai na 1ª
/// parcela, como o Itaú faz: 4.500,00 em 19x = 236,88 + 18 × 236,84.
List<int> dividirEmParcelas(int total, int parcelas) {
  final base = total ~/ parcelas;
  final resto = total - base * parcelas;
  return [base + resto, for (var i = 1; i < parcelas; i++) base];
}

/// Mês de vencimento sugerido para uma compra em [data] no cartão de
/// [diaFechamento] e [diaVencimento] (DP-28).
///
/// A compra até o dia de fechamento entra na fatura que fecha no mês da
/// compra; depois dele, na do mês seguinte. A fatura vence no mesmo mês do
/// fechamento se o vencimento é depois do fechamento; senão, no mês
/// seguinte. Sem os dias, sugere o mês seguinte à compra.
Mes sugerirVencimento(
  DateTime data, {
  required int? diaFechamento,
  required int? diaVencimento,
}) {
  final mesDaCompra = Mes.de(data);
  if (diaFechamento == null) return mesDaCompra.proximo;
  final fechamento = data.day <= diaFechamento
      ? mesDaCompra
      : mesDaCompra.proximo;
  final venceNoMesmoMes =
      diaVencimento != null && diaVencimento > diaFechamento;
  return venceNoMesmoMes ? fechamento : fechamento.proximo;
}

/// Fatura sugerida para um pagamento em [data] no cartão de vencimento
/// [diaVencimento]: a que vence a partir de [data]. Sem o dia, a do mês.
Mes sugerirFaturaPaga(DateTime data, {required int? diaVencimento}) {
  final mes = Mes.de(data);
  if (diaVencimento == null) return mes;
  return data.day <= diaVencimento ? mes : mes.proximo;
}

/// Compras no cartão com as parcelas, pagamentos de fatura e estornos
/// (E01-F03-T06, T13, T17; E02-F05).
final class FaturadoRepository {
  /// Cria o repositório sobre o banco do app.
  new(
    this._banco, {
    required this._relogio,
    required this._uuid,
    required this._fuso,
  });

  final BancoRavix _banco;
  final Relogio _relogio;
  final GeradorUuid _uuid;
  final Fuso _fuso;

  // ---------------------------------------------------------------- compras

  /// Grava a compra e as parcelas; devolve o UUID da compra.
  Future<String> criarCompra(DadosCompraFaturada dados) =>
      _banco.transaction(() async {
        final uuid = _uuid.gerar();
        final agora = paraIsoUtc(_relogio.agora());
        await _banco
            .into(_banco.tblCompraFaturada)
            .insert(
              TblCompraFaturadaCompanion.insert(
                uuidCompraFaturada: uuid,
                uuidCartaoCredito: dados.uuidCartao,
                timestampCompraFaturada: paraIsoLocal(dados.momento),
                fusoMinutos: _fuso.minutosAtuais(),
                descricao: dados.descricao.trim(),
                descricaoNormalizada: normalizarTexto(dados.descricao),
                valorTotal: dados.valorTotalCentavos,
                quantParcela: dados.parcelas,
                mesVencimento: dados.vencimento.mes,
                anoVencimento: dados.vencimento.ano,
                idSubcategoria: dados.idSubcategoria,
                uuidTag: Value(dados.uuidTag),
                criadoEm: agora,
                atualizadoEm: agora,
              ),
            );
        await _gerarParcelas(uuid, dados);
        return uuid;
      });

  /// Substitui os dados da compra [uuid] e regera as parcelas.
  ///
  /// Mantém o fuso gravado se a data não mudou (DP-33). Lança [StateError]
  /// se a compra não existir.
  Future<void> editarCompra(String uuid, DadosCompraFaturada dados) =>
      _banco.transaction(() async {
        final atual = await buscarCompra(uuid);
        if (atual == null) throw StateError('Compra $uuid não existe');
        final timestamp = paraIsoLocal(dados.momento);
        await (_banco.update(
          _banco.tblCompraFaturada,
        )..where((c) => c.uuidCompraFaturada.equals(uuid))).write(
          TblCompraFaturadaCompanion(
            uuidCartaoCredito: Value(dados.uuidCartao),
            timestampCompraFaturada: Value(timestamp),
            fusoMinutos: Value(
              timestamp == atual.timestampCompraFaturada
                  ? atual.fusoMinutos
                  : _fuso.minutosAtuais(),
            ),
            descricao: Value(dados.descricao.trim()),
            descricaoNormalizada: Value(normalizarTexto(dados.descricao)),
            valorTotal: Value(dados.valorTotalCentavos),
            quantParcela: Value(dados.parcelas),
            mesVencimento: Value(dados.vencimento.mes),
            anoVencimento: Value(dados.vencimento.ano),
            idSubcategoria: Value(dados.idSubcategoria),
            uuidTag: Value(dados.uuidTag),
            atualizadoEm: Value(paraIsoUtc(_relogio.agora())),
          ),
        );
        await (_banco.delete(
          _banco.tblParcela,
        )..where((p) => p.uuidCompraFaturada.equals(uuid))).go();
        await _gerarParcelas(uuid, dados);
      });

  /// Apaga a compra e as parcelas (exclusão física, DP-34). Estornos ligados
  /// a ela ficam, sem a compra original.
  Future<void> excluirCompra(String uuid) => (_banco.delete(
    _banco.tblCompraFaturada,
  )..where((c) => c.uuidCompraFaturada.equals(uuid))).go();

  /// Compra pelo UUID, ou `null`.
  Future<CompraFaturada?> buscarCompra(String uuid) => (_banco.select(
    _banco.tblCompraFaturada,
  )..where((c) => c.uuidCompraFaturada.equals(uuid))).getSingleOrNull();

  /// Parcelas da compra [uuid], em ordem.
  Future<List<Parcela>> parcelasDe(String uuid) =>
      (_banco.select(_banco.tblParcela)
            ..where((p) => p.uuidCompraFaturada.equals(uuid))
            ..orderBy([(p) => OrderingTerm.asc(p.numeroParcela)]))
          .get();

  Future<void> _gerarParcelas(String uuid, DadosCompraFaturada dados) async {
    final valores = dividirEmParcelas(dados.valorTotalCentavos, dados.parcelas);
    var mes = dados.vencimento;
    await _banco.batch((b) {
      for (var i = 0; i < valores.length; i++) {
        b.insert(
          _banco.tblParcela,
          TblParcelaCompanion.insert(
            uuidParcela: _uuid.gerar(),
            uuidCompraFaturada: uuid,
            numeroParcela: i + 1,
            valorParcela: valores[i],
            mesVencimento: mes.mes,
            anoVencimento: mes.ano,
          ),
        );
        mes = mes.proximo;
      }
    });
  }

  // ------------------------------------------------------------- pagamentos

  /// Grava um pagamento de fatura; devolve o UUID.
  Future<String> criarPagamento(DadosPagamentoFatura dados) async {
    final uuid = _uuid.gerar();
    final agora = paraIsoUtc(_relogio.agora());
    await _banco
        .into(_banco.tblPagamentoFatura)
        .insert(
          TblPagamentoFaturaCompanion.insert(
            uuidPagamentoFatura: uuid,
            uuidCartaoCredito: dados.uuidCartao,
            mesVencimento: dados.fatura.mes,
            anoVencimento: dados.fatura.ano,
            timestampPagamento: paraIsoLocal(dados.momento),
            fusoMinutos: _fuso.minutosAtuais(),
            valorPagamento: dados.valorCentavos,
            tipoPagamento: dados.forma.codigo,
            criadoEm: agora,
            atualizadoEm: agora,
          ),
        );
    return uuid;
  }

  /// Substitui o pagamento [uuid]. Lança [StateError] se não existir.
  Future<void> editarPagamento(String uuid, DadosPagamentoFatura dados) async {
    final atual = await buscarPagamento(uuid);
    if (atual == null) throw StateError('Pagamento $uuid não existe');
    final timestamp = paraIsoLocal(dados.momento);
    await (_banco.update(
      _banco.tblPagamentoFatura,
    )..where((p) => p.uuidPagamentoFatura.equals(uuid))).write(
      TblPagamentoFaturaCompanion(
        uuidCartaoCredito: Value(dados.uuidCartao),
        mesVencimento: Value(dados.fatura.mes),
        anoVencimento: Value(dados.fatura.ano),
        timestampPagamento: Value(timestamp),
        fusoMinutos: Value(
          timestamp == atual.timestampPagamento
              ? atual.fusoMinutos
              : _fuso.minutosAtuais(),
        ),
        valorPagamento: Value(dados.valorCentavos),
        tipoPagamento: Value(dados.forma.codigo),
        atualizadoEm: Value(paraIsoUtc(_relogio.agora())),
      ),
    );
  }

  /// Apaga o pagamento [uuid].
  Future<void> excluirPagamento(String uuid) => (_banco.delete(
    _banco.tblPagamentoFatura,
  )..where((p) => p.uuidPagamentoFatura.equals(uuid))).go();

  /// Pagamento pelo UUID, ou `null`.
  Future<PagamentoFatura?> buscarPagamento(String uuid) => (_banco.select(
    _banco.tblPagamentoFatura,
  )..where((p) => p.uuidPagamentoFatura.equals(uuid))).getSingleOrNull();

  // --------------------------------------------------------------- estornos

  /// Grava um estorno; devolve o UUID.
  Future<String> criarEstorno(DadosEstorno dados) async {
    final uuid = _uuid.gerar();
    final agora = paraIsoUtc(_relogio.agora());
    await _banco
        .into(_banco.tblEstorno)
        .insert(
          TblEstornoCompanion.insert(
            uuidEstorno: uuid,
            uuidCartaoCredito: dados.uuidCartao,
            uuidCompraFaturada: Value(dados.uuidCompraOriginal),
            timestampEstorno: paraIsoLocal(dados.momento),
            fusoMinutos: _fuso.minutosAtuais(),
            descricao: dados.descricao.trim(),
            valorEstorno: dados.valorCentavos,
            mesVencimento: dados.fatura.mes,
            anoVencimento: dados.fatura.ano,
            idSubcategoria: dados.idSubcategoria,
            uuidTag: Value(dados.uuidTag),
            criadoEm: agora,
            atualizadoEm: agora,
          ),
        );
    return uuid;
  }

  /// Substitui o estorno [uuid]. Lança [StateError] se não existir.
  Future<void> editarEstorno(String uuid, DadosEstorno dados) async {
    final atual = await buscarEstorno(uuid);
    if (atual == null) throw StateError('Estorno $uuid não existe');
    final timestamp = paraIsoLocal(dados.momento);
    await (_banco.update(
      _banco.tblEstorno,
    )..where((e) => e.uuidEstorno.equals(uuid))).write(
      TblEstornoCompanion(
        uuidCartaoCredito: Value(dados.uuidCartao),
        uuidCompraFaturada: Value(dados.uuidCompraOriginal),
        timestampEstorno: Value(timestamp),
        fusoMinutos: Value(
          timestamp == atual.timestampEstorno
              ? atual.fusoMinutos
              : _fuso.minutosAtuais(),
        ),
        descricao: Value(dados.descricao.trim()),
        valorEstorno: Value(dados.valorCentavos),
        mesVencimento: Value(dados.fatura.mes),
        anoVencimento: Value(dados.fatura.ano),
        idSubcategoria: Value(dados.idSubcategoria),
        uuidTag: Value(dados.uuidTag),
        atualizadoEm: Value(paraIsoUtc(_relogio.agora())),
      ),
    );
  }

  /// Apaga o estorno [uuid].
  Future<void> excluirEstorno(String uuid) => (_banco.delete(
    _banco.tblEstorno,
  )..where((e) => e.uuidEstorno.equals(uuid))).go();

  /// Estorno pelo UUID, ou `null`.
  Future<Estorno?> buscarEstorno(String uuid) => (_banco.select(
    _banco.tblEstorno,
  )..where((e) => e.uuidEstorno.equals(uuid))).getSingleOrNull();
}
