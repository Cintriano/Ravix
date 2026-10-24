import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ravix/core/tema/capra_tokens.dart';
import 'package:ravix/core/tema/icones.dart';
import 'package:ravix/core/tema/tema.dart';
import 'package:ravix/features/shell/bloqueio.dart';

/// Tela de bloqueio (E01-F01-T07). Pede a credencial do aparelho ao aparecer
/// e oferece o botão para tentar de novo.
class TelaBloqueio extends ConsumerStatefulWidget {
  /// Cria a tela.
  const new({super.key});

  @override
  ConsumerState<TelaBloqueio> createState() => _TelaBloqueioState();
}

class _TelaBloqueioState extends ConsumerState<TelaBloqueio> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) unawaited(ref.read(bloqueioProvider.notifier).desbloquear());
    });
  }

  @override
  Widget build(BuildContext context) {
    final estado = ref.watch(bloqueioProvider);
    final texto = Theme.of(context).textTheme;
    final paleta = context.temaRavix.paleta;
    final mensagem = switch (estado.ultimoResultado) {
      ResultadoDesbloqueio.negado =>
        'Não foi possível confirmar. Tente de novo.',
      ResultadoDesbloqueio.falhou =>
        'O desbloqueio não está disponível agora. Tente de novo em instantes.',
      _ => null,
    };

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(CapraTokens.spaceMd),
          child: Column(
            children: [
              const Spacer(),
              Semantics(
                label: 'Ravix',
                image: true,
                child: Image.asset(
                  'assets/marca/ravix-marca.png',
                  width: 96,
                  height: 96,
                ),
              ),
              const SizedBox(height: CapraTokens.spaceLg),
              Text('Ravix está bloqueado', style: texto.titleLarge),
              const SizedBox(height: CapraTokens.spaceSm),
              Text(
                'Use a biometria ou o PIN do aparelho.',
                style: texto.bodyLarge?.copyWith(color: paleta.textSecondary),
                textAlign: TextAlign.center,
              ),
              if (mensagem != null) ...[
                const SizedBox(height: CapraTokens.spaceMd),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icones.circleAlert,
                      size: CapraTokens.iconSizeMd,
                      color: paleta.danger,
                    ),
                    const SizedBox(width: CapraTokens.spaceSm),
                    Flexible(
                      child: Text(
                        mensagem,
                        style: texto.bodyLarge?.copyWith(color: paleta.danger),
                      ),
                    ),
                  ],
                ),
              ],
              const Spacer(),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: () =>
                      ref.read(bloqueioProvider.notifier).desbloquear(),
                  icon: const Icon(Icones.fingerprint),
                  label: const Text('Desbloquear'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
