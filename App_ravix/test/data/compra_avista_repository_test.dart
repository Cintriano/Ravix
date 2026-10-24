import 'package:flutter_test/flutter_test.dart';
import 'package:ravix/core/datas.dart';
import 'package:ravix/data/banco.dart';
import 'package:ravix/data/compra_avista_repository.dart';
import 'package:ravix/data/tag_repository.dart';

import '../helpers/ambiente_falso.dart';
import '../helpers/banco_de_teste.dart';

void main() {
  late BancoRavix banco;
  late RelogioFixo relogio;
  late FusoFixo fuso;
  late CompraAvistaRepository compras;
  late TagRepository tags;

  final outubro = Mes(2026, 10);

  setUp(() {
    banco = bancoEmMemoria();
    relogio = RelogioFixo(DateTime.utc(2026, 10, 24, 15));
    fuso = FusoFixo(-180);
    final uuid = GeradorUuidSequencial();
    compras = CompraAvistaRepository(
      banco,
      relogio: relogio,
      uuid: uuid,
      fuso: fuso,
    );
    tags = TagRepository(banco, relogio: relogio, uuid: uuid);
  });
  tearDown(() => banco.close());

  Future<List<CompraDoMes>> doMes(
    Mes mes, [
    FiltroCompras filtro = semFiltro,
  ]) => compras.observarMes(mes, filtro: filtro).first;

  group('TipoPagamento', () {
    test('ida e volta pelo código', () {
      for (final tipo in TipoPagamento.values) {
        expect(TipoPagamento.deCodigo(tipo.codigo), tipo);
      }
      expect(() => TipoPagamento.deCodigo('credito'), throwsArgumentError);
    });
  });

  group('criar', () {
    test('grava os campos calculados', () async {
      final uuid = await compras.criar(
        gasto(
          momento: DateTime(2026, 10, 15, 8, 30, 12, 999),
          descricao: '  Açaí da   Praça ',
          valorCentavos: 1890,
          tipoPagamento: TipoPagamento.debito,
          idSubcategoria: 105,
        ),
      );

      final salvo = (await compras.buscar(uuid))!;
      expect(uuid, '00000000-0000-4000-8000-000000000001');
      expect(salvo.timestampCompraAvista, '2026-10-15T08:30:12');
      expect(salvo.fusoMinutos, -180);
      expect(salvo.descricao, 'Açaí da   Praça');
      expect(salvo.descricaoNormalizada, 'acai da praca');
      expect(salvo.valorCompraAvista, 1890);
      expect(salvo.tipoPagamento, 'debito');
      expect(salvo.idSubcategoria, 105);
      expect(salvo.uuidTag, isNull);
      expect(salvo.criadoEm, '2026-10-24T15:00:00Z');
      expect(salvo.atualizadoEm, salvo.criadoEm);
    });

    test('aceita data futura', () async {
      final uuid = await compras.criar(gasto(momento: DateTime(2027, 3)));
      expect(
        (await compras.buscar(uuid))!.timestampCompraAvista,
        '2027-03-01T00:00:00',
      );
    });

    test('buscar devolve null para UUID inexistente', () async {
      expect(await compras.buscar('nao-existe'), isNull);
    });
  });

  group('mês', () {
    test('31/10 23:59:59 entra em outubro; 01/11 00:00:00 não', () async {
      await compras.criar(
        gasto(momento: DateTime(2026, 10, 31, 23, 59, 59), descricao: 'fim'),
      );
      await compras.criar(
        gasto(momento: DateTime(2026, 11), descricao: 'novembro'),
      );
      await compras.criar(
        gasto(momento: DateTime(2026, 10), descricao: 'inicio'),
      );

      final descricoes = (await doMes(outubro)).map((c) => c.c.descricao);
      expect(descricoes, ['fim', 'inicio']);
      expect((await doMes(Mes(2026, 11))).map((c) => c.c.descricao), [
        'novembro',
      ]);
    });

    test('traz subcategoria, categoria e tag pelo join', () async {
      final viagem = await tags.criar('Viagem');
      await compras.criar(gasto(idSubcategoria: 302, uuidTag: viagem.uuidTag));

      final linha = (await doMes(outubro)).single;
      expect(linha.subcategoria, 'Mobilidade Urbana');
      expect(linha.idCategoria, 3);
      expect(linha.categoria, 'Transporte');
      expect(linha.tag, 'Viagem');
    });
  });

  group('filtros e acumulado', () {
    late String viagem;

    setUp(() async {
      viagem = (await tags.criar('Viagem')).uuidTag;
      final dia = DateTime(2026, 10, 10);
      await compras.criar(gasto(momento: dia, valorCentavos: 100));
      await compras.criar(
        gasto(momento: dia, idSubcategoria: 103, valorCentavos: 200),
      );
      await compras.criar(
        gasto(
          momento: dia,
          idSubcategoria: 103,
          valorCentavos: 400,
          uuidTag: viagem,
        ),
      );
      await compras.criar(
        gasto(
          momento: dia,
          idSubcategoria: 302,
          valorCentavos: 800,
          uuidTag: viagem,
        ),
      );
      await compras.criar(
        gasto(momento: DateTime(2026, 9, 30), valorCentavos: 1600),
      );
    });

    int soma(List<CompraDoMes> linhas) =>
        linhas.fold(0, (t, l) => t + l.c.valorCompraAvista);

    test('sem filtro traz o mês inteiro', () async {
      expect(soma(await doMes(outubro)), 1500);
    });

    test('filtro por categoria', () async {
      final linhas = await doMes(outubro, (
        idCategoria: 1,
        idSubcategoria: null,
        uuidTag: null,
      ));
      expect(soma(linhas), 700);
    });

    test('filtro por subcategoria', () async {
      final linhas = await doMes(outubro, (
        idCategoria: null,
        idSubcategoria: 103,
        uuidTag: null,
      ));
      expect(soma(linhas), 600);
    });

    test('filtro por tag', () async {
      final linhas = await doMes(outubro, (
        idCategoria: null,
        idSubcategoria: null,
        uuidTag: viagem,
      ));
      expect(soma(linhas), 1200);
    });

    test('filtros combinados', () async {
      final linhas = await doMes(outubro, (
        idCategoria: 1,
        idSubcategoria: 103,
        uuidTag: viagem,
      ));
      expect(soma(linhas), 400);
      final nenhum = await doMes(outubro, (
        idCategoria: 3,
        idSubcategoria: 103,
        uuidTag: null,
      ));
      expect(nenhum, isEmpty);
    });

    test('acumulado soma o mês e ignora os filtros', () async {
      expect(await compras.observarAcumulado(outubro).first, 1500);
      expect(await compras.observarAcumulado(Mes(2026, 9)).first, 1600);
      expect(await compras.observarAcumulado(Mes(2026, 12)).first, 0);
    });
  });

  group('sugestão de subcategoria', () {
    Future<void> registrar(String descricao, int sub, DateTime momento) =>
        compras.criar(
          gasto(descricao: descricao, idSubcategoria: sub, momento: momento),
        );

    test('sem histórico não sugere', () async {
      expect(await compras.sugerirSubcategoria('padaria'), isNull);
    });

    test('menos de 3 caracteres não consulta', () async {
      await registrar('Pão', 101, DateTime(2026, 10));
      expect(await compras.sugerirSubcategoria('pa'), isNull);
      expect(await compras.sugerirSubcategoria('  p  '), isNull);
    });

    test('busca por "contém" e ignora acentos', () async {
      await registrar('Açaí do Parque', 105, DateTime(2026, 10));
      expect(await compras.sugerirSubcategoria('acai'), 105);
      expect(await compras.sugerirSubcategoria('PARQUE'), 105);
      expect(await compras.sugerirSubcategoria('do pa'), 105);
      expect(await compras.sugerirSubcategoria('pizza'), isNull);
    });

    test('a subcategoria mais frequente vence', () async {
      await registrar('Uber', 302, DateTime(2026, 10));
      await registrar('Uber', 302, DateTime(2026, 10, 2));
      await registrar('Uber Eats', 104, DateTime(2026, 10, 3));
      expect(await compras.sugerirSubcategoria('uber'), 302);
    });

    test('no empate, a usada mais recentemente vence', () async {
      await registrar('Mercado Livre', 507, DateTime(2026, 10));
      await registrar('Mercado Central', 102, DateTime(2026, 10, 20));
      expect(await compras.sugerirSubcategoria('mercado'), 102);
    });

    test('% e _ digitados não viram curinga', () async {
      await registrar('Loja abcde', 507, DateTime(2026, 10));
      // Como curingas, "a_c" e "a%e" casariam com "abcde".
      expect(await compras.sugerirSubcategoria('a_c'), isNull);
      expect(await compras.sugerirSubcategoria('a%e'), isNull);
      expect(await compras.sugerirSubcategoria('%%%'), isNull);
      expect(await compras.sugerirSubcategoria('abc'), 507);
    });
  });

  group('editar e excluir', () {
    test('atualiza atualizado_em e mantém criado_em', () async {
      final uuid = await compras.criar(gasto());
      relogio.avancar(const Duration(hours: 2));

      await compras.editar(
        uuid,
        gasto(descricao: 'Padaria Nova', valorCentavos: 999),
      );

      final salvo = (await compras.buscar(uuid))!;
      expect(salvo.descricao, 'Padaria Nova');
      expect(salvo.descricaoNormalizada, 'padaria nova');
      expect(salvo.valorCompraAvista, 999);
      expect(salvo.criadoEm, '2026-10-24T15:00:00Z');
      expect(salvo.atualizadoEm, '2026-10-24T17:00:00Z');
    });

    test('mantém o fuso gravado se a data não mudar', () async {
      final uuid = await compras.criar(gasto());
      fuso.minutos = 540;

      await compras.editar(uuid, gasto(descricao: 'outra'));

      expect((await compras.buscar(uuid))!.fusoMinutos, -180);
    });

    test('usa o fuso atual se a data mudar', () async {
      final uuid = await compras.criar(gasto());
      fuso.minutos = 540;

      await compras.editar(uuid, gasto(momento: DateTime(2026, 10, 16)));

      final salvo = (await compras.buscar(uuid))!;
      expect(salvo.timestampCompraAvista, '2026-10-16T00:00:00');
      expect(salvo.fusoMinutos, 540);
    });

    test('troca e remove a tag', () async {
      final viagem = await tags.criar('Viagem');
      final uuid = await compras.criar(gasto());

      await compras.editar(uuid, gasto(uuidTag: viagem.uuidTag));
      expect((await compras.buscar(uuid))!.uuidTag, viagem.uuidTag);

      await compras.editar(uuid, gasto());
      expect((await compras.buscar(uuid))!.uuidTag, isNull);
    });

    test('editar gasto inexistente lança StateError', () async {
      await expectLater(
        compras.editar('nao-existe', gasto()),
        throwsStateError,
      );
    });

    test('excluir apaga o registro', () async {
      final uuid = await compras.criar(gasto());
      await compras.excluir(uuid);
      expect(await compras.buscar(uuid), isNull);
    });
  });

  group('streams', () {
    test('inserir, editar e excluir emitem o novo resultado', () async {
      final emissoes = compras
          .observarMes(outubro)
          .map((linhas) => linhas.map((l) => l.c.descricao).toList());
      final acumulados = compras.observarAcumulado(outubro);

      final esperado = expectLater(
        emissoes,
        emitsInOrder([
          isEmpty,
          ['Padaria do Zé'],
          ['Editada'],
          isEmpty,
        ]),
      );
      final esperadoAcumulado = expectLater(
        acumulados,
        emitsInOrder([0, 1250, 500, 0]),
      );

      await pumpEventQueue();
      final uuid = await compras.criar(gasto());
      await pumpEventQueue();
      await compras.editar(
        uuid,
        gasto(descricao: 'Editada', valorCentavos: 500),
      );
      await pumpEventQueue();
      await compras.excluir(uuid);

      await esperado;
      await esperadoAcumulado;
    });
  });
}
