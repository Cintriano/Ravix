import 'package:flutter_test/flutter_test.dart';
import 'package:ravix/core/datas.dart';
import 'package:ravix/core/tema/icones.dart';
import 'package:ravix/core/valor.dart';
import 'package:ravix/data/cartao_repository.dart';
import 'package:ravix/data/compra_avista_repository.dart';
import 'package:ravix/data/faturado_repository.dart';
import 'package:ravix/data/tag_repository.dart';

import '../../helpers/ambiente_falso.dart';
import '../../helpers/app_de_teste.dart';
import '../../helpers/banco_de_teste.dart';

void main() {
  /// Hoje é 24/10/2026. Outubro: Padaria R$ 10 e Refeição R$ 40 no à
  /// vista, e uma passagem de R$ 1.200 em 6x com a tag Viagem, a partir
  /// da fatura de outubro.
  Future<void> abrir(WidgetTester tester, {String? aba = 'À vista'}) async {
    final banco = bancoEmMemoria();
    addTearDown(banco.close);
    final relogio = RelogioFixo(agoraDosTestes);
    final uuid = GeradorUuidSequencial();
    final fuso = FusoFixo(-180);
    await tester.runAsync(() async {
      final compras = CompraAvistaRepository(
        banco,
        relogio: relogio,
        uuid: uuid,
        fuso: fuso,
      );
      await compras.criar(
        gasto(momento: DateTime(2026, 10, 3, 9), valorCentavos: 1000),
      );
      await compras.criar(
        gasto(
          momento: DateTime(2026, 10, 3, 12),
          valorCentavos: 4000,
          idSubcategoria: 103,
        ),
      );
      final viagem = (await TagRepository(
        banco,
        relogio: relogio,
        uuid: uuid,
      ).criar('Viagem')).uuidTag;
      final itau =
          (await CartaoRepository(banco, relogio: relogio, uuid: uuid).criar((
            nome: 'Itaú',
            limiteCentavos: 590000,
            diaFechamento: 29,
            diaVencimento: 5,
            finalCartao: null,
            cnpjEmissor: null,
          ))).uuidCartaoCredito;
      await FaturadoRepository(
        banco,
        relogio: relogio,
        uuid: uuid,
        fuso: fuso,
      ).criarCompra((
        momento: DateTime(2026, 9, 20, 10),
        descricao: 'Passagem',
        valorTotalCentavos: 120000,
        parcelas: 6,
        uuidCartao: itau,
        vencimento: Mes(2026, 10),
        idSubcategoria: 405,
        uuidTag: viagem,
      ));
    });
    await montarApp(tester, banco: banco, aba: aba);
  }

  testarApp('à vista por categoria, com subcategorias e seletor', (
    tester,
  ) async {
    await abrir(tester);
    await tester.tap(find.text('Ver por categoria'));
    await tester.pumpAndSettle();

    expect(find.text('GASTOS À VISTA POR CATEGORIA'), findsOneWidget);
    expect(find.text(formatarCentavos(5000)), findsWidgets);
    expect(find.text('Alimentação'), findsOneWidget);
    expect(find.text('Refeição'), findsNothing);

    await tester.tap(find.text('Alimentação'));
    await tester.pumpAndSettle();
    expect(find.text('Refeição'), findsOneWidget);
    expect(find.text('80%'), findsOneWidget);

    await tester.tap(find.text('Subcategoria'));
    await tester.pumpAndSettle();
    expect(find.text('Padaria'), findsOneWidget);
    expect(find.text('Alimentação'), findsNWidgets(2));
  });

  testarApp('faturas por categoria', (tester) async {
    await abrir(tester, aba: 'Faturada');
    await tester.tap(find.text('Ver por categoria'));
    await tester.pumpAndSettle();
    expect(find.text('FATURAS POR CATEGORIA'), findsOneWidget);
    expect(find.text('Lazer'), findsOneWidget);
    expect(find.text(formatarCentavos(20000)), findsWidgets);
  });

  testarApp('visão da tag: pago até agora e total do parcelamento', (
    tester,
  ) async {
    await abrir(tester);
    await tester.tap(find.byIcon(Icones.settings));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Tags'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Viagem'));
    await tester.pumpAndSettle();

    expect(find.text('Pago até agora'), findsOneWidget);
    expect(find.text(formatarCentavos(20000)), findsOneWidget);
    expect(
      find.text('de ${formatarCentavos(120000)} no total do parcelamento'),
      findsOneWidget,
    );
    expect(
      find.text('${formatarCentavos(20000)} de ${formatarCentavos(120000)}'),
      findsOneWidget,
    );
  });
}
