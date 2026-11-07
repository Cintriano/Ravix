import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:intl/intl.dart';

import '../theme/ravix_theme.dart';

// ---------------------------------------------------------------------------
// Dinheiro
// ---------------------------------------------------------------------------

final NumberFormat _brl = NumberFormat.currency(locale: 'pt_BR', symbol: r'R$', decimalDigits: 2);
final NumberFormat _brlNumber = NumberFormat.currency(locale: 'pt_BR', symbol: '', decimalDigits: 2);

/// `1234.5` → `R$ 1.234,50`
String formatBRL(num value) => _brl.format(value);

/// `1234.5` → `1.234,50` (sem o símbolo, para compor com um "R$" menor)
String formatBRLNumber(num value) => _brlNumber.format(value).trim();

// ---------------------------------------------------------------------------
// Logo e símbolo
// ---------------------------------------------------------------------------

enum RavixLogoTone {
  /// Escolhe pela luminosidade do tema.
  auto,

  /// Floresta + seta Menta 600, para fundos claros.
  positivo,

  /// Névoa + seta Menta, para Floresta ou fundos escuros.
  negativo,
}

/// Logotipo completo. Use sempre este widget, nunca o texto "Ravix" na fonte.
class RavixLogo extends StatelessWidget {
  const RavixLogo({super.key, this.height = 28, this.tone = RavixLogoTone.auto});

  /// Altura em dp (mínimo recomendado: 24).
  final double height;
  final RavixLogoTone tone;

  @override
  Widget build(BuildContext context) {
    final dark = switch (tone) {
      RavixLogoTone.auto => Theme.of(context).brightness == Brightness.dark,
      RavixLogoTone.positivo => false,
      RavixLogoTone.negativo => true,
    };
    return SvgPicture.asset(
      dark ? 'assets/brand/ravix-logo-negativo.svg' : 'assets/brand/ravix-logo.svg',
      height: height,
      semanticsLabel: 'Ravix',
    );
  }
}

/// Só o x com a seta.
class RavixSymbol extends StatelessWidget {
  const RavixSymbol({super.key, this.size = 32, this.tone = RavixLogoTone.auto});

  final double size;
  final RavixLogoTone tone;

  @override
  Widget build(BuildContext context) {
    final dark = switch (tone) {
      RavixLogoTone.auto => Theme.of(context).brightness == Brightness.dark,
      RavixLogoTone.positivo => false,
      RavixLogoTone.negativo => true,
    };
    return SvgPicture.asset(
      dark ? 'assets/brand/ravix-simbolo-negativo.svg' : 'assets/brand/ravix-simbolo.svg',
      height: size,
      semanticsLabel: 'Ravix',
    );
  }
}

// ---------------------------------------------------------------------------
// Componentes do monitoramento
// ---------------------------------------------------------------------------

class RavixCategoryShare {
  const RavixCategoryShare(this.name, this.value, this.color);
  final String name;
  final double value;
  final Color color;
}

/// Card de resumo do mês: total, orçamento e divisão por categoria.
class RavixSummaryCard extends StatelessWidget {
  const RavixSummaryCard({
    super.key,
    required this.total,
    this.label = 'Gasto no mês',
    this.budget,
    this.categories = const [],
  });

  final double total;
  final String label;
  final double? budget;
  final List<RavixCategoryShare> categories;

  @override
  Widget build(BuildContext context) {
    final t = context.ravix;
    final small = Theme.of(context).textTheme.bodySmall!.copyWith(color: t.summaryMuted);

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: ShapeDecoration(color: t.summaryBackground, shape: RavixShapes.cut(RavixShapes.g)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: small),
          const SizedBox(height: 8),
          Text.rich(
            TextSpan(children: [
              TextSpan(text: r'R$ ', style: t.moneyList.copyWith(color: t.summaryMuted, fontSize: 16)),
              TextSpan(text: formatBRLNumber(total), style: t.moneyHero.copyWith(color: t.summaryForeground)),
            ]),
            semanticsLabel: formatBRL(total),
          ),
          if (budget != null && budget! > 0) ...[
            const SizedBox(height: 14),
            _BudgetBar(total: total, budget: budget!, small: small),
          ],
          if (categories.isNotEmpty) ...[
            const SizedBox(height: 14),
            _CategoryStack(categories: categories, small: small),
          ],
        ],
      ),
    );
  }
}

class _BudgetBar extends StatelessWidget {
  const _BudgetBar({required this.total, required this.budget, required this.small});
  final double total;
  final double budget;
  final TextStyle small;

  @override
  Widget build(BuildContext context) {
    final t = context.ravix;
    final ratio = total / budget;
    final left = budget - total;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(
          height: 8,
          child: LinearProgressIndicator(
            value: ratio.clamp(0.0, 1.0),
            backgroundColor: t.summaryTrack,
            color: ratio < 0.8 ? RavixColors.menta : t.budgetColor(ratio),
            borderRadius: BorderRadius.zero,
          ),
        ),
        const SizedBox(height: 6),
        Row(
          children: [
            Expanded(child: Text('${(ratio * 100).round()}% de ${formatBRL(budget)}', style: small)),
            Text(left >= 0 ? 'Restam ${formatBRL(left)}' : 'Passou ${formatBRL(-left)}', style: small),
          ],
        ),
      ],
    );
  }
}

class _CategoryStack extends StatelessWidget {
  const _CategoryStack({required this.categories, required this.small});
  final List<RavixCategoryShare> categories;
  final TextStyle small;

  @override
  Widget build(BuildContext context) {
    final items = categories.where((c) => c.value > 0).toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          height: 10,
          child: Row(
            children: [
              for (var i = 0; i < items.length; i++) ...[
                if (i > 0) const SizedBox(width: 2),
                Expanded(
                  flex: math.max(1, (items[i].value * 100).round()),
                  child: ColoredBox(color: items[i].color),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 12,
          runSpacing: 4,
          children: [
            for (final c in items)
              Row(mainAxisSize: MainAxisSize.min, children: [
                SizedBox.square(dimension: 7, child: ColoredBox(color: c.color)),
                const SizedBox(width: 5),
                Text(c.name, style: small.copyWith(fontSize: 11)),
              ]),
          ],
        ),
      ],
    );
  }
}

/// Cabeçalho de dia na lista, com o subtotal à direita.
class RavixDayHeader extends StatelessWidget {
  const RavixDayHeader({super.key, required this.label, required this.subtotal});
  final String label;
  final double subtotal;

  @override
  Widget build(BuildContext context) {
    final style = context.ravix.overline;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 6),
      child: Row(children: [
        Expanded(child: Text(label.toUpperCase(), style: style)),
        Text(formatBRL(subtotal), style: style.copyWith(fontFamily: RavixFonts.values)),
      ]),
    );
  }
}

/// Quadrado chanfrado com o ícone da categoria.
class RavixCategoryIcon extends StatelessWidget {
  const RavixCategoryIcon({super.key, required this.icon, required this.color, this.size = 36});
  final IconData icon;
  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: ShapeDecoration(color: color.withValues(alpha: 0.18), shape: RavixShapes.cut(RavixShapes.p)),
      child: Icon(icon, size: size / 2, color: color),
    );
  }
}

/// Linha de um gasto: ícone, descrição, detalhe e valor.
class RavixExpenseTile extends StatelessWidget {
  const RavixExpenseTile({
    super.key,
    required this.title,
    required this.detail,
    required this.amount,
    required this.icon,
    required this.color,
    this.onTap,
  });

  final String title;

  /// Ex.: "Padaria · 16:28 · Lanche da tarde"
  final String detail;
  final double amount;
  final IconData icon;
  final Color color;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    return InkWell(
      onTap: onTap,
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 64),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
          child: Row(children: [
            RavixCategoryIcon(icon: icon, color: color),
            const SizedBox(width: 12),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
                Text(title, maxLines: 1, overflow: TextOverflow.ellipsis, style: tt.bodyLarge?.copyWith(fontWeight: FontWeight.w500)),
                Text(detail, maxLines: 1, overflow: TextOverflow.ellipsis, style: tt.bodySmall),
              ]),
            ),
            const SizedBox(width: 12),
            Text(formatBRL(amount), style: context.ravix.moneyList.copyWith(color: tt.bodyLarge?.color)),
          ]),
        ),
      ),
    );
  }
}
