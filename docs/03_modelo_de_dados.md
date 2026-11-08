# Ravix — Modelo de dados

> Exportado do Notion (Projetos / Ravix / Backlog app / modelagem banco) em 08/11/2026.
> Fonte: https://app.notion.com/p/3dfb044db6b1802a803bcebfcef7233f

> **Status:** esquema da v1 implementado (seção 3, Revisão 7). Esquema 2 implementado (seção 4, Revisão 8), com a migração 1 → 2 testada; as telas da v2 ainda não o usam. A v2 continua só local, e a sincronização com o banco transacional fica na v3 (DP-37).

> **Revisão 8 (08/11/2026):** esquema da v2 detalhado (DDL, regras, consultas e migração 1 → 2), com as decisões DP-1, 10, 13, 14, 25, 28, 29 e 35 e os testes reais da Pluggy. Novas tabelas `tbl_estorno` e `tbl_recorrencia_excecao`; recorrência também no à vista; previstos calculados, sem `status_lancamento`.

> **Revisão 7 (24/10/2026):** esquema da v1 implementado no M2 exatamente como na seção 3 (`App_ravix/lib/data/banco.drift`), com as consultas da seção 3.4 e o schema 1 exportado em `App_ravix/drift_schemas/`. O SQLite vem embutido pelo `sqlite3` 3.x (sem `sqlite3_flutter_libs`). Duas regras ficaram também no repositório: remover tag conta os registros antes de decidir entre excluir e arquivar, e nome de tag repetido é checado sem diferenciar maiúsculas inclusive em letras acentuadas (o `COLLATE NOCASE` só cobre ASCII). Medido no aparelho com 20 mil gastos: consulta do mês em 1 ms e sugestão em 27 ms.

> **Revisão 5 (22/10/2026):** `fuso_minutos` adicionado às tabelas com data de evento; `criado_em` e `atualizado_em` em UTC (DP-33).

> **Revisão 6 (22/10/2026):** coluna `descricao_normalizada` e consulta da sugestão pela descrição; configuração de desempenho do banco (DP-36). Plano de implementação em [Plano de desenvolvimento — v1](04_plano_desenvolvimento_v1.md).

> **Revisão 4 (22/10/2026):** esquema da v1 detalhado com tipos, constraints, índices e carga inicial. Aplicados o DP-32 (`tbl_tag`), o DP-11 (8 categorias, 34 subcategorias) e a proposta do DP-33 (sem `uuid_usuario` local, datas ISO no horário local, `criado_em`/`atualizado_em`). As compras passam a guardar só `id_subcategoria` e os valores em centavos. Dúvidas novas no quadro [Decisões pendentes](05_decisoes.md): DP-33, DP-34 e DP-35.

**Documentos relacionados:** [01_visao_geral_e_arquitetura.md](01_visao_geral_e_arquitetura.md) · [Backlog app](02_backlog.md)

---

## 1. Escopo

Banco interno do app. Na v1 e na v2 ele é o único banco (DP-7, DP-37). Na v3, os registros passam a ser enviados ao banco transacional e, depois, ao DW, que expande o escopo para o contexto analítico.

| Camada | Documentação |
| --- | --- |
| SQLite (app), v1 | Seção 3 (pronto) |
| SQLite (app), v2 | Seção 4 (implementado) |
| Banco transacional | A definir (v3, DP-37) |
| Data Warehouse (`DW_APOLO`) | A definir (pipelines sem conteúdo) |

---

## 2. Convenções

| Item | Regra |
| --- | --- |
| Nomes | Tabelas `tbl_*`, colunas em `snake_case` minúsculo, vocabulário à vista / faturada (DP-30) |
| Chaves de registros do usuário | `uuid_*`, TEXT com UUID v4 gerado no app. Evita colisão na sincronização da v3 |
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
- **Excluir registro** (E01-F03-T11) e **excluir tag sem registros** (E01-F07-T10): exclusão física na v1 (DP-34). Na v3, com a sincronização, as tabelas sincronizadas passam a ter exclusão lógica com `excluido_em` (E02-F02-T03, DP-37).

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

## 4. Esquema da v2 (schema 2)

> **Status (08/11/2026):** implementado em `App_ravix/lib/data/banco.drift`, com a migração em `banco.dart`, o schema 2 exportado em `App_ravix/drift_schemas/` e os testes de migração em `test/data/migracoes/`. Montado a partir das decisões DP-1, 10, 13, 14, 25, 28, 29 e 35 e dos testes reais da Pluggy (seções 4.7 e 4.8 de [01_visao_geral_e_arquitetura.md](01_visao_geral_e_arquitetura.md)).

Mesmas convenções da seção 2. A v2 continua só local (DP-37). Na v3, com a sincronização, toda tabela sincronizada ganha `excluido_em` (nullable) para a exclusão lógica, e as consultas passam a filtrar `excluido_em IS NULL` (DP-34). O usuário é atribuído na carga para o banco externo, pela sessão autenticada (DP-33).

### 4.1 Tabelas

| Tabela | Uso |
| --- | --- |
| `tbl_cartoes_credito` | Cartões (E01-F07-T03, T06–T08) |
| `tbl_compra_faturada` | Compra no cartão, parcelada ou lançamento de recorrência (E01-F03-T06) |
| `tbl_parcela` | Uma linha por parcela (DP-27). Base da fatura, da timeline e do consumo do limite |
| `tbl_recorrencia` | Regra de cobrança recorrente, à vista ou faturada (DP-13, DP-25) |
| `tbl_recorrencia_excecao` | Ocorrências puladas ("excluir só este" de um lançamento recorrente) |
| `tbl_pagamento_fatura` | Pagamento de fatura; não soma no consumo (DP-14) |
| `tbl_estorno` | Estorno de cartão; abate da fatura e do consumo (DP-14) |
| `tbl_renda` | Salário e voucher por vigência (DP-6) |
| `tbl_compra_avista` | Já existe; ganha `uuid_recorrencia` e `ocorrencia` |

### 4.2 DDL

O DDL implementado está em `App_ravix/lib/data/banco.drift`. Resumo, com os comentários de cada coluna:

```sql
PRAGMA user_version = 2;

CREATE TABLE tbl_cartoes_credito (
  uuid_cartao_credito TEXT    NOT NULL PRIMARY KEY,
  nome_cartao         TEXT    NOT NULL UNIQUE COLLATE NOCASE
                      CHECK (length(trim(nome_cartao)) > 0),
  final_cartao        TEXT    NULL CHECK (final_cartao GLOB '[0-9][0-9][0-9][0-9]'),  -- 4 últimos dígitos (casa com cardNumber na v3)
  limite_cartao       INTEGER NOT NULL CHECK (limite_cartao > 0),                      -- centavos
  dia_fechamento      INTEGER NULL CHECK (dia_fechamento BETWEEN 1 AND 31),            -- só sugestão (DP-28)
  dia_vencimento      INTEGER NULL CHECK (dia_vencimento BETWEEN 1 AND 31),            -- só sugestão (DP-28)
  cnpj_emissor        TEXT    NULL CHECK (length(cnpj_emissor) = 14 AND cnpj_emissor NOT GLOB '*[^0-9]*'),
  status              TEXT    NOT NULL DEFAULT 'ativo' CHECK (status IN ('ativo', 'arquivado')),
  criado_em           TEXT    NOT NULL,
  atualizado_em       TEXT    NOT NULL
);

CREATE TABLE tbl_recorrencia (
  uuid_recorrencia       TEXT    NOT NULL PRIMARY KEY,
  tipo_registro          TEXT    NOT NULL CHECK (tipo_registro IN ('avista', 'faturado')),
  uuid_cartao_credito    TEXT    NULL REFERENCES tbl_cartoes_credito (uuid_cartao_credito) ON DELETE RESTRICT,
  tipo_pagamento         TEXT    NULL CHECK (tipo_pagamento IN ('pix', 'debito', 'dinheiro', 'voucher', 'boleto')),
  documento_beneficiario TEXT    NULL CHECK (length(documento_beneficiario) IN (11, 14)
                         AND documento_beneficiario NOT GLOB '*[^0-9]*'),  -- CPF ou CNPJ; gatilho do pagamento na v3
  descricao              TEXT    NOT NULL CHECK (length(trim(descricao)) > 0),
  descricao_normalizada  TEXT    NOT NULL,
  valor_recorrencia      INTEGER NOT NULL CHECK (valor_recorrencia > 0),  -- centavos
  id_subcategoria        INTEGER NOT NULL REFERENCES tbl_subcategoria (id_subcategoria),
  periodicidade          TEXT    NOT NULL CHECK (periodicidade IN ('mensal', 'anual')),
  dia_cobranca           INTEGER NOT NULL CHECK (dia_cobranca BETWEEN 1 AND 31),
  data_inicio            TEXT    NOT NULL,  -- YYYY-MM-DD; na anual, o mês da cobrança
  data_fim               TEXT    NULL,      -- nulo = sem fim
  status                 TEXT    NOT NULL DEFAULT 'ativa'
                         CHECK (status IN ('ativa', 'pausada', 'cancelada')),
  criado_em              TEXT    NOT NULL,
  atualizado_em          TEXT    NOT NULL,
  CHECK ((tipo_registro = 'faturado' AND uuid_cartao_credito IS NOT NULL AND tipo_pagamento IS NULL)
      OR (tipo_registro = 'avista'   AND uuid_cartao_credito IS NULL     AND tipo_pagamento IS NOT NULL)),
  CHECK (data_fim IS NULL OR data_fim >= data_inicio)
);  -- sem tag: a tag vai no lançamento (DP-35)

CREATE TABLE tbl_recorrencia_excecao (
  uuid_recorrencia TEXT NOT NULL REFERENCES tbl_recorrencia (uuid_recorrencia) ON DELETE CASCADE,
  ocorrencia       TEXT NOT NULL,  -- YYYY-MM-DD da cobrança pulada
  criado_em        TEXT NOT NULL,
  PRIMARY KEY (uuid_recorrencia, ocorrencia)
);

CREATE TABLE tbl_compra_faturada (
  uuid_compra_faturada      TEXT    NOT NULL PRIMARY KEY,
  uuid_cartao_credito       TEXT    NOT NULL REFERENCES tbl_cartoes_credito (uuid_cartao_credito) ON DELETE RESTRICT,
  uuid_recorrencia          TEXT    NULL REFERENCES tbl_recorrencia (uuid_recorrencia) ON DELETE RESTRICT,
  ocorrencia                TEXT    NULL,  -- YYYY-MM-DD da cobrança que gerou o lançamento
  timestamp_compra_faturada TEXT    NOT NULL,
  fuso_minutos              INTEGER NOT NULL CHECK (fuso_minutos BETWEEN -720 AND 840),
  descricao                 TEXT    NOT NULL CHECK (length(trim(descricao)) > 0),
  descricao_normalizada     TEXT    NOT NULL,
  valor_total               INTEGER NOT NULL CHECK (valor_total > 0),  -- centavos
  quant_parcela             INTEGER NOT NULL CHECK (quant_parcela BETWEEN 1 AND 99),
  mes_vencimento            INTEGER NOT NULL CHECK (mes_vencimento BETWEEN 1 AND 12),  -- fatura da 1ª parcela
  ano_vencimento            INTEGER NOT NULL CHECK (ano_vencimento BETWEEN 2000 AND 2100),
  id_subcategoria           INTEGER NOT NULL REFERENCES tbl_subcategoria (id_subcategoria),
  uuid_tag                  TEXT    NULL REFERENCES tbl_tag (uuid_tag) ON DELETE RESTRICT,
  criado_em                 TEXT    NOT NULL,
  atualizado_em             TEXT    NOT NULL,
  CHECK ((uuid_recorrencia IS NULL) = (ocorrencia IS NULL)),
  CHECK (uuid_recorrencia IS NULL OR quant_parcela = 1),
  CHECK (valor_total >= quant_parcela)  -- nenhuma parcela de zero centavo
);

CREATE TABLE tbl_parcela (
  uuid_parcela         TEXT    NOT NULL PRIMARY KEY,
  uuid_compra_faturada TEXT    NOT NULL REFERENCES tbl_compra_faturada (uuid_compra_faturada) ON DELETE CASCADE,
  numero_parcela       INTEGER NOT NULL CHECK (numero_parcela >= 1),
  valor_parcela        INTEGER NOT NULL CHECK (valor_parcela > 0),
  mes_vencimento       INTEGER NOT NULL CHECK (mes_vencimento BETWEEN 1 AND 12),
  ano_vencimento       INTEGER NOT NULL CHECK (ano_vencimento BETWEEN 2000 AND 2100),
  UNIQUE (uuid_compra_faturada, numero_parcela)
);

CREATE TABLE tbl_pagamento_fatura (
  uuid_pagamento_fatura TEXT    NOT NULL PRIMARY KEY,
  uuid_cartao_credito   TEXT    NOT NULL REFERENCES tbl_cartoes_credito (uuid_cartao_credito) ON DELETE RESTRICT,
  mes_vencimento        INTEGER NOT NULL CHECK (mes_vencimento BETWEEN 1 AND 12),  -- fatura paga
  ano_vencimento        INTEGER NOT NULL CHECK (ano_vencimento BETWEEN 2000 AND 2100),
  timestamp_pagamento   TEXT    NOT NULL,
  fuso_minutos          INTEGER NOT NULL CHECK (fuso_minutos BETWEEN -720 AND 840),
  valor_pagamento       INTEGER NOT NULL CHECK (valor_pagamento > 0),
  tipo_pagamento        TEXT    NOT NULL CHECK (tipo_pagamento IN ('pix', 'debito', 'boleto')),
  criado_em             TEXT    NOT NULL,
  atualizado_em         TEXT    NOT NULL
);

CREATE TABLE tbl_estorno (
  uuid_estorno         TEXT    NOT NULL PRIMARY KEY,
  uuid_cartao_credito  TEXT    NOT NULL REFERENCES tbl_cartoes_credito (uuid_cartao_credito) ON DELETE RESTRICT,
  uuid_compra_faturada TEXT    NULL REFERENCES tbl_compra_faturada (uuid_compra_faturada) ON DELETE SET NULL,  -- compra original, opcional
  timestamp_estorno    TEXT    NOT NULL,
  fuso_minutos         INTEGER NOT NULL CHECK (fuso_minutos BETWEEN -720 AND 840),
  descricao            TEXT    NOT NULL CHECK (length(trim(descricao)) > 0),
  valor_estorno        INTEGER NOT NULL CHECK (valor_estorno > 0),
  mes_vencimento       INTEGER NOT NULL CHECK (mes_vencimento BETWEEN 1 AND 12),  -- fatura que recebe o abatimento
  ano_vencimento       INTEGER NOT NULL CHECK (ano_vencimento BETWEEN 2000 AND 2100),
  id_subcategoria      INTEGER NOT NULL REFERENCES tbl_subcategoria (id_subcategoria),  -- herdada da compra original
  uuid_tag             TEXT    NULL REFERENCES tbl_tag (uuid_tag) ON DELETE RESTRICT,
  criado_em            TEXT    NOT NULL,
  atualizado_em        TEXT    NOT NULL
);

CREATE TABLE tbl_renda (
  uuid_renda     TEXT    NOT NULL PRIMARY KEY,
  salario        INTEGER NOT NULL CHECK (salario >= 0),  -- centavos
  voucher        INTEGER NOT NULL CHECK (voucher >= 0),
  mes_referencia INTEGER NOT NULL CHECK (mes_referencia BETWEEN 1 AND 12),  -- vale a partir deste mês
  ano_referencia INTEGER NOT NULL CHECK (ano_referencia BETWEEN 2000 AND 2100),
  criado_em      TEXT    NOT NULL,
  atualizado_em  TEXT    NOT NULL,
  UNIQUE (ano_referencia, mes_referencia)
);

-- tbl_compra_avista reconstruída: boleto no tipo_pagamento e as colunas da recorrência
CREATE TABLE tbl_compra_avista (
  uuid_compra_avista      TEXT    NOT NULL PRIMARY KEY,
  timestamp_compra_avista TEXT    NOT NULL,
  fuso_minutos            INTEGER NOT NULL CHECK (fuso_minutos BETWEEN -720 AND 840),
  descricao               TEXT    NOT NULL CHECK (length(trim(descricao)) > 0),
  descricao_normalizada   TEXT    NOT NULL,
  valor_compra_avista     INTEGER NOT NULL CHECK (valor_compra_avista > 0),
  tipo_pagamento          TEXT    NOT NULL
                          CHECK (tipo_pagamento IN ('pix', 'debito', 'dinheiro', 'voucher', 'boleto')),
  id_subcategoria         INTEGER NOT NULL REFERENCES tbl_subcategoria (id_subcategoria),
  uuid_tag                TEXT    NULL REFERENCES tbl_tag (uuid_tag) ON DELETE RESTRICT,
  uuid_recorrencia        TEXT    NULL REFERENCES tbl_recorrencia (uuid_recorrencia) ON DELETE RESTRICT,
  ocorrencia              TEXT    NULL,
  criado_em               TEXT    NOT NULL,
  atualizado_em           TEXT    NOT NULL,
  CHECK ((uuid_recorrencia IS NULL) = (ocorrencia IS NULL))
);

CREATE UNIQUE INDEX ux_compra_avista_ocorrencia   ON tbl_compra_avista   (uuid_recorrencia, ocorrencia) WHERE uuid_recorrencia IS NOT NULL;
CREATE UNIQUE INDEX ux_compra_faturada_ocorrencia ON tbl_compra_faturada (uuid_recorrencia, ocorrencia) WHERE uuid_recorrencia IS NOT NULL;
CREATE INDEX idx_compra_faturada_cartao       ON tbl_compra_faturada (uuid_cartao_credito);
CREATE INDEX idx_compra_faturada_timestamp    ON tbl_compra_faturada (timestamp_compra_faturada);
CREATE INDEX idx_compra_faturada_subcategoria ON tbl_compra_faturada (id_subcategoria);
CREATE INDEX idx_compra_faturada_tag          ON tbl_compra_faturada (uuid_tag);
CREATE INDEX idx_parcela_vencimento           ON tbl_parcela (ano_vencimento, mes_vencimento);
CREATE INDEX idx_pagamento_fatura_fatura      ON tbl_pagamento_fatura (uuid_cartao_credito, ano_vencimento, mes_vencimento);
CREATE INDEX idx_estorno_fatura               ON tbl_estorno (uuid_cartao_credito, ano_vencimento, mes_vencimento);
```

### 4.3 Regras

- **Sugestão do mês de vencimento** (DP-28): no formulário, se o cartão tem `dia_fechamento`, a compra feita até esse dia entra na fatura que fecha no mês da compra; depois dele, na do mês seguinte. A fatura vence no mesmo mês do fechamento se `dia_vencimento` > `dia_fechamento`, senão no mês seguinte. Sem os dias, sugere o mês seguinte à compra. O usuário pode trocar; o que vale é o mês gravado.
- **Parcelas** (DP-27): ao salvar a compra, o app gera `quant_parcela` linhas em `tbl_parcela`, com mês da 1ª parcela + (n − 1). O resto da divisão vai na 1ª parcela, como o Itaú faz (R$ 236,88 + 18 × R$ 236,84). Editar valor, quantidade ou mês regera todas as parcelas.
- **Recorrências** (DP-13, DP-25): `tbl_recorrencia` guarda só a regra. Os previstos são calculados na consulta, para o mês selecionado. Quando o previsto vira lançamento real (em `tbl_compra_avista` ou `tbl_compra_faturada`, com `ocorrencia` preenchida; o índice único impede duplicar) depende do tipo:
  - **Faturado:** automaticamente. Ao abrir o app (e ao voltar para ele), cada ocorrência com data até hoje que ainda não existe é gravada, porque o cartão cobra sozinho.
  - **À vista, v2:** o previsto aparece pré-registrado na aba à vista do mês, marcado como previsto e fora das somas. Quando o usuário paga, toca em **Registrar**: o lançamento é gravado com a data e hora do toque e os dados da regra, editáveis antes de salvar (valor de conta variável, forma de pagamento). Previsto com data já passada continua pré-registrado, com aviso de atraso.
  - **À vista, v3:** uma saída vinda da API para o `documento_beneficiario` da regra, com valor dentro de uma faixa, no mês da ocorrência, registra o lançamento sozinha, com data e valor reais.
  - Ocorrências em `tbl_recorrencia_excecao` são puladas nos três casos.
  - `dia_cobranca` 29, 30 ou 31 em mês mais curto cai no último dia do mês. A anual cobra no mês de `data_inicio`.
  - Pausada ou cancelada não gera previstos nem lançamentos; os lançamentos já gerados ficam.
  - Lançamento faturado gerado: `quant_parcela = 1` e mês de vencimento pela regra de sugestão.
  - "Só este": editar um previsto o materializa antes com os valores editados; excluir grava uma exceção (e apaga o lançamento, se já existir).
  - "Este e os próximos": a regra antiga ganha `data_fim` na véspera da ocorrência e uma nova regra começa nela. Os lançamentos reais anteriores não mudam.
  - Recorrência com lançamentos não é excluída (`RESTRICT`): é cancelada.
- **Fatura** de um cartão num mês = soma das parcelas daquele mês de vencimento − estornos daquele mês. Os previstos de recorrência aparecem na fatura marcados como previstos (E01-F05-T07).
- **Fatura paga** (E01-F05-T09): soma dos pagamentos daquela fatura ≥ valor da fatura. Abaixo disso e acima de zero, paga parcialmente.
- **Consumo do limite** (E01-F05-T01): soma das parcelas de todas as faturas ainda não pagas do cartão, inclusive futuras, menos os estornos delas, dividido por `limite_cartao`. Previstos não entram.
- **Estorno** (DP-14): valor positivo que abate da fatura do mês indicado, do consumo e dos totais por categoria e tag. Com compra original, herda subcategoria e tag dela (editáveis).
- **Pagamento de fatura** não entra em nenhuma soma de consumo.
- **Renda vigente** (DP-6): para um mês, vale a linha de `tbl_renda` com a maior referência menor ou igual a ele. Sem nenhuma linha, a visão macro pede o cadastro da renda.
- **Remover cartão** (DP-29): o `RESTRICT` impede excluir cartão com compras, pagamentos ou estornos; o app então arquiva. Arquivado some dos seletores e continua nas telas de histórico.

### 4.4 Consultas principais

```sql
-- Fatura de um mês por cartão, com o valor pago (E01-F05-T01, T09). Previstos somados no app.
SELECT k.uuid_cartao_credito, k.nome_cartao,
       COALESCE((SELECT SUM(p.valor_parcela)
                 FROM tbl_parcela p
                 JOIN tbl_compra_faturada c ON c.uuid_compra_faturada = p.uuid_compra_faturada
                 WHERE c.uuid_cartao_credito = k.uuid_cartao_credito
                   AND p.ano_vencimento = :ano AND p.mes_vencimento = :mes), 0)
     - COALESCE((SELECT SUM(e.valor_estorno)
                 FROM tbl_estorno e
                 WHERE e.uuid_cartao_credito = k.uuid_cartao_credito
                   AND e.ano_vencimento = :ano AND e.mes_vencimento = :mes), 0) AS valor_fatura,
       COALESCE((SELECT SUM(g.valor_pagamento)
                 FROM tbl_pagamento_fatura g
                 WHERE g.uuid_cartao_credito = k.uuid_cartao_credito
                   AND g.ano_vencimento = :ano AND g.mes_vencimento = :mes), 0) AS valor_pago
FROM tbl_cartoes_credito k
ORDER BY k.nome_cartao;

-- Renda vigente de um mês (DP-6)
SELECT salario, voucher
FROM tbl_renda
WHERE ano_referencia * 100 + mes_referencia <= :ano * 100 + :mes
ORDER BY ano_referencia DESC, mes_referencia DESC
LIMIT 1;
```

Visão macro (E01-F06, DP-1): faturado do mês = soma das faturas de todos os cartões que vencem no mês; à vista = consulta da v1, separando o voucher. Só lançamentos reais entram; previstos de recorrência ficam fora do total e do farol (4.6, item 5). Só salário = (faturado + à vista sem voucher) ÷ salário; renda total = tudo ÷ (salário + voucher).

### 4.5 Migração 1 → 2

1. Criar as oito tabelas novas e os índices.
2. Reconstruir `tbl_compra_avista` (criar a nova, copiar os registros, apagar a antiga, renomear e recriar os três índices da v1), via `TableMigration` do drift. Os registros da v1 ficam com as colunas novas nulas; nenhum valor muda.
3. `user_version = 2`, schema 2 exportado em `App_ravix/drift_schemas/` e teste de migração do drift (banco v1 com dados → v2, comparando com o schema exportado).

Com a reconstrução, o `CHECK` de `uuid_recorrencia` e `ocorrencia` fica no banco também no à vista.

### 4.6 Pontos revisados (08/11/2026)

Todos aplicados no schema 2.

1. **`final_cartao`** opcional: deixa a v3 casar o cartão pelo `cardNumber` sem migração (seção 4.8 de [01_visao_geral_e_arquitetura.md](01_visao_geral_e_arquitetura.md)).
2. **`dia_vencimento` além de `dia_fechamento`**: só com o fechamento não dá para sugerir o mês de vencimento quando o vencimento cai no mês seguinte ao fechamento (caso do Itaú: fecha ~29, vence ~5).
3. **Boleto** como forma de pagamento no à vista, nas recorrências à vista e no pagamento de fatura. Exigiu reconstruir `tbl_compra_avista` na migração.
4. **Arredondamento na 1ª parcela**, como o Itaú, em vez da última (rascunho anterior). Facilita casar com o banco na v3.
5. **Previstos fora da visão macro**: não entram no total nem no farol; só contam depois de pagos (viram lançamento). Aparecem como linha secundária ("+ R$ X previstos até o fim do mês").
6. **Estorno herda subcategoria e tag** da compra original, para abater também nos gráficos por categoria e na visão por tag.
7. **Pagamento parcial** de fatura aparece como "paga parcialmente".
8. **`status_lancamento` (previsto/confirmado) saiu** de `tbl_compra_faturada`: com o DP-25, previsto não é gravado.

### Tabela temporária de pendências (v3)

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

(Contexto na seção 4 de [01_visao_geral_e_arquitetura.md](01_visao_geral_e_arquitetura.md).)

- Guardar `id_externo`, **sem** usá-lo como PK. O `providerId` veio em todas as transações reais e é a chave de reconciliação preferida; data + valor + descrição fica como alternativa.
- Guardar `purchaseDate`. No Itaú as parcelas lançadas mantêm a data da compra e as futuras vêm `PENDING`; a fatura de cada parcela vem em `billForecastDate`.
- `final_cartao` (4 dígitos) para casar com `cardNumber`, que distingue titular e adicional.
- Distinguir tipos de transação (compra, pagamento de fatura, estorno, tarifa) para não duplicar consumo.
- Pagamentos à vista para empresas com cartão cadastrado (via `cnpj_emissor`) não somam no consumo e confirmam a fatura paga (DP-14).
- `data_fechamento` e `data_vencimento` reais por fatura: confirmadas no Itaú (`billClosingDate` e `dueDate` em `bills`). Entram na v3 numa tabela de faturas.
- Sinal: no cartão, compra = `DEBIT` positivo e pagamento = `CREDIT` negativo; na conta, o contrário.

### 5.4 Reserva futura (v3)

As fatias do superávit (E01-F07-T05) ainda não têm tabela. Quando entrarem, uma tabela de fatias (nome, valor fixo, ativa) deve bastar.

### 5.5 Remoção de `importancia`

Fora do SQLite e do esquema da v2. Falta remover do DW (`dim_importancia` e a coluna nas fatos, E02-F03-T03).

---

## 6. Decisões

Acompanhamento em [Decisões pendentes](05_decisoes.md).

**Abertas que afetam a v1**

Nenhuma. DP-33 e DP-34 foram decididas e aplicadas.

**Abertas da v2**

Nenhuma. Os pontos da seção 4.6 foram revisados. DP-23 (pendências) é da v3 e DP-26 (ganhos extras) segue sem versão.

**Decididas:** IDs de categoria (DP-21), usuário em JSON (DP-22), `tbl_parcela` (DP-27), vocabulário (DP-30), renda por vigência (DP-6), mês de vencimento (DP-3, DP-9), pagamento de fatura (DP-14), tags (DP-32), categorias (DP-11), bloqueio pelo PIN do aparelho (DP-31), exclusão física na v1 e na v2, lógica na v3 com a sincronização (DP-34, DP-37), sem `uuid_usuario` local, datas em horário local com `fuso_minutos` e auditoria em UTC (DP-33).

---

## 7. Próximos passos

- [x] Esquema da v1: tipos, constraints, índices e carga inicial (E02-F01)
- [x] `tbl_tag` e FK nas compras (E02-F01-T05)
- [x] Remover `importancia` do SQLite (E02-F01-T03)
- [x] Aplicar o vocabulário padrão (E02-F01-T04)
- [x] Confirmar DP-33 e aplicar DP-34
- [x] Fechar o esquema da v1
- [x] Tipos e constraints das tabelas da v2 (seção 4)
- [x] Revisar os pontos da seção 4.6 e implementar a migração 1 → 2
- [x] Geração de lançamentos previstos das recorrências (E02-F04, DP-25)
- [ ] Esquema do banco transacional (E02-F02, v3)
- [ ] Modelo analítico do DW e pipelines `DW_APOLO` (E02-F03)
- [ ] Estratégia de sincronização SQLite → transacional → DW (v3)
