import 'package:flutter_test/flutter_test.dart';
import 'package:ravix/data/banco.dart';
import 'package:ravix/data/categoria_repository.dart';

import '../helpers/banco_de_teste.dart';

void main() {
  late BancoRavix banco;
  late CategoriaRepository categorias;

  setUp(() {
    banco = bancoEmMemoria();
    categorias = CategoriaRepository(banco);
  });
  tearDown(() => banco.close());

  Future<List<String>> nomesDaCategoria(int id) async =>
      (await categorias.listarSubcategorias(id)).map((s) => s.nome).toList();

  test('categorias em ordem alfabética', () async {
    final nomes = (await categorias.listarCategorias()).map((c) => c.nome);
    expect(nomes, [
      'Alimentação',
      'Compras e Bens',
      'Contas a pagar',
      'Educação',
      'Lazer',
      'Moradia',
      'Saúde e Bem-estar',
      'Transporte',
    ]);
  });

  test('subcategorias em ordem alfabética, com Diversos por último', () async {
    expect(await nomesDaCategoria(5), [
      'Casa e Decoração',
      'Construção e Reparos',
      'Eletro e Móveis',
      'Ferramentas',
      'Presentes',
      'Tech e Eletrônicos',
      'Vestuário',
      'Diversos',
    ]);
  });

  test('a ordem ignora acentos', () async {
    expect(await nomesDaCategoria(4), [
      'Alcoólicos',
      'Entrada e Ingressos',
      'Hobbies e Jogos',
      'Viagens e Turismo',
    ]);
  });

  test('só traz as subcategorias da categoria pedida', () async {
    expect(await nomesDaCategoria(7), ['Aluguel', 'Condomínio', 'IPTU']);
    expect(await nomesDaCategoria(99), isEmpty);
  });

  test('busca subcategoria pelo ID', () async {
    final sub = (await categorias.buscarSubcategoria(302))!;
    expect(sub.nome, 'Mobilidade Urbana');
    expect(sub.idCategoria, 3);
    expect(await categorias.buscarSubcategoria(403), isNull);
  });
}
