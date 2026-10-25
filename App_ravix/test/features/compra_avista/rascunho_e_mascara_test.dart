import 'package:flutter_test/flutter_test.dart';
import 'package:ravix/data/banco.dart';
import 'package:ravix/data/compra_avista_repository.dart';
import 'package:ravix/features/compra_avista/mascara_valor.dart';
import 'package:ravix/features/compra_avista/rascunho_compra.dart';

void main() {
  group('RascunhoCompra', () {
    RascunhoCompra completo() => RascunhoCompra(momento: DateTime(2026, 10, 24))
      ..descricao = 'Padaria'
      ..valorCentavos = 1250
      ..tipoPagamento = TipoPagamento.pix
      ..idCategoria = 1
      ..idSubcategoria = 101;

    test('vazio: todos os campos obrigatórios acusam', () {
      final erros = RascunhoCompra(momento: DateTime(2026, 10, 24)).validar();
      expect(erros.keys, CampoCompra.values);
    });

    test('cada campo obrigatório vazio bloqueia sozinho', () {
      final casos = <CampoCompra, void Function(RascunhoCompra)>{
        CampoCompra.descricao: (r) => r.descricao = '   ',
        CampoCompra.valor: (r) => r.valorCentavos = 0,
        CampoCompra.tipoPagamento: (r) => r.tipoPagamento = null,
        CampoCompra.categoria: (r) => r.idCategoria = null,
        CampoCompra.subcategoria: (r) => r.idSubcategoria = null,
      };
      for (final MapEntry(key: campo, value: esvaziar) in casos.entries) {
        final rascunho = completo();
        esvaziar(rascunho);
        expect(rascunho.validar().keys, [campo], reason: campo.name);
      }
    });

    test('a tag é opcional e data futura é aceita', () {
      final rascunho = completo()
        ..uuidTag = null
        ..momento = DateTime(2030);
      expect(rascunho.validar(), isEmpty);
      expect(rascunho.paraDados().momento, DateTime(2030));
    });

    test('carrega um gasto salvo, com a categoria derivada', () {
      const compra = CompraAvista(
        uuidCompraAvista: 'c1',
        timestampCompraAvista: '2026-10-15T08:30:00',
        fusoMinutos: -180,
        descricao: 'Uber',
        descricaoNormalizada: 'uber',
        valorCompraAvista: 2390,
        tipoPagamento: 'debito',
        idSubcategoria: 302,
        uuidTag: 't1',
        criadoEm: '2026-10-15T11:30:00Z',
        atualizadoEm: '2026-10-15T11:30:00Z',
      );
      final r = RascunhoCompra.deCompra(compra);
      expect(r.momento, DateTime(2026, 10, 15, 8, 30));
      expect(r.descricao, 'Uber');
      expect(r.valorCentavos, 2390);
      expect(r.tipoPagamento, TipoPagamento.debito);
      expect(r.idCategoria, 3);
      expect(r.idSubcategoria, 302);
      expect(r.uuidTag, 't1');
    });
  });

  group('MascaraValor', () {
    final mascara = MascaraValor();
    String digitar(String texto, {String antes = ''}) => mascara
        .formatEditUpdate(
          TextEditingValue(text: antes),
          TextEditingValue(text: texto),
        )
        .text;

    test('preenche da direita para a esquerda', () {
      expect(digitar('1'), '0,01');
      expect(digitar('12'), '0,12');
      expect(digitar('125'), '1,25');
      expect(digitar('1250'), '12,50');
      expect(digitar('123456'), '1.234,56');
    });

    test('ignora letras, sinais e zeros à esquerda', () {
      expect(digitar('abc'), '');
      expect(digitar('1a2b5'), '1,25');
      expect(digitar('-500'), '5,00');
      expect(digitar('0001'), '0,01');
      expect(digitar('0'), '');
    });

    test('apagar até o fim deixa o campo vazio', () {
      expect(digitar('0,0', antes: '0,01'), '');
    });

    test('cursor sempre no fim', () {
      final valor = mascara.formatEditUpdate(
        TextEditingValue.empty,
        const TextEditingValue(text: '125'),
      );
      expect(valor.selection.baseOffset, valor.text.length);
    });

    test('limite de 11 dígitos', () {
      expect(digitar('99999999999'), '999.999.999,99');
      expect(
        digitar('123456789012', antes: '1.234.567.890,12'),
        '1.234.567.890,12',
      );
    });
  });
}
