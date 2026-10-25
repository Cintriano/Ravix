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
  late TagRepository tags;
  late CompraAvistaRepository compras;

  setUp(() {
    banco = bancoEmMemoria();
    relogio = RelogioFixo(DateTime.utc(2026, 10, 24, 15));
    final uuid = GeradorUuidSequencial();
    tags = TagRepository(banco, relogio: relogio, uuid: uuid);
    compras = CompraAvistaRepository(
      banco,
      relogio: relogio,
      uuid: uuid,
      fuso: FusoFixo(-180),
    );
  });
  tearDown(() => banco.close());

  Future<List<String>> nomesAtivos() async =>
      (await tags.observarAtivas().first).map((t) => t.nome).toList();

  group('criar', () {
    test('cria tag ativa com nome limpo e auditoria', () async {
      final tag = await tags.criar('  Viagem   Nordeste ');
      expect(tag.uuidTag, '00000000-0000-4000-8000-000000000001');
      expect(tag.nome, 'Viagem Nordeste');
      expect(tag.status, 'ativa');
      expect(tag.criadoEm, '2026-10-24T15:00:00Z');
      expect(tag.atualizadoEm, tag.criadoEm);
    });

    test('nome vazio é rejeitado', () async {
      await expectLater(tags.criar('   '), throwsA(isA<NomeTagVazio>()));
    });

    test('nome repetido com maiúsculas diferentes é rejeitado', () async {
      await tags.criar('Viagem');
      await expectLater(
        tags.criar('VIAGEM'),
        throwsA(isA<NomeTagRepetido>().having((e) => e.nome, 'nome', 'VIAGEM')),
      );
    });

    test('a comparação cobre letras acentuadas', () async {
      await tags.criar('Rolê');
      await expectLater(tags.criar('ROLÊ'), throwsA(isA<NomeTagRepetido>()));
    });

    test('nome de tag arquivada também conta como repetido', () async {
      final tag = await tags.criar('Viagem');
      await compras.criar(gasto(uuidTag: tag.uuidTag));
      await tags.remover(tag.uuidTag);
      await expectLater(tags.criar('viagem'), throwsA(isA<NomeTagRepetido>()));
    });

    test('mensagens de erro', () {
      expect(NomeTagVazio().toString(), contains('vazio'));
      expect(NomeTagRepetido('Viagem').toString(), contains('"Viagem"'));
    });
  });

  group('renomear', () {
    test('troca o nome e os registros acompanham', () async {
      final tag = await tags.criar('Viajem');
      await compras.criar(gasto(uuidTag: tag.uuidTag));
      relogio.avancar(const Duration(minutes: 5));

      await tags.renomear(tag.uuidTag, 'Viagem');

      final salva = (await tags.buscar(tag.uuidTag))!;
      expect(salva.nome, 'Viagem');
      expect(salva.atualizadoEm, '2026-10-24T15:05:00Z');
      final linha = (await compras.observarMes(Mes(2026, 10)).first).single;
      expect(linha.c.uuidTag, tag.uuidTag);
      expect(linha.tag, 'Viagem');
    });

    test('pode trocar só as maiúsculas do próprio nome', () async {
      final tag = await tags.criar('viagem');
      await tags.renomear(tag.uuidTag, 'Viagem');
      expect((await tags.buscar(tag.uuidTag))!.nome, 'Viagem');
    });

    test('não pode usar o nome de outra tag', () async {
      await tags.criar('Viagem');
      final outra = await tags.criar('Rolê');
      await expectLater(
        tags.renomear(outra.uuidTag, 'viagem'),
        throwsA(isA<NomeTagRepetido>()),
      );
      await expectLater(
        tags.renomear(outra.uuidTag, ''),
        throwsA(isA<NomeTagVazio>()),
      );
    });
  });

  test('conta os gastos que usam a tag', () async {
    final tag = await tags.criar('Viagem');
    expect(await tags.contarUsos(tag.uuidTag), 0);
    await compras.criar(gasto(uuidTag: tag.uuidTag));
    await compras.criar(gasto(uuidTag: tag.uuidTag));
    await compras.criar(gasto());
    expect(await tags.contarUsos(tag.uuidTag), 2);
  });

  group('remover', () {
    test('sem registros: exclui', () async {
      final tag = await tags.criar('Viagem');
      expect(await tags.remover(tag.uuidTag), RemocaoTag.excluida);
      expect(await tags.buscar(tag.uuidTag), isNull);
    });

    test('com registros: arquiva e mantém nos registros antigos', () async {
      final tag = await tags.criar('Viagem');
      await compras.criar(gasto(uuidTag: tag.uuidTag));

      expect(await tags.remover(tag.uuidTag), RemocaoTag.arquivada);

      expect((await tags.buscar(tag.uuidTag))!.status, 'arquivada');
      expect(await nomesAtivos(), isEmpty);
      final linha = (await compras.observarMes(Mes(2026, 10)).first).single;
      expect(linha.tag, 'Viagem');
    });
  });

  test('todas: ativas e arquivadas, em ordem alfabética', () async {
    final viagem = await tags.criar('viagem');
    await tags.criar('Aniversário');
    await compras.criar(gasto(uuidTag: viagem.uuidTag));
    await tags.remover(viagem.uuidTag);
    final todas = await tags.observarTodas().first;
    expect(todas.map((t) => (t.nome, t.status)), [
      ('Aniversário', 'ativa'),
      ('viagem', 'arquivada'),
    ]);
  });

  test('ativas em ordem alfabética, sem as arquivadas', () async {
    await tags.criar('viagem');
    await tags.criar('Aniversário');
    final arquivar = await tags.criar('Mudança');
    await tags.criar('rolê');
    await compras.criar(gasto(uuidTag: arquivar.uuidTag));
    await tags.remover(arquivar.uuidTag);

    expect(await nomesAtivos(), ['Aniversário', 'rolê', 'viagem']);
  });
}
