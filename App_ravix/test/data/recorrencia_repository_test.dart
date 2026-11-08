import 'package:drift/drift.dart' show OrderingTerm;
import 'package:flutter_test/flutter_test.dart';
import 'package:ravix/core/datas.dart';
import 'package:ravix/data/banco.dart';
import 'package:ravix/data/cartao_repository.dart';
import 'package:ravix/data/compra_avista_repository.dart';
import 'package:ravix/data/recorrencia_repository.dart';

import '../helpers/ambiente_falso.dart';
import '../helpers/banco_de_teste.dart';

void main() {
  late BancoRavix banco;
  late RelogioFixo relogio;
  late RecorrenciaRepository repositorio;
  late String cartao;

  setUp(() async {
    banco = bancoEmMemoria();
    relogio = RelogioFixo(DateTime(2026, 11, 8, 12));
    final uuid = GeradorUuidSequencial();
    repositorio = RecorrenciaRepository(
      banco,
      relogio: relogio,
      uuid: uuid,
      fuso: FusoFixo(-180),
    );
    cartao = (await CartaoRepository(banco, relogio: relogio, uuid: uuid).criar(
      (
        nome: 'Itaú',
        limiteCentavos: 590000,
        diaFechamento: 29,
        diaVencimento: 5,
        finalCartao: null,
        cnpjEmissor: null,
      ),
    )).uuidCartaoCredito;
  });
  tearDown(() => banco.close());

  DadosRecorrencia aluguel({
    int dia = 25,
    DateTime? inicio,
    DateTime? fim,
    Periodicidade periodicidade = Periodicidade.mensal,
    int valor = 150000,
  }) => (
    descricao: 'Aluguel',
    valorCentavos: valor,
    idSubcategoria: 701,
    periodicidade: periodicidade,
    diaCobranca: dia,
    inicio: inicio ?? DateTime(2026, 9),
    fim: fim,
    uuidCartao: null,
    tipoPagamento: TipoPagamento.pix,
    documentoBeneficiario: null,
  );

  DadosRecorrencia netflix({int dia = 10, DateTime? inicio}) => (
    descricao: 'Netflix',
    valorCentavos: 5590,
    idSubcategoria: 601,
    periodicidade: Periodicidade.mensal,
    diaCobranca: dia,
    inicio: inicio ?? DateTime(2026, 9, 10),
    fim: null,
    uuidCartao: cartao,
    tipoPagamento: null,
    documentoBeneficiario: null,
  );

  Future<Recorrencia> regra(DadosRecorrencia dados) async =>
      (await repositorio.buscar(await repositorio.criar(dados)))!;

  group('ocorrências no mês', () {
    test('dia 31 cai no último dia dos meses curtos', () async {
      final r = await regra(aluguel(dia: 31, inicio: DateTime(2026)));
      expect(ocorrenciasNoMes(r, Mes(2027, 2)), [DateTime(2027, 2, 28)]);
      expect(ocorrenciasNoMes(r, Mes(2026, 4)), [DateTime(2026, 4, 30)]);
    });

    test('respeita o início e o fim', () async {
      final r = await regra(
        aluguel(inicio: DateTime(2026, 9), fim: DateTime(2026, 11, 20)),
      );
      expect(ocorrenciasNoMes(r, Mes(2026, 8)), isEmpty);
      expect(ocorrenciasNoMes(r, Mes(2026, 10)), [DateTime(2026, 10, 25)]);
      expect(ocorrenciasNoMes(r, Mes(2026, 11)), isEmpty);
    });

    test('cobrança antes do dia de início não conta', () async {
      final r = await regra(aluguel(dia: 10, inicio: DateTime(2026, 10, 24)));
      expect(ocorrenciasNoMes(r, Mes(2026, 10)), isEmpty);
      expect(ocorrenciasNoMes(r, Mes(2026, 11)), [DateTime(2026, 11, 10)]);
    });

    test('anual cobra só no mês de início', () async {
      final r = await regra(
        aluguel(periodicidade: Periodicidade.anual, inicio: DateTime(2026, 3)),
      );
      expect(ocorrenciasNoMes(r, Mes(2027, 3)), [DateTime(2027, 3, 25)]);
      expect(ocorrenciasNoMes(r, Mes(2027, 4)), isEmpty);
    });
  });

  group('à vista (DP-25)', () {
    test('fica prevista até ser registrada', () async {
      await repositorio.criar(aluguel());
      final previstas = await repositorio.previstasAvista(Mes(2026, 11));
      expect(previstas.single.ocorrencia, DateTime(2026, 11, 25));

      await repositorio.registrarAvista(
        previstas.single,
        momento: DateTime(2026, 11, 27, 9),
        valorCentavos: 151000,
        tipoPagamento: TipoPagamento.boleto,
      );
      expect(await repositorio.previstasAvista(Mes(2026, 11)), isEmpty);

      final gasto = await banco.select(banco.tblCompraAvista).getSingle();
      expect(gasto.valorCompraAvista, 151000);
      expect(gasto.tipoPagamento, 'boleto');
      expect(gasto.timestampCompraAvista, '2026-11-27T09:00:00');
      expect(gasto.ocorrencia, '2026-11-25');
    });

    test('pular tira a prevista e apaga o lançamento do mês', () async {
      await repositorio.criar(aluguel());
      final prevista = (await repositorio.previstasAvista(Mes(2026, 10)))
          .single;
      await repositorio.registrarAvista(
        prevista,
        momento: DateTime(2026, 10, 25),
        valorCentavos: 150000,
        tipoPagamento: TipoPagamento.pix,
      );
      await repositorio.pular(
        prevista.regra.uuidRecorrencia,
        prevista.ocorrencia,
      );
      expect(await banco.select(banco.tblCompraAvista).get(), isEmpty);
      expect(await repositorio.previstasAvista(Mes(2026, 10)), isEmpty);
      expect(await repositorio.previstasAvista(Mes(2026, 11)), hasLength(1));
    });

    test('pausada não aparece', () async {
      final uuid = await repositorio.criar(aluguel());
      await repositorio.mudarSituacao(uuid, SituacaoRecorrencia.pausada);
      expect(await repositorio.previstasAvista(Mes(2026, 11)), isEmpty);
    });
  });

  group('faturado (DP-25)', () {
    test('cada cobrança até hoje vira lançamento sozinha, uma vez', () async {
      await repositorio.criar(netflix());
      // 10/09, 10/10 e 10/11; hoje é 08/11, então até 10/10.
      expect(await repositorio.materializarFaturadas(), 2);
      expect(await repositorio.materializarFaturadas(), 0);

      final compras = await (banco.select(
        banco.tblCompraFaturada,
      )..orderBy([(c) => OrderingTerm.asc(c.ocorrencia)])).get();
      expect(compras.map((c) => c.ocorrencia), ['2026-09-10', '2026-10-10']);
      // 10/10, antes do fechamento (29): fatura que vence em novembro.
      expect(compras.last.mesVencimento, 11);
      expect(await banco.select(banco.tblParcela).get(), hasLength(2));

      relogio.momento = DateTime(2026, 11, 10, 8);
      expect(await repositorio.materializarFaturadas(), 1);
    });

    test('a cobrança deste mês fica prevista até o dia', () async {
      await repositorio.criar(netflix());
      await repositorio.materializarFaturadas();
      final previstas = await repositorio.previstasFaturadas(Mes(2026, 11));
      expect(previstas.single.ocorrencia, DateTime(2026, 11, 10));
    });
  });

  test('este e os próximos: encerra na véspera e cria a regra nova', () async {
    final antiga = await repositorio.criar(aluguel());
    final nova = await repositorio.alterarDaqui(
      antiga,
      DateTime(2026, 12, 25),
      aluguel(valor: 160000, inicio: DateTime(2026, 12, 25)),
    );

    final velha = (await repositorio.buscar(antiga))!;
    expect(velha.dataFim, '2026-12-24');
    expect(ocorrenciasNoMes(velha, Mes(2026, 11)), [DateTime(2026, 11, 25)]);
    expect(ocorrenciasNoMes(velha, Mes(2026, 12)), isEmpty);

    final previstas = await repositorio.previstasAvista(Mes(2026, 12));
    expect(previstas.single.regra.uuidRecorrencia, nova);
    expect(previstas.single.regra.valorRecorrencia, 160000);
  });

  test('editar daqui pra frente não duplica a cobrança do mês', () async {
    final antiga = await repositorio.criar(aluguel(dia: 5));
    // Hoje é 08/11: a cobrança de 05/11 ficou com a regra antiga.
    final nova = await repositorio.editarDaquiPraFrente(
      antiga,
      valorCentavos: 160000,
      diaCobranca: 5,
      idSubcategoria: 701,
    );
    final novembro = await repositorio.previstasAvista(Mes(2026, 11));
    expect(novembro.single.regra.uuidRecorrencia, antiga);
    final dezembro = await repositorio.previstasAvista(Mes(2026, 12));
    expect(dezembro.single.regra.uuidRecorrencia, nova);
    expect(dezembro.single.regra.valorRecorrencia, 160000);
  });

  test('alterar desde o início atualiza a própria regra', () async {
    final uuid = await repositorio.criar(aluguel(inicio: DateTime(2026, 9)));
    final mesma = await repositorio.alterarDaqui(
      uuid,
      DateTime(2026, 9),
      aluguel(valor: 170000, inicio: DateTime(2026, 9)),
    );
    expect(mesma, uuid);
    final regra = (await repositorio.buscar(uuid))!;
    expect(regra.valorRecorrencia, 170000);
    expect(regra.status, 'ativa');
    expect(await banco.select(banco.tblRecorrencia).get(), hasLength(1));
  });

  test('encerrar antes do início cancela a regra inteira', () async {
    final uuid = await repositorio.criar(aluguel(inicio: DateTime(2026, 9)));
    await repositorio.encerrarAntesDe(uuid, DateTime(2026, 9));
    expect((await repositorio.buscar(uuid))!.status, 'cancelada');
    expect(await repositorio.previstasAvista(Mes(2026, 11)), isEmpty);
  });

  test('remover: sem lançamentos exclui; com lançamentos cancela', () async {
    final livre = await repositorio.criar(aluguel());
    final usada = await repositorio.criar(netflix());
    await repositorio.materializarFaturadas();

    expect(await repositorio.remover(livre), isTrue);
    expect(await repositorio.buscar(livre), isNull);
    expect(await repositorio.remover(usada), isFalse);
    final cancelada = (await repositorio.buscar(usada))!;
    expect(cancelada.status, 'cancelada');
    expect(cancelada.dataFim, '2026-11-08');
  });
}
