import 'dart:math';

import 'package:drift/drift.dart';
import 'package:ravix/core/datas.dart';
import 'package:ravix/core/texto.dart';
import 'package:ravix/data/banco.dart';
import 'package:ravix/data/carga_inicial.dart';

/// Descrições realistas por subcategoria, para a sugestão ter histórico.
const _descricoes = <int, List<String>>{
  101: ['Padaria do Zé', 'Pão de Açúcar padaria', 'Padaria Real'],
  102: ['Supermercado Dia', 'Atacadão', 'Mercado Central'],
  103: ['Restaurante Sabor', 'Almoço por quilo', 'Jantar fora'],
  104: ['iFood', 'Pizza delivery', 'Hamburgueria delivery'],
  105: ['Café da esquina', 'Açaí do Parque', 'Lanchonete'],
  201: ['Drogasil', 'Farmácia Pague Menos'],
  301: ['Posto Shell', 'Posto Ipiranga'],
  302: ['Uber', '99 corrida'],
  303: ['Zona azul', 'Estacionamento shopping'],
  401: ['Steam', 'Loja de jogos'],
  404: ['Bar do Chico', 'Adega'],
  504: ['Renner', 'Loja de roupas'],
  507: ['Shopee', 'Mercado Livre'],
  601: ['Netflix', 'Spotify', 'Google One'],
  602: ['Conta de luz', 'Internet fibra'],
};

const _formas = ['pix', 'debito', 'dinheiro', 'voucher'];

/// Grava [quantidade] gastos à vista sintéticos espalhados pelos [meses]
/// anteriores a [ate], de forma reproduzível pela [semente]. Cerca de 15%
/// levam uma das 5 tags criadas aqui.
///
/// Só para medir desempenho (DP-36): nunca rode no banco de uso.
Future<void> gerarMassaDeTeste(
  BancoRavix banco, {
  required DateTime ate,
  int quantidade = 20000,
  int meses = 60,
  int semente = 42,
}) async {
  final sorte = Random(semente);
  final inicio = DateTime(ate.year, ate.month - meses, ate.day);
  final janela = ate.difference(inicio).inSeconds;
  final agora = paraIsoUtc(ate);
  final subcategorias = subcategoriasIniciais.map((s) => s.id).toList();
  String uuid(String prefixo, int n) =>
      '$prefixo-0000-4000-8000-${n.toString().padLeft(12, '0')}';

  await banco.transaction(() async {
    const nomes = ['Viagem', 'Rolê', 'Aniversário', 'Mudança', 'Trabalho'];
    final tags = [for (var i = 0; i < nomes.length; i++) uuid('7a600000', i)];
    await banco.batch(
      (b) => b.insertAll(banco.tblTag, [
        for (var i = 0; i < nomes.length; i++)
          TblTagCompanion.insert(
            uuidTag: tags[i],
            nome: nomes[i],
            criadoEm: agora,
            atualizadoEm: agora,
          ),
      ]),
    );

    const lote = 1000;
    for (var feitos = 0; feitos < quantidade; feitos += lote) {
      await banco.batch((b) {
        b.insertAll(banco.tblCompraAvista, [
          for (var i = feitos; i < min(feitos + lote, quantidade); i++)
            () {
              final sub = sorte.nextInt(3) == 0
                  ? subcategorias[sorte.nextInt(subcategorias.length)]
                  : _descricoes.keys.elementAt(
                      sorte.nextInt(_descricoes.length),
                    );
              final nomes = _descricoes[sub] ?? const ['Compra avulsa'];
              final descricao = nomes[sorte.nextInt(nomes.length)];
              final momento = inicio.add(
                Duration(seconds: sorte.nextInt(janela)),
              );
              return TblCompraAvistaCompanion.insert(
                uuidCompraAvista: uuid('c0a00000', i),
                timestampCompraAvista: paraIsoLocal(momento),
                fusoMinutos: -180,
                descricao: descricao,
                descricaoNormalizada: normalizarTexto(descricao),
                valorCompraAvista: 100 + sorte.nextInt(30000),
                tipoPagamento: _formas[sorte.nextInt(_formas.length)],
                idSubcategoria: sub,
                uuidTag: Value(
                  sorte.nextDouble() < 0.15
                      ? tags[sorte.nextInt(tags.length)]
                      : null,
                ),
                criadoEm: agora,
                atualizadoEm: agora,
              );
            }(),
        ]);
      });
    }
  });
}
