import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:ravix/app/dependencias.dart';
import 'package:ravix/core/datas.dart';
import 'package:ravix/core/tema/tema.dart';
import 'package:ravix/core/tema/tokens.dart';
import 'package:ravix/core/valor.dart';
import 'package:ravix/data/compra_avista_repository.dart';
import 'package:ravix/data/macro_repository.dart';
import 'package:ravix/data/recorrencia_repository.dart';
import 'package:ravix/features/compra_avista/aba_avista_providers.dart';
import 'package:ravix/features/compra_avista/formulario_compra.dart';
import 'package:ravix/features/faturada/aba_faturada_providers.dart';
import 'package:ravix/features/macro/macro_providers.dart';
import 'package:ravix/features/shell/estados_tela.dart';
import 'package:ravix/features/shell/mes_selecionado.dart';

/// Aba Macro (E01-F06): faturado + à vista do mês contra a renda, com
/// farol pelo ritmo, sobra, composição e consumo dia a dia.
class AbaMacro extends ConsumerWidget {
  /// Cria a aba.
  const new({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final faturas = ref.watch(faturasDoMesProvider);
    final avista = ref.watch(avistaPorDiaProvider);
    final renda = ref.watch(rendaDoMesSelecionadoProvider);
    if (faturas.hasError || avista.hasError || renda.hasError) {
      return EstadoErro(
        aoTentarDeNovo: () => ref
          ..invalidate(faturasDoMesProvider)
          ..invalidate(avistaPorDiaProvider)
          ..invalidate(rendaDoMesSelecionadoProvider),
      );
    }
    if (!faturas.hasValue || !avista.hasValue || !renda.hasValue) {
      return const EstadoCarregando();
    }

    final mes = ref.watch(mesSelecionadoProvider);
    final base = ref.watch(baseDaMacroProvider);
    final macro = calcularMacro(
      mes: mes,
      hoje: ref.watch(relogioProvider).agora(),
      base: base,
      renda: renda.value,
      avista: avista.value!,
      faturas: faturas.value!,
    );
    final previstas = macro.periodo == PeriodoDoMes.passado
        ? const <Prevista>[]
        : [
            ...?ref.watch(previstasDoMesProvider).value,
            ...?ref.watch(previstasDaFaturaProvider).value,
          ];
    final previsto = previstas.fold(0, (s, p) => s + p.regra.valorRecorrencia);

    return ListView(
      // Espaço para o botão flutuante não cobrir o fim.
      padding: const EdgeInsets.only(bottom: 96),
      children: [
        _Resumo(macro: macro, mes: mes, base: base, previsto: previsto),
        if (renda.value == null) _SemRenda(mes: mes) else const _SeletorBase(),
        _Composicao(macro),
        if (macro.serie.isNotEmpty && macro.serie.last > 0)
          _ConsumoDiaADia(macro: macro, mes: mes),
      ],
    );
  }
}

/// Rótulo da base no texto do percentual.
String _daBase(BaseComparacao base) => switch (base) {
  BaseComparacao.rendaTotal => 'da renda total',
  BaseComparacao.soSalario => 'do salário',
};

/// Texto do farol para o período.
String textoDoFarol(Farol farol, PeriodoDoMes periodo) =>
    switch ((periodo, farol)) {
      (PeriodoDoMes.passado, Farol.verde) => 'Dentro da renda',
      (PeriodoDoMes.passado, Farol.amarelo) => 'Passou um pouco da renda',
      (PeriodoDoMes.passado, Farol.vermelho) => 'Passou da renda',
      (_, Farol.verde) => 'No ritmo do mês',
      (_, Farol.amarelo) => 'Um pouco acima do ritmo',
      (_, Farol.vermelho) => 'Acima do ritmo',
    };

/// Card de resumo em Floresta (E01-F06-T01, T03, T04).
class _Resumo extends StatelessWidget {
  const new({
    required this.macro,
    required this.mes,
    required this.base,
    required this.previsto,
  });

  final Macro macro;
  final Mes mes;
  final BaseComparacao base;
  final int previsto;

  @override
  Widget build(BuildContext context) {
    final tema = context.temaRavix;
    final texto = Theme.of(context).textTheme;
    final apoio = texto.bodySmall?.copyWith(color: tema.resumoApoio);
    final claro = texto.bodyMedium?.copyWith(color: tema.resumoTexto);
    final titulo = switch (macro.periodo) {
      PeriodoDoMes.atual => 'Consumo de ${mes.nome} até agora',
      PeriodoDoMes.passado => 'Consumo de ${mes.nome}',
      PeriodoDoMes.futuro => 'Já comprometido em ${mes.nome}',
    };
    final valor = formatarCentavos(macro.consumo);
    final porcento = macro.porcento;
    final farol = macro.farol;
    final ritmo = macro.ritmo;
    final superavit = macro.superavit;
    final linhaFarol = farol == null
        ? null
        : [
            textoDoFarol(farol, macro.periodo),
            if (macro.periodo == PeriodoDoMes.atual && ritmo != null)
              'ritmo ${ritmo.round()}%',
          ].join(' · ');
    final linhaSobra = superavit == null
        ? null
        : switch (macro.periodo) {
            PeriodoDoMes.passado =>
              superavit >= 0
                  ? 'Superávit de ${formatarCentavos(superavit)}'
                  : 'Déficit de ${formatarCentavos(-superavit)}',
            _ =>
              superavit >= 0
                  ? 'Sobram ${formatarCentavos(superavit)}'
                  : 'Passou ${formatarCentavos(-superavit)} da renda',
          };
    final extras = [
      if (macro.faturadoAVencer > 0)
        '+ ${formatarCentavos(macro.faturadoAVencer)} em faturas a vencer',
      if (previsto > 0 && macro.periodo == PeriodoDoMes.atual)
        '+ ${formatarCentavos(previsto)} previstos até o fim do mês',
      if (previsto > 0 && macro.periodo != PeriodoDoMes.atual)
        '+ ${formatarCentavos(previsto)} previstos',
    ];

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        TokensRavix.spaceMd,
        TokensRavix.spaceSm,
        TokensRavix.spaceMd,
        0,
      ),
      child: DecoratedBox(
        decoration: ShapeDecoration(
          color: tema.resumoFundo,
          shape: chanfro(TokensRavix.chanfroG),
        ),
        child: Padding(
          padding: const EdgeInsets.all(TokensRavix.spaceMd + 4),
          child: Semantics(
            container: true,
            label: [
              '$titulo: $valor',
              if (porcento != null) '${porcento.round()}% ${_daBase(base)}',
              ?linhaFarol,
              ?linhaSobra,
              ...extras,
            ].join('. '),
            excludeSemantics: true,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(titulo, style: apoio),
                const SizedBox(height: TokensRavix.spaceXs),
                Text(
                  valor,
                  style: tema.valorDestaque.copyWith(color: tema.resumoTexto),
                ),
                if (porcento != null)
                  Text('${porcento.round()}% ${_daBase(base)}', style: claro),
                if (linhaFarol != null && farol != null) ...[
                  const SizedBox(height: TokensRavix.spaceSm),
                  Row(
                    children: [
                      SizedBox.square(
                        dimension: 10,
                        child: ColoredBox(color: corDoFarol(context, farol)),
                      ),
                      const SizedBox(width: TokensRavix.spaceSm),
                      Expanded(child: Text(linhaFarol, style: claro)),
                    ],
                  ),
                ],
                if (porcento != null) ...[
                  const SizedBox(height: TokensRavix.spaceSm),
                  _BarraDoConsumo(
                    parte: porcento / 100,
                    ritmo: ritmo == null ? null : ritmo / 100,
                    cor: farol == null
                        ? tema.resumoTexto
                        : corDoFarol(context, farol),
                  ),
                ],
                if (linhaSobra != null) ...[
                  const SizedBox(height: TokensRavix.spaceSm),
                  Text(linhaSobra, style: claro),
                ],
                for (final e in extras) Text(e, style: apoio),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Cor de cada farol.
Color corDoFarol(BuildContext context, Farol farol) {
  final paleta = context.temaRavix.paleta;
  return switch (farol) {
    Farol.verde => paleta.ok,
    Farol.amarelo => CoresRavix.atencao,
    Farol.vermelho => paleta.danger,
  };
}

/// Barra do consumo contra a base, com a marca do ritmo.
class _BarraDoConsumo extends StatelessWidget {
  const new({required this.parte, required this.ritmo, required this.cor});

  final double parte;
  final double? ritmo;
  final Color cor;

  @override
  Widget build(BuildContext context) {
    final tema = context.temaRavix;
    return SizedBox(
      height: 10,
      child: LayoutBuilder(
        builder: (context, limites) {
          final largura = limites.maxWidth;
          return Stack(
            children: [
              Positioned.fill(child: ColoredBox(color: tema.resumoTrilho)),
              Positioned(
                left: 0,
                top: 0,
                bottom: 0,
                width: largura * parte.clamp(0, 1),
                child: ColoredBox(color: cor),
              ),
              if (ritmo case final r?)
                Positioned(
                  left: (largura * r.clamp(0, 1) - 1).clamp(0, largura - 2),
                  top: -2,
                  bottom: -2,
                  width: 2,
                  child: ColoredBox(color: tema.resumoTexto),
                ),
            ],
          );
        },
      ),
    );
  }
}

/// Seletor de base de comparação (E01-F06-T02).
class _SeletorBase extends ConsumerWidget {
  const new();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final base = ref.watch(baseDaMacroProvider);
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        TokensRavix.spaceMd,
        TokensRavix.spaceMd,
        TokensRavix.spaceMd,
        0,
      ),
      child: SegmentedButton<BaseComparacao>(
        showSelectedIcon: false,
        segments: [
          for (final b in BaseComparacao.values)
            ButtonSegment(value: b, label: Text(b.rotulo)),
        ],
        selected: {base},
        onSelectionChanged: (escolha) =>
            ref.read(baseDaMacroProvider.notifier).escolher(escolha.single),
      ),
    );
  }
}

/// Aviso de renda não cadastrada, com o atalho para a Configuração.
class _SemRenda extends StatelessWidget {
  const new({required this.mes});

  final Mes mes;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(
      TokensRavix.spaceMd,
      TokensRavix.spaceMd,
      TokensRavix.spaceMd,
      0,
    ),
    child: Row(
      children: [
        Expanded(
          child: Text(
            'Sem renda para ${mes.rotulo}. Cadastre o salário para ver o '
            'farol e a sobra.',
            style: TextStyle(color: context.temaRavix.paleta.textSecondary),
          ),
        ),
        TextButton(
          onPressed: () => context.push('/configuracao/renda'),
          child: const Text('Cadastrar renda'),
        ),
      ],
    ),
  );
}

/// Faturado e à vista, com o à vista por forma de pagamento; em mês fechado,
/// a barra 100% faturado/à vista (E01-F06-T06).
class _Composicao extends StatelessWidget {
  const new(this.macro);

  final Macro macro;

  @override
  Widget build(BuildContext context) {
    final tema = context.temaRavix;
    final paleta = tema.paleta;
    final formas = [
      for (final f in TipoPagamento.values)
        if ((macro.avistaPorForma[f] ?? 0) > 0) (f, macro.avistaPorForma[f]!),
    ];
    final totalAvista = formas.fold(0, (s, f) => s + f.$2);
    final total = macro.faturado + macro.avista;
    final fechado = macro.periodo == PeriodoDoMes.passado && total > 0;
    final corFaturado = CoresRavix.graficos[1];
    final corAvista = CoresRavix.graficos[0];

    Widget linha(String rotulo, int valor, {Color? cor, bool sub = false}) =>
        Padding(
          padding: EdgeInsets.fromLTRB(
            sub
                ? TokensRavix.spaceLg + TokensRavix.spaceSm
                : TokensRavix.spaceMd,
            TokensRavix.spaceXs,
            TokensRavix.spaceMd,
            TokensRavix.spaceXs,
          ),
          child: Row(
            children: [
              if (cor != null) ...[
                SizedBox.square(dimension: 10, child: ColoredBox(color: cor)),
                const SizedBox(width: TokensRavix.spaceSm),
              ],
              Expanded(
                child: Text(
                  rotulo,
                  style: sub ? TextStyle(color: paleta.textSecondary) : null,
                ),
              ),
              Text(
                formatarCentavos(valor),
                style: tema.valorLista.copyWith(
                  color: sub ? paleta.textSecondary : null,
                  fontSize: sub ? 13 : null,
                ),
              ),
            ],
          ),
        );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(
            TokensRavix.spaceMd,
            TokensRavix.spaceLg,
            TokensRavix.spaceMd,
            TokensRavix.spaceXs,
          ),
          child: Semantics(
            header: true,
            child: Text('COMPOSIÇÃO', style: tema.sobretitulo),
          ),
        ),
        if (fechado)
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: TokensRavix.spaceMd,
              vertical: TokensRavix.spaceSm,
            ),
            child: Semantics(
              label:
                  'Faturado ${(macro.faturado * 100 / total).round()}%, '
                  'à vista ${(macro.avista * 100 / total).round()}%',
              excludeSemantics: true,
              child: SizedBox(
                height: 12,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  spacing: 2,
                  children: [
                    if (macro.faturado > 0)
                      Expanded(
                        flex: macro.faturado,
                        child: ColoredBox(color: corFaturado),
                      ),
                    if (macro.avista > 0)
                      Expanded(
                        flex: macro.avista,
                        child: ColoredBox(color: corAvista),
                      ),
                  ],
                ),
              ),
            ),
          ),
        linha('Faturado', macro.faturado, cor: fechado ? corFaturado : null),
        if (macro.faturadoAVencer > 0)
          linha('A vencer', macro.faturadoAVencer, sub: true),
        linha('À vista', totalAvista, cor: fechado ? corAvista : null),
        for (final (forma, valor) in formas)
          linha(forma.rotulo, valor, sub: true),
        if (macro.avista != totalAvista)
          Padding(
            padding: const EdgeInsets.fromLTRB(
              TokensRavix.spaceMd,
              TokensRavix.spaceXs,
              TokensRavix.spaceMd,
              0,
            ),
            child: Text(
              'O voucher fica fora do consumo na base só salário.',
              style: Theme.of(context).textTheme.bodySmall
                  ?.copyWith(color: paleta.textSecondary),
            ),
          ),
      ],
    );
  }
}

/// Consumo acumulado dia a dia, com a linha do ritmo até a base
/// (E01-F06-T05). A fatura entra como degrau no dia do vencimento.
class _ConsumoDiaADia extends StatelessWidget {
  const new({required this.macro, required this.mes});

  final Macro macro;
  final Mes mes;

  @override
  Widget build(BuildContext context) {
    final tema = context.temaRavix;
    final dias = ultimoDiaDo(mes);
    final ultimo = macro.serie.last;
    final base = macro.base;
    final rotulo = Theme.of(context).textTheme.labelSmall
        ?.copyWith(color: tema.paleta.textSecondary);
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        TokensRavix.spaceMd,
        TokensRavix.spaceLg,
        TokensRavix.spaceMd,
        0,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Semantics(
            header: true,
            child: Text('CONSUMO DIA A DIA', style: tema.sobretitulo),
          ),
          const SizedBox(height: TokensRavix.spaceSm),
          Semantics(
            label:
                'Consumo acumulado de ${formatarCentavos(ultimo)} até o dia '
                '${macro.serie.length}'
                '${base == null ? '' : ', contra ${formatarCentavos(base)} '
                          'da base'}.',
            excludeSemantics: true,
            child: SizedBox(
              height: 160,
              width: double.infinity,
              child: CustomPaint(
                painter: _PintorDoConsumo(
                  serie: macro.serie,
                  dias: dias,
                  base: base,
                  corLinha: tema.acento,
                  corRitmo: tema.paleta.textSecondary,
                  corGrade: tema.paleta.border,
                ),
              ),
            ),
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Text('1', style: rotulo),
              const Spacer(),
              Text('${(dias + 1) ~/ 2}', style: rotulo),
              const Spacer(),
              Text('$dias', style: rotulo),
            ],
          ),
          if (base != null)
            Padding(
              padding: const EdgeInsets.only(top: TokensRavix.spaceXs),
              child: Text(
                'Tracejado: ritmo até ${formatarCentavos(base)} no fim do mês.',
                style: rotulo,
              ),
            ),
        ],
      ),
    );
  }
}

class _PintorDoConsumo extends CustomPainter {
  new({
    required this.serie,
    required this.dias,
    required this.base,
    required this.corLinha,
    required this.corRitmo,
    required this.corGrade,
  });

  final List<int> serie;
  final int dias;
  final int? base;
  final Color corLinha;
  final Color corRitmo;
  final Color corGrade;

  @override
  void paint(Canvas canvas, Size size) {
    final maximo = math.max(base ?? 0, serie.last) * 1.05;
    if (maximo <= 0) return;
    Offset ponto(double dia, num valor) => Offset(
      size.width * dia / dias,
      size.height - size.height * valor / maximo,
    );

    final grade = Paint()
      ..color = corGrade
      ..strokeWidth = 1;
    canvas.drawLine(
      Offset(0, size.height),
      Offset(size.width, size.height),
      grade,
    );

    if (base case final b?) {
      final ritmo = Paint()
        ..color = corRitmo
        ..strokeWidth = 1.5;
      final inicio = ponto(0, 0);
      final fim = ponto(dias.toDouble(), b);
      const traco = 6.0;
      final distancia = (fim - inicio).distance;
      final direcao = (fim - inicio) / distancia;
      for (var d = 0.0; d < distancia; d += traco * 2) {
        canvas.drawLine(
          inicio + direcao * d,
          inicio + direcao * math.min(d + traco, distancia),
          ritmo,
        );
      }
      canvas.drawLine(ponto(0, b), ponto(dias.toDouble(), b), grade);
    }

    // Degraus: o valor de cada dia vale do início ao fim dele.
    final caminho = Path()..moveTo(0, size.height);
    var anterior = 0;
    for (final (i, valor) in serie.indexed) {
      if (valor != anterior) {
        caminho.lineTo(
          ponto(i.toDouble(), anterior).dx,
          ponto(i.toDouble(), valor).dy,
        );
      }
      caminho.lineTo(ponto(i + 1.0, valor).dx, ponto(i + 1.0, valor).dy);
      anterior = valor;
    }
    canvas.drawPath(
      caminho,
      Paint()
        ..color = corLinha
        ..strokeWidth = 2.5
        ..style = PaintingStyle.stroke,
    );
  }

  @override
  bool shouldRepaint(_PintorDoConsumo antigo) =>
      antigo.serie != serie ||
      antigo.base != base ||
      antigo.dias != dias ||
      antigo.corLinha != corLinha;
}
