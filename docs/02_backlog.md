# Ravix — Backlog

> Exportado do Notion (Projetos / Ravix / Backlog app) em 24/10/2026.
> Fonte: https://app.notion.com/p/3dfb044db6b180628983e3c499af7208

**Documentos relacionados:** [01_visao_geral_e_arquitetura.md](01_visao_geral_e_arquitetura.md) · [03_modelo_de_dados.md](03_modelo_de_dados.md)

**Hierarquia:** Épico (E) → Feature (F) → Task (T)<br />
**Legenda:** `v1`, `v2`, `v3` = versão planejada · `(F)` = finalizada · ⚠ = premissa a confirmar

> **Revisão:** E01 reestruturado com abordagem top-down (mapa do app → features → tasks). E02 atualizado (campo `importancia` removido do projeto). E03 e E04 mantidos como estavam, para discussão posterior.

> **Revisão 2 (08/10/2026):** visão macro movida para a v2; categorias e subcategorias adicionadas (E01-F03); criadas as tasks de cadastro de cartão, a regra do consumo do limite e as telas faltantes (excluir registro, novo registro na aba faturada, gerenciar recorrências). Os demais pontos da revisão do E01 estão no quadro [Decisões pendentes](05_decisoes.md), para revisão.

> **Revisão 3 (11/10/2026):** aplicadas as decisões do quadro (DP-3, 5, 6, 7, 8, 9, 15, 16, 17, 21, 22, 27 e 30, mais a parte decidida de DP-11 e DP-14). Principais mudanças: v1 só local, renda na v2 com vigência mensal, regime de caixa com mês de vencimento, botão flutuante de novo registro, tipo pagamento de fatura, categoria Rolê e versões do E03 e do E04.

> **Revisão 4 (21/10/2026):** classificação em três níveis (DP-32): categoria e subcategoria para a natureza do gasto, tag opcional para o contexto. Categoria Rolê removida; Moradia e Educação criadas; tarifas bancárias e impostos em Contas a pagar (DP-11). Configuração entra na v1 só com a aba Tags. Bloqueio local pelo PIN do aparelho (DP-31). E01 fechado para a v1.

> **Revisão 5 (22/10/2026):** modelo de dados da v1 fechado (DP-33, DP-34): sem `uuid_usuario` nas tabelas locais (o usuário é gravado na carga para o banco externo), datas em horário local com `fuso_minutos` (auditoria em UTC), exclusão física na v1 e lógica na v2. E01 e E02-F01 fechados para a v1.

> **Revisão 6 (24/10/2026):** v1 implementada e instalada ([Plano de desenvolvimento — v1](04_plano_desenvolvimento_v1.md), M0 a M7). Todas as tasks `v1` marcadas como (F). Além do backlog: escolha de aparência (Sistema, Escuro, Claro) na Configuração, que virou uma lista com Aparência e Tags; filtro de tag inclui as arquivadas. Na v1 o app abre na aba à vista sem barra de abas, que aparece quando houver duas ou mais.

---

## E01 — Front-end

### Mapa do app (Nível 0)

```txt
App
├─ Autenticação
│   ├─ Bloqueio local ao abrir o app (v1)
│   ├─ Login (e-mail + senha, biometria após 1ª sessão) (v2, com o backend)
│   └─ Cadastro (nome, e-mail, senha) (v2, com o backend)
├─ Shell
│   ├─ Cabeçalho: seletor de mês global (passados e futuros) + última atualização (v2) + farol de conexão (v2)
│   ├─ Botão flutuante de novo registro (tipo da aba ativa)
│   ├─ Aba Visão macro (v2; aba padrão a partir da v2)
│   ├─ Aba Visão faturada (v2)
│   └─ Aba Visão à vista (v1)
├─ Formulário de registro (único, parametrizado)
│   ├─ tipo: à vista | faturado (parcelado ou recorrente) | pagamento de fatura (v2)
│   ├─ modo: criar | editar | completar pendência
│   ├─ classificação: categoria → subcategoria + tag opcional (DP-32)
│   └─ excluir registro (no modo editar)
├─ Configuração (v1: aba Tags; v2: renda + cartões, único ponto de entrada da renda)
│   ├─ Aba Tags (v1)
│   ├─ Cadastro e edição de cartão (v2)
│   └─ Gerenciar recorrências (v2)
├─ Visão por tag (v2)
├─ Registros pendentes (também recebe capturas para aprovação)
├─ Central de notificações do sistema
└─ Onboarding de permissões
```

### Decisões de projeto que valem para todo o E01

- **Seletor de mês global** no Shell. As três abas leem esse estado; nenhuma tem filtro de mês próprio.
- **Formulário único** parametrizado por `tipo` e `modo`. Botões de edição (abas e pendências) chamam o mesmo componente.
- **Renda** é editada só na Configuração.
- **Estados de tela padrão** (carregando, vazio, erro e, a partir da v2, offline) em todas as telas que consultam dados.
- O faturado **sempre** entra na visão macro.
- A **visão macro** entra na v2, junto com o faturado. Na v1, o app abre na aba à vista.
- A **v1 é só local** (SQLite), sem backend. Login com conta, sincronização, indicador de última atualização e estado offline entram com o backend, na v2 (DP-7).
- **Regime de caixa:** o mês de um gasto faturado é o mês de vencimento da fatura; o à vista conta pela data da compra (DP-9).
- **Pagamento de fatura** é um tipo de registro próprio e não entra nas somas de consumo (DP-14).
- **Classificação em três níveis** (DP-32): categoria e subcategoria descrevem a natureza do gasto e são obrigatórias; a tag descreve o contexto (viagem, rolê etc.), é opcional e única por registro. A tag é um recorte dos mesmos registros e não soma nada ao consumo.

---

### E01-F01 — Autenticação

Na v1 o app é só local: a autenticação se resume ao bloqueio local (T07). Login, cadastro e logout entram com o backend (DP-7).

- **T01** Tela de login: logo centralizada, e-mail e senha `v2`
- **T02** Tela de cadastro: nome, e-mail, senha `v2`
- **T03** Logout `v2`
- **T04** Autenticação biométrica, oferecida após o primeiro login válido `v2`
- **T05** Recuperação de senha `v2`
- **T06** Tratamento de sessão expirada `v2`
- **T07** Bloqueio local ao abrir o app `v1` (F)
  - PIN ou padrão do próprio Android, via `local_auth`; o app não guarda PIN próprio (DP-31).

### E01-F02 — Shell (tela inicial)

- **T01** Estrutura de abas: À vista `v1` (F); Macro (padrão) e Faturada `v2`
- **T02** Seletor de mês global: meses passados e futuros (nos futuros aparecem parcelas e recorrências previstas) `v1` (F)
- **T03** Indicador de data da última atualização dos dados `v2`
- **T04** Padrão de estados de tela: carregando, vazio e erro `v1` (F); offline `v2`
- **T05** Navegação para Configuração `v1` (F); Registros pendentes e Central de notificações `v2`
  - Na v1 a Configuração tem só a aba Tags (F07-T09); renda, cartões, pendências e notificações são v2.
- **T06** Farol de conexão do app com a API `v2`
  - 🟢 conectado e sincronizado
  - 🟡 sincronizando ou dados desatualizados além do limite (limite a definir)
  - 🔴 falha, com a causa na mensagem: sem internet, API própria indisponível ou conexão bancária expirada
  - Ao tocar, abre a Central de notificações com o log resumido
- **T07** Botão flutuante de novo registro: abre o formulário no tipo da aba ativa; na aba Macro, pergunta o tipo `v1` (F)
  - Substitui os botões por aba (F04-T04 e F05-T08), conforme DP-16.

### E01-F03 — Formulário de registro (único)

Componente reutilizável. Define `tipo` (à vista, faturado ou pagamento de fatura) e `modo` (criar | editar | completar pendência).

- **T01** Estrutura base parametrizada por tipo e modo `v1` (F)
- **T02** Data e hora automáticas e editáveis `v1` (F)
  - Datas futuras são aceitas (DP-15).
  - O app grava o fuso do aparelho (deslocamento em minutos, lido do sistema, sem rede) junto com a data. Ao editar a data, usa o fuso atual; se a data não for tocada, mantém o gravado (DP-33).
- **T03** Campo de valor com máscara monetária de até duas casas decimais, sempre maior que zero `v1` (F)
- **T04** Campos do tipo **à vista** `v1` (F)
  - UUID (sistema), data, hora, descrição, valor
  - Forma de pagamento: Pix, débito, dinheiro, voucher
  - Categoria, subcategoria (ver T10) e tag opcional (ver T15)
- **T05** Modo editar (acionado pelos botões de edição das abas) `v1` (F)
- **T06** Campos do tipo **faturado** `v2`
  - UUID (sistema), data, hora, descrição, valor total
  - Cartão
  - Mês e ano de vencimento da fatura, manuais (DP-3, DP-9)
  - Categoria, subcategoria (ver T10) e tag opcional (ver T15)
  - Quantidade de parcelas (fatura finita) **ou** recorrência (fatura de serviço), ver T08
- **T07** Seleção de cartão, incluindo cartão sugerido pelo app (ver E04-F03) `v2`
- **T08** Toggle **Cobrança recorrente** (somente tipo faturado) `v2`
  - Ativo: esconde quantidade de parcelas e mostra periodicidade, dia de cobrança e data fim (opcional)
  - Depende de `tbl_recorrencia` (ver modelagem banco)
- **T09** Modo completar pendência `v2`
- **T10** Carga inicial de categorias e subcategorias (tabela abaixo), usada nos dois tipos de registro `v1` (F)
- **T11** Excluir registro no modo editar, com confirmação `v1` (F)
- **T12** Editar ou excluir lançamento recorrente: escolher entre "só este" e "este e os próximos" `v2`
- **T13** Campos do tipo **pagamento de fatura** `v2`
  - UUID (sistema), data, hora, valor, forma de pagamento (Pix ou débito), cartão, mês e ano de vencimento da fatura paga
  - Não entra nas somas de consumo; marca a fatura como paga (F05-T09)
- **T14** Validação: todos os campos são obrigatórios, exceto a tag e a data fim da recorrência (vazia = sem fim) `v1` (F)
- **T15** Campo **tag**: opcional, uma por registro, com seletor das tags ativas e criação inline ("+ nova tag") `v1` (F)
- **T16** Sugestão de categoria e subcategoria pela descrição: histórico que contém o texto digitado, subcategoria mais frequente (desempate pela mais recente), a partir de 3 caracteres com espera de 300 ms; só preenche se o usuário ainda não escolheu (DP-36) `v1` (F)

*Decidido:* mês e ano de vencimento são preenchidos só pelo formulário (DP-3). Compras faturadas vindas da API ou de notificações chegam sem esse campo e entram em Registros pendentes para completar.

#### Categorias e subcategorias (carga inicial)

Fonte: planilha `App_Gestão_Financeira.xlsx`, aba Categorias, ajustada pelo DP-11 (8 categorias, 34 subcategorias). O ID da subcategoria segue o padrão categoria × 100 + sequência. Os registros guardam só os IDs; os nomes ficam em `tbl_categoria` e `tbl_subcategoria` (DP-21). Contexto não é categoria: viagem, rolê etc. vão na tag (T15). O Uber da festa, por exemplo, é 302 + tag. Os IDs 7 e 8 foram reaproveitados por Moradia e Educação, já que a antiga categoria Rolê nunca teve registros. Nos seletores, categorias e subcategorias aparecem em ordem alfabética, com Diversos sempre por último (DP-36).

| Categoria | Subcategoria | Descrição |
| --- | --- | --- |
| 1 · Alimentação | 101 · Padaria | Pão, leite e itens de café da manhã ou consumo rápido. |
| 1 · Alimentação | 102 · Supermercado | Compras mensais/semanais de mantimentos, limpeza e higiene. |
| 1 · Alimentação | 103 · Refeição | Almoço ou jantar. |
| 1 · Alimentação | 104 · Delivery | Comida pedida em casa (iFood, pizza, hambúrguer). |
| 1 · Alimentação | 105 · Lanche | Cafés, doces, salgados e gastos pequenos fora de hora. |
| 2 · Saúde e Bem-estar | 201 · Farmácia | Medicamentos, vitaminas e curativos. |
| 2 · Saúde e Bem-estar | 202 · Cuidados Pessoais | Corte de cabelo, barba e cosméticos. |
| 2 · Saúde e Bem-estar | 203 · Saúde | Consultas médicas, dentista, exames. |
| 3 · Transporte | 301 · Combustível | Abastecimento do veículo. |
| 3 · Transporte | 302 · Mobilidade Urbana | Caronas, Uber. |
| 3 · Transporte | 303 · Estacionamento | Zona azul, shoppings, valets. |
| 3 · Transporte | 304 · Manutenção | Mecânico, revisões, troca de óleo, lavagem e peças. |
| 4 · Lazer | 401 · Hobbies e Jogos | Jogos, colecionáveis, instrumentos e cursos livres. |
| 4 · Lazer | 402 · Entrada e Ingressos | Cinema, teatro, shows e museus. |
| 4 · Lazer | 404 · Alcoólicos | Bebidas em bares/festas ou compra de álcool para casa. |
| 4 · Lazer | 405 · Viagens e Turismo | Hospedagem, pacotes turísticos e passeios de férias. |
| 5 · Compras e Bens | 501 · Presentes | Mimos para terceiros, doações e datas comemorativas. |
| 5 · Compras e Bens | 502 · Eletro e Móveis | Geladeira, fogão, micro-ondas, móveis e eletroportáteis. |
| 5 · Compras e Bens | 503 · Construção e Reparos | Materiais (fita isolante, parafusos, tintas) e serviços da casa. |
| 5 · Compras e Bens | 504 · Vestuário | Peças de roupa. |
| 5 · Compras e Bens | 505 · Ferramentas | Ferramentas manuais, elétricas e equipamentos em geral. |
| 5 · Compras e Bens | 506 · Tech e Eletrônicos | Peças de PC (processador, watercooler), celulares, TVs, fones. |
| 5 · Compras e Bens | 507 · Diversos | Papelaria e compras genéricas (Shopee, Mercado Livre etc.). |
| 5 · Compras e Bens | 508 · Casa e Decoração | Utensílios de cozinha, cama/mesa/banho e itens decorativos. |
| 6 · Contas a pagar | 601 · Serviços online | Mensalidades de serviços (Netflix, Spotify, Google, Notion). |
| 6 · Contas a pagar | 602 · Contas de Consumo | Boletos de água, energia e internet. |
| 6 · Contas a pagar | 603 · Tarifas bancárias | Anuidade, tarifas de conta e de transferências. |
| 6 · Contas a pagar | 604 · Impostos | IPVA, imposto de renda e demais tributos (IPTU fica em 703). |
| 7 · Moradia | 701 · Aluguel | Aluguel do imóvel. |
| 7 · Moradia | 702 · Condomínio | Taxa de condomínio. |
| 7 · Moradia | 703 · IPTU | Imposto predial do imóvel. |
| 8 · Educação | 801 · Cursos | Cursos, certificações e treinamentos profissionais (cursos de hobby ficam em 401). |
| 8 · Educação | 802 · Livros e material | Livros, apostilas e material de estudo. |
| 8 · Educação | 803 · Mensalidade | Faculdade, pós-graduação e escola. |

### E01-F04 — Aba visão à vista

Consumo à vista (Pix, débito, dinheiro físico, voucher). Dinheiro físico e voucher são registrados manualmente.

- **T01** Acumulado de gastos do mês `v1` (F)
- **T02** Tabela de histórico de consumo (somente o mês selecionado) `v1` (F)
- **T03** Botão de edição do registro na tabela `v1` (F)
- **T04** ~~Botão de novo registro na aba~~ substituído pelo botão flutuante do Shell (F02-T07)
- **T05** Filtro de categoria/subcategoria e tag `v1` (F)
- **T06** Gráfico de gasto agregado por categoria/subcategoria, com seletor de visão `v2`

*Comportamento dos filtros:* o mês (global) afeta a tela inteira; categoria/subcategoria e tag filtram apenas a tabela.

### E01-F05 — Aba visão faturada

Considera vários cartões simultaneamente.

- **T01** Tabela de cartões: `nome_cartao`, `valor_fatura`, `consumo_limite` (indicador de consumo do limite integrado) `v2`
  - `consumo_limite` = soma de todas as parcelas ainda não pagas do cartão (fatura atual + faturas futuras) ÷ `limite_cartao`. Não é só a fatura do mês. Calculado sobre `tbl_parcela` (DP-27).
  - Exemplo: uma compra de R$ 1.200 em 12x consome R$ 1.200 do limite na hora e libera R$ 100 a cada fatura paga.
  - Lançamentos recorrentes previstos só entram depois de cobrados.
- **T02** Seletor de cartão `v2`
- **T03** Tabela de parcelas vigentes na fatura, por cartão `v2`
- **T04** Botão de edição do registro na tabela de parcelas `v2`
- **T05** Timeline dos valores da fatura, todos os cartões simultaneamente `v2`
- **T06** Gráfico de gasto agregado por categoria/subcategoria, somando todos os cartões `v2`
- **T07** Exibir lançamentos recorrentes (reais e previstos) na fatura do mês `v2`
- **T08** ~~Botão de novo registro na aba~~ substituído pelo botão flutuante do Shell (F02-T07)
- **T09** Indicar fatura paga quando existir um pagamento de fatura do cartão para aquele mês de vencimento `v2`

*Comportamento:* o seletor de mês global afeta a tela inteira.

### E01-F06 — Aba visão macro

Mescla faturado (faturas que vencem no mês selecionado, regime de caixa) e à vista (agregado por forma de pagamento). Visão sempre mensal. Entra inteira na v2, junto com o faturado. Pagamentos de fatura não entram nas somas.

- **T01** Valor acumulado do mês (soma total: faturado + à vista) `v2`
- **T02** Seletor de base de comparação: **só salário** ou **renda total** (salário + voucher + ganhos extras) ⚠ `v2`
  - O faturado entra nas duas bases.
  - Substitui o antigo "filtro por forma de pagamento".
- **T03** Cálculo do superávit `v2`
- **T04** Farol consumo × base de comparação: porcentagem e cor (verde, amarelo, vermelho) `v2`
- **T05** Gráfico de linha do consumo dia a dia (fatura atual com cartões somados + acumulado à vista do dia) `v2`
  - A fatura entra como degrau no dia do vencimento (DP-9).
- **T06** Gráfico de barras 100% com a proporção faturado/à vista, apenas em meses fechados `v2`

### E01-F07 — Configuração

Único ponto de entrada da renda. Na v1 a tela existe só com a aba Tags (T09, T10); renda e cartões entram na v2 (DP-8).

- **T01** Campo editável de salário `v2`
- **T02** Campo editável de voucher/benefícios `v2`
  - Renda por vigência (DP-6): ao alterar salário ou voucher, o app pergunta a partir de qual mês o valor vale; os meses anteriores não mudam.
- **T03** Cards de cartões, com menu (…) para editar (T07) ou remover (T08) `v2`
- **T04** Cartões cadastrados automaticamente quando detectados na API (ver E04-F03) `v2`
- **T05** Fatias do superávit: valor fixo destinado à reserva, gerando superávit **absoluto** (total) e **efetivo** (com as fatias descontadas) `v3`
  - A tela deve reservar espaço para isso desde a v2.
- **T06** Cadastro manual de cartão: nome, limite e dia de fechamento `v2`
- **T07** Edição de cartão: nome, limite e dia de fechamento `v2`
- **T08** Remover cartão `v2`
  - Com compras vinculadas: arquiva (some da seleção no formulário, histórico preservado).
  - Sem compras: exclui.
- **T09** Aba Tags: listar, criar e renomear tags `v1` (F)
  - Renomear não afeta os registros, que guardam só o ID da tag.
- **T10** Remover tag `v1` (F)
  - Com registros vinculados: arquiva (some da seleção no formulário, histórico preservado).
  - Sem registros: exclui.

*Decidido:* sem faixas de valor; renda variável é registrada pelo valor real de cada mês (DP-5).

### E01-F08 — Registros pendentes

Abriga registros com cadastro incompleto (limitação da API, categoria não mapeada, cartão não cadastrado) e capturas aguardando aprovação ⚠.

- **T01** Tabela de registros pendentes por tipo de pendência `v2`
  - Tipos: categoria desconhecida, cartão não cadastrado, mês de vencimento ausente, baixa confiança (v3, com E04-F05), aguardando aprovação (v3, com E03)
- **T02** Botão de edição, abrindo o formulário no modo completar pendência `v2`
- **T03** Ação de aprovar/rejeitar captura (E03-F02-T03) `v3`

### E01-F09 — Central de notificações do sistema

Tela de retorno do sistema.

- **T01** Log resumido de erros `v2`
- **T02** Alerta de cartão novo cadastrado `v2`
- **T03** Aviso de consulta na API bem-sucedida `v2`

### E01-F10 — Notificação de reconhecimento de pagamento

- **T01** Notificar quando o usuário executa um pagamento, sugerindo o registro imediato `v3`

### E01-F11 — Onboarding de permissões

- **T01** Orientação para conceder acesso a notificações do Android `v2`
- **T02** Solicitação de permissão de biometria `v2`

### E01-F12 — Gerenciar recorrências

Lista as cobranças de `tbl_recorrencia`. Acesso pela Configuração.

- **T01** Lista de recorrências por status (ativa, pausada, cancelada), com cartão, valor e dia de cobrança `v2`
- **T02** Ações de pausar, retomar e cancelar; cancelar altera só `status` e `data_fim`, preservando o histórico `v2`
- **T03** Editar recorrência (valor, dia de cobrança, categoria), aplicando apenas aos lançamentos previstos `v2`

### E01-F13 — Visão por tag `v2`

Recorte dos registros por contexto (viagem, rolê etc.). Não soma nada ao consumo (DP-32).

- **T01** Visão de uma tag: total e quebra por categoria/subcategoria
- **T02** Atribuição em lote: escolher um período e marcar a tag nos registros sem tag

*A definir:* se compras parceladas entram na visão pelo valor total da compra ou pelas parcelas.

### Fora do escopo (E01)

- Scanner de QR code e de código de barras (e a permissão de câmera)
- Campo de importância
- Datas e agendamento de tags (tag ativa por período)

---

## E02 — Modelo de dados

Detalhes em [modelagem banco](03_modelo_de_dados.md).

### E02-F01 — Banco interno SQLite

- **T01** Decidir categorias literais vs. IDs (F): IDs nas compras, nomes em `tbl_categoria` e `tbl_subcategoria` (DP-21)
- **T02** Decidir se `tbl_usuario` existe no app ou vira JSON local (F): JSON local, baixa prioridade (DP-22)
- **T03** Remover `importancia` do esquema local `v1` (F)
- **T04** Aplicar o vocabulário padrão: à vista (Pix, débito, dinheiro físico) e faturada (cartão de crédito) nas tabelas e colunas (DP-30) `v1` (F)
- **T05** Criar `tbl_tag` (`uuid_tag`, nome, status ativa/arquivada) e a FK nullable de tag nas tabelas de compra (DP-32) `v1` (F)
- **T06** Detalhar o esquema da v1: tipos, constraints, índices, DDL e carga inicial; sem `uuid_usuario` local, datas em horário local e `fuso_minutos` (DP-33, DP-34) `v1` (F)
- **T07** Coluna `descricao_normalizada` e configuração de desempenho do banco (DP-36) `v1` (F)

### E02-F02 — Banco transacional `v2`

Atende o app, foco em performance. A v1 é só local (DP-7).

- **T01** Definir esquema transacional
- **T02** Remover `importancia` do esquema
- **T03** Exclusão lógica (`excluido_em`) nas tabelas sincronizadas, com migração do SQLite da v1 (DP-34)

### E02-F03 — Data Warehouse

Foco analítico, esquema financeiro.

- **T01** Criar o modelo analítico para o painel
- **T02** Documentar pipelines `DW_APOLO` (e "Backlog pipelines")
- **T03** Remover `importancia` das dimensões e fatos

### E02-F04 — Recorrências

- **T01** Criar `tbl_recorrencia` e FK em `tbl_compra_faturada`
- **T02** Definir geração de lançamentos previstos e projeção de meses futuros

### E02-F05 — Modelo do faturado e da renda `v2`

- **T01** Criar `tbl_parcela` (uma linha por parcela) e mover `valor_parcela` para ela (DP-27)
- **T02** Criar `tbl_pagamento_fatura` e `cnpj_emissor` em `tbl_cartoes_credito` (DP-14)
- **T03** Renomear `mes_exercicio`/`ano_exercicio` para `mes_vencimento`/`ano_vencimento` (DP-9)
- **T04** Renda por vigência: `mes_referencia` e `ano_referencia` em `tbl_renda` (DP-6)

---

## E03 — Captura de notificações

Extrair o máximo de informações dos pagamentos por notificação, pré-preencher o formulário, guardar em tabela temporária e pedir validação antes de gravar na tabela central.

### E03-F01 — Captura e reconhecimento `v3`

- **T01** API Android de captura de notificações
- **T02** Reconhecimento de notificações de pagamento

### E03-F02 — Extração das informações `v3`

- **T01** Extrair data, hora e valor
- **T02** Preencher o formulário com os dados obtidos
- **T03** Solicitar aprovação do usuário antes de inserir

---

## E04 — Integração Pluggy e classificação

Acesso centralizado e normalizado aos dados via Pluggy (Open Finance). Contexto técnico em [01_visao_geral_e_arquitetura.md](01_visao_geral_e_arquitetura.md), seção 4.

https://www.pluggy.ai/

### E04-F01 — Validação da API (testes) `v2`

- **T01** Executar o checklist de testes da seção 4.5 da arquitetura
- **T02** Decidir como derivar mês/ano de exercício (F): manual, só pelo formulário (DP-3)
- **T03** Verificar se o plano gratuito expõe o CNPJ de quem recebe o pagamento, para reconhecer pagamentos de fatura (DP-14)

### E04-F02 — API própria `v2`

Camada intermediária para não ficar preso a uma fonte de dados.

- **T01** Definir contrato independente da Pluggy
- **T02** Receber webhooks e repassar ao app
- **T03** Reconciliação de transações (data + valor + descrição)
- **T04** Pagamentos à vista para empresas com cartão cadastrado não somam no consumo e confirmam a fatura como paga (depende de E04-F01-T03, DP-14)

### E04-F03 — Cartão não cadastrado `v2`

- **T01** App detecta cartão desconhecido e sugere o cadastro
- **T02** Cartão aparece como opção selecionável no formulário

### E04-F04 — Mapeamento de categorias `v2`

- **T01** Perguntar ao usuário na primeira ocorrência
- **T02** Guardar mapeamento em tabela fixa do app
- **T03** Classificar sozinho nas ocorrências seguintes

### E04-F05 — Classificação automática com confiança `v3`

- **T01** Modelo que usa os dados do registro para sugerir categoria e índice de confiança
- **T02** Confiança ≥ 90: automático; abaixo: validação do usuário
- **T03** Avaliar uso da categoria da Pluggy como entrada

### E04-F06 — Ganhos e superávit `v2`

Considerar entradas (PIX) durante o mês para calcular o superávit com mais precisão.

- **T01** Capturar ganhos via API e/ou formulário
- **T02** Classificar ganho: salário ou ganho extra

### E04-F07 — Tabela temporária de pendências `v2`

- **T01** Guardar registros que precisam de intervenção (cartão não cadastrado, categoria desconhecida, baixa confiança)

---

### Legenda

- indicador de versão (v1, v2…) em que a task será implementada
- quando a versão aparece no título da feature, vale para todas as tasks dela (DP-17)
- indicador de conclusão da task (F: finalizado)

### Assuntos pendentes

- Tabela temporária para guardar os dados que precisam de intervenção do usuário (classificação, cartão não cadastrado etc.), com coluna de tipo de pendência: cartão não cadastrado ou categoria desconhecida.
- Mapeamento de categorias e subcategorias funciona perguntando ao usuário como se classifica cada registro na primeira vez, armazenando isso em uma tabela separada e fixa do app; depois o app classifica sozinho.
- Criar API própria que se comunica com a API externa, para criar um sistema robusto que não fique preso a uma fonte de dados.
- Aplicar um modelo especializado de classificação que use os dados do registro para gerar um índice de confiança e escolher uma categoria; índices altos (90+) são automáticos, abaixo disso precisam de validação do usuário.
- Como considerar ganhos (PIX) durante o mês, para chegar ao cálculo mais exato do superávit: talvez um formulário de ganho, que também pode ser capturado pela API. Será preciso classificar esses ganhos, porque podem ser a entrada do salário ou um ganho extra.
- Considerar uma forma de registrar qual a renda de cada mês (ou em cada registro de consumo) para calcular o superávit de dados históricos. Decidido: renda por vigência mensal (DP-6).

### Premissas a confirmar (⚠)

1. O filtro por forma de pagamento da visão macro virou um seletor de base de comparação (só salário | renda total).
2. A confirmação de capturas do E03 reutiliza a tela de Registros pendentes.

---

## Decisões pendentes

As decisões em aberto ficam em [Decisões pendentes](05_decisoes.md), num quadro com status e farol de risco ao projeto. Ao decidir, registre lá e leve o resultado para a task correspondente aqui.
