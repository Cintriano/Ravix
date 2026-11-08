import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ravix/core/tema/icones.dart';

import '../../helpers/app_de_teste.dart';

void main() {
  Future<void> abrirRenda(WidgetTester tester) async {
    await montarApp(tester);
    await tester.tap(find.byIcon(Icones.settings));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Renda'));
    await tester.pumpAndSettle();
  }

  Future<void> preencher(
    WidgetTester tester,
    String salario,
    String voucher,
  ) async {
    await tester.enterText(find.widgetWithText(TextField, 'Salário'), salario);
    await tester.enterText(
      find.widgetWithText(TextField, 'Voucher/benefícios'),
      voucher,
    );
  }

  testarApp('sem renda, mostra o estado vazio', (tester) async {
    await abrirRenda(tester);
    expect(find.text('Nenhuma renda'), findsOneWidget);
  });

  testarApp('cadastrar a renda do mês atual', (tester) async {
    await abrirRenda(tester);
    await tester.tap(find.text('Cadastrar renda'));
    await tester.pumpAndSettle();
    expect(find.text('Outubro de 2026'), findsOneWidget);

    await preencher(tester, '500000', '80000');
    await tester.tap(find.text('Salvar renda'));
    await tester.pumpAndSettle();

    expect(find.text('A partir de outubro de 2026'), findsOneWidget);
    expect(
      find.textContaining(
        'Salário R\$\u00a05.000,00 · Voucher R\$\u00a0800,00',
      ),
      findsOneWidget,
    );
    expect(find.textContaining('Em vigor neste mês'), findsOneWidget);

    await tester.tap(find.byTooltip('Voltar'));
    await tester.pumpAndSettle();
    expect(
      find.text('Salário R\$\u00a05.000,00 · Voucher R\$\u00a0800,00'),
      findsOneWidget,
    );
  });

  testarApp('nova vigência num mês futuro não muda o mês atual', (
    tester,
  ) async {
    await abrirRenda(tester);
    await tester.tap(find.text('Cadastrar renda'));
    await tester.pumpAndSettle();
    await preencher(tester, '500000', '0');
    await tester.tap(find.text('Salvar renda'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Alterar renda'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Próximo mês'));
    await tester.pumpAndSettle();
    expect(find.text('Novembro de 2026'), findsOneWidget);
    await preencher(tester, '600000', '0');
    await tester.tap(find.text('Salvar renda'));
    await tester.pumpAndSettle();

    expect(find.text('A partir de novembro de 2026'), findsOneWidget);
    expect(find.text('A partir de outubro de 2026'), findsOneWidget);
    expect(
      find.textContaining(
        'Salário R\$\u00a05.000,00 · Voucher R\$\u00a00,00\nEm vigor',
      ),
      findsOneWidget,
    );
  });

  testarApp('salário vazio mostra o erro', (tester) async {
    await abrirRenda(tester);
    await tester.tap(find.text('Cadastrar renda'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Salvar renda'));
    await tester.pumpAndSettle();
    expect(find.text('Informe um salário maior que zero.'), findsOneWidget);
  });

  testarApp('remover a vigência volta ao vazio', (tester) async {
    await abrirRenda(tester);
    await tester.tap(find.text('Cadastrar renda'));
    await tester.pumpAndSettle();
    await preencher(tester, '500000', '0');
    await tester.tap(find.text('Salvar renda'));
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Remover a renda de outubro de 2026'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Remover'));
    await tester.pumpAndSettle();
    expect(find.text('Nenhuma renda'), findsOneWidget);
  });
}
