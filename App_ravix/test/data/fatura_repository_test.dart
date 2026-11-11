import 'package:flutter_test/flutter_test.dart';
import 'package:ravix/core/datas.dart';
import 'package:ravix/data/banco.dart';
import 'package:ravix/data/cartao_repository.dart';
import 'package:ravix/data/fatura_repository.dart';
import 'package:ravix/data/faturado_repository.dart';
import 'package:ravix/data/recorrencia_repository.dart';

import '../helpers/ambiente_falso.dart';
import '../helpers/banco_de_teste.dart';

void main() {
  late BancoRavix banco;
  late FaturaRepository faturas;
  late FaturadoRepository faturado;
  late CartaoRepository cartoes;
  late RecorrenciaRepository recorrencias;
  late String itau;
  late String nubank;

  setUp(() async {
    banco = bancoEmMemoria();
    final relogio = RelogioFixo(DateTime(2026, 11, 8, 12));
    final uuid = GeradorUuidSequencial();
    final fuso = FusoFixo(-180);
    faturas = FaturaRepository(banco);
    faturado = FaturadoRepository(
      banco,
      relogio: relogio,
      uuid: uuid,
      fuso: fuso,
    );
    recorrencias = RecorrenciaRepository(
      banco,
      relogio: relogio,
      uuid: uuid,
      fuso: fuso,
    );
    cartoes = CartaoRepository(banco, relogio: relogio, uuid: uuid);
    itau = (await cartoes.criar((
      nome: 'Itaú',
      limiteCentavos: 590000,
      diaFechamento: 29,
      diaVencimento: 5,
      finalCartao: '9827',
      cnpjEmissor: null,
    ))).uuidCartaoCredito;
    nubank = (await cartoes.criar((
      nome: 'Nubank',
      limiteCentavos: 100000,
      diaFechamento: null,
      diaVencimento: null,
      finalCartao: null,
      cnpjEmissor: null,
    ))).uuidCartaoCredito;
  });
  tearDown(() => banco.close());

  Future<String> compra({
    required String cartao,
    int total = 120000,
    int parcelas = 12,
    Mes? vencimento,
    String descricao = 'Geladeira',
    DateTime? momento,
  }) => faturado.criarCompra((
    momento: momento ?? DateTime(2026, 10, 20, 10),
    descricao: descricao,
    valorTotalCentavos: total,
    parcelas: parcelas,
    uuidCartao: cartao,
    vencimento: vencimento ?? Mes(2026, 11),
    idSubcategoria: 506,
    uuidTag: null,
  ));

  Future<void> pagar(String cartao, Mes fatura, int valor) =>
      faturado.criarPagamento((
        momento: DateTime(fatura.ano, fatura.mes, 5, 9),
        valorCentavos: valor,
        forma: FormaPagamentoFatura.pix,
        uuidCartao: cartao,
        fatura: fatura,
      ));

  Future<void> estornar(String cartao, Mes fatura, int valor) =>
      faturado.criarEstorno((
        momento: DateTime(2026, 10, 25),
        descricao: 'Devolução',
        valorCentavos: valor,
        uuidCartao: cartao,
        fatura: fatura,
        idSubcategoria: 504,
        uuidTag: null,
        uuidCompraOriginal: null,
      ));

  group('faturas por cartão', () {
    test('valor do mês é parcelas menos estornos', () async {
      await compra(cartao: itau);
      await compra(cartao: itau, total: 5000, parcelas: 1, descricao: 'Livro');
      await estornar(itau, Mes(2026, 11), 2000);

      final lista = await faturas.observarFaturas(Mes(2026, 11)).first;
      expect(lista.map((f) => f.cartao.nomeCartao), ['Itaú', 'Nubank']);
      final f = lista.first;
      expect(f.valor, 10000 + 5000 - 2000);
      expect(f.pago, 0);
      expect(f.pagoEm, isNull);
      expect(lista.last.valor, 0);
    });

    test(
      'consumo do limite: tudo que falta pagar, de todos os meses',
      () async {
        await compra(cartao: itau);
        var f = (await faturas.observarFaturas(Mes(2026, 11)).first).first;
        // R$ 1.200 em 12x consome R$ 1.200 do limite na hora.
        expect(f.consumo, 120000);

        await pagar(itau, Mes(2026, 11), 10000);
        f = (await faturas.observarFaturas(Mes(2026, 11)).first).first;
        expect(f.pago, 10000);
        expect(f.pagoEm, DateTime(2026, 11, 5, 9));
        expect(f.consumo, 110000);

        // O consumo não muda com o mês escolhido.
        final dezembro = await faturas.observarFaturas(Mes(2026, 12)).first;
        expect(dezembro.first.consumo, 110000);
        expect(dezembro.first.valor, 10000);
      },
    );

    test('pagamento parcial libera só o que foi pago', () async {
      await compra(cartao: itau, total: 100000, parcelas: 1);
      await pagar(itau, Mes(2026, 11), 1000);
      final f = (await faturas.observarFaturas(Mes(2026, 11)).first).first;
      expect(f.pago, 1000);
      expect(f.consumo, 99000);
    });

    test('pagar a mais numa fatura não abate as outras', () async {
      await compra(cartao: itau, total: 20000, parcelas: 2);
      await pagar(itau, Mes(2026, 11), 15000);
      final f = (await faturas.observarFaturas(Mes(2026, 11)).first).first;
      expect(f.consumo, 10000);
    });

    test('fatura vencida sem pagamento registrado segue no limite', () async {
      await compra(
        cartao: itau,
        total: 30000,
        parcelas: 3,
        vencimento: Mes(2026, 8),
      );
      final f = (await faturas.observarFaturas(Mes(2026, 11)).first).first;
      expect(f.consumo, 30000);
    });

    test('vencidas em aberto: só as vencidas, pelo que falta pagar', () async {
      // Hoje é 08/11/2026; o Itaú vence dia 5. Parcelas de nov a mar.
      await compra(cartao: itau, total: 50000, parcelas: 5);
      await compra(
        cartao: itau,
        total: 30000,
        parcelas: 3,
        vencimento: Mes(2026, 9),
        descricao: 'TV',
      );
      await pagar(itau, Mes(2026, 9), 4000);
      final v = await faturas
          .observarVencidasEmAberto(DateTime(2026, 11, 8))
          .first;
      expect(v.map((f) => (f.fatura, f.emAberto)), [
        (Mes(2026, 9), 6000),
        (Mes(2026, 10), 10000),
        (Mes(2026, 11), 20000),
      ]);
      expect(v.first.vencimento, DateTime(2026, 9, 5));
      // Antes do dia 5 de novembro, a de novembro ainda não venceu.
      final antes = await faturas
          .observarVencidasEmAberto(DateTime(2026, 11, 4))
          .first;
      expect(antes, hasLength(2));
    });

    test('quitar vencidas zera o que venceu e libera o limite', () async {
      await compra(
        cartao: itau,
        total: 30000,
        parcelas: 3,
        vencimento: Mes(2026, 9),
      );
      final hoje = DateTime(2026, 11, 8);
      final v = await faturas.observarVencidasEmAberto(hoje).first;
      expect(await faturado.quitarVencidas(v), 3);
      expect(await faturas.observarVencidasEmAberto(hoje).first, isEmpty);
      final f = (await faturas.observarFaturas(Mes(2026, 11)).first).first;
      expect(f.consumo, 0);
      expect(f.pago, 10000);
      expect(f.pagoEm, DateTime(2026, 11, 5, 12));
    });

    test('estorno de fatura não paga libera o limite', () async {
      await compra(cartao: itau, total: 30000, parcelas: 1);
      await estornar(itau, Mes(2026, 11), 30000);
      final f = (await faturas.observarFaturas(Mes(2026, 11)).first).first;
      expect(f.consumo, 0);
      expect(f.valor, 0);
    });

    test('arquivado só aparece no mês em que tem movimento', () async {
      await compra(cartao: nubank, parcelas: 1, total: 1000);
      await cartoes.remover(nubank);
      final nov = await faturas.observarFaturas(Mes(2026, 11)).first;
      expect(nov.map((f) => f.cartao.nomeCartao), ['Itaú', 'Nubank']);
      final dez = await faturas.observarFaturas(Mes(2026, 12)).first;
      expect(dez.map((f) => f.cartao.nomeCartao), ['Itaú']);
    });
  });

  test('itens: parcelas com o número e estornos como crédito', () async {
    final geladeira = await compra(cartao: itau, vencimento: Mes(2026, 9));
    await estornar(nubank, Mes(2026, 11), 1500);

    final itens = await faturas.observarItens(Mes(2026, 11)).first;
    expect(itens, hasLength(2));
    final parcela = itens.firstWhere((i) => i.tipo == TipoItemFatura.parcela);
    expect(parcela.uuid, geladeira);
    expect((parcela.numeroParcela, parcela.quantParcelas), (3, 12));
    expect(parcela.valor, 10000);
    expect(parcela.subcategoria, isNotEmpty);
    expect(parcela.recorrente, isFalse);
    final estorno = itens.firstWhere((i) => i.tipo == TipoItemFatura.estorno);
    expect(estorno.valor, 1500);
    expect(estorno.idCategoria, 5);

    final soItau = await faturas
        .observarItens(Mes(2026, 11), uuidCartao: itau)
        .first;
    expect(soItau.single.tipo, TipoItemFatura.parcela);
  });

  test('pagamentos das faturas do mês', () async {
    await pagar(itau, Mes(2026, 11), 106383);
    await pagar(itau, Mes(2026, 12), 1000);
    final lista = await faturas.observarPagamentos(Mes(2026, 11)).first;
    expect(lista.single.pagamento.valorPagamento, 106383);
    expect(lista.single.nomeCartao, 'Itaú');
  });

  test('linha do tempo soma por cartão e mês, com estornos', () async {
    await compra(cartao: itau, total: 30000, parcelas: 3);
    await compra(cartao: nubank, total: 5000, parcelas: 1);
    await estornar(itau, Mes(2026, 12), 4000);

    final pontos = await faturas
        .observarLinhaDoTempo(Mes(2026, 11), Mes(2027, 1))
        .first;
    expect(
      {for (final p in pontos) '${p.mes} ${p.uuidCartao == itau}': p.valor},
      {
        '2026-11 true': 10000,
        '2026-11 false': 5000,
        '2026-12 true': 6000,
        '2027-01 true': 10000,
      },
    );
  });

  test('por categoria soma os cartões e abate os estornos', () async {
    await compra(cartao: itau, total: 10000, parcelas: 1);
    await compra(cartao: nubank, total: 5000, parcelas: 1);
    await estornar(itau, Mes(2026, 11), 1000); // Vestuário, mesma categoria.

    final totais = await faturas.observarPorCategoria(Mes(2026, 11)).first;
    expect(totais.single.idCategoria, 5);
    expect(totais.single.total, 14000);
  });

  group('recorrências previstas na fatura', () {
    DadosRecorrencia netflix({required String cartao, int dia = 10}) => (
      descricao: 'Netflix',
      valorCentavos: 5590,
      idSubcategoria: 601,
      periodicidade: Periodicidade.mensal,
      diaCobranca: dia,
      inicio: DateTime(2026, 9, 10),
      fim: null,
      uuidCartao: cartao,
      tipoPagamento: null,
      documentoBeneficiario: null,
    );

    test('caem na fatura pelo fechamento do cartão', () async {
      await recorrencias.criar(netflix(cartao: itau));
      await recorrencias.materializarFaturadas();
      // 10/11 (ainda não cobrada), antes do fechamento 29: vence em
      // dezembro.
      expect(await recorrencias.previstasNaFatura(Mes(2026, 11)), isEmpty);
      final dez = await recorrencias.previstasNaFatura(Mes(2026, 12));
      expect(dez.single.ocorrencia, DateTime(2026, 11, 10));
      final jan = await recorrencias.previstasNaFatura(Mes(2027, 1));
      expect(jan.single.ocorrencia, DateTime(2026, 12, 10));
    });

    test('cartão sem dias: fatura do mês seguinte à cobrança', () async {
      await recorrencias.criar(netflix(cartao: nubank));
      await recorrencias.materializarFaturadas();
      final dez = await recorrencias.previstasNaFatura(Mes(2026, 12));
      expect(dez.single.ocorrencia, DateTime(2026, 11, 10));
    });

    test('a cobrança já lançada sai das previstas', () async {
      await recorrencias.criar(netflix(cartao: itau, dia: 1));
      await recorrencias.materializarFaturadas();
      // 01/11 já foi lançada: vence em dezembro, mas não é mais prevista.
      expect(await recorrencias.previstasNaFatura(Mes(2026, 12)), isEmpty);
      final jan = await recorrencias.previstasNaFatura(Mes(2027, 1));
      expect(jan.single.ocorrencia, DateTime(2026, 12));
      final itens = await faturas.observarItens(Mes(2026, 12)).first;
      expect(itens.single.recorrente, isTrue);
    });
  });
}
