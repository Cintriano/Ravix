# Ravix — Decisões do projeto

> Exportado do Notion (Projetos / Ravix / Decisões pendentes) em 24/10/2026.
> Fonte: https://app.notion.com/p/3f3b044db6b1811fbe7ddbcd95000cfc

Quadro único das decisões em aberto do Ravix. Substitui a seção Decisões pendentes que ficava no [Backlog](02_backlog.md); o conteúdo dela, incluindo suas respostas e deliberações, foi migrado para os cards abaixo.

## Como usar

- **Status:** A decidir → Em análise (você começou a deliberar) → Decidido → Aplicado (resultado já levado ao backlog ou à modelagem).
- **Farol de risco ao projeto:**
  - 🔴 **Alto:** bloqueia o início da v1 ou mexe em arquitetura e modelo de dados. Decidir tarde gera retrabalho caro ou migração de dados.
  - 🟡 **Médio:** afeta a v2, um cálculo central ou o esquema de forma localizada.
  - 🟢 **Baixo:** ajuste de UX, documentação ou escopo futuro. Fácil de mudar depois.
- Ao decidir, escreva a decisão na propriedade **Decisão** e mova o card. Quando a decisão chegar às tasks, mova para **Aplicado**.

## Resumo

| Código | Pendência | Status | Risco | Versão | Épico |
| --- | --- | --- | --- | --- | --- |
| DP-1 | Base de comparação da visão macro: só salário ou renda total | A decidir | 🟡 | v2 | E01 |
| DP-2 | Confirmação de capturas reutiliza a tela de Registros pendentes | A decidir | 🟢 | v3 | E01, E03 |
| DP-3 | Mês e ano de exercício: manuais ou derivados da API | Aplicado | 🟡 | v2 | E01, E04 |
| DP-4 | Limite de tempo para dados desatualizados no farol de conexão | A decidir | 🟢 | v2 | E01 |
| DP-5 | Renda variável: registrar em faixas de valor | Aplicado | 🟢 | v1 | E01 |
| DP-6 | Renda por mês para calcular o superávit histórico | Aplicado | 🔴 | v1 | E01, E02 |
| DP-7 | Backend da v1: só local ou com sincronização | Aplicado | 🔴 | v1 | E01, E02, E04 |
| DP-8 | Renda na v1 sem a visão macro | Aplicado | 🟢 | v1 | E01 |
| DP-9 | Regime do mês: caixa, mês de vencimento e meses futuros | Aplicado | 🔴 | v2 | E01, E02 |
| DP-10 | Limites de cor do farol de consumo | A decidir | 🟢 | v2 | E01 |
| DP-11 | Ajustes na lista de categorias | Aplicado | 🟡 | v1 | E01, E02 |
| DP-12 | Tela de gerenciar categorias | A decidir | 🟢 | v2 | E01 |
| DP-13 | Recorrências à vista | A decidir | 🟡 | v2 | E01, E02 |
| DP-14 | Pagamento de fatura e estorno | A decidir | 🟡 | v2 | E01 |
| DP-15 | Validações do formulário | Aplicado | 🟢 | v1 | E01 |
| DP-16 | Botão flutuante de novo registro | Aplicado | 🟢 | v1 | E01 |
| DP-17 | Dependências do E01 em épicos sem versão | Aplicado | 🟡 | v2 | E01, E03, E04 |
| DP-18 | Onboarding de permissões | A decidir | 🟢 | v2, v3 | E01 |
| DP-19 | Aviso de consulta bem-sucedida na Central de notificações | A decidir | 🟢 | v2 | E01 |
| DP-20 | Organização do Backlog app | A decidir | 🟢 | Sem versão | E01 |
| DP-21 | Categorias: texto literal ou IDs | Aplicado | 🔴 | v1 | E02 |
| DP-22 | tbl_usuario no SQLite ou JSON local | Aplicado | 🟡 | v1 | E02 |
| DP-23 | Pendências à vista: tabela temporária genérica ou própria | A decidir | 🟡 | v2 | E02 |
| DP-24 | DW: alinhar tabelas fato | A decidir | 🟢 | Sem versão | E02 |
| DP-25 | Geração de lançamentos previstos das recorrências | A decidir | 🟡 | v2 | E02 |
| DP-26 | Estrutura de renda e ganhos extras | A decidir | 🟡 | Sem versão | E02, E04 |
| DP-27 | Parcelas: tbl_parcela ou valor e quantidade | Aplicado | 🟡 | v2 | E02 |
| DP-28 | dia_vencimento em tbl_cartoes_credito | A decidir | 🟢 | v2 | E02, E04 |
| DP-29 | Status do cartão: ativo ou arquivado | A decidir | 🟢 | v2 | E02 |
| DP-30 | Vocabulário padrão das tabelas | Aplicado | 🟡 | v1 | E02 |
| DP-31 | Bloqueio local da v1: mecanismo | Aplicado | 🟡 | v1 | E01 |
| DP-32 | Classificação em três níveis: categoria, subcategoria e tag | Aplicado | 🔴 | v1, v2 | E01, E02 |
| DP-33 | Metadados para a sincronização: uuid_usuario local e formato de data | Aplicado | 🟡 | v1, v2 | E02 |
| DP-34 | Exclusão de registros: física ou lógica | Aplicado | 🟡 | v1, v2 | E01, E02 |
| DP-35 | Tag nas recorrências | A decidir | 🟢 | v2 | E02 |
| DP-36 | Stack, sugestão por descrição e otimização da v1 | Aplicado | 🟡 | v1 | E01, E02 |

---

## DP-1 — Base de comparação da visão macro: só salário ou renda total

- **Status:** A decidir · **Risco:** 🟡 Médio · **Versão:** v2 · **Épico:** E01 · **Origem:** Backlog
- **Tasks relacionadas:** E01-F06-T02
- **Decisão:** —

**Contexto:** premissa ⚠. O antigo filtro por forma de pagamento da visão macro virou um seletor de base de comparação (só salário ou renda total). O faturado entra nas duas bases.

**Proposta:** na base só salário, o numerador exclui o que foi pago com voucher: (faturado + à vista sem voucher) ÷ salário. Na renda total: tudo ÷ (salário + voucher + ganhos extras). Enquanto o E04-F06 não existir, renda total = salário + voucher.

**Por que 🟡:** define o número principal da visão macro, mas a macro só entra na v2.

## DP-2 — Confirmação de capturas reutiliza a tela de Registros pendentes

- **Status:** A decidir · **Risco:** 🟢 Baixo · **Versão:** v3 · **Épico:** E01, E03 · **Origem:** Backlog
- **Tasks relacionadas:** E01-F08, E03-F02-T03
- **Decisão:** —

**Contexto:** premissa ⚠. As capturas de notificação aguardando aprovação aparecem em Registros pendentes, com o tipo "aguardando aprovação", em vez de ganharem uma tela própria.

## DP-3 — Mês e ano de exercício: manuais ou derivados da API

- **Status:** Aplicado · **Risco:** 🟡 Médio · **Versão:** v2 · **Épico:** E01, E04 · **Origem:** Backlog
- **Tasks relacionadas:** E01-F03-T06, E04-F01-T02
- **Decisão:** Serão manuais apenas pelo formulário de gastos faturados.

**Falta aplicar:** levar a decisão para E01-F03-T06 (removendo o "Em aberto" do F03) e fechar E04-F01-T02.

**Proposta complementar:** pré-preencher o campo com um padrão calculado pelo `dia_fechamento` do cartão, editável, para não pesar no objetivo de baixa latência.

**Ponto ainda aberto:** compras vindas da API ou de notificações chegarão sem o campo. Definir se viram um tipo de pendência próprio.

**Por que 🟡:** a decisão está tomada, mas o ponto da API afeta o fluxo de pendências.

## DP-4 — Limite de tempo para dados desatualizados no farol de conexão

- **Status:** A decidir · **Risco:** 🟢 Baixo · **Versão:** v2 · **Épico:** E01 · **Origem:** Backlog
- **Tasks relacionadas:** E01-F02-T06
- **Decisão:** —

**Contexto:** definir depois de quanto tempo sem sincronizar o farol de conexão passa para 🟡 (dados desatualizados).

## DP-5 — Renda variável: registrar em faixas de valor

- **Status:** Aplicado · **Risco:** 🟢 Baixo · **Versão:** v1 · **Épico:** E01 · **Origem:** Backlog
- **Tasks relacionadas:** E01-F07
- **Decisão:** Aprovado

**Anotação existente:** "Opção".

**Proposta:** com a renda registrada por mês (ver a pendência de renda por mês), registra-se o valor real de cada mês e as faixas deixam de ser necessárias. Faixas também deixam o farol ambíguo: qual valor da faixa comparar?

## DP-6 — Renda por mês para calcular o superávit histórico

- **Status:** Aplicado · **Risco:** 🔴 Alto · **Versão:** v1 · **Épico:** E01, E02 · **Origem:** Backlog
- **Tasks relacionadas:** E01-F06-T03, E01-F07-T01/T02, tbl_renda
- **Decisão:** Aprovado

**Sua deliberação:** a ideia seria que cada registro teria um valor de renda associado, para que em dados históricos eu consiga recalcular o superávit.

**Proposta:** em vez de gravar a renda em cada registro (o mesmo valor repetido em todas as compras do mês, sem resolver qual vale quando a renda muda no meio do mês), registrar a renda por vigência (`mes_referencia`/`ano_referencia`). Cada mês encontra a própria renda com uma consulta e o histórico fica intacto.

**Impacto no E01:** alterar a renda em F07-T01/T02 pergunta "a partir de qual mês" em vez de sobrescrever.

**Por que 🔴:** define a estrutura de `tbl_renda`, e a renda é editada já na v1. Mudar depois exige migrar dados históricos.

## DP-7 — Backend da v1: só local ou com sincronização

- **Status:** Aplicado · **Risco:** 🔴 Alto · **Versão:** v1 · **Épico:** E01, E02, E04 · **Origem:** Revisão 2 do E01
- **Tasks relacionadas:** E01-F01-T01/T02/T03, E01-F02-T03/T04, E02-F02, E04-F02
- **Decisão:** V1 apenas local

**Contexto:** login com e-mail e senha, indicador de última atualização e estado offline pressupõem servidor, mas o banco transacional (E02-F02) e a API própria (E04-F02) não têm versão.

**Opção A:** v1 só local (SQLite). O login vira bloqueio local com biometria ou PIN, e o indicador de última atualização sai da v1.

**Opção B:** v1 com sincronização. E02-F02 entra na v1, e o logout precisa de uma regra para dados ainda não enviados.

**Por que 🔴:** define a arquitetura da v1 e bloqueia o início da autenticação e da persistência.

## DP-8 — Renda na v1 sem a visão macro

- **Status:** Aplicado · **Risco:** 🟢 Baixo · **Versão:** v1 · **Épico:** E01 · **Origem:** Revisão 2 do E01
- **Tasks relacionadas:** E01-F07-T01/T02
- **Decisão:** mover para a v2

**Contexto:** com a macro na v2, a renda não é usada por nenhuma tela da v1.

**Opções:** manter na v1 para já coletar o dado, ou mover para a v2 junto com a macro.

## DP-9 — Regime do mês: caixa, mês de vencimento e meses futuros

- **Status:** Aplicado · **Risco:** 🔴 Alto · **Versão:** v2 · **Épico:** E01, E02 · **Origem:** Revisão 2 do E01
- **Tasks relacionadas:** E01-F06-T05, E01-F02-T02, mes_exercicio
- **Decisão:** Pode renomear o mes_exercicio para o nome sugerido, o degrau vai ser pelo vencimento, sim o filtro aceita messes futuros.

**Contexto:** a macro soma a fatura que vence no mês com o à vista pela data da compra, ou seja, regime de caixa (o que sai da conta no mês).

**A decidir:**

- Registrar o regime de caixa e redefinir `mes_exercicio` como "mês de vencimento da fatura" (menos ambíguo que "entra em vigor").
- Como a fatura entra no gráfico dia a dia (F06-T05): degrau no vencimento ou distribuída pelas compras.
- Se o seletor de mês (F02-T02) aceita meses futuros, para parcelas e recorrências previstas.

**Por que 🔴:** define o significado de um campo gravado em toda compra faturada e o cálculo central do superávit.

## DP-10 — Limites de cor do farol de consumo

- **Status:** A decidir · **Risco:** 🟢 Baixo · **Versão:** v2 · **Épico:** E01 · **Origem:** Revisão 2 do E01
- **Tasks relacionadas:** E01-F06-T04
- **Decisão:** —

**Contexto:** as faixas de verde, amarelo e vermelho não estão definidas.

**Proposta:** comparar o percentual consumido com o percentual do mês já decorrido. 60% da renda no dia 10 é diferente de 60% no dia 28.

## DP-11 — Ajustes na lista de categorias

- **Status:** Aplicado · **Risco:** 🟡 Médio · **Versão:** v1 · **Épico:** E01, E02 · **Origem:** Revisão 2 do E01
- **Tasks relacionadas:** E01-F03-T10
- **Decisão:** Rolê vira tag (DP-32); categoria 7 · Rolê removida. Criadas Moradia (aluguel, condomínio, IPTU) e Educação (cursos, livros e material, mensalidade); tarifas bancárias e impostos em Contas a pagar. Carga inicial com 8 categorias e 34 subcategorias.

**Aplicado em 11/10/2026:** categoria 7 · Rolê criada com 701 Alimentação, 702 Entradas, 703 Bebidas alcoólicas e 704 Transporte; 403 Custo rolê removida (E01-F03).

**Aplicado em 21/10/2026 (com o DP-32):**

- Categoria 7 · Rolê removida: rolê passa a ser tag. Isso resolve a sobreposição com 402 e 404 e a dúvida do Uber da festa (302 + tag).
- Descrição da 402 sem a menção a rolê.
- Criadas 7 · Moradia (701 Aluguel, 702 Condomínio, 703 IPTU) e 8 · Educação (801 Cursos, 802 Livros e material, 803 Mensalidade).
- Contas a pagar ganhou 603 Tarifas bancárias e 604 Impostos.
- Carga inicial: 8 categorias, 34 subcategorias.

**Contexto:** 402 Entrada e Ingressos e 403 Custo rolê se sobrepõem (as duas citam gasto genérico de rolê). Não há lugar para moradia (aluguel, condomínio), educação ou impostos e tarifas bancárias.

**Por que 🟡:** a carga inicial é v1. Mudar categorias depois exige reclassificar registros.

## DP-12 — Tela de gerenciar categorias

- **Status:** A decidir · **Risco:** 🟢 Baixo · **Versão:** v2 · **Épico:** E01 · **Origem:** Revisão 2 do E01
- **Tasks relacionadas:** E01-F07, E02-F01-T01
- **Decisão:** —

**Proposta:** tela na Configuração para criar e editar categorias e subcategorias. Depende da decisão entre texto literal e IDs.

## DP-13 — Recorrências à vista

- **Status:** A decidir · **Risco:** 🟡 Médio · **Versão:** v2 · **Épico:** E01, E02 · **Origem:** Revisão 2 do E01
- **Tasks relacionadas:** E01-F03-T08, tbl_recorrencia
- **Decisão:** —

**Contexto:** o toggle de recorrência é só do faturado, mas aluguel e contas de consumo (602) costumam ser Pix, boleto ou débito automático.

**Proposta:** avaliar estender `tbl_recorrencia` ao à vista.

**Por que 🟡:** hoje `tbl_recorrencia` tem FK de cartão; estender depois muda o esquema.

## DP-14 — Pagamento de fatura e estorno

- **Status:** A decidir · **Risco:** 🟡 Médio · **Versão:** v2 · **Épico:** E01 · **Origem:** Revisão 2 do E01
- **Tasks relacionadas:** E01-F03
- **Decisão:** no form manual vai ser adicionado um tipo de registro (pagamento de fatura) junto com os existentes (fatura finita, fatura de serviço), no registro via API precisa verificar se tem como acessar com o plano free o cnpj da empressa que recebe o pagamento e associar com isso, todo pagamento Avista destinados a essas empressas que tem (cartão/faturas) registradas não somam nas contas, e podem ser usados como um check de que a fatura foi paga.

**Aplicado em 11/10/2026:** tipo de registro pagamento de fatura no formulário (E01-F03-T13, v2), indicação de fatura paga (E01-F05-T09), `tbl_pagamento_fatura` e `cnpj_emissor` na modelagem, teste do CNPJ no plano gratuito (E04-F01-T03) e regra da API (E04-F02-T04). Interpretei "fatura finita" como compra parcelada e "fatura de serviço" como cobrança recorrente.

**Falta decidir:** como lançar estornos de cartão. Com o valor sempre maior que zero (DP-15), o estorno não pode entrar como valor negativo; precisa de um tipo próprio ou de um abatimento na fatura.

**Contexto:** pagar a fatura via Pix ou débito não é gasto à vista; registrar esse pagamento duplica o consumo. Estorno de cartão ainda não tem caminho.

**A decidir:** a regra no formulário (categoria que não entra nas somas, ou orientação para não registrar) e como lançar estornos.

**Por que 🟡:** um registro errado distorce o número principal do app.

## DP-15 — Validações do formulário

- **Status:** Aplicado · **Risco:** 🟢 Baixo · **Versão:** v1 · **Épico:** E01 · **Origem:** Revisão 2 do E01
- **Tasks relacionadas:** E01-F03-T03
- **Decisão:** valor sempre maior que 0 a mascara monetaria até duas casas descimeis, todos os campos são obirgatorios, aceita datas futuras

**A definir:** valor maior que zero; máscara monetária com centavos (no lugar de "apenas números"); campos obrigatórios; se data futura é aceita.

## DP-16 — Botão flutuante de novo registro

- **Status:** Aplicado · **Risco:** 🟢 Baixo · **Versão:** v1 · **Épico:** E01 · **Origem:** Revisão 2 do E01
- **Tasks relacionadas:** E01-F04-T04, E01-F05-T08
- **Decisão:** Aprovado

**Proposta:** alternativa aos botões por aba. Um botão flutuante no Shell abre o formulário com o tipo da aba ativa.

## DP-17 — Dependências do E01 em épicos sem versão

- **Status:** Aplicado · **Risco:** 🟡 Médio · **Versão:** v2 · **Épico:** E01, E03, E04 · **Origem:** Revisão 2 do E01
- **Tasks relacionadas:** E01-F02-T06, E01-F03-T07, E01-F07-T04, E01-F08, E01-F09-T02/T03
- **Decisão:** Versiona esses épicos

**Contexto:** essas tasks v2 só têm dados com o E03/E04 pronto, e esses épicos não têm versão.

**Proposta:** versionar E03/E04 ou marcar as tasks como "bloqueada por E04-Fxx".

**Por que 🟡:** sem isso, o escopo da v2 fica irreal.

## DP-18 — Onboarding de permissões

- **Status:** A decidir · **Risco:** 🟢 Baixo · **Versão:** v2, v3 · **Épico:** E01 · **Origem:** Revisão 2 do E01
- **Tasks relacionadas:** E01-F11, E01-F01-T04, E01-F10
- **Decisão:** —

- O acesso a notificações (F11-T01) está na v2, mas F10 e E03 são v3. Melhor pedir no contexto, na versão em que for usado.
- A biometria (F11-T02) não precisa de permissão em tempo de execução no Android (`USE_BIOMETRIC` é concedida na instalação). O opt-in já está em F01-T04, então dá para fundir.
- Falta `POST_NOTIFICATIONS`, obrigatória no Android 13+ para o app enviar a notificação do F10.

## DP-19 — Aviso de consulta bem-sucedida na Central de notificações

- **Status:** A decidir · **Risco:** 🟢 Baixo · **Versão:** v2 · **Épico:** E01 · **Origem:** Revisão 2 do E01
- **Tasks relacionadas:** E01-F09-T03, E01-F02-T03
- **Decisão:** —

**Contexto:** um aviso a cada consulta bem-sucedida tende a virar ruído. O indicador de última atualização já cumpre esse papel.

## DP-20 — Organização do Backlog app

- **Status:** A decidir · **Risco:** 🟢 Baixo · **Versão:** Sem versão · **Épico:** E01 · **Origem:** Revisão 2 do E01
- **Tasks relacionadas:** Backlog app
- **Decisão:** —

- "Premissas a confirmar" repete as pendências de base de comparação e de confirmação de capturas, que agora vivem neste quadro.
- O cabeçalho cita os arquivos `.md` em vez das páginas do Notion.

## DP-21 — Categorias: texto literal ou IDs

- **Status:** Aplicado · **Risco:** 🔴 Alto · **Versão:** v1 · **Épico:** E02 · **Origem:** Backlog
- **Tasks relacionadas:** E02-F01-T01
- **Decisão:** usar os IDs nas tabelas de compra, mas tendo o nome da categoria/subcategoria nas suas tabelas referentes.

**Contexto:** `tbl_compra_avista` guarda texto e `tbl_compra_faturada` guarda IDs.

**Tendência da modelagem:** IDs com `tbl_categoria` e `tbl_subcategoria`. A carga inicial (E01-F03-T10) já vem com IDs.

**Por que 🔴:** define o esquema das tabelas de compra na v1.

## DP-22 — tbl_usuario no SQLite ou JSON local

- **Status:** Aplicado · **Risco:** 🟡 Médio · **Versão:** v1 · **Épico:** E02 · **Origem:** Backlog
- **Tasks relacionadas:** E02-F01-T02
- **Decisão:** vai ser um json, mas é uma funcionalidade que não é prioridade se a dependência do backend interferir.

**Contexto:** só um usuário fica logado por vez no app. Depende da pendência do backend da v1.

## DP-23 — Pendências à vista: tabela temporária genérica ou própria

- **Status:** A decidir · **Risco:** 🟡 Médio · **Versão:** v2 · **Épico:** E02 · **Origem:** Backlog
- **Tasks relacionadas:** E04-F07, tbl_compra_faturada_temp
- **Decisão:** —

**Opções:** tornar a tabela temporária genérica (com `tipo_registro`) ou criar `tbl_compra_avista_temp`.

## DP-24 — DW: alinhar tabelas fato

- **Status:** A decidir · **Risco:** 🟢 Baixo · **Versão:** Sem versão · **Épico:** E02 · **Origem:** Backlog
- **Tasks relacionadas:** E02-F03-T01
- **Decisão:** —

**Contexto:** alinhar as tabelas fato com cartão, `ano_exercicio`, recorrência e `status_lancamento`.

## DP-25 — Geração de lançamentos previstos das recorrências

- **Status:** A decidir · **Risco:** 🟡 Médio · **Versão:** v2 · **Épico:** E02 · **Origem:** Backlog
- **Tasks relacionadas:** E02-F04-T02
- **Decisão:** —

**Contexto:** definir como os lançamentos previstos são gerados e como a projeção de meses futuros é calculada.

## DP-26 — Estrutura de renda e ganhos extras

- **Status:** A decidir · **Risco:** 🟡 Médio · **Versão:** Sem versão · **Épico:** E02, E04 · **Origem:** Backlog
- **Tasks relacionadas:** E04-F06, tbl_renda
- **Decisão:** —

**Contexto:** ganhos extras provavelmente exigem uma tabela própria de entradas. Conversa com a pendência de renda por mês.

## DP-27 — Parcelas: tbl_parcela ou valor e quantidade

- **Status:** Aplicado · **Risco:** 🟡 Médio · **Versão:** v2 · **Épico:** E02 · **Origem:** Backlog
- **Tasks relacionadas:** E01-F05-T01, E01-F05-T03, E01-F05-T05
- **Decisão:** Tabela de parcelas aprovada

**Opções:** criar `tbl_parcela` (uma linha por parcela, com o mês da fatura) ou manter `valor_parcela` e `quant_parcela`.

**Peso a favor de `tbl_parcela`:** o consumo do limite (E01-F05-T01) precisa das parcelas futuras por cartão, assim como a tabela de parcelas e a timeline.

## DP-28 — dia_vencimento em tbl_cartoes_credito

- **Status:** A decidir · **Risco:** 🟢 Baixo · **Versão:** v2 · **Épico:** E02, E04 · **Origem:** Backlog
- **Tasks relacionadas:** tbl_cartoes_credito
- **Decisão:** —

**Contexto:** possivelmente vindo da API. Ganha peso se o mês de exercício virar "mês de vencimento" (ver a pendência de regime do mês).

## DP-29 — Status do cartão: ativo ou arquivado

- **Status:** A decidir · **Risco:** 🟢 Baixo · **Versão:** v2 · **Épico:** E02 · **Origem:** Revisão 2 do E01
- **Tasks relacionadas:** E01-F07-T08, tbl_cartoes_credito
- **Decisão:** —

**Contexto:** coluna de status em `tbl_cartoes_credito` para arquivar cartão com compras vinculadas.

## DP-30 — Vocabulário padrão das tabelas

- **Status:** Aplicado · **Risco:** 🟡 Médio · **Versão:** v1 · **Épico:** E02 · **Origem:** Backlog
- **Tasks relacionadas:** Modelagem banco
- **Decisão:** O termos vigentes são, Avista para pagamentos de pix, cartão de debito e dinheiro fisico, e faturada para pagamentos no cartão de crédito.

**Contexto:** os termos divergem: `avista`/`imediata` e `faturada`/`credito`.

**Por que 🟡:** barato de padronizar antes do código da v1, caro depois.

## DP-31 — Bloqueio local da v1: mecanismo

- **Status:** Aplicado · **Risco:** 🟡 Médio · **Versão:** v1 · **Épico:** E01 · **Origem:** Revisão 3
- **Tasks relacionadas:** E01-F01-T07, E01-F01-T04, E01-F11-T02
- **Decisão:** Na v1 o bloqueio usa o PIN do aparelho (PIN ou padrão do Android, via local_auth). O app não guarda PIN próprio, então não há nada a modelar nem a recuperar.

**Contexto:** o DP-7 decidiu que a v1 é só local, então o login com conta vira um bloqueio local ao abrir o app (E01-F01-T07). Falta definir o mecanismo.

**Opções:** PIN próprio do app; só biometria; ou biometria com alternativa pelo bloqueio de tela do aparelho.

**Proposta:** biometria com alternativa pelo PIN ou padrão do próprio Android. O `BiometricPrompt` aceita a credencial do aparelho como alternativa (no Flutter, o `local_auth` com `biometricOnly: false`), então o app não precisa guardar um PIN próprio.

**Relacionado:** E01-F01-T04 (biometria após o primeiro login) e E01-F11-T02 (permissão de biometria) mudam conforme a escolha.

**Por que 🟡:** é a primeira tela da v1, mas a escolha é localizada.

## DP-32 — Classificação em três níveis: categoria, subcategoria e tag

- **Status:** Aplicado · **Risco:** 🔴 Alto · **Versão:** v1, v2 · **Épico:** E01, E02
- **Tasks relacionadas:** E01-F03-T14, E01-F03-T15, E01-F04-T05, E01-F07-T09, E01-F07-T10, E01-F13, E02-F01-T05
- **Decisão:** Três níveis: categoria e subcategoria descrevem a natureza do gasto; a tag descreve o contexto (viagem, rolê etc.). Uma tag por registro, opcional. Tags criadas no formulário e na aba Tags da Configuração (v1). Tag com registros é arquivada; sem registros, excluída. Filtro por tag na aba à vista (v1). Visão por tag e atribuição em lote na v2. Datas/agendamento de tag fora do escopo.

**Contexto:** criar categorias de contexto (Rolê, Viagem) tira peso das categorias de natureza: o almoço da viagem sai de Alimentação, o Uber da festa sai de Transporte. Uma árvore única obriga cada gasto a escolher um pai.

**Decisão:** separar natureza e contexto em dimensões independentes. A tag é um recorte dos mesmos registros, não soma nada ao consumo.

- Uma tag por registro (FK nullable): a soma por tag fecha com o total, sem dupla contagem.
- Criação inline no formulário e gestão na aba Tags da Configuração, que entra na v1 só com essa aba.
- Remoção segue a regra dos cartões: arquiva se houver registros, exclui se não houver. Renomear não afeta os registros.
- Na v1 tudo é manual. A classificação automática (E04) não tenta inferir tag, porque o dado da transação não carrega contexto.
- Visão por tag e atribuição em lote por período: v2 (E01-F13).
- Datas e agendamento de tag (tag ativa por período): fora do escopo.

**Consequência:** a categoria 7 · Rolê sai da carga inicial (DP-11).

**Por que 🔴:** muda o esquema das tabelas de compra e a carga inicial de categorias da v1.

## DP-33 — Metadados para a sincronização: uuid_usuario local e formato de data

- **Status:** Aplicado · **Risco:** 🟡 Médio · **Versão:** v1, v2 · **Épico:** E02
- **Tasks relacionadas:** E02-F01, E02-F02-T01
- **Decisão:** Sem uuid_usuario nas tabelas locais: o usuário é gravado na carga para o banco da aplicação externo. Datas do evento (timestamp_\*) em ISO 8601 no horário local, com fuso_minutos (offset do aparelho, lido do sistema sem rede). criado_em e atualizado_em em UTC.

**Contexto:** as tabelas do modelo têm `uuid_usuario` como FK, mas o DP-22 tirou `tbl_usuario` do SQLite (vira JSON local). Na v1 só existe um usuário por aparelho, então a coluna repetiria o mesmo valor em todas as linhas e apontaria para uma tabela que não existe. A data/hora também precisa de um formato definido antes do primeiro registro.

**Proposta aplicada no modelo (revise):**

- Sem `uuid_usuario` nas tabelas locais. Na v2, o servidor associa o usuário na sincronização, pela sessão autenticada.
- Datas em texto ISO 8601 no horário local do aparelho (`YYYY-MM-DDTHH:MM:SS`), sem fuso. O mês de um gasto é o mês local em que ele aconteceu. A conversão para UTC, se o servidor exigir, fica para o sync.
- `criado_em` e `atualizado_em` em toda tabela editável, para a v2 saber o que mudou desde a última sincronização.

**Decisão (22/10/2026):** proposta confirmada.

- Sem `uuid_usuario` nas tabelas locais. O usuário é gravado na carga para o banco da aplicação externo, pela sessão autenticada.
- Datas do evento (`timestamp_*`) em ISO 8601 no horário local do aparelho, com a coluna `fuso_minutos` (INTEGER, deslocamento em relação ao UTC, −180 = UTC−3) gravada junto. O app lê o fuso do sistema, sem rede. Com data local + deslocamento, a v2 reconstrói o instante exato; o mês do gasto continua sendo o mês local em que ele aconteceu.
- `criado_em` e `atualizado_em` em ISO 8601 em UTC (com `Z`): são instantes do sistema e servem para a v2 saber o que mudou desde a última sincronização.
- Ao editar a data de um registro, o app usa o fuso atual do aparelho; se a data não for tocada, mantém o gravado.
- Limitação aceita: o fuso vem do sistema. Em modo avião, sem sinal de rede, o Android mantém o último fuso conhecido até atualizar (ou até o usuário trocar), então um registro feito logo após pousar pode sair com o fuso anterior.
- Regra da v2: como o SQLite local é de um usuário só, trocar de conta no aparelho exige limpar o banco local.

**Por que 🟡:** mudar depois de haver dados exige migração, mas a escolha é localizada.

## DP-34 — Exclusão de registros: física ou lógica

- **Status:** Aplicado · **Risco:** 🟡 Médio · **Versão:** v1, v2 · **Épico:** E01, E02
- **Tasks relacionadas:** E01-F03-T11, E01-F07-T10, E02-F01, E02-F02-T03
- **Decisão:** Opção A mas deixa registrado a B para a v2

**Contexto:** o formulário exclui registros (E01-F03-T11) e a aba Tags exclui tags sem registros (E01-F07-T10). Na v1, só local, apagar a linha (exclusão física) é o mais simples. Na v2, com sincronização, o servidor precisa saber que algo foi apagado no aparelho; uma linha que sumiu não avisa ninguém.

**Opções:**

- **A:** exclusão física na v1; na v2, uma tabela de exclusões pendentes de envio.
- **B:** exclusão lógica desde a v1, com `excluido_em` (nullable) em cada tabela; toda consulta filtra `excluido_em IS NULL`.

**Proposta:** A. Mantém as consultas da v1 simples e não carrega linhas mortas; a tabela de exclusões da v2 é aditiva e não exige migração. O modelo atual segue A.

**Por que 🟡:** B adotada depois exige mexer em todas as consultas.

**Aplicado em 22/10/2026:** v1 com exclusão física (opção A). Para a v2 fica registrada a opção B: exclusão lógica com `excluido_em` nas tabelas sincronizadas, como parte da sincronização (E02-F02-T03). A migração da v1 para a v2 adiciona a coluna e passa a filtrar `excluido_em IS NULL` nas consultas.

## DP-35 — Tag nas recorrências

- **Status:** A decidir · **Risco:** 🟢 Baixo · **Versão:** v2 · **Épico:** E02
- **Tasks relacionadas:** E01-F03-T12, E02-F04
- **Decisão:** —

**Contexto:** cada cobrança de `tbl_recorrencia` gera uma linha em `tbl_compra_faturada`. Com a tag (DP-32), falta definir se a recorrência tem tag própria e se os lançamentos gerados herdam essa tag.

**Proposta:** sem tag na recorrência. Assinaturas raramente pertencem a um contexto (viagem, rolê); se uma cobrança pertencer, a tag vai no lançamento, pela edição "só este" (E01-F03-T12).

**Por que 🟢:** é v2 e aditivo; se precisar, a coluna entra depois sem migração de dados.

## DP-36 — Stack, sugestão por descrição e otimização da v1

- **Status:** Aplicado · **Risco:** 🟡 Médio · **Versão:** v1 · **Épico:** E01, E02
- **Tasks relacionadas:** E01-F03-T16, E02-F01-T07
- **Decisão:** Stack: drift, Riverpod, go_router, local_auth, uuid, intl, build_runner. Sugestão: descrições que contêm o texto digitado, subcategoria mais frequente (desempate pela mais recente), a partir de 3 caracteres com espera de 300 ms, sobre a nova coluna descricao_normalizada. Ordem alfabética com Diversos por último. Otimização: isolate, WAL, carga só no onCreate, autoDispose, totais na hora. Metas: abertura < 2 s, salvar < 100 ms, cadastro < 10 s. Backup fora do escopo por enquanto.

**Contexto:** com o E01 e o E02-F01 fechados, faltava decidir as ferramentas de implementação, a regra da sugestão de categoria pela descrição e o que definir desde já para garantir desempenho.

**Stack da v1:**

| Necessidade | Ferramenta |
| --- | --- |
| Banco | `drift` e `sqlite3_flutter_libs`, com o DDL em arquivo `.drift` |
| Estado | `flutter_riverpod` e `riverpod_generator` |
| Navegação | `go_router` (`StatefulShellRoute`) |
| Bloqueio | `local_auth` (PIN do aparelho, DP-31) |
| IDs | `uuid` |
| Formatação | `intl` |
| Geração de código | `build_runner` |
| Lint | `flutter_lints` ou `very_good_analysis` (escolha no M0 do plano) |

Arquitetura em três camadas: telas → providers → repositórios → drift. A sincronização da v2 entra nos repositórios sem mexer nas telas.

**Sugestão pela descrição (E01-F03-T16):**

- Busca as descrições do histórico que **contêm** o texto digitado e propõe a subcategoria mais frequente entre elas (a categoria vem junto). Desempate: a usada mais recentemente.
- Consulta a partir de 3 caracteres, com espera de 300 ms após a última tecla.
- Comparação sobre a coluna nova `descricao_normalizada` (minúsculas, sem acento, espaços colapsados), preenchida pelo app ao salvar. O `lower()` do SQLite não trata acentos.

**Ordenação:** categorias e subcategorias em ordem alfabética, com Diversos sempre por último.

**Otimização definida desde já:**

- Banco aberto em isolate separado (`NativeDatabase.createInBackground`).
- PRAGMAs: `journal_mode = WAL`, `synchronous = NORMAL`, `foreign_keys = ON`.
- Carga inicial só no `onCreate` da migração.
- Providers com `autoDispose`; tabela do mês com `ListView.builder`, sem paginação no banco.
- Totais calculados na hora (`SUM`), sem valores guardados.
- Fora por enquanto: FTS5, índices compostos e cache. Ficam como caminho de escalada se as medições pedirem.

**Metas (medidas em profile/release, com massa de ~20 mil registros):** app aberto até a aba à vista utilizável em menos de 2 s; salvar e ver a tabela atualizada em menos de 100 ms; cadastrar um gasto em menos de 10 s.

**Fora do escopo por enquanto:** backup dos dados.

**Por que 🟡:** a coluna nova altera o esquema da v1, ainda antes de existirem dados; o resto é configuração de implementação.
