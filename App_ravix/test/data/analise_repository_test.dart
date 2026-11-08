import 'package:flutter_test/flutter_test.dart';
import 'package:ravix/core/datas.dart';
import 'package:ravix/data/analise_repository.dart';
import 'package:ravix/data/banco.dart';
import 'package:ravix/data/cartao_repository.dart';
import 'package:ravix/data/compra_avista_repository.dart';
import 'package:ravix/data/faturado_repository.dart';
import 'package:ravix/data/tag_repository.dart';

import '../helpers/ambiente_falso.dart';
import '../helpers/banco_de_teste.dart';

void main() {
  late BancoRavix banco;
  late AnaliseRepository analise;
  late CompraAvistaRepository avista;
  late FaturadoRepository faturado;
  late TagRepository tags;
  late String cartao;

  setUp(() async {
    banco = bancoEmMemoria();
    final relogio = RelogioFixo(DateTime(2026, 11, 8, 12));
    final uuid = GeradorUuidSequencial();
    final fuso = FusoFixo(-180);
    analise = AnaliseRepository(banco);
    avista = CompraAvistaRepository(
      banco,
      relogio: relogio,
      uuid: uuid,
      fuso: fuso,
    );
    faturado = FaturadoRepository(
      banco,
      relogio: relogio,
      uuid: uuid,
      fuso: fuso,
    );
    tags = TagRepository(banco, relogio: relogio, uuid: uuid);
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

  Future<void> passagem({String? tag}) => faturado.criarCompra((
    momento: DateTime(2026, 10, 1, 10),
    descricao: 'Passagem',
    valorTotalCentavos: 120000,
    parcelas: 6,
    uuidCartao: cartao,
    vencimento: Mes(2026, 10),
    idSubcategoria: 405,
    uuidTag: tag,
  ));

  Future<void> estorno({String? tag, int valor = 10000}) =>
      faturado.criarEstorno((
        momento: DateTime(2026, 10, 20),
        descricao: 'Taxa devolvida',
        valorCentavos: valor,
        uuidCartao: cartao,
        fatura: Mes(2026, 11),
        idSubcategoria: 405,
        uuidTag: tag,
        uuidCompraOriginal: null,
      ));

  test('à vista do mês por subcategoria', () async {
    await avista.criar(
      gasto(momento: DateTime(2026, 11, 2), valorCentavos: 1000),
    );
    await avista.criar(
      gasto(
        momento: DateTime(2026, 11, 3),
        valorCentavos: 5000,
        idSubcategoria: 103,
      ),
    );
    await avista.criar(
      gasto(momento: DateTime(2026, 10, 3), valorCentavos: 9999),
    );
    final linhas = await analise.observarAvista(Mes(2026, 11)).first;
    expect(linhas.map((l) => (l.idSubcategoria, l.total)), [
      (103, 5000),
      (101, 1000),
    ]);
    final categorias = agruparPorCategoria(linhas);
    expect(categorias.single.categoria, 'Alimentação');
    expect(categorias.single.total, 6000);
  });

  test('faturas do mês por subcategoria abatem os estornos', () async {
    await passagem();
    await estorno();
    final linhas = await analise.observarFaturada(Mes(2026, 11)).first;
    // Parcela de 200,00 menos o estorno de 100,00.
    expect(linhas.single.total, 10000);
  });

  group('visão por tag', () {
    test('parcelado: pago até agora e total do parcelamento', () async {
      final viagem = (await tags.criar('Viagem')).uuidTag;
      await passagem(tag: viagem);
      await avista.criar(
        gasto(
          momento: DateTime(2026, 10, 2),
          valorCentavos: 8000,
          idSubcategoria: 103,
          uuidTag: viagem,
        ),
      );
      await estorno(tag: viagem, valor: 2000);
      await avista.criar(gasto(valorCentavos: 777));

      final linhas = await analise.observarTag(viagem, Mes(2026, 11)).first;
      final porSub = {
        for (final l in linhas) l.idSubcategoria: (l.pago, l.total),
      };
      // Faturas de outubro e novembro: 2 × 200,00 pagos de 1.200,00; o
      // estorno abate dos dois.
      expect(porSub[405], (40000 - 2000, 120000 - 2000));
      expect(porSub[103], (8000, 8000));
      expect(porSub.length, 2);
    });

    test('tag usada só no cartão é arquivada, não excluída', () async {
      final viagem = (await tags.criar('Viagem')).uuidTag;
      await passagem(tag: viagem);
      expect(await tags.contarUsos(viagem), 1);
      expect(await tags.remover(viagem), RemocaoTag.arquivada);
    });
  });
}
