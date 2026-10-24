import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:ravix/core/ambiente.dart';
import 'package:ravix/core/datas.dart';
import 'package:ravix/data/banco.dart';
import 'package:ravix/data/compra_avista_repository.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('banco do app abre no aparelho, em WAL, com a carga', (_) async {
    final banco = abrirBancoRavix();
    addTearDown(banco.close);

    final pragmas = await banco
        .customSelect('SELECT * FROM pragma_journal_mode, pragma_foreign_keys')
        .getSingle();
    expect(pragmas.read<String>('journal_mode'), 'wal');
    expect(pragmas.read<int>('foreign_keys'), 1);
    expect(await banco.select(banco.tblSubcategoria).get(), hasLength(34));

    final compras = CompraAvistaRepository(
      banco,
      relogio: const RelogioSistema(),
      uuid: const GeradorUuidV4(),
      fuso: const FusoSistema(),
    );
    final momento = DateTime(1999, 1, 1, 12);
    final uuid = await compras.criar((
      momento: momento,
      descricao: 'Teste de integração',
      valorCentavos: 1,
      tipoPagamento: TipoPagamento.pix,
      idSubcategoria: 507,
      uuidTag: null,
    ));
    try {
      final linhas = await compras.observarMes(Mes.de(momento)).first;
      expect(linhas.map((l) => l.c.uuidCompraAvista), contains(uuid));
    } finally {
      await compras.excluir(uuid);
    }
  });
}
