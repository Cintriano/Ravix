import 'package:flutter/material.dart';
import 'package:ravix/app/dependencias.dart';
import 'package:ravix/data/banco.dart';
import 'package:ravix/features/faturado/formulario_compra_faturada.dart';
import 'package:ravix/features/faturado/formulario_estorno.dart';
import 'package:ravix/features/faturado/formulario_pagamento_fatura.dart';
import 'package:ravix/features/registro/tipo_registro.dart';

/// Rota da compra no cartão: cria sem [uuid]; com [uuid], carrega e edita.
class TelaCompraFaturada extends StatelessWidget {
  /// Cria a tela.
  const new({this.uuid, super.key});

  /// Compra a editar.
  final String? uuid;

  @override
  Widget build(BuildContext context) => switch (uuid) {
    null => const FormularioCompraFaturada(),
    final uuid => CarregarParaEditar<CompraFaturada>(
      titulo: 'Editar compra no cartão',
      buscar: (ref) => ref.read(faturadoRepositoryProvider).buscarCompra(uuid),
      formulario: (compra) => FormularioCompraFaturada(compra: compra),
    ),
  };
}

/// Rota do pagamento de fatura: cria sem [uuid]; com [uuid], edita.
class TelaPagamentoFatura extends StatelessWidget {
  /// Cria a tela.
  const new({this.uuid, super.key});

  /// Pagamento a editar.
  final String? uuid;

  @override
  Widget build(BuildContext context) => switch (uuid) {
    null => const FormularioPagamentoFatura(),
    final uuid => CarregarParaEditar<PagamentoFatura>(
      titulo: 'Editar pagamento de fatura',
      buscar: (ref) =>
          ref.read(faturadoRepositoryProvider).buscarPagamento(uuid),
      formulario: (p) => FormularioPagamentoFatura(pagamento: p),
    ),
  };
}

/// Rota do estorno: cria sem [uuid]; com [uuid], edita.
class TelaEstorno extends StatelessWidget {
  /// Cria a tela.
  const new({this.uuid, super.key});

  /// Estorno a editar.
  final String? uuid;

  @override
  Widget build(BuildContext context) => switch (uuid) {
    null => const FormularioEstorno(),
    final uuid => CarregarParaEditar<Estorno>(
      titulo: 'Editar estorno',
      buscar: (ref) => ref.read(faturadoRepositoryProvider).buscarEstorno(uuid),
      formulario: (e) => FormularioEstorno(estorno: e),
    ),
  };
}
