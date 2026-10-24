# Ravix — Modelo de dados

> Exportado do Notion (Projetos / Ravix / Backlog app / modelagem banco) em 24/10/2026.
> Fonte: https://app.notion.com/p/3dfb044db6b1802a803bcebfcef7233f

> **Status:** esquema da v1 (SQLite) fechado e pronto para implementação (seção 3), com todas as decisões aplicadas (DP-33, DP-34). Tabelas da v2 seguem como rascunho (seção 4).

> **Revisão 5 (22/10/2026):** `fuso_minutos` adicionado às tabelas com data de evento; `criado_em` e `atualizado_em` em UTC (DP-33).

> **Revisão 6 (22/10/2026):** coluna `descricao_normalizada` e consulta da sugestão pela descrição; configuração de desempenho do banco (DP-36). Plano de implementação em [Plano de desenvolvimento — v1](04_plano_desenvolvimento_v1.md).

> **Revisão 4 (22/10/2026):** esquema da v1 detalhado com tipos, constraints, índices e carga inicial. Aplicados o DP-32 (`tbl_tag`), o DP-11 (8 categorias, 34 subcategorias) e a proposta do DP-33 (sem `uuid_usuario` local, datas ISO no horário local, `criado_em`/`atualizado_em`). As compras passam a guardar só `id_subcategoria` e os valores em centavos. Dúvidas novas no quadro [Decisões pendentes](05_decisoes.md): DP-33, DP-34 e DP-35.

**Documentos relacionados:** [01_visao_geral_e_arquitetura.md](01_visao_geral_e_arquitetura.md) · [Backlog app](02_backlog.md)

---

## 1. Escopo

Banco interno do app. Na v1 ele é o único banco (DP-7). Na v2, os registros passam a ser enviados ao banco transacional e, depois, ao DW, que expande o escopo para o contexto analítico.

| Camada | Documentação |
| --- | --- |
| SQLite (app), v1 | Seção 3 (pronto) |
| SQLite (app), v2 | Seção 4 (rascunho) |
| Banco transacional | A definir (v2, DP-7) |
| Data Warehouse (`DW_APOLO`) | A definir (pipelines sem conteúdo) |

---

## 2. Convenções

| Item | Regra |
| --- | --- |
| Nomes | Tabelas `tbl_*`, colunas em `snake_case` minúsculo, vocabulário à vista / faturada (DP-30) |
| Chaves de registros do usuário | `uuid_*`, TEXT com UUID v4 gerado no app. Evita colisão na sincronização da v2 |
| Chaves de domínio fixo | `id_*`, INTEGER definido na carga inicial (categorias e subcategorias) |
| Valores | INTEGER em centavos (R$ 12,34 = 1234). Nunca REAL: ponto flutuante erra somas de dinheiro |
| Data e hora | TEXT ISO 8601 no horário local do aparelho, `YYYY-MM-DDTHH:MM:SS`, sem fuso no texto (DP-33) |
| Fuso | `fuso_minutos` INTEGER NOT NULL nas tabelas com data de evento: deslocamento do aparelho em relação ao UTC no momento do registro (−180 = UTC−3), lido do sistema, sem rede (DP-33) |
| Domínios fechados | TEXT com `CHECK` e códigos sem acento (`pix`, `debito`…); o app traduz para exibição |
| Auditoria | `criado_em` e `atualizado_em` em toda tabela editável, ISO 8601 em UTC com `Z` (DP-33) |
| Usuário | Sem `uuid_usuario` nas tabelas locais; dados do usuário em JSON local (DP-22). O usuário é gravado na carga para o banco da aplicação externo (DP-33) |
| Versão do esquema | `PRAGMA user_version`; cada mudança é uma migração numerada |
| Integridade | `PRAGMA foreign_keys = ON` em toda conexão (o SQLite vem com FKs desligadas) |

---

## 3. Esquema da v1 (SQLite)

A v1 tem quatro tabelas. O bloqueio local usa o PIN do aparelho (DP-31), então não há nada de autenticação para guardar.

| Tabela | Uso na v1 |
| --- | --- |
| `tbl_categoria` | Domínio fixo, carga inicial (E01-F03-T10) |
| `tbl_subcategoria` | Domínio fixo, carga inicial (E01-F03-T10) |
| `tbl_tag` | Tags criadas pelo usuário (E01-F03-T15, E01-F07-T09/T10) |
| `tbl_compra_avista` | Registros de gasto à vista (E01-F03-T04, E01-F04) |

### 3.1 DDL

```sql
PRAGMA foreign_keys = ON;
PRAGMA user_version = 1;

CREATE TABLE tbl_categoria (
  id_categoria INTEGER PRIMARY KEY,
  nome         TEXT    NOT NULL UNIQUE
);

CREATE TABLE tbl_subcategoria (
  id_subcategoria INTEGER PRIMARY KEY,  -- categoria x 100 + sequência
  id_categoria    INTEGER NOT NULL REFERENCES tbl_categoria (id_categoria),
  nome            TEXT    NOT NULL,
  UNIQUE (id_categoria, nome),
  CHECK (id_subcategoria / 100 = id_categoria)
);

CREATE TABLE tbl_tag (
  uuid_tag      TEXT PRIMARY KEY,
  nome          TEXT NOT NULL UNIQUE COLLATE NOCASE,
  status        TEXT NOT NULL DEFAULT 'ativa'
                CHECK (status IN ('ativa', 'arquivada')),
  criado_em     TEXT NOT NULL,
  atualizado_em TEXT NOT NULL
);

CREATE TABLE tbl_compra_avista (
  uuid_compra_avista      TEXT    PRIMARY KEY,
  timestamp_compra_avista TEXT    NOT NULL,
  fuso_minutos            INTEGER NOT NULL CHECK (fuso_minutos BETWEEN -720 AND 840),
  descricao               TEXT    NOT NULL CHECK (length(trim(descricao)) > 0),
  descricao_normalizada   TEXT    NOT NULL,  -- minúsculas, sem acento, espaços colapsados (DP-36)
  valor_compra_avista     INTEGER NOT NULL CHECK (valor_compra_avista > 0),  -- centavos
  tipo_pagamento          TEXT    NOT NULL
                          CHECK (tipo_pagamento IN ('pix', 'debito', 'dinheiro', 'voucher')),
  id_subcategoria         INTEGER NOT NULL
                          REFERENCES tbl_subcategoria (id_subcategoria),
  uuid_tag                TEXT    NULL
                          REFERENCES tbl_tag (uuid_tag) ON DELETE RESTRICT,
  criado_em               TEXT    NOT NULL,
  atualizado_em           TEXT    NOT NULL
);

CREATE INDEX idx_compra_avista_timestamp    ON tbl_compra_avista (timestamp_compra_avista);
CREATE INDEX idx_compra_avista_subcategoria ON tbl_compra_avista (id_subcategoria);
CREATE INDEX idx_compra_avista_tag          ON tbl_compra_avista (uuid_tag);
```

### 3.2 Carga inicial

Fonte: tabela de categorias do [Backlog app](02_backlog.md) (E01-F03-T10, DP-11). A descrição de cada subcategoria fica no app como texto de ajuda, não no banco. O ID 403 não existe (antiga subcategoria removida).

```sql
INSERT INTO tbl_categoria (id_categoria, nome) VALUES
  (1, 'Alimentação'), (2, 'Saúde e Bem-estar'), (3, 'Transporte'), (4, 'Lazer'),
  (5, 'Compras e Bens'), (6, 'Contas a pagar'), (7, 'Moradia'), (8, 'Educação');

INSERT INTO tbl_subcategoria (id_subcategoria, id_categoria, nome) VALUES
  (101, 1, 'Padaria'), (102, 1, 'Supermercado'), (103, 1, 'Refeição'),
  (104, 1, 'Delivery'), (105, 1, 'Lanche'),
  (201, 2, 'Farmácia'), (202, 2, 'Cuidados Pessoais'), (203, 2, 'Saúde'),
  (301, 3, 'Combustível'), (302, 3, 'Mobilidade Urbana'),
  (303, 3, 'Estacionamento'), (304, 3, 'Manutenção'),
  (401, 4, 'Hobbies e Jogos'), (402, 4, 'Entrada e Ingressos'),
  (404, 4, 'Alcoólicos'), (405, 4, 'Viagens e Turismo'),
  (501, 5, 'Presentes'), (502, 5, 'Eletro e Móveis'), (503, 5, 'Construção e Reparos'),
  (504, 5, 'Vestuário'), (505, 5, 'Ferramentas'), (506, 5, 'Tech e Eletrônicos'),
  (507, 5, 'Diversos'), (508, 5, 'Casa e Decoração'),
  (601, 6, 'Serviços online'), (602, 6, 'Contas de Consumo'),
  (603, 6, 'Tarifas bancárias'), (604, 6, 'Impostos'),
  (701, 7, 'Aluguel'), (702, 7, 'Condomínio'), (703, 7, 'IPTU'),
  (801, 8, 'Cursos'), (802, 8, 'Livros e material'), (803, 8, 'Mensalidade');
```

### 3.3 Regras que o esquema garante

- **Categoria derivada:** a compra guarda só `id_subcategoria`; a categoria vem do join com `tbl_subcategoria`. Guardar as duas permitiria um registro com subcategoria de uma categoria e categoria de outra.
- **Tag opcional e única por registro** (DP-32): `uuid_tag` nullable, uma coluna só.
- **Remover tag** (E01-F07-T10): o `ON DELETE RESTRICT` impede excluir tag com registros. O app tenta excluir e, se houver registros, arquiva (`status = 'arquivada'`). O seletor do formulário lista só tags ativas; registros antigos continuam mostrando a tag arquivada.
- **Renomear tag:** só muda `tbl_tag.nome`; os registros guardam o UUID.
- **Nome de tag repetido:** `COLLATE NOCASE` trata "Viagem" e "viagem" como iguais.
- **Valor** sempre maior que zero e **descrição** não vazia (E01-F03-T03, T14).
- **Fuso:** o app grava `fuso_minutos` com o deslocamento do aparelho no momento do registro, sem rede (`DateTime.now().timeZoneOffset.inMinutes`). Ao editar a data, usa o fuso atual; se a data não for tocada, mantém o gravado. As consultas por mês usam só o horário local e não mudam.
- **Sugestão de subcategoria** (E01-F03-T16, DP-36): o app preenche `descricao_normalizada` ao salvar (minúsculas, sem acento, espaços colapsados, sem `%` e `_`, que são curingas do `LIKE`). A busca compara o texto digitado, normalizado do mesmo jeito, com essa coluna.
- **Ordenação** dos seletores: categorias e subcategorias em ordem alfabética, com Diversos por último (DP-36).
- **Excluir registro** (E01-F03-T11) e **excluir tag sem registros** (E01-F07-T10): exclusão física na v1 (DP-34). Na v2, as tabelas sincronizadas passam a ter exclusão lógica com `excluido_em` (E02-F02-T03).

### 3.4 Consultas das telas da v1

```sql
-- Acumulado do mês (E01-F04-T01); :inicio = '2026-10-01T00:00:00', :fim = '2026-11-01T00:00:00'
SELECT COALESCE(SUM(valor_compra_avista), 0)
FROM tbl_compra_avista
WHERE timestamp_compra_avista >= :inicio AND timestamp_compra_avista < :fim;

-- Tabela do mês com filtros opcionais (E01-F04-T02, T05)
SELECT c.*, s.nome AS subcategoria, k.id_categoria, k.nome AS categoria, t.nome AS tag
FROM tbl_compra_avista c
JOIN tbl_subcategoria s ON s.id_subcategoria = c.id_subcategoria
JOIN tbl_categoria    k ON k.id_categoria    = s.id_categoria
LEFT JOIN tbl_tag     t ON t.uuid_tag        = c.uuid_tag
WHERE c.timestamp_compra_avista >= :inicio AND c.timestamp_compra_avista < :fim
  AND (:id_categoria    IS NULL OR k.id_categoria    = :id_categoria)
  AND (:id_subcategoria IS NULL OR c.id_subcategoria = :id_subcategoria)
  AND (:uuid_tag        IS NULL OR c.uuid_tag        = :uuid_tag)
ORDER BY c.timestamp_compra_avista DESC;
```

O acumulado do mês ignora os filtros de categoria e tag, que afetam só a tabela (E01-F04).

```sql
-- Sugestão pela descrição (E01-F03-T16); :texto já normalizado, mínimo de 3 caracteres
SELECT id_subcategoria
FROM tbl_compra_avista
WHERE descricao_normalizada LIKE '%' || :texto || '%'
GROUP BY id_subcategoria
ORDER BY COUNT(*) DESC, MAX(timestamp_compra_avista) DESC
LIMIT 1;
```

O `LIKE` com curinga no início não usa índice; no volume da v1 a varredura leva milissegundos. Se as medições pedirem, o caminho de escalada é o FTS5 (DP-36).

---

## 4. Tabelas da v2 (rascunho)

Ajustadas às convenções da seção 2: valores em centavos, só `id_subcategoria`, `uuid_tag` nas compras, `criado_em`/`atualizado_em` e sem `uuid_usuario` (DP-33). Na v2, toda tabela sincronizada ganha `excluido_em` (nullable) para a exclusão lógica, e as consultas passam a filtrar `excluido_em IS NULL` (DP-34). O usuário é atribuído na carga para o banco da aplicação externo, pela sessão autenticada (DP-33). Como o SQLite local é de um usuário só, trocar de conta no aparelho exige limpar o banco local (regra da v2). As tabelas com data de evento (`tbl_compra_faturada` e `tbl_pagamento_fatura`) também ganham `fuso_minutos` (DP-33). Tipos e constraints serão detalhados quando a v2 começar.

### tbl_compra_faturada

| Coluna | Observação |
| --- | --- |
| uuid_compra_faturada | PK |
| uuid_cartao_credito | FK → tbl_cartoes_credito (E01-F05) |
| uuid_recorrencia | FK → tbl_recorrencia, nullable |
| timestamp_compra_faturada |  |
| descricao |  |
| id_subcategoria | FK → tbl_subcategoria (categoria derivada) |
| uuid_tag | FK → tbl_tag, nullable (DP-32) |
| valor_total | Centavos |
| mes_vencimento | Mês de vencimento da fatura da 1ª parcela. Manual (DP-3, DP-9) |
| ano_vencimento |  |
| quant_parcela | Lançamentos de recorrência usam 1 |
| status_lancamento | previsto · confirmado |
| criado_em, atualizado_em |  |

### tbl_parcela

Uma linha por parcela (DP-27). Base do consumo do limite (E01-F05-T01), da tabela de parcelas e da timeline da fatura.

| Coluna | Observação |
| --- | --- |
| uuid_parcela | PK |
| uuid_compra_faturada | FK → tbl_compra_faturada, `ON DELETE CASCADE` |
| numero_parcela | 1 a `quant_parcela` |
| valor_parcela | Centavos; a última parcela absorve o arredondamento |
| mes_vencimento | Mês da 1ª parcela + (n − 1) |
| ano_vencimento |  |

### tbl_pagamento_fatura

Registro do tipo pagamento de fatura (DP-14). Não entra nas somas de consumo; confirma que a fatura foi paga (E01-F05-T09).

| Coluna | Observação |
| --- | --- |
| uuid_pagamento_fatura | PK |
| uuid_cartao_credito | FK → tbl_cartoes_credito |
| mes_vencimento, ano_vencimento | Fatura paga |
| timestamp_pagamento |  |
| valor | Centavos |
| tipo_pagamento | pix · debito |
| criado_em, atualizado_em |  |

### tbl_recorrencia

Cobranças sem data final calculável (assinaturas). Cancelar altera só `status` e `data_fim`; o histórico permanece. A geração de lançamentos previstos está em aberto (E02-F04-T02), assim como a extensão ao à vista (DP-13) e a tag (DP-35).

| Coluna | Observação |
| --- | --- |
| uuid_recorrencia | PK |
| uuid_cartao_credito | FK. Pode virar nullable se o DP-13 estender a recorrência ao à vista |
| descricao |  |
| valor | Centavos |
| id_subcategoria | FK → tbl_subcategoria |
| periodicidade | mensal · anual… |
| dia_cobranca |  |
| data_inicio |  |
| data_fim | nullable; nulo = sem fim |
| status | ativa · cancelada · pausada |
| criado_em, atualizado_em |  |

### tbl_cartoes_credito

| Coluna | Observação |
| --- | --- |
| uuid_cartao_credito | PK |
| nome_cartao |  |
| limite_cartao | Centavos |
| dia_fechamento | nullable |
| cnpj_emissor | nullable; reconhece pagamentos de fatura vindos da API (DP-14) |
| status | ativo · arquivado. Cartão com compras é arquivado, não excluído (E01-F07-T08) |
| criado_em, atualizado_em |  |

### tbl_renda

Renda por vigência (DP-6): cada linha vale a partir de `mes_referencia`/`ano_referencia` até a próxima. Ganhos extras ainda em aberto (DP-26).

| Coluna | Observação |
| --- | --- |
| uuid_renda | PK |
| salario | Centavos |
| voucher | Centavos |
| mes_referencia | Mês a partir do qual o valor vale |
| ano_referencia |  |
| criado_em, atualizado_em |  |

### Tabela temporária de pendências

Mesmos campos da compra, todos nullable, mais os da seção 5.1. Falta decidir se é uma tabela genérica (com `tipo_registro`) ou uma por tipo de compra (DP-23).

---

## 5. Propostas em discussão (v2 em diante)

### 5.1 Pendências

Serve às três origens de dado (manual, notificação, API). Além dos campos da compra:

| Coluna | Valores / observação |
| --- | --- |
| origem | manual · notificacao · api |
| tipo_pendencia | cartao_nao_cadastrado · categoria_desconhecida · mes_vencimento_ausente · baixa_confianca · aguardando_aprovacao |
| indice_confianca | 0–100 |
| payload_original | dado bruto recebido |
| status | pendente · validado · descartado |

A tag não é motivo de pendência: registro sem tag é o caso normal (DP-32).

### 5.2 Mapeamento de categorias

Guarda a classificação aprendida (descrição/estabelecimento → subcategoria), para o app classificar sozinho depois da primeira vez (E04-F04). Aponta para `tbl_subcategoria`. Não infere tag.

### 5.3 Impactos da Pluggy

(Contexto na seção 4 do documento de arquitetura.)

- Guardar `id_externo`, **sem** usá-lo como PK; manter chave de reconciliação própria (data + valor + descrição).
- Guardar `purchaseDate` (data original da compra), pois as parcelas seguintes são re-datadas.
- Campo de número do cartão para mapear com `tbl_cartoes_credito`.
- Distinguir tipos de transação (compra, pagamento de fatura, estorno, tarifa) para não duplicar consumo.
- Pagamentos à vista para empresas com cartão cadastrado (via `cnpj_emissor`) não somam no consumo e confirmam a fatura paga (DP-14).
- Possível `data_fechamento` por fatura, se `billClosingDate` se confirmar nos testes.

### 5.4 Reserva futura (v3)

As fatias do superávit (E01-F07-T05) ainda não têm tabela. Quando entrarem, uma tabela de fatias (nome, valor fixo, ativa) deve bastar.

### 5.5 Remoção de `importancia`

Fora do SQLite e do rascunho da v2. Falta remover do DW (`dim_importancia` e a coluna nas fatos, E02-F03-T03).

---

## 6. Decisões

Acompanhamento em [Decisões pendentes](05_decisoes.md).

**Abertas que afetam a v1**

Nenhuma. DP-33 e DP-34 foram decididas e aplicadas.

**Abertas da v2**

3. DP-13: recorrências à vista.
4. DP-23: pendências à vista, tabela genérica ou por tipo.
5. DP-26: estrutura de renda e ganhos extras.
6. DP-35: tag nas recorrências.
7. Geração de lançamentos previstos das recorrências (E02-F04-T02).

**Decididas:** IDs de categoria (DP-21), usuário em JSON (DP-22), `tbl_parcela` (DP-27), vocabulário (DP-30), renda por vigência (DP-6), mês de vencimento (DP-3, DP-9), pagamento de fatura (DP-14), tags (DP-32), categorias (DP-11), bloqueio pelo PIN do aparelho (DP-31), exclusão física na v1 e lógica na v2 (DP-34), sem `uuid_usuario` local, datas em horário local com `fuso_minutos` e auditoria em UTC (DP-33).

---

## 7. Próximos passos

- [x] Esquema da v1: tipos, constraints, índices e carga inicial (E02-F01)
- [x] `tbl_tag` e FK nas compras (E02-F01-T05)
- [x] Remover `importancia` do SQLite (E02-F01-T03)
- [x] Aplicar o vocabulário padrão (E02-F01-T04)
- [x] Confirmar DP-33 e aplicar DP-34
- [x] Fechar o esquema da v1
- [ ] Tipos e constraints das tabelas da v2
- [ ] Esquema do banco transacional (E02-F02)
- [ ] Modelo analítico do DW e pipelines `DW_APOLO` (E02-F03)
- [ ] Estratégia de sincronização SQLite → transacional → DW (v2)
- [ ] Geração de lançamentos previstos das recorrências (E02-F04)
