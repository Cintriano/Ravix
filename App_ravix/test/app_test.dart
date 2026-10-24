import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ravix/app.dart';

void main() {
  testWidgets('o app sobe e mostra a tela inicial', (tester) async {
    await tester.pumpWidget(const ProviderScope(child: RavixApp()));

    expect(find.text('Ravix'), findsOneWidget);
  });
}
