import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ravix/app.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  // Borda a borda: as barras do sistema ficam sobre o fundo do app.
  unawaited(SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge));
  LicenseRegistry.addLicense(() async* {
    final ofl = await rootBundle.loadString('assets/fonts/Inter-OFL.txt');
    yield LicenseEntryWithLineBreaks(['Inter'], ofl);
  });
  runApp(const ProviderScope(child: RavixApp()));
}
