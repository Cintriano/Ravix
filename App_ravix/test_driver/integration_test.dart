// Driver dos testes no aparelho em modo profile. Os números do teste de
// desempenho saem em build/integration_response_data.json.
//
// flutter drive --profile --driver test_driver/integration_test.dart \
//   --target integration_test/desempenho_test.dart -d <aparelho>
import 'package:integration_test/integration_test_driver.dart';

Future<void> main() => integrationDriver();
