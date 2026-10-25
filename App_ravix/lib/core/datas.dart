/// Datas do app (DP-33).
///
/// - Data do evento: ISO 8601 no horário local, `YYYY-MM-DDTHH:MM:SS`, sem
///   fuso no texto, gravada junto com `fuso_minutos`.
/// - Auditoria (`criado_em`, `atualizado_em`): ISO 8601 em UTC, com `Z`.
library;

import 'package:meta/meta.dart';

String _doisDigitos(int n) => n.toString().padLeft(2, '0');

String _isoSemFuso(DateTime d) =>
    '${d.year.toString().padLeft(4, '0')}-${_doisDigitos(d.month)}'
    '-${_doisDigitos(d.day)}T${_doisDigitos(d.hour)}:${_doisDigitos(d.minute)}'
    ':${_doisDigitos(d.second)}';

final _isoLocal = RegExp(r'^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}$');

/// Formata o relógio de parede de [data] como `YYYY-MM-DDTHH:MM:SS`.
///
/// Usa os campos de [data] como estão, sem converter fuso; milissegundos
/// são descartados.
String paraIsoLocal(DateTime data) => _isoSemFuso(data);

/// Data para exibição: `dd/MM/yyyy`.
String formatarData(DateTime data) =>
    '${_doisDigitos(data.day)}/${_doisDigitos(data.month)}/'
    '${data.year.toString().padLeft(4, '0')}';

/// Hora para exibição: `HH:mm`.
String formatarHora(DateTime data) =>
    '${_doisDigitos(data.hour)}:${_doisDigitos(data.minute)}';

/// Lê uma data gravada por [paraIsoLocal] como `DateTime` local.
///
/// Lança [FormatException] se [texto] não estiver no formato exato.
DateTime deIsoLocal(String texto) {
  if (!_isoLocal.hasMatch(texto)) {
    throw FormatException(
      'Data local fora do formato YYYY-MM-DDTHH:MM:SS',
      texto,
    );
  }
  return DateTime.parse(texto);
}

/// Formata o instante de [data] em UTC como `YYYY-MM-DDTHH:MM:SSZ`.
String paraIsoUtc(DateTime data) => '${_isoSemFuso(data.toUtc())}Z';

/// Reconstrói o instante exato de um evento a partir da data local gravada e
/// do `fuso_minutos` (deslocamento em relação ao UTC; −180 = UTC−3).
DateTime instanteUtc(String isoLocal, int fusoMinutos) {
  final local = deIsoLocal(isoLocal);
  final comoUtc = DateTime.utc(
    local.year,
    local.month,
    local.day,
    local.hour,
    local.minute,
    local.second,
  );
  return comoUtc.subtract(Duration(minutes: fusoMinutos));
}

/// Nomes dos meses em português, de janeiro a dezembro.
const nomesDosMeses = [
  'janeiro',
  'fevereiro',
  'março',
  'abril',
  'maio',
  'junho',
  'julho',
  'agosto',
  'setembro',
  'outubro',
  'novembro',
  'dezembro',
];

/// Um mês do calendário, usado pelo seletor de mês global e pelas consultas.
///
/// O intervalo é semiaberto: [inicioIso] entra, [fimIso] não.
@immutable
final class Mes implements Comparable<Mes> {
  /// Cria o mês [mes] (1 a 12) de [ano].
  new(this.ano, this.mes) {
    RangeError.checkValueInInterval(mes, 1, 12, 'mes');
  }

  /// Mês do calendário que contém [data].
  new de(DateTime data) : this(data.year, data.month);

  /// Ano.
  final int ano;

  /// Mês, de 1 a 12.
  final int mes;

  /// Mês seguinte (dezembro vira janeiro do ano seguinte).
  Mes get proximo => mes == 12 ? Mes(ano + 1, 1) : Mes(ano, mes + 1);

  /// Mês anterior (janeiro vira dezembro do ano anterior).
  Mes get anterior => mes == 1 ? Mes(ano - 1, 12) : Mes(ano, mes - 1);

  /// Nome do mês por extenso, em minúsculas: "outubro".
  String get nome => nomesDosMeses[mes - 1];

  /// Rótulo do seletor de mês: "outubro de 2026".
  String get rotulo => '$nome de $ano';

  /// Primeiro instante do mês, inclusivo: `YYYY-MM-01T00:00:00`.
  String get inicioIso => paraIsoLocal(DateTime(ano, mes));

  /// Primeiro instante do mês seguinte, exclusivo.
  String get fimIso => proximo.inicioIso;

  @override
  int compareTo(Mes outro) =>
      ano != outro.ano ? ano.compareTo(outro.ano) : mes.compareTo(outro.mes);

  @override
  bool operator ==(Object other) =>
      other is Mes && other.ano == ano && other.mes == mes;

  @override
  int get hashCode => Object.hash(ano, mes);

  @override
  String toString() => '${ano.toString().padLeft(4, '0')}-${_doisDigitos(mes)}';
}
