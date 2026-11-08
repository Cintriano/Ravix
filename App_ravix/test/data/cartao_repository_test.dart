import 'package:flutter_test/flutter_test.dart';
import 'package:ravix/data/banco.dart';
import 'package:ravix/data/cartao_repository.dart';

import '../helpers/ambiente_falso.dart';
import '../helpers/banco_de_teste.dart';

const _agora = '2026-11-08T12:00:00Z';

DadosCartao cartao({
  String nome = 'Itaú',
  int limite = 590000,
  int? fechamento = 29,
  int? vencimento = 5,
  String? finalCartao = '9827',
  String? cnpj = '60.872.504/0001-23',
}) => (
  nome: nome,
  limiteCentavos: limite,
  diaFechamento: fechamento,
  diaVencimento: vencimento,
  finalCartao: finalCartao,
  cnpjEmissor: cnpj,
);

void main() {
  late BancoRavix banco;
  late CartaoRepository repositorio;

  setUp(() {
    banco = bancoEmMemoria();
    repositorio = CartaoRepository(
      banco,
      relogio: RelogioFixo(DateTime.utc(2026, 11, 8, 12)),
      uuid: GeradorUuidSequencial(),
    );
  });
  tearDown(() => banco.close());

  Future<Map<CampoCartao, String>> errosDe(Future<void> acao) async {
    try {
      await acao;
    } on CartaoInvalido catch (e) {
      return e.erros;
    }
    fail('esperava CartaoInvalido');
  }

  group('CNPJ', () {
    test('confere os dígitos verificadores', () {
      expect(cnpjValido('60872504000123'), isTrue);
      expect(cnpjValido('22896431000110'), isTrue);
      expect(cnpjValido('60872504000124'), isFalse);
      expect(cnpjValido('11111111111111'), isFalse);
      expect(cnpjValido('6087250400012'), isFalse);
    });

    test('formata com pontuação', () {
      expect(formatarCnpj('60872504000123'), '60.872.504/0001-23');
    });
  });

  test('criar limpa o nome e guarda só os dígitos', () async {
    final criado = await repositorio.criar(
      cartao(nome: '  Itaú   Platinum ', finalCartao: ' 98-27'),
    );
    expect(criado.nomeCartao, 'Itaú Platinum');
    expect(criado.finalCartao, '9827');
    expect(criado.cnpjEmissor, '60872504000123');
    expect(criado.status, 'ativo');
    expect(criado.criadoEm, _agora);
  });

  test('opcionais vazios ficam nulos', () async {
    final criado = await repositorio.criar(
      cartao(fechamento: null, vencimento: null, finalCartao: '', cnpj: ''),
    );
    expect(criado.diaFechamento, isNull);
    expect(criado.diaVencimento, isNull);
    expect(criado.finalCartao, isNull);
    expect(criado.cnpjEmissor, isNull);
  });

  test('valida cada campo', () async {
    final erros = await errosDe(
      repositorio.criar(
        cartao(
          nome: ' ',
          limite: 0,
          fechamento: 0,
          vencimento: 32,
          finalCartao: '123',
          cnpj: '60.872.504/0001-24',
        ),
      ),
    );
    expect(erros.keys, CampoCartao.values);
  });

  test('nome repetido, ignorando maiúsculas e acentos', () async {
    await repositorio.criar(cartao());
    final erros = await errosDe(repositorio.criar(cartao(nome: 'ITAU')));
    expect(erros[CampoCartao.nome], contains('Já existe'));
  });

  test('editar troca os dados e aceita o próprio nome', () async {
    final criado = await repositorio.criar(cartao());
    await repositorio.editar(
      criado.uuidCartaoCredito,
      cartao(limite: 700000, fechamento: 26),
    );
    final editado = await repositorio.buscar(criado.uuidCartaoCredito);
    expect(editado!.limiteCartao, 700000);
    expect(editado.diaFechamento, 26);
  });

  test('remover sem uso exclui; com compra, arquiva', () async {
    final livre = await repositorio.criar(cartao(nome: 'PicPay'));
    final usado = await repositorio.criar(cartao());
    await banco.customStatement(
      'INSERT INTO tbl_compra_faturada (uuid_compra_faturada, '
      'uuid_cartao_credito, timestamp_compra_faturada, fuso_minutos, '
      'descricao, descricao_normalizada, valor_total, quant_parcela, '
      'mes_vencimento, ano_vencimento, id_subcategoria, criado_em, '
      "atualizado_em) VALUES ('f1', ?, '2026-11-08T10:00:00', -180, "
      "'Passagem', 'passagem', 120000, 6, 12, 2026, 405, ?, ?)",
      [usado.uuidCartaoCredito, _agora, _agora],
    );

    expect(await repositorio.contarUsos(usado.uuidCartaoCredito), 1);
    expect(
      await repositorio.remover(livre.uuidCartaoCredito),
      RemocaoCartao.excluido,
    );
    expect(
      await repositorio.remover(usado.uuidCartaoCredito),
      RemocaoCartao.arquivado,
    );
    expect(await repositorio.buscar(livre.uuidCartaoCredito), isNull);
    expect(await repositorio.observarAtivos().first, isEmpty);
    expect(
      (await repositorio.buscar(usado.uuidCartaoCredito))!.status,
      'arquivado',
    );
  });

  test('reativar volta o arquivado para os ativos', () async {
    final usado = await repositorio.criar(cartao());
    await banco.customStatement(
      'INSERT INTO tbl_compra_faturada (uuid_compra_faturada, '
      'uuid_cartao_credito, timestamp_compra_faturada, fuso_minutos, '
      'descricao, descricao_normalizada, valor_total, quant_parcela, '
      'mes_vencimento, ano_vencimento, id_subcategoria, criado_em, '
      "atualizado_em) VALUES ('f1', ?, '2026-11-08T10:00:00', -180, "
      "'Passagem', 'passagem', 120000, 6, 12, 2026, 405, ?, ?)",
      [usado.uuidCartaoCredito, _agora, _agora],
    );
    await repositorio.remover(usado.uuidCartaoCredito);
    expect(
      (await repositorio.observarArquivados().first).single.nomeCartao,
      'Itaú',
    );

    // O nome continua ocupado: o aviso aponta para a reativação.
    final erros = await errosDe(repositorio.criar(cartao(nome: 'itau')));
    expect(erros[CampoCartao.nome], contains('arquivado'));

    await repositorio.reativar(usado.uuidCartaoCredito);
    expect(await repositorio.observarArquivados().first, isEmpty);
    expect(
      (await repositorio.observarAtivos().first).single.uuidCartaoCredito,
      usado.uuidCartaoCredito,
    );
  });

  test('ativos em ordem alfabética', () async {
    await repositorio.criar(cartao(nome: 'PicPay'));
    await repositorio.criar(cartao(nome: 'itaú'));
    final nomes = (await repositorio.observarAtivos().first).map(
      (c) => c.nomeCartao,
    );
    expect(nomes, ['itaú', 'PicPay']);
  });
}
