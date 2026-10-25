/// Preferências do usuário guardadas no aparelho.
library;

import 'package:flutter/material.dart';
import 'package:ravix/core/tema/icones.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shared_preferences/shared_preferences.dart';

part 'preferencias.g.dart';

/// Chave da aparência escolhida.
const chaveAparencia = 'aparencia';

/// Armazém de preferências simples (texto por chave).
abstract interface class Preferencias {
  /// Valor guardado em [chave], ou `null`.
  String? texto(String chave);

  /// Guarda [valor] em [chave].
  Future<void> gravarTexto(String chave, String valor);
}

/// [Preferencias] do aparelho (`shared_preferences`), com cache em memória:
/// a leitura é síncrona, então o app abre já no tema certo.
final class PreferenciasDoAparelho implements Preferencias {
  new _(this._prefs);

  /// Abre as preferências. Chame antes do `runApp`.
  static Future<PreferenciasDoAparelho> abrir() async =>
      PreferenciasDoAparelho._(
        await SharedPreferencesWithCache.create(
          cacheOptions: const SharedPreferencesWithCacheOptions(
            allowList: {chaveAparencia},
          ),
        ),
      );

  final SharedPreferencesWithCache _prefs;

  @override
  String? texto(String chave) => _prefs.getString(chave);

  @override
  Future<void> gravarTexto(String chave, String valor) =>
      _prefs.setString(chave, valor);
}

/// [Preferencias] só em memória (testes e padrão antes de abrir as do
/// aparelho).
final class PreferenciasEmMemoria implements Preferencias {
  /// Cria o armazém com [valores] iniciais.
  new([Map<String, String>? valores]) : _valores = {...?valores};

  final Map<String, String> _valores;

  @override
  String? texto(String chave) => _valores[chave];

  @override
  Future<void> gravarTexto(String chave, String valor) async =>
      _valores[chave] = valor;
}

/// Preferências do app. O `main` troca pelas do aparelho.
@Riverpod(keepAlive: true)
Preferencias preferencias(Ref ref) => PreferenciasEmMemoria();

/// Aparência do app (guia CAPRA: Sistema, Escuro ou Claro).
enum Aparencia {
  /// Segue o tema do sistema.
  sistema('Sistema', ThemeMode.system, Icones.smartphone),

  /// Sempre escuro.
  escuro('Escuro', ThemeMode.dark, Icones.moon),

  /// Sempre claro.
  claro('Claro', ThemeMode.light, Icones.sun);

  new(this.rotulo, this.modo, this.icone);

  /// Texto do seletor.
  final String rotulo;

  /// Modo de tema do `MaterialApp`.
  final ThemeMode modo;

  /// Ícone do seletor.
  final IconData icone;
}

/// Aparência escolhida, guardada nas preferências.
@Riverpod(keepAlive: true)
final class AparenciaEscolhida extends _$AparenciaEscolhida {
  @override
  Aparencia build() {
    final guardada = ref.watch(preferenciasProvider).texto(chaveAparencia);
    return Aparencia.values.asNameMap()[guardada] ?? Aparencia.sistema;
  }

  /// Troca a aparência e guarda a escolha.
  Future<void> escolher(Aparencia aparencia) async {
    state = aparencia;
    await ref
        .read(preferenciasProvider)
        .gravarTexto(chaveAparencia, aparencia.name);
  }
}
