import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ravix/app.dart';
import 'package:ravix/app/dependencias.dart';
import 'package:ravix/core/tema/icones.dart';
import 'package:ravix/data/recorrencia_repository.dart';

import '../../helpers/app_de_teste.dart';

void main() {
  Future<void> abrirCartoes(WidgetTester tester) async {
    await montarApp(tester);
    await tester.tap(find.byIcon(Icones.settings));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Cartões'));
    await tester.pumpAndSettle();
  }

  Finder campo(String rotulo) => find.widgetWithText(TextField, rotulo);

  Future<void> cadastrar(
    WidgetTester tester, {
    String nome = 'Itaú',
    String limite = '590000',
  }) async {
    await tester.tap(find.text('Novo cartão'));
    await tester.pumpAndSettle();
    await tester.enterText(campo('Nome'), nome);
    await tester.enterText(campo('Limite'), limite);
    await tester.enterText(campo('Dia de fechamento'), '29');
    await tester.enterText(campo('Dia de vencimento'), '5');
    await tester.enterText(campo('Final do cartão'), '9827');
    await tester.enterText(campo('CNPJ do emissor'), '60872504000123');
    await tester.ensureVisible(find.text('Cadastrar cartão'));
    await tester.tap(find.text('Cadastrar cartão'));
    await tester.pumpAndSettle();
    // Espera o aviso "Cartão cadastrado." sumir: ele cobre o pé da tela.
    await tester.pump(const Duration(seconds: 5));
    await tester.pumpAndSettle();
  }

  testarApp('sem cartões, mostra o estado vazio', (tester) async {
    await abrirCartoes(tester);
    expect(find.text('Nenhum cartão'), findsOneWidget);
  });

  testarApp('cadastrar um cartão', (tester) async {
    await abrirCartoes(tester);
    await cadastrar(tester);

    expect(find.text('Itaú •••• 9827'), findsOneWidget);
    expect(
      find.text('Limite R\$\u00a05.900,00 · fecha dia 29 · vence dia 5'),
      findsOneWidget,
    );

    await tester.tap(find.byTooltip('Voltar'));
    await tester.pumpAndSettle();
    expect(find.text('1 cartão'), findsOneWidget);
  });

  testarApp('campos inválidos mostram os erros', (tester) async {
    await abrirCartoes(tester);
    await tester.tap(find.text('Novo cartão'));
    await tester.pumpAndSettle();
    await tester.enterText(campo('Dia de fechamento'), '45');
    await tester.enterText(campo('CNPJ do emissor'), '60872504000124');
    await tester.ensureVisible(find.text('Cadastrar cartão'));
    await tester.tap(find.text('Cadastrar cartão'));
    await tester.pumpAndSettle();

    expect(find.text('Informe o nome do cartão.'), findsOneWidget);
    expect(find.text('Informe um limite maior que zero.'), findsOneWidget);
    expect(find.text('Use um dia de 1 a 31.'), findsOneWidget);
    expect(find.text('CNPJ inválido.'), findsOneWidget);
  });

  testarApp('editar o limite', (tester) async {
    await abrirCartoes(tester);
    await cadastrar(tester);
    await tester.tap(find.text('Itaú •••• 9827'));
    await tester.pumpAndSettle();
    expect(find.text('Editar cartão'), findsOneWidget);

    await tester.enterText(campo('Limite'), '700000');
    await tester.ensureVisible(find.text('Salvar cartão'));
    await tester.tap(find.text('Salvar cartão'));
    await tester.pumpAndSettle();
    expect(
      find.text('Limite R\$\u00a07.000,00 · fecha dia 29 · vence dia 5'),
      findsOneWidget,
    );
  });

  testarApp('cartão sem registros é excluído', (tester) async {
    await abrirCartoes(tester);
    await cadastrar(tester);
    await tester.tap(find.byTooltip('Remover Itaú'));
    await tester.pumpAndSettle();
    expect(find.text('Excluir o cartão?'), findsOneWidget);
    await tester.tap(find.widgetWithText(FilledButton, 'Excluir'));
    await tester.pumpAndSettle();
    expect(find.text('Nenhum cartão'), findsOneWidget);
  });

  testarApp('arquivado aparece no fim e pode ser reativado', (tester) async {
    await abrirCartoes(tester);
    await cadastrar(tester);
    final container = ProviderScope.containerOf(
      tester.element(find.byType(RavixApp)),
    );
    final uuid = (await tester.runAsync(
      () => container.read(cartaoRepositoryProvider).observarAtivos().first,
    ))!.single.uuidCartaoCredito;
    // Uma recorrência no cartão faz a remoção arquivar.
    await tester.runAsync(
      () => container.read(recorrenciaRepositoryProvider).criar((
        descricao: 'Netflix',
        valorCentavos: 5590,
        idSubcategoria: 601,
        periodicidade: Periodicidade.mensal,
        diaCobranca: 30,
        inicio: DateTime(2026, 10, 30),
        fim: null,
        uuidCartao: uuid,
        tipoPagamento: null,
        documentoBeneficiario: null,
      )),
    );
    await tester.tap(find.byTooltip('Remover Itaú'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Arquivar'));
    await tester.pumpAndSettle();

    expect(find.text('ARQUIVADOS'), findsOneWidget);
    expect(find.byTooltip('Remover Itaú'), findsNothing);
    await tester.tap(find.text('Reativar'));
    await tester.pumpAndSettle();
    expect(find.text('ARQUIVADOS'), findsNothing);
    expect(find.byTooltip('Remover Itaú'), findsOneWidget);
  });
}
