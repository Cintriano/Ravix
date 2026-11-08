import 'package:ravix/app/dependencias.dart';
import 'package:ravix/core/datas.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'mes_selecionado.g.dart';

/// Seletor de mês global (E01-F02-T02). As abas leem este estado; nenhuma tem
/// filtro de mês próprio. Aceita meses passados e futuros (DP-9).
@Riverpod(keepAlive: true)
final class MesSelecionado extends _$MesSelecionado {
  @override
  Mes build() => Mes.de(ref.read(relogioProvider).agora());

  /// Vai para o mês seguinte.
  void avancar() => state = state.proximo;

  /// Volta para o mês anterior.
  void voltar() => state = state.anterior;

  /// Vai para [mes].
  // Método, e não setter, como avancar e voltar.
  // ignore: use_setters_to_change_properties
  void ir(Mes mes) => state = mes;

  /// Volta para o mês atual.
  void irParaHoje() => state = Mes.de(ref.read(relogioProvider).agora());
}
