# Ravix — Visão geral e arquitetura

> Exportado do Notion (Projetos / Ravix) em 08/11/2026.
> Fonte: https://app.notion.com/p/3fdb044db6b182bd870201140670d798

**Descrição:** Gerenciador de gastos pessoais<br />
**Status:** v1 concluída em 24/10/2026, em fase de testes no aparelho ([plano](04_plano_desenvolvimento_v1.md))<br />
**Repositório:** [github.com/Cintriano/Ravix](https://github.com/Cintriano/Ravix) (app em `App_ravix`, documentação em `docs`)<br />
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
| Stack da v1 | Flutter 3.47 (Dart 3.13), drift + `sqlite3` 3.x, Riverpod 3, go_router, local_auth, shared_preferences (DP-36) |
| Qualidade | `very_good_analysis`, CI no GitHub Actions (`analyze` + testes com cobertura) |
| Identidade visual | Identidade própria v2 (Floresta e Menta, Chakra Petch e Archivo, cantos chanfrados), em `identidade_visual/v2` (DP-39) |

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

Fluxo: **SQLite → transacional → DW**. Os pipelines do DW (`DW_APOLO`) ainda serão documentados. Na v1 e na v2, o app é só local (SQLite); o banco transacional, a API própria e a integração com a Pluggy entram na v3 (DP-7, DP-37).

### 3.4 Princípios

1. **API própria como intermediária.** O app nunca fala direto com a Pluggy. A API própria normaliza os dados para que o sistema não fique preso a uma única fonte.
2. **Baixa latência.** Notificação do pagamento sugere o registro imediato; webhooks em vez de polling.
3. **Usuário valida o que a máquina não sabe.** Registros incompletos ou de baixa confiança vão para uma tabela temporária e esperam validação.
4. **Aprendizado de classificação.** Na primeira vez o usuário classifica; o app memoriza e passa a classificar sozinho pelo mapeamento salvo. Um modelo com índice de confiança (≥ 90 automático, abaixo disso validação) fica para uma versão futura, ainda não decidida.

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
   • confiança < 90 (versão futura)
        │
        ▼
 Usuário valida/completa ──▶ tabela central
```

---

## 4. Integração externa: Pluggy

> **Status:** pesquisa na documentação pública ([docs.pluggy.ai](http://docs.pluggy.ai)) e prova de conceito no sandbox concluída em 31/10/2026 (ver 4.6). Testes com dados reais em 07/11/2026: conta PicPay (ver 4.7) e cartão Itaú (ver 4.8). Ainda faltam observar um fechamento de fatura, medir a latência do webhook e anotar limites e custos (4.5).

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

1. **Data de fechamento.** Em jul/2026 a Pluggy adicionou `billClosingDate` e `billForecastDate` em transações e faturas de cartão. Só vêm em conexões criadas depois da implementação, e `billClosingDate` pode ser nulo. **Dados reais (Itaú):** `billClosingDate` vem na fatura e não na transação; a transação traz `billForecastDate` (ver 4.8).
2. **ID instável em cartão.** Reajustes perto do fechamento podem chegar como *delete + create* com novo `id`. Recomendação da Pluggy: reconciliar por data + valor + descrição (ou `providerId`, só em Open Finance).
3. **Webhook de exclusão** (`transactions/deleted`) traz apenas IDs; processar de forma idempotente.
4. **Parcelas.** A 1ª parcela vem com a data original da compra; as seguintes são re-datadas para o ciclo da fatura. `creditCardMetadata.purchaseDate` guarda a data original. **Dados reais (Itaú):** não se confirmou. As parcelas lançadas mantêm a data da compra, e as futuras vêm `PENDING` com data no ciclo; usar `billForecastDate` para saber a fatura (ver 4.8).
5. **Transações com data futura** não são necessariamente erro.
6. **Status `PENDING`** para compras ainda não incluídas em fatura fechada.
7. **Sinal normalizado.** Compras de cartão são DEBIT; pagamento de fatura é CREDIT (`PAGAMENTO_FATURA`). Precisa ser filtrado para não duplicar consumo. **Dados reais (Itaú):** compra = `DEBIT` com `amount` positivo e pagamento = `CREDIT` com `amount` negativo, ao contrário da conta corrente; tratar por tipo de conta (ver 4.8).
8. **Categoria da Pluggy** (campo `category`) pode servir de sinal de entrada para o classificador próprio.
9. **Histórico inicial** de cerca de 12 meses ao conectar.
10. **Limites de chamadas.** Listagem de faturas ~30/mês; usar webhooks.

### 4.4 Respostas parciais às dúvidas do backlog

- **Data de fechamento via API?** Sim, na fatura (`bills`), confirmado com o Itaú (4.8).
- **Vários cartões?** Cada cartão é uma account; a transação traz `cardNumber` em `creditCardMetadata` com os 4 últimos dígitos, e distingue o adicional (4.8).

### 4.5 Checklist de testes 🧪

- [x] Criar item e listar accounts (cartão e conta corrente): feito no sandbox em 31/10/2026, ver 4.6
- [x] Ver se `billClosingDate` / `billForecastDate` vêm preenchidos nos seus bancos: no Itaú, `billClosingDate` vem na **fatura** (`bills`), não na transação; `billForecastDate` vem na transação (ver 4.8)
- [x] Comparar data da 1ª parcela com as seguintes numa compra parcelada: no Itaú, parcelas lançadas mantêm a data da compra; parcelas futuras vêm PENDING com data futura (ver 4.8)
- [ ] Observar um fechamento de fatura (delete + create?)
- [x] Ver o formato de `cardNumber`: 4 últimos dígitos, por transação, e distingue o cartão adicional (ver 4.8)
- [x] Verificar se PIX recebidos têm tipo identificável (renda/superávit): sim como PIX recebido, não como renda (ver 4.7)
- [ ] Medir latência entre pagamento e webhook
- [x] Avaliar utilidade da categoria da Pluggy: útil como sinal, com erros (ver 4.7)
- [x] Verificar se o plano gratuito expõe o CNPJ de quem recebe pagamentos (Pix, boleto), para reconhecer pagamento de fatura (DP-14): sim (ver 4.7)
- [ ] Anotar limites de chamadas e custos do plano

### 4.6 Prova de conceito no sandbox (31/10/2026)

Protótipo descartável em Python (Flask + `pluggy_sdk`) e uma página HTML com o widget Pluggy Connect. Fluxo validado de ponta a ponta com o conector **Pluggy Bank** (sandbox): gerar token, conectar, listar contas e transações. Dados do sandbox são fictícios e não substituem o teste com dados reais.

#### Fluxo de autenticação

1. O backend chama `auth_create` com `CLIENT_ID` e `CLIENT_SECRET` e recebe uma **API key** temporária (cerca de 2 h). Ela não é guardada no `.env`; é gerada a cada uso.
2. Com a API key (header `X-API-KEY`), o backend chama `connect_token_create` e devolve o `accessToken` ao front.
3. O front abre o widget com esse token. O token é de vida curta (poucos minutos), então deve ser gerado a cada clique.
4. No `onSuccess` o widget entrega o `item.id`. O backend usa esse ID para listar contas e transações.

O app nunca deve receber as credenciais: só o backend as conhece (princípio 3.4.1).

#### Armadilhas encontradas

| Problema | Causa | Solução |
| --- | --- | --- |
| 403 `API_KEY_MISSING_OR_INVALID` ao gerar o connect token | No `pluggy_sdk`, a API key precisa ser registrada com o nome `'default'` em `Configuration(api_key=...)`. Com outro nome (ex.: `ApiKeyAuth`) o header não é enviado | `api_key={'default': auth_response.api_key}` |
| 410 `ENDPOINT_DEPRECATED` ao listar transações | `GET /transactions` foi descontinuado | Usar `GET /v2/transactions` com paginação por cursor (`transactions_list_by_cursor`; parâmetros `date_from`, `date_to`, `created_at_from`, `after`) |
| Widget não carrega (script 404) | URL antiga do script do Pluggy Connect | Usar `https://cdn.pluggy.ai/pluggy-connect/v2.8.2/pluggy-connect.js` (fixar a versão) |
| Página chamando a API local falha | Origem diferente (CORS) | Liberar CORS no backend de teste; em produção, restringir à origem do app |
| Botão "Autorizar" desabilitado no MeuPluggy | A conta no MeuPluggy não tinha nenhum banco conectado ("Nenhuma conta disponível para compartilhar") | Conectar um banco em [meu.pluggy.ai](http://meu.pluggy.ai) antes, ou usar o Pluggy Bank no sandbox |

Os erros `ERR_BLOCKED_BY_CLIENT` de `posthog` no console são só analytics bloqueado pelo navegador e podem ser ignorados.

#### Sandbox x dados reais

- `includeSandbox: true` no widget habilita os bancos de teste. O **MeuPluggy não é um banco de teste**: usa Open Finance real e depende de contas já conectadas nele.
- Credenciais do Pluggy Bank: usuário `user-ok`, senha `password-ok`, código MFA `123456`.
- O sandbox retorna uma conta corrente (BANK / CHECKING_ACCOUNT) e um cartão (CREDIT / CREDIT_CARD) no mesmo item, com cerca de 12 meses de transações.

#### Observações sobre os dados retornados (sandbox)

- No cartão, as compras vieram com `type = CREDIT` e `amount` **negativo**. Isso diverge do item 7 de 4.3 (compras de cartão como DEBIT). Para somar gastos, tratar o **sinal do `amount`** e confirmar o comportamento com dados reais antes de fixar a regra.
- `creditCardMetadata` apareceu em apenas uma transação (parcelada: `installmentNumber`, `totalInstallments`, `totalAmount`, `billId`, `billForecastDate`, `paymentType`). Não vieram `cardNumber` nem `purchaseDate` nesse exemplo; o formato do cartão segue em aberto 🧪.
- O objeto da conta de cartão trouxe `creditData` (`balanceCloseDate`, `balanceDueDate`, `creditLimit`, `availableCreditLimit`, `minimumPayment`). `balanceCloseDate` é uma fonte candidata para a data de fechamento da fatura (DP aberta no backlog) 🧪.
- `paymentData` (pagador, recebedor, boleto) veio só no pagamento de boleto; nas demais transações é nulo. Relevante para reconhecer o recebedor no pagamento de fatura (DP-14), mas só se confirma com dados reais.
- Muitos campos opcionais chegam como `null` (`descriptionRaw`, `providerCode`, `operationType`, `providerId`). O modelo deve tolerar ausência.

#### Acesso à produção (dados reais)

Painel da Pluggy: "Solicitar acesso à produção" tem 3 etapas. Em 31/10/2026: personalizar a aplicação ✅, conectar item demo ✅, **registrar webhooks** pendente. O webhook exige um endpoint **não localhost** cobrindo `item/created`, `item/updated`, `transactions/created`, `transactions/updated` e `transactions/deleted` (ou o evento `all`). Em desenvolvimento, um túnel (ngrok, Cloudflare Tunnel) resolve.

O pedido "Testar com dados reais" está **em análise** (solicitado há semanas). A due diligence é voltada a empresas; como o escopo é pessoal, confirmar com o suporte da Pluggy o que se aplica. Alternativa para uso pessoal: conectar o banco em [meu.pluggy.ai](http://meu.pluggy.ai) e usar o MeuPluggy.

#### Próximos passos

- Implementar o webhook (idempotente, com `transactions/deleted` trazendo só IDs) e expô-lo por túnel.
- Paginar transações pelo cursor (`next` / `after`); o protótipo lê só a 1ª página (20 itens).
- Repetir o checklist 4.5 com dados reais assim que o acesso for liberado.

### 4.7 Teste com dados reais (07/11/2026)

Conexão real pelo widget (PicPay via Open Finance), no mesmo protótipo, agora com paginação pelo cursor e uma rota de faturas (`bills_list`). Vieram uma conta corrente (BANK / CHECKING_ACCOUNT) e um cartão (CREDIT / CREDIT_CARD).

#### Conta corrente

- **773 transações** de 08/11/2025 a 06/11/2026: confirma o histórico de cerca de 12 meses. A paginação pelo cursor funciona (`next` traz a query string; extrair o `after` e repassar).
- **Sinal do valor:** gasto = `DEBIT` com `amount` negativo; entrada = `CREDIT` com `amount` positivo.
- **Campos preenchidos em todas as linhas:** `providerId`, `descriptionRaw`, `operationType`, `category`, `paymentData`. Diferente do sandbox, onde vinham nulos. O `providerId` serve para reconciliar (4.3.2).
- `operationType` só teve dois valores: `PIX` (340) e `OUTROS` (433).
- **CNPJ de quem recebe (DP-14):** todo PIX enviado a empresa traz `paymentData.receiver.documentNumber` (tipo CNPJ) e o objeto `merchant` (`businessName`, `cnpj`, `cnae`, `category`). Para pessoa física vem CPF, sem `merchant`.
- **Pagamento de fatura:** 6 lançamentos "Pagamento de fatura PicPay Card" (dez/2025 a abr/2026), `DEBIT`, `operationType = OUTROS`, `paymentMethod = OTHER`, **sem `receiver`**, mas com `merchant.cnpj` = CNPJ do PicPay (22.896.431/0001-10). Categoria Pluggy: Transfers. Ou seja, o reconhecimento por CNPJ precisa olhar `merchant.cnpj` além de `paymentData.receiver`.
- **PIX recebidos:** 77, com `operationType = PIX` e `type = CREDIT`. `operationTypeAdditionalInfo` traz "Recebimento via PIX" (32), "Devolução de recebimento via PIX" (1) ou vem nulo (44). Não há distinção entre renda e outros recebimentos.
- **Movimentos internos do PicPay:** "Aporte na carteira Cofrinho", "Resgate na carteira Cofrinho" e "Troco Guardado" somam **416 das 773 linhas**, com `operationType = OUTROS` e sem recebedor. Não são gasto nem renda, e o resgate costuma cobrir um gasto logo em seguida. Ver o DP-38 em [05_decisoes.md](05_decisoes.md).
- **Categoria da Pluggy:** boa em parte dos casos (Food delivery, Pharmacy, Telecommunications, Groceries), com erros (pagamentos ao SESC caíram em Healthcare). Serve como sinal de entrada do classificador, não como categoria final.

#### Cartão

- **Nenhuma transação** e **nenhuma fatura** (`bills_list` vazio) no período, apesar dos pagamentos de fatura na conta até abr/2026. `balanceCloseDate`, `balanceDueDate` e `minimumPayment` nulos.
- `creditData` traz limite, bandeira, nível, `status = ACTIVE`, `disaggregatedCreditLimits` e `additionalCards` (só os 4 últimos dígitos).
- Data de fechamento, parcelas e `cardNumber` seguem sem teste 🧪: precisa de um cartão com compras recentes.
- **Motivo:** o PicPay Card quase não é usado. O PicPay serve quase só para PIX; o cartão de crédito do dia a dia é do **Itaú**. Os testes de cartão do 4.5 serão feitos conectando o Itaú.

#### Pagamento da fatura do Itaú visto pela conta PicPay

- 12 pagamentos mensais (dez/2025 a out/2026), todos ao CNPJ **60.872.504/0001-23** (Itaú Unibanco Holding S.A.), em `paymentData.receiver` e em `merchant.cnpj`.
- Dois formatos: "Pagamento de boleto" (`operationType = OUTROS`, categoria Transfer - Bank Slip) até jun/2026 e "PIX ENVIADO ITAU UNIBANCO..." (`operationType = PIX`, categoria Transfers) depois. Em nenhum deles a descrição diz "fatura".
- Ao contrário do PicPay Card, aqui o CNPJ do recebedor é o do emissor do cartão, e não o da instituição da conta. A regra do DP-14 (CNPJ do emissor de um cartão cadastrado) funciona, mas outros pagamentos ao Itaú (empréstimo, boleto de outro produto) cairiam nela. Para confirmar que é fatura, cruzar valor e data com a fatura do Itaú quando ela vier pela API.
- Buscas por texto ("ita") dão falso positivo em nomes de pessoas; usar o CNPJ.

#### Próximos passos

- Conectar um cartão com uso recente para fechar os itens de cartão do 4.5 (feito no Itaú, ver 4.8).
- Webhook por túnel, para medir a latência.

### 4.8 Teste com dados reais: cartão Itaú (07/11/2026)

Conexão real do Itaú pelo widget. Vieram uma poupança (BANK / SAVINGS_ACCOUNT, quase sem movimento) e o cartão (CREDIT / CREDIT_CARD, Mastercard Platinum) com **81 transações** de 04/12/2025 a 25/09/2027 (14 com data futura) e **12 faturas**.

#### Fatura e data de fechamento

- `bills_list` trouxe 12 faturas com `dueDate`, **`billClosingDate`**, `totalAmount`, `minimumPaymentAmount`, `allowsInstallments` e `payments`.
- **A data de fechamento existe, mas na fatura.** Nas transações, `billClosingDate` nunca veio; vem `billForecastDate` (mês da fatura, ex.: 2026-11) e `billPostDate`. Na conta, `balanceCloseDate` veio nulo e `balanceDueDate` preenchido.
- Fechamento entre os dias 26 e 29 e vencimento entre os dias 5 e 8. O dia varia mês a mês, então não dá para fixar um dia no cadastro: guardar a data de cada fatura (DP-28).
- `billId` veio em 65 das 81 transações, e todos batem com uma fatura listada. As 16 sem `billId` são as `PENDING` (ainda sem fatura fechada).
- `payments` da fatura traz data, valor e `paymentMode`. Veio `BANK_SLIP` mesmo em fatura paga por PIX, então o modo não é confiável.

#### Sinal do valor

- No cartão Itaú: compra = `DEBIT` com `amount` **positivo**; pagamento de fatura = `CREDIT` com `amount` **negativo** ("Pagamento PIX", "Pagamento recebido"). É o oposto da conta corrente e do sandbox. A regra de soma precisa olhar o tipo da conta (BANK x CREDIT) junto com `type`, e não só o sinal.

#### Parcelas

- 59 transações parceladas em 13 compras. `creditCardMetadata` traz `installmentNumber`, `totalInstallments`, `purchaseDate` e `paymentType` (`INSTALLMENT` ou `SINGLE`). `totalAmount` veio 0, então o total tem que ser calculado.
- **Diverge do item 4.3.4:** no Itaú, as parcelas já lançadas (`POSTED`) mantêm a **data da compra**, e não são re-datadas para o ciclo. O que indica a fatura de cada parcela é o `billForecastDate`.
- As parcelas futuras já vêm todas, como `PENDING`, com data futura no ciclo e sem `billId`. Ex.: compra em 19x de mar/2026 trouxe as 19 parcelas, da 9ª à 19ª até set/2027. Isso alimenta direto a visão faturada de meses futuros (DP-9).
- A descrição traz o número da parcela colado ("...01/09"). Para agrupar a compra, usar `purchaseDate` + `totalInstallments` + valor, não a descrição.

#### Cartão e titularidade

- `cardNumber` vem por transação com os 4 últimos dígitos e distingue o titular (9827) do adicional (7346). Só os pagamentos de fatura vêm sem `cardNumber`. Viabiliza o E04-F03 (cartão não cadastrado).
- `merchant` veio em só 10 das 81 transações do cartão; `payeeMCC` veio em 65, e pode ajudar a classificar.

#### Reconciliação com a conta PicPay

- Os pagamentos da fatura batem nas três pontas, ao centavo: PIX ou boleto saído do PicPay para o CNPJ do Itaú (4.7), `CREDIT` "Pagamento PIX" no cartão e `totalAmount` da fatura. Ex.: fatura com vencimento em 05/11/2026, total 1.063,83, paga em 29/10.
- Com isso, o DP-14 fica fechado tecnicamente: pagamento à vista ao CNPJ do emissor + valor igual ao total de uma fatura em aberto = pagamento de fatura, sem somar no consumo.

#### Pendente

- Observar um fechamento de fatura (*delete + create* nas parcelas `PENDING`?).
- Webhook e latência.

---

## 5. Fontes

- docs.pluggy.ai: Credit Card Installments, Credit card transactions and the statement cycle, Transaction, Credit Card Bills, Changelog

---

## Outras páginas do projeto

- **Esquema — Data Warehouse:** [06_data_warehouse.md](06_data_warehouse.md) (Modelagem dados + Backlog pipelines)
- **Pipelines DW_APOLO:** [04_plano_desenvolvimento_v1.md](04_plano_desenvolvimento_v1.md) (no Notion, o Plano de desenvolvimento — v1 fica sob este título) · projeto irmão [07_dw_apolo.md](07_dw_apolo.md)
