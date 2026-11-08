import 'package:flutter_test/flutter_test.dart';
import 'package:ravix/core/datas.dart';
import 'package:ravix/data/banco.dart';
import 'package:ravix/data/cartao_repository.dart';
import 'package:ravix/data/compra_avista_repository.dart';
import 'package:ravix/data/faturado_repository.dart';

import '../helpers/ambiente_falso.dart';
import '../helpers/banco_de_teste.dart';

void main() {
  late BancoRavix banco;
  late FaturadoRepository repositorio;
  late String cartao;
  late FusoFixo fuso;

  setUp(() async {
    banco = bancoEmMemoria();
    final relogio = RelogioFixo(DateTime.utc(2026, 11, 8, 12));
    final uuid = GeradorUuidSequencial();
    fuso = FusoFixo(-180);
    repositorio = FaturadoRepository(
      banco,
      relogio: relogio,
      uuid: uuid,
      fuso: fuso,
    );
    final criado = await CartaoRepository(banco, relogio: relogio, uuid: uuid)
        .criar((
          nome: 'Itaú',
          limiteCentavos: 590000,
          diaFechamento: 29,
          diaVencimento: 5,
          finalCartao: null,
          cnpjEmissor: null,
        ));
    cartao = criado.uuidCartaoCredito;
  });
  tearDown(() => banco.close());

  DadosCompraFaturada compra({
    int total = 450000,
    int parcelas = 19,
    Mes? vencimento,
    String descricao = 'Notebook',
  }) => (
    momento: DateTime(2026, 3, 14, 10),
    descricao: descricao,
    valorTotalCentavos: total,
    parcelas: parcelas,
    uuidCartao: cartao,
    vencimento: vencimento ?? Mes(2026, 4),
    idSubcategoria: 506,
    uuidTag: null,
  );

  group('parcelas', () {
    test('o resto vai na 1ª parcela, como no Itaú', () {
      expect(dividirEmParcelas(450000, 19), [
        23688,
        for (var i = 0; i < 18; i++) 23684,
      ]);
      expect(dividirEmParcelas(120000, 6), List.filled(6, 20000));
      expect(dividirEmParcelas(5500, 1), [5500]);
    });

    test('criar grava uma parcela por mês a partir do vencimento', () async {
      final uuid = await repositorio.criarCompra(compra());
      final parcelas = await repositorio.parcelasDe(uuid);

      expect(parcelas, hasLength(19));
      expect(parcelas.fold(0, (s, p) => s + p.valorParcela), 450000);
      expect(
        (parcelas.first.mesVencimento, parcelas.first.anoVencimento),
        (4, 2026),
      );
      expect(
        (parcelas.last.mesVencimento, parcelas.last.anoVencimento),
        (10, 2027),
      );
    });

    test('editar regera as parcelas', () async {
      final uuid = await repositorio.criarCompra(compra());
      await repositorio.editarCompra(
        uuid,
        compra(total: 120000, parcelas: 3, vencimento: Mes(2026, 5)),
      );
      final parcelas = await repositorio.parcelasDe(uuid);
      expect(parcelas.map((p) => p.valorParcela), [40000, 40000, 40000]);
      expect(parcelas.map((p) => p.mesVencimento), [5, 6, 7]);
      expect((await repositorio.buscarCompra(uuid))!.quantParcela, 3);
    });

    test('excluir apaga as parcelas', () async {
      final uuid = await repositorio.criarCompra(compra());
      await repositorio.excluirCompra(uuid);
      expect(await repositorio.buscarCompra(uuid), isNull);
      expect(await repositorio.parcelasDe(uuid), isEmpty);
    });
  });

  group('sugestão do mês de vencimento (DP-28)', () {
    Mes sugerir(int dia, {int? fechamento = 29, int? vencimento = 5}) =>
        sugerirVencimento(
          DateTime(2026, 11, dia),
          diaFechamento: fechamento,
          diaVencimento: vencimento,
        );

    test('Itaú: fecha 29, vence 5', () {
      expect(sugerir(10), Mes(2026, 12));
      expect(sugerir(29), Mes(2026, 12));
      expect(sugerir(30), Mes(2027, 1));
    });

    test('vencimento depois do fechamento vence no mesmo mês', () {
      expect(sugerir(3, fechamento: 5, vencimento: 15), Mes(2026, 11));
      expect(sugerir(6, fechamento: 5, vencimento: 15), Mes(2026, 12));
    });

    test('sem os dias, o mês seguinte', () {
      expect(sugerir(10, fechamento: null, vencimento: null), Mes(2026, 12));
    });

    test('fatura paga: a que vence a partir da data', () {
      expect(
        sugerirFaturaPaga(DateTime(2026, 10, 29), diaVencimento: 5),
        Mes(2026, 11),
      );
      expect(
        sugerirFaturaPaga(DateTime(2026, 11, 3), diaVencimento: 5),
        Mes(2026, 11),
      );
      expect(
        sugerirFaturaPaga(DateTime(2026, 11, 3), diaVencimento: null),
        Mes(2026, 11),
      );
    });
  });

  test('pagamento de fatura: criar, editar e excluir', () async {
    final uuid = await repositorio.criarPagamento((
      momento: DateTime(2026, 10, 29, 9),
      valorCentavos: 106383,
      forma: FormaPagamentoFatura.pix,
      uuidCartao: cartao,
      fatura: Mes(2026, 11),
    ));
    var pagamento = (await repositorio.buscarPagamento(uuid))!;
    expect(pagamento.tipoPagamento, 'pix');
    expect((pagamento.mesVencimento, pagamento.anoVencimento), (11, 2026));

    await repositorio.editarPagamento(uuid, (
      momento: DateTime(2026, 10, 29, 9),
      valorCentavos: 106383,
      forma: FormaPagamentoFatura.boleto,
      uuidCartao: cartao,
      fatura: Mes(2026, 11),
    ));
    pagamento = (await repositorio.buscarPagamento(uuid))!;
    expect(pagamento.tipoPagamento, 'boleto');

    await repositorio.excluirPagamento(uuid);
    expect(await repositorio.buscarPagamento(uuid), isNull);
  });

  test(
    'estorno guarda a compra original; excluí-la mantém o estorno',
    () async {
      final original = await repositorio.criarCompra(compra(parcelas: 1));
      final uuid = await repositorio.criarEstorno((
        momento: DateTime(2026, 4, 2, 15),
        descricao: 'Estorno notebook',
        valorCentavos: 10000,
        uuidCartao: cartao,
        fatura: Mes(2026, 4),
        idSubcategoria: 506,
        uuidTag: null,
        uuidCompraOriginal: original,
      ));
      expect(
        (await repositorio.buscarEstorno(uuid))!.uuidCompraFaturada,
        original,
      );

      await repositorio.excluirCompra(original);
      final estorno = (await repositorio.buscarEstorno(uuid))!;
      expect(estorno.uuidCompraFaturada, isNull);
      expect(estorno.valorEstorno, 10000);
    },
  );

  test('editar sem mudar a data mantém o fuso gravado (DP-33)', () async {
    final uuid = await repositorio.criarCompra(compra());
    fuso.minutos = 60;
    await repositorio.editarCompra(uuid, compra(descricao: 'Notebook novo'));
    expect((await repositorio.buscarCompra(uuid))!.fusoMinutos, -180);
  });

  test('a sugestão de categoria usa também o histórico do faturado', () async {
    await repositorio.criarCompra(compra(descricao: 'Kabum notebook'));
    final avista = CompraAvistaRepository(
      banco,
      relogio: RelogioFixo(DateTime(2026, 11, 8)),
      uuid: GeradorUuidSequencial(),
      fuso: FusoFixo(-180),
    );
    expect(await avista.sugerirSubcategoria('kabum'), 506);
  });
}
