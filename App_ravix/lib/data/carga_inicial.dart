/// Carga inicial de categorias e subcategorias (E01-F03-T10, DP-11).
///
/// Os nomes vão para o banco; a descrição fica só no app, como texto de
/// ajuda. O ID 403 não existe (subcategoria removida).
library;

/// Uma categoria da carga inicial.
typedef CategoriaInicial = ({int id, String nome});

/// Uma subcategoria da carga inicial. O `id` segue categoria × 100 +
/// sequência.
typedef SubcategoriaInicial = ({
  int id,
  int idCategoria,
  String nome,
  String descricao,
});

/// As 8 categorias da v1.
const List<CategoriaInicial> categoriasIniciais = [
  (id: 1, nome: 'Alimentação'),
  (id: 2, nome: 'Saúde e Bem-estar'),
  (id: 3, nome: 'Transporte'),
  (id: 4, nome: 'Lazer'),
  (id: 5, nome: 'Compras e Bens'),
  (id: 6, nome: 'Contas a pagar'),
  (id: 7, nome: 'Moradia'),
  (id: 8, nome: 'Educação'),
];

/// As 34 subcategorias da v1.
const List<SubcategoriaInicial> subcategoriasIniciais = [
  (
    id: 101,
    idCategoria: 1,
    nome: 'Padaria',
    descricao: 'Pão, leite e itens de café da manhã ou consumo rápido.',
  ),
  (
    id: 102,
    idCategoria: 1,
    nome: 'Supermercado',
    descricao: 'Compras mensais/semanais de mantimentos, limpeza e higiene.',
  ),
  (id: 103, idCategoria: 1, nome: 'Refeição', descricao: 'Almoço ou jantar.'),
  (
    id: 104,
    idCategoria: 1,
    nome: 'Delivery',
    descricao: 'Comida pedida em casa (iFood, pizza, hambúrguer).',
  ),
  (
    id: 105,
    idCategoria: 1,
    nome: 'Lanche',
    descricao: 'Cafés, doces, salgados e gastos pequenos fora de hora.',
  ),
  (
    id: 201,
    idCategoria: 2,
    nome: 'Farmácia',
    descricao: 'Medicamentos, vitaminas e curativos.',
  ),
  (
    id: 202,
    idCategoria: 2,
    nome: 'Cuidados Pessoais',
    descricao: 'Corte de cabelo, barba e cosméticos.',
  ),
  (
    id: 203,
    idCategoria: 2,
    nome: 'Saúde',
    descricao: 'Consultas médicas, dentista, exames.',
  ),
  (
    id: 301,
    idCategoria: 3,
    nome: 'Combustível',
    descricao: 'Abastecimento do veículo.',
  ),
  (
    id: 302,
    idCategoria: 3,
    nome: 'Mobilidade Urbana',
    descricao: 'Caronas, Uber.',
  ),
  (
    id: 303,
    idCategoria: 3,
    nome: 'Estacionamento',
    descricao: 'Zona azul, shoppings, valets.',
  ),
  (
    id: 304,
    idCategoria: 3,
    nome: 'Manutenção',
    descricao: 'Mecânico, revisões, troca de óleo, lavagem e peças.',
  ),
  (
    id: 401,
    idCategoria: 4,
    nome: 'Hobbies e Jogos',
    descricao: 'Jogos, colecionáveis, instrumentos e cursos livres.',
  ),
  (
    id: 402,
    idCategoria: 4,
    nome: 'Entrada e Ingressos',
    descricao: 'Cinema, teatro, shows e museus.',
  ),
  (
    id: 404,
    idCategoria: 4,
    nome: 'Alcoólicos',
    descricao: 'Bebidas em bares/festas ou compra de álcool para casa.',
  ),
  (
    id: 405,
    idCategoria: 4,
    nome: 'Viagens e Turismo',
    descricao: 'Hospedagem, pacotes turísticos e passeios de férias.',
  ),
  (
    id: 501,
    idCategoria: 5,
    nome: 'Presentes',
    descricao: 'Mimos para terceiros, doações e datas comemorativas.',
  ),
  (
    id: 502,
    idCategoria: 5,
    nome: 'Eletro e Móveis',
    descricao: 'Geladeira, fogão, micro-ondas, móveis e eletroportáteis.',
  ),
  (
    id: 503,
    idCategoria: 5,
    nome: 'Construção e Reparos',
    descricao:
        'Materiais (fita isolante, parafusos, tintas) e serviços da casa.',
  ),
  (id: 504, idCategoria: 5, nome: 'Vestuário', descricao: 'Peças de roupa.'),
  (
    id: 505,
    idCategoria: 5,
    nome: 'Ferramentas',
    descricao: 'Ferramentas manuais, elétricas e equipamentos em geral.',
  ),
  (
    id: 506,
    idCategoria: 5,
    nome: 'Tech e Eletrônicos',
    descricao: 'Peças de PC (processador, watercooler), celulares, TVs, fones.',
  ),
  (
    id: 507,
    idCategoria: 5,
    nome: 'Diversos',
    descricao: 'Papelaria e compras genéricas (Shopee, Mercado Livre etc.).',
  ),
  (
    id: 508,
    idCategoria: 5,
    nome: 'Casa e Decoração',
    descricao: 'Utensílios de cozinha, cama/mesa/banho e itens decorativos.',
  ),
  (
    id: 601,
    idCategoria: 6,
    nome: 'Serviços online',
    descricao: 'Mensalidades de serviços (Netflix, Spotify, Google, Notion).',
  ),
  (
    id: 602,
    idCategoria: 6,
    nome: 'Contas de Consumo',
    descricao: 'Boletos de água, energia e internet.',
  ),
  (
    id: 603,
    idCategoria: 6,
    nome: 'Tarifas bancárias',
    descricao: 'Anuidade, tarifas de conta e de transferências.',
  ),
  (
    id: 604,
    idCategoria: 6,
    nome: 'Impostos',
    descricao: 'IPVA, imposto de renda e demais tributos (IPTU fica em 703).',
  ),
  (id: 701, idCategoria: 7, nome: 'Aluguel', descricao: 'Aluguel do imóvel.'),
  (
    id: 702,
    idCategoria: 7,
    nome: 'Condomínio',
    descricao: 'Taxa de condomínio.',
  ),
  (
    id: 703,
    idCategoria: 7,
    nome: 'IPTU',
    descricao: 'Imposto predial do imóvel.',
  ),
  (
    id: 801,
    idCategoria: 8,
    nome: 'Cursos',
    descricao:
        'Cursos, certificações e treinamentos profissionais '
        '(cursos de hobby ficam em 401).',
  ),
  (
    id: 802,
    idCategoria: 8,
    nome: 'Livros e material',
    descricao: 'Livros, apostilas e material de estudo.',
  ),
  (
    id: 803,
    idCategoria: 8,
    nome: 'Mensalidade',
    descricao: 'Faculdade, pós-graduação e escola.',
  ),
];
