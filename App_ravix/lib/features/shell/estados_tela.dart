/// Estados de tela padrão (E01-F02-T04): carregando, vazio e erro.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ravix/core/tema/icones.dart';
import 'package:ravix/core/tema/marca.dart';
import 'package:ravix/core/tema/tema.dart';
import 'package:ravix/core/tema/tokens.dart';

/// Carregando: o símbolo da marca com a seta passando, em laço. Fica
/// parado quando o sistema pede para reduzir movimento.
class EstadoCarregando extends StatelessWidget {
  /// Cria o indicador.
  const new({super.key});

  @override
  Widget build(BuildContext context) => Center(
    child: Semantics(
      label: 'Carregando…',
      child: const ExcludeSemantics(child: MarcaRavix.simbolo(emLaco: true)),
    ),
  );
}

/// Estado vazio: símbolo da marca, título, uma frase e, se houver, uma
/// ação.
class EstadoVazio extends StatelessWidget {
  /// Cria o estado vazio.
  const new({
    required this.titulo,
    required this.mensagem,
    this.rotuloAcao,
    this.aoAgir,
    super.key,
  });

  /// Título em H2.
  final String titulo;

  /// Uma frase explicando o vazio.
  final String mensagem;

  /// Texto do botão de ação; sem ele, não há botão.
  final String? rotuloAcao;

  /// Ação do botão.
  final VoidCallback? aoAgir;

  @override
  Widget build(BuildContext context) {
    final texto = Theme.of(context).textTheme;
    final tema = context.temaRavix;
    return _Centralizado(
      children: [
        const ExcludeSemantics(child: MarcaRavix.simbolo(altura: 48)),
        const SizedBox(height: TokensRavix.spaceLg),
        Text(titulo, style: texto.titleLarge, textAlign: TextAlign.center),
        const SizedBox(height: TokensRavix.spaceSm),
        Text(
          mensagem,
          style: texto.bodyLarge?.copyWith(color: tema.paleta.textSecondary),
          textAlign: TextAlign.center,
        ),
        if (rotuloAcao != null) ...[
          const SizedBox(height: TokensRavix.spaceLg),
          OutlinedButton(onPressed: aoAgir, child: Text(rotuloAcao!)),
        ],
      ],
    );
  }
}

/// Estado de erro: ícone e mensagem em `danger` e a ação de tentar de novo.
class EstadoErro extends StatelessWidget {
  /// Cria o estado de erro.
  const new({
    this.titulo = 'Algo deu errado',
    this.mensagem = 'Não foi possível carregar os dados.',
    this.aoTentarDeNovo,
    super.key,
  });

  /// Título em H2.
  final String titulo;

  /// O que aconteceu e o que fazer.
  final String mensagem;

  /// Ação de tentar de novo; sem ela, não há botão.
  final VoidCallback? aoTentarDeNovo;

  @override
  Widget build(BuildContext context) {
    final texto = Theme.of(context).textTheme;
    final paleta = context.temaRavix.paleta;
    return _Centralizado(
      children: [
        Icon(Icones.circleAlert, size: 40, color: paleta.danger),
        const SizedBox(height: TokensRavix.spaceMd),
        Text(titulo, style: texto.titleLarge, textAlign: TextAlign.center),
        const SizedBox(height: TokensRavix.spaceSm),
        Text(
          mensagem,
          style: texto.bodyLarge?.copyWith(color: paleta.textSecondary),
          textAlign: TextAlign.center,
        ),
        if (aoTentarDeNovo != null) ...[
          const SizedBox(height: TokensRavix.spaceLg),
          OutlinedButton.icon(
            onPressed: aoTentarDeNovo,
            icon: const Icon(Icones.refreshCw, size: TokensRavix.iconSizeMd),
            label: const Text('Tentar de novo'),
          ),
        ],
      ],
    );
  }
}

class _Centralizado extends StatelessWidget {
  const new({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) => Center(
    child: SingleChildScrollView(
      padding: const EdgeInsets.all(TokensRavix.spaceXl),
      child: Column(mainAxisSize: MainAxisSize.min, children: children),
    ),
  );
}

/// Mostra o estado certo de um [AsyncValue]: carregando, erro, vazio ou o
/// conteúdo.
class ConteudoAssincrono<T> extends StatelessWidget {
  /// Cria o seletor de estados.
  const new({
    required this.valor,
    required this.conteudo,
    this.estaVazio,
    this.vazio,
    this.aoTentarDeNovo,
    super.key,
  });

  /// Valor observado.
  final AsyncValue<T> valor;

  /// Conteúdo quando há dados.
  final Widget Function(T dados) conteudo;

  /// Diz se os dados contam como vazio. Sem ele, nunca é vazio.
  final bool Function(T dados)? estaVazio;

  /// Estado vazio a mostrar quando [estaVazio] for verdadeiro.
  final Widget? vazio;

  /// Ação do botão do estado de erro.
  final VoidCallback? aoTentarDeNovo;

  @override
  Widget build(BuildContext context) => switch (valor) {
    AsyncData(:final value) when estaVazio?.call(value) ?? false =>
      vazio ?? const SizedBox.shrink(),
    AsyncData(:final value) => conteudo(value),
    AsyncError() => EstadoErro(aoTentarDeNovo: aoTentarDeNovo),
    _ => const EstadoCarregando(),
  };
}
