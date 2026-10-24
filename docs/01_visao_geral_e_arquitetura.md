# Ravix — Visão geral e arquitetura

> Exportado do Notion (Projetos / Ravix) em 24/10/2026.
> Fonte: https://app.notion.com/p/3fdb044db6b182bd870201140670d798

**Descrição:** Gerenciador de gastos pessoais<br />
**Status:** Modelagem<br />
**Linguagem:** Dart<br />
**Documentos relacionados:** [02_backlog.md](02_backlog.md) · [03_modelo_de_dados.md](03_modelo_de_dados.md)

---

## 1. Visão geral

### 1.1 Objetivo

Alcançar o próximo nível de maturidade em gestão financeira, acompanhando o fluxo de caixa de forma detalhada e com baixa latência (do pagamento ao registro).

### 1.2 Sentido do nome

Amálgama de **Ratio** + **Vindex** (latim): "razão e defesa", "raciocínio e proteção", "aquele que, pela razão, defende/reivindica algo".

- **Ratio** (de *reri*, calcular/julgar): maneira ordenada de pensar ou calcular. Ex.: *ratio decidendi*, o fundamento de uma decisão judicial.
- **Vindex** (de *vindicare*, reivindicar): defensor, protetor, aquele que faz valer um direito. Não é "vingador" no sentido de vingança pessoal. Ex.: *vindex libertatis*.

---

## 2. Definições técnicas

### 2.1 Ambiente de desenvolvimento

| Item | Escolha |
| --- | --- |
| Linguagem / framework | Dart com Flutter |
| Editor | Android Studio |
| Sistema operacional | Linux (Fedora) |

### 2.2 Recursos Android

- ~~Câmera: leitura de QR codes e códigos de barras~~ (fora do escopo por ora)
- Leitor biométrico
- Captura de notificações (ver E03 no backlog)

---

## 3. Arquitetura

### 3.1 Backlog do sistema

- [Backlog app](02_backlog.md)
- [Decisões pendentes](05_decisoes.md)

### 3.2 Visão em camadas

```txt
 Fontes de dados                  App (Flutter)                  Backend
┌─────────────────┐         ┌────────────────────┐      ┌────────────────────┐
│ Entrada manual  │────────▶│                    │      │                    │
│ Notificações    │────────▶│ SQLite interno     │─────▶│ Banco transacional │──▶ Data Warehouse
│ API própria ◀───┼─────────│ + tabela temporária│      │ (performance)      │    (análise)
│    ▲            │         │   (pendências)     │      │                    │
│    └─ Pluggy    │         └────────────────────┘      └────────────────────┘
└─────────────────┘
```

### 3.3 Camadas de dados

| Camada | Papel |
| --- | --- |
| SQLite (app) | Armazenamento temporário dos registros antes da carga |
| Banco transacional | Atende o app, foco em performance |
| Data Warehouse | Escopo analítico (modelo financeiro, painel) |

Fluxo: **SQLite → transacional → DW**. Os pipelines do DW (`DW_APOLO`) ainda serão documentados. Na v1, o app é só local (SQLite); o banco transacional e a API própria entram na v2 (DP-7).

### 3.4 Princípios

1. **API própria como intermediária.** O app nunca fala direto com a Pluggy. A API própria normaliza os dados para que o sistema não fique preso a uma única fonte.
2. **Baixa latência.** Notificação do pagamento sugere o registro imediato; webhooks em vez de polling.
3. **Usuário valida o que a máquina não sabe.** Registros incompletos ou de baixa confiança vão para uma tabela temporária e esperam validação.
4. **Aprendizado de classificação.** Na primeira vez o usuário classifica; o app memoriza e passa a classificar sozinho. Um modelo com índice de confiança ≥ 90 classifica automaticamente; abaixo disso, pede validação.

### 3.5 Fluxo de entrada de um registro

```txt
Origem (manual | notificação | Pluggy)
        │
        ▼
 Dados completos e confiáveis? ── sim ──▶ tabela central
        │ não
        ▼
 Tabela temporária (tipo de pendência)
   • cartão não cadastrado
   • categoria desconhecida
   • confiança < 90
        │
        ▼
 Usuário valida/completa ──▶ tabela central
```

---

## 4. Integração externa: Pluggy

> **Status:** pesquisa preliminar na documentação pública (docs.pluggy.ai). Itens marcados com 🧪 dependem dos seus testes.

### 4.1 O que é

Infraestrutura de Open Finance para o Brasil. Conecta contas bancárias do usuário (um *item*) e entrega contas, transações e faturas de forma normalizada.

### 4.2 Entidades relevantes

| Entidade | Uso no Ravix |
| --- | --- |
| Item | Conexão do usuário com uma instituição |
| Account | Conta corrente (BANK) ou cartão (CREDIT) |
| Transaction | Gastos e recebimentos |
| Bill (fatura) | Valor, vencimento e fechamento da fatura. Só em conexões "Regulado" |

### 4.3 Comportamentos que afetam o desenho

1. **Data de fechamento.** Em jul/2026 a Pluggy adicionou `billClosingDate` e `billForecastDate` em transações e faturas de cartão. Só vêm em conexões criadas depois da implementação, e `billClosingDate` pode ser nulo.
2. **ID instável em cartão.** Reajustes perto do fechamento podem chegar como *delete + create* com novo `id`. Recomendação da Pluggy: reconciliar por data + valor + descrição (ou `providerId`, só em Open Finance).
3. **Webhook de exclusão** (`transactions/deleted`) traz apenas IDs; processar de forma idempotente.
4. **Parcelas.** A 1ª parcela vem com a data original da compra; as seguintes são re-datadas para o ciclo da fatura. `creditCardMetadata.purchaseDate` guarda a data original.
5. **Transações com data futura** não são necessariamente erro.
6. **Status `PENDING`** para compras ainda não incluídas em fatura fechada.
7. **Sinal normalizado.** Compras de cartão são DEBIT; pagamento de fatura é CREDIT (`PAGAMENTO_FATURA`). Precisa ser filtrado para não duplicar consumo.
8. **Categoria da Pluggy** (campo `category`) pode servir de sinal de entrada para o classificador próprio.
9. **Histórico inicial** de cerca de 12 meses ao conectar.
10. **Limites de chamadas.** Listagem de faturas ~30/mês; usar webhooks.

### 4.4 Respostas parciais às dúvidas do backlog

- **Data de fechamento via API?** Provavelmente sim (item 1), com ressalvas. 🧪
- **Vários cartões?** Cada cartão é uma account; a transação traz `cardNumber` em `creditCardMetadata`. 🧪 Confirmar formato (mascarado?).

### 4.5 Checklist de testes 🧪

- [ ] Criar item e listar accounts (cartão e conta corrente)
- [ ] Ver se `billClosingDate` / `billForecastDate` vêm preenchidos nos seus bancos
- [ ] Comparar data da 1ª parcela com as seguintes numa compra parcelada
- [ ] Observar um fechamento de fatura (delete + create?)
- [ ] Ver o formato de `cardNumber`
- [ ] Verificar se PIX recebidos têm tipo identificável (renda/superávit)
- [ ] Medir latência entre pagamento e webhook
- [ ] Avaliar utilidade da categoria da Pluggy
- [ ] Verificar se o plano gratuito expõe o CNPJ de quem recebe pagamentos (Pix, boleto), para reconhecer pagamento de fatura (DP-14)
- [ ] Anotar limites de chamadas e custos do plano

---

## 5. Fontes

- docs.pluggy.ai: Credit Card Installments, Credit card transactions and the statement cycle, Transaction, Credit Card Bills, Changelog

---

## Outras páginas do projeto

- **Esquema — Data Warehouse:** [06_data_warehouse.md](06_data_warehouse.md) (Modelagem dados + Backlog pipelines)
- **Pipelines DW_APOLO:** [04_plano_desenvolvimento_v1.md](04_plano_desenvolvimento_v1.md) (no Notion, o Plano de desenvolvimento — v1 fica sob este título) · projeto irmão [07_dw_apolo.md](07_dw_apolo.md)
