# Ravix

> Gerenciador de gastos pessoais com fluxo de caixa detalhado e baixa latência.

![Status](https://img.shields.io/badge/status-modelagem-yellow)
![Flutter](https://img.shields.io/badge/Flutter-Dart-02569B?logo=flutter)
![Plataforma](https://img.shields.io/badge/plataforma-Android-3DDC84?logo=android)

## Sobre o projeto

O **Ravix** é um aplicativo Android, feito em Flutter/Dart, para acompanhar o fluxo de caixa pessoal com mais detalhe e com o mínimo de atrito no registro dos gastos.

A ideia central é dar ao usuário o "caminho do dinheiro" ao longo do mês: quanto da renda já foi consumido, em quê, com qual forma de pagamento e quanto ainda está comprometido nas faturas do cartão de crédito.

## Objetivo

Alcançar o próximo nível de maturidade em gestão financeira pessoal, acompanhando o fluxo de caixa de forma detalhada e com baixa latência, ou seja, com o registro de cada gasto acontecendo o mais próximo possível do momento em que ele ocorre.

## Por que "Ravix"?

O nome é uma amálgama de duas palavras do latim:

- **Ratio**: do verbo *reri* ("calcular", "considerar", "julgar"). Para os romanos, carregava a ideia de uma maneira ordenada de pensar ou calcular algo.
- **Vindex**: do verbo *vindicare* ("reivindicar", "defender um direito"). Significa defensor, protetor, aquele que faz valer um direito.

Juntos, transmitem algo como **"razão e defesa"**, **"raciocínio e proteção"** ou **"aquele que, pela razão, defende algo"**: gerir o dinheiro com método para proteger o patrimônio.

## Funcionalidades

### Visões na tela inicial

| Visão | O que mostra |
|---|---|
| **Macro** | Consumo real do mês (faturado + à vista), timeline, filtro por forma de pagamento e farol de consumo da renda (verde, amarelo, vermelho) |
| **Faturada** | Valor da fatura atual, timeline das faturas vigentes, indicador de consumo do limite e lista de parcelas |
| **À vista** | Acumulado do mês por categoria/subcategoria e percentual de "queima" da renda |

### Registro de gastos

- **Gastos faturados** (cartão de crédito): descrição, valor total, parcelas, mês/ano de exercício da fatura, importância (1 a 5), categoria e subcategoria.
- **Gastos à vista**: valor, forma de pagamento (Pix, débito, dinheiro, voucher), importância, categoria e subcategoria.
- **Renda**: salário e voucher (benefícios).
- **Registros não classificados**: fila de registros que precisam de intervenção do usuário (categoria desconhecida, cartão não cadastrado etc.).
- **Leitura de QR code e código de barras** pela câmera, e **login com biometria**.

### Captura automática

- **Notificações de pagamento**: o app reconhece notificações do Android, extrai data, hora e valor, pré-preenche o formulário e pede a validação do usuário antes de gravar.
- **Open Finance via Pluggy**: importação automática das transações (detalhada abaixo).

## Como e por que o Ravix usa a API da Pluggy

### O problema

Registrar manualmente cada gasto é trabalhoso, e quem desiste de registrar perde o controle do fluxo de caixa. As notificações de pagamento ajudam, mas dependem de cada banco, trazem informação parcial e não cobrem todos os casos. Para ter uma visão fiel e com baixa latência, o app precisa acessar os dados diretamente na fonte: as contas bancárias e cartões do usuário.

### A solução: Pluggy

A [Pluggy](https://www.pluggy.ai/) é uma infraestrutura de **Open Finance para o Brasil**. Ela conecta as contas bancárias do usuário (com o consentimento dele) e entrega os dados de forma **centralizada e normalizada** por uma única API.

**Por que a Pluggy:**

- **Uma integração, vários bancos.** Sem ela, seria preciso lidar com o formato e as particularidades de cada instituição.
- **Dados normalizados.** Transações, contas e cartões chegam em um formato único, o que simplifica a ingestão no pipeline.
- **Menos digitação.** As transações chegam prontas, reduzindo o registro manual a uma validação.
- **Baixa latência.** Os gastos entram no app logo após acontecerem, sem depender de o usuário lembrar de registrá-los.

### Como a integração funciona

1. **Conexão**: o usuário autoriza o acesso às suas contas via Pluggy (Open Finance).
2. **Camada própria de API**: o Ravix não consome a Pluggy diretamente. Uma **API própria** fica no meio e traduz os dados da Pluggy para o modelo interno. Isso evita ficar preso a uma única fonte de dados: se a Pluggy mudar ou for substituída, só o adaptador muda.
3. **Ingestão e tabela temporária**: as transações entram em uma tabela temporária. O que já vem completo segue adiante; o que precisa de intervenção fica pendente (cartão não cadastrado, categoria desconhecida, importância).
4. **Classificação automática**: o sistema encaixa cada transação em categoria e subcategoria.
   - Na primeira vez que aparece um estabelecimento ou padrão desconhecido, o app **pergunta ao usuário** como classificar e guarda a resposta em uma tabela fixa de mapeamento. Nas próximas ocorrências, classifica sozinho.
   - Um **modelo de classificação** calcula um índice de confiança: acima de **90** o registro é classificado automaticamente; abaixo disso, vai para validação do usuário.
5. **Carga**: após validado, o registro vai para o banco transacional e, na sequência, para o Data Warehouse.

### Dados que a Pluggy ajuda a resolver

- **Registro de compras à vista e no cartão**, com valor, data e descrição.
- **Entradas (Pix e salário)**: permitem calcular o superávit do mês com mais exatidão. Como uma entrada pode ser salário ou ganho extra, ela também precisa ser classificada.
- **Mês de exercício da fatura**: hoje esse campo é manual, porque a data de fechamento varia por cartão. Está em investigação se a Pluggy consegue fornecer a data de fechamento para preencher o mês vigente corretamente.

> **Observação:** a integração com a Pluggy está planejada (épico E4) e o projeto ainda está na fase de modelagem. Os detalhes acima descrevem a arquitetura pretendida e podem mudar ao longo da implementação.

## Arquitetura de dados

```
App (SQLite local) ──► API própria ◄── Pluggy (Open Finance)
        │                   │
        ▼                   ▼
   Banco transacional ──► Data Warehouse (analítico)
```

- **SQLite interno**: armazena temporariamente os registros no app antes da carga.
- **Banco transacional**: atende às demandas do app com foco em performance.
- **Data Warehouse**: expande o escopo para o contexto analítico e alimenta o painel.

### Principais tabelas

| Tabela | Descrição |
|---|---|
| `tbl_usuario` | Dados do usuário |
| `tbl_compra_avista` | Gastos à vista (Pix, débito, dinheiro, voucher) |
| `tbl_compra_faturada` | Compras no crédito, com parcelas e mês de exercício |
| `tbl_compra_faturada_temp` | Registros faturados pendentes de validação |
| `tbl_renda` | Salário e voucher |
| `tbl_cartoes_credito` | Cartões e limites |

## Stack e ambiente

- **Linguagem/framework:** Dart com Flutter
- **Editor:** Android Studio
- **Sistema de desenvolvimento:** Linux (Fedora)
- **Recursos Android:** câmera (QR code e código de barras), leitor biométrico, captura de notificações

## Roadmap

- [ ] **E01 Front-end**: telas inicial, formulários, visão macro e login
- [ ] **E02 Modelo de dados**: Data Warehouse, banco transacional e SQLite interno
- [ ] **E03 Captura de notificações**: reconhecimento e extração de dados de pagamentos
- [ ] **E04 Integração Pluggy**: ingestão automática e classificação

### Questões em aberto

- Armazenar categorias por texto ou apenas por ID? Qual a melhor estrutura para cadastrar novas categorias?
- Importância (1 a 5): guardar o número e exibir o nome, ou usar só o número?
- Como tratar faturas de cartões diferentes?
- Faz sentido ter tabela de usuário no app local, já que só um usuário fica logado por vez?

## Status

✅ **v1 concluída** (M0 a M7): app local de gastos à vista, com tags, bloqueio pelo PIN do aparelho e tema CAPRA.

## Desenvolvimento

Plano de implementação em [`../docs/04_plano_desenvolvimento_v1.md`](../docs/04_plano_desenvolvimento_v1.md). Requisitos: Flutter stable (3.47.8 ou mais novo) e Android SDK.

| Comando | O que faz |
| --- | --- |
| `make get` | `flutter pub get` |
| `make gen` | Gera o código do drift e do riverpod (`*.g.dart`) |
| `make watch` | Gera o código a cada alteração |
| `make analyze` | `flutter analyze` (lint `very_good_analysis`) |
| `make test` | Testes unitários e de widget |
| `make coverage` | Testes com relatório HTML em `coverage/html` (precisa do `lcov`) |
| `make check` | O mesmo que o CI: get, gen, analyze e testes com cobertura |
| `dart run tool/gerar_tokens.dart` | Gera `lib/core/tema/capra_tokens.dart` a partir de `docs/identidade_visual/capra-tokens.json` |
| `bash tool/gerar_icones.sh` | Gera ícone, abertura e marca do app a partir dos SVGs da marca (precisa do ImageMagick com librsvg) |

### No aparelho

Os testes no aparelho usam banco próprio (em memória ou em arquivo separado) e não tocam nos dados do app de uso. Compile só para a arquitetura do aparelho (arm64): o APK de debug com todas fica com mais de 160 MB.

```bash
# Ponta a ponta (desbloquear → criar → filtrar → editar → excluir; tags)
flutter build apk --debug --target-platform android-arm64 -t integration_test/ponta_a_ponta_test.dart
flutter drive --use-application-binary build/app/outputs/flutter-apk/app-debug.apk \
  --driver test_driver/integration_test.dart --target integration_test/ponta_a_ponta_test.dart -d <aparelho>

# Desempenho (DP-36) com 20 mil gastos, em modo profile
flutter build apk --profile --target-platform android-arm64 -t integration_test/desempenho_test.dart
flutter drive --profile --use-application-binary build/app/outputs/flutter-apk/app-profile.apk \
  --driver test_driver/integration_test.dart --target integration_test/desempenho_test.dart -d <aparelho>
```

Debug e profile instalam como `com.cintriano.ravix.debug` e `.profile` ("Ravix (debug)" e "Ravix (profile)") e convivem com o app de uso.

### Release

A chave fica fora do repositório, em `~/.android/ravix-release.jks`, e a senha em `android/key.properties` (ignorado pelo Git). **Guarde os dois num cofre de senhas**: sem a chave, não dá para instalar atualizações por cima do app.

```bash
flutter build apk --release --target-platform android-arm64
adb install -r build/app/outputs/flutter-apk/app-release.apk
```

Sem o `key.properties` (como no CI), o release é assinado com a chave de debug.

Estrutura: `lib/core` (funções puras), `lib/data` (banco e repositórios), `lib/features/<feature>` (telas e providers). A pasta `test/` espelha `lib/`; os testes ponta a ponta ficam em `integration_test/`.

### Commits

[Conventional Commits](https://www.conventionalcommits.org/pt-br/v1.0.0/), com o módulo ou a task do backlog no escopo quando houver:

```text
feat(m2): repositório de compras à vista
fix(E01-F03-T03): máscara monetária aceitava zero
test(core): datas na virada de ano
chore: atualiza dependências
```

Tipos: `feat`, `fix`, `test`, `refactor`, `docs`, `chore`, `ci`, `build`, `perf`.
