import 'package:drift/drift.dart';
import 'package:ravix/core/ambiente.dart';
import 'package:ravix/core/datas.dart';
import 'package:ravix/core/texto.dart';
import 'package:ravix/data/banco.dart';

/// Campos validados do cadastro de cartão (E01-F07-T06).
enum CampoCartao {
  /// Nome do cartão.
  nome,

  /// Limite.
  limite,

  /// Dia de fechamento.
  diaFechamento,

  /// Dia de vencimento.
  diaVencimento,

  /// 4 últimos dígitos.
  finalCartao,

  /// CNPJ do emissor.
  cnpjEmissor,
}

/// O que o formulário informa ao criar ou editar um cartão. Os opcionais
/// vazios chegam como `null`.
typedef DadosCartao = ({
  String nome,
  int limiteCentavos,
  int? diaFechamento,
  int? diaVencimento,
  String? finalCartao,
  String? cnpjEmissor,
});

/// Dados inválidos, com a mensagem de cada campo.
final class CartaoInvalido implements Exception {
  /// Cria o erro com [erros].
  new(this.erros);

  /// Mensagem por campo.
  final Map<CampoCartao, String> erros;

  @override
  String toString() => erros.values.join(' ');
}

/// O que aconteceu ao remover um cartão (E01-F07-T08, DP-29).
enum RemocaoCartao {
  /// Não tinha registros e foi apagado.
  excluido,

  /// Tinha registros e foi arquivado: some dos seletores e continua no
  /// histórico.
  arquivado,
}

final _espacos = RegExp(r'\s+');
final _naoDigito = RegExp(r'\D');

/// Só os dígitos de [texto]; `null` se não sobrar nenhum.
String? soDigitos(String? texto) {
  final digitos = (texto ?? '').replaceAll(_naoDigito, '');
  return digitos.isEmpty ? null : digitos;
}

/// Confere os dígitos verificadores de um CNPJ de 14 dígitos.
bool cnpjValido(String cnpj) {
  if (cnpj.length != 14 || cnpj.contains(_naoDigito)) return false;
  if (RegExp(r'^(\d)\1{13}$').hasMatch(cnpj)) return false;
  final d = cnpj.split('').map(int.parse).toList();
  int digito(int tamanho) {
    final pesos = tamanho == 12
        ? [5, 4, 3, 2, 9, 8, 7, 6, 5, 4, 3, 2]
        : [6, 5, 4, 3, 2, 9, 8, 7, 6, 5, 4, 3, 2];
    var soma = 0;
    for (var i = 0; i < tamanho; i++) {
      soma += d[i] * pesos[i];
    }
    final resto = soma % 11;
    return resto < 2 ? 0 : 11 - resto;
  }

  return digito(12) == d[12] && digito(13) == d[13];
}

/// Formata um CNPJ de 14 dígitos: `60.872.504/0001-23`.
String formatarCnpj(String cnpj) => cnpj.length != 14
    ? cnpj
    : '${cnpj.substring(0, 2)}.${cnpj.substring(2, 5)}.'
          '${cnpj.substring(5, 8)}/${cnpj.substring(8, 12)}-'
          '${cnpj.substring(12)}';

/// Cartões de crédito (E01-F07-T03, T06–T08).
final class CartaoRepository {
  /// Cria o repositório sobre o banco do app.
  new(this._banco, {required this._relogio, required this._uuid});

  final BancoRavix _banco;
  final Relogio _relogio;
  final GeradorUuid _uuid;

  /// Cria um cartão ativo e devolve o cartão criado.
  ///
  /// Lança [CartaoInvalido].
  Future<CartaoCredito> criar(DadosCartao dados) =>
      _banco.transaction(() async {
        final limpo = await _validar(dados);
        final agora = paraIsoUtc(_relogio.agora());
        return await _banco
            .into(_banco.tblCartoesCredito)
            .insertReturning(
              TblCartoesCreditoCompanion.insert(
                uuidCartaoCredito: _uuid.gerar(),
                nomeCartao: limpo.nome,
                limiteCartao: limpo.limiteCentavos,
                diaFechamento: Value(limpo.diaFechamento),
                diaVencimento: Value(limpo.diaVencimento),
                finalCartao: Value(limpo.finalCartao),
                cnpjEmissor: Value(limpo.cnpjEmissor),
                criadoEm: agora,
                atualizadoEm: agora,
              ),
            );
      });

  /// Troca os dados do cartão [uuid] (E01-F07-T07). As compras guardam só
  /// o UUID e não mudam.
  ///
  /// Lança [CartaoInvalido].
  Future<void> editar(String uuid, DadosCartao dados) =>
      _banco.transaction(() async {
        final limpo = await _validar(dados, ignorar: uuid);
        await (_banco.update(
          _banco.tblCartoesCredito,
        )..where((c) => c.uuidCartaoCredito.equals(uuid))).write(
          TblCartoesCreditoCompanion(
            nomeCartao: Value(limpo.nome),
            limiteCartao: Value(limpo.limiteCentavos),
            diaFechamento: Value(limpo.diaFechamento),
            diaVencimento: Value(limpo.diaVencimento),
            finalCartao: Value(limpo.finalCartao),
            cnpjEmissor: Value(limpo.cnpjEmissor),
            atualizadoEm: Value(paraIsoUtc(_relogio.agora())),
          ),
        );
      });

  /// Exclui o cartão [uuid] se nada o usa; senão, arquiva (DP-29).
  Future<RemocaoCartao> remover(String uuid) => _banco.transaction(() async {
    final filtro = _banco.tblCartoesCredito.uuidCartaoCredito.equals(uuid);
    if (await contarUsos(uuid) == 0) {
      await (_banco.delete(
        _banco.tblCartoesCredito,
      )..where((_) => filtro)).go();
      return RemocaoCartao.excluido;
    }
    await (_banco.update(_banco.tblCartoesCredito)..where((_) => filtro)).write(
      TblCartoesCreditoCompanion(
        status: const Value('arquivado'),
        atualizadoEm: Value(paraIsoUtc(_relogio.agora())),
      ),
    );
    return RemocaoCartao.arquivado;
  });

  /// Volta o cartão arquivado [uuid] para ativo: reaparece nos seletores
  /// do formulário (DP-29).
  Future<void> reativar(String uuid) =>
      (_banco.update(
        _banco.tblCartoesCredito,
      )..where((c) => c.uuidCartaoCredito.equals(uuid))).write(
        TblCartoesCreditoCompanion(
          status: const Value('ativo'),
          atualizadoEm: Value(paraIsoUtc(_relogio.agora())),
        ),
      );

  /// Quantos registros usam o cartão [uuid]: compras, pagamentos de
  /// fatura, estornos e recorrências.
  Future<int> contarUsos(String uuid) =>
      _banco.contarUsosDoCartao(uuid: uuid).getSingle();

  /// Cartões ativos em ordem alfabética (Configuração e seletores).
  Stream<List<CartaoCredito>> observarAtivos() =>
      (_banco.select(_banco.tblCartoesCredito)
            ..where((c) => c.status.equals('ativo'))
            ..orderBy([
              (c) => OrderingTerm(
                expression: c.nomeCartao.collate(Collate.noCase),
              ),
            ]))
          .watch();

  /// Cartões arquivados em ordem alfabética.
  Stream<List<CartaoCredito>> observarArquivados() =>
      (_banco.select(_banco.tblCartoesCredito)
            ..where((c) => c.status.equals('arquivado'))
            ..orderBy([
              (c) => OrderingTerm(
                expression: c.nomeCartao.collate(Collate.noCase),
              ),
            ]))
          .watch();

  /// Cartão pelo UUID (ativo ou arquivado), ou `null`.
  Future<CartaoCredito?> buscar(String uuid) => (_banco.select(
    _banco.tblCartoesCredito,
  )..where((c) => c.uuidCartaoCredito.equals(uuid))).getSingleOrNull();

  Future<DadosCartao> _validar(DadosCartao dados, {String? ignorar}) async {
    final nome = dados.nome.trim().replaceAll(_espacos, ' ');
    final finalCartao = soDigitos(dados.finalCartao);
    final cnpj = soDigitos(dados.cnpjEmissor);
    bool diaInvalido(int? dia) => dia != null && (dia < 1 || dia > 31);

    final erros = <CampoCartao, String>{
      if (nome.isEmpty) CampoCartao.nome: 'Informe o nome do cartão.',
      if (dados.limiteCentavos <= 0)
        CampoCartao.limite: 'Informe um limite maior que zero.',
      if (diaInvalido(dados.diaFechamento))
        CampoCartao.diaFechamento: 'Use um dia de 1 a 31.',
      if (diaInvalido(dados.diaVencimento))
        CampoCartao.diaVencimento: 'Use um dia de 1 a 31.',
      if (finalCartao != null && finalCartao.length != 4)
        CampoCartao.finalCartao: 'Use os 4 últimos dígitos.',
      if (cnpj != null && !cnpjValido(cnpj))
        CampoCartao.cnpjEmissor: 'CNPJ inválido.',
    };
    if (nome.isNotEmpty) {
      // O COLLATE NOCASE do banco só cobre ASCII; aqui cobre os acentos.
      final chave = normalizarTexto(nome);
      final existentes = await _banco.select(_banco.tblCartoesCredito).get();
      final repetido = existentes
          .where(
            (c) =>
                c.uuidCartaoCredito != ignorar &&
                normalizarTexto(c.nomeCartao) == chave,
          )
          .firstOrNull;
      if (repetido != null) {
        erros[CampoCartao.nome] = repetido.status == 'arquivado'
            ? 'Há um cartão arquivado chamado "$nome". Reative-o na lista '
                  'de cartões.'
            : 'Já existe um cartão chamado "$nome".';
      }
    }
    if (erros.isNotEmpty) throw CartaoInvalido(erros);
    return (
      nome: nome,
      limiteCentavos: dados.limiteCentavos,
      diaFechamento: dados.diaFechamento,
      diaVencimento: dados.diaVencimento,
      finalCartao: finalCartao,
      cnpjEmissor: cnpj,
    );
  }
}
