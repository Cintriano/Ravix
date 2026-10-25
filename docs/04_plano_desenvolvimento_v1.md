# Ravix — Plano de desenvolvimento — v1

> Exportado do Notion (Projetos / Ravix / Plano de desenvolvimento — v1) em 24/10/2026.
> Fonte: https://app.notion.com/p/401b044db6b1812db9bbc1917c0f7835

> Plano de implementação da v1 do Ravix, a partir do [Backlog app](02_backlog.md) (E01 e E02-F01) e da [modelagem banco](03_modelo_de_dados.md). Stack, regra da sugestão e metas de desempenho: DP-36 em [Decisões pendentes](05_decisoes.md).

> **Regra geral:** nenhum módulo está pronto sem os testes automatizados dele passando no CI. Cada módulo fecha com `flutter analyze` e `flutter test` verdes.

---

## Visão geral

| Módulo | Entrega | Depende de | Backlog |
| --- | --- | --- | --- |
| M0 · Ambiente ✅ | Fedora pronto, projeto criado, rodando no aparelho, CI verde | — | — |
| M1 · Core ✅ | Utilitários de texto, valor, data e IDs | M0 | E01-F03-T02, T03 |
| M2 · Dados ✅ | Banco drift, carga inicial, consultas e repositórios | M1 | E02-F01, E01-F03-T10 |
| M3 · Shell e bloqueio ✅ | Navegação, seletor de mês, estados de tela, PIN do aparelho | M2 | E01-F01-T07, E01-F02 |
| M4 · Tags ✅ | Configuração > aba Tags | M3 | E01-F07-T09, T10 |
| M5 · Formulário ✅ | Criar, editar e excluir gasto, sugestão, tag inline | M4 | E01-F03 |
| M6 · Aba à vista ✅ | Acumulado, tabela do mês e filtros | M5 | E01-F04 |
| M7 · Desempenho e release | Massa de teste, metas, teste ponta a ponta, build de release | M6 | DP-36 |

Os módulos são sequenciais: cada um usa o anterior. As telas (M3 a M6) só começam com o banco testado.

---

## Estratégia de testes

| Camada | Ferramenta | Onde roda |
| --- | --- | --- |
| Unitário (core, providers) | `flutter_test`, `mocktail` | Fedora e CI |
| Banco | drift com `NativeDatabase.memory()` | Fedora e CI (SQLite embutido pelo `sqlite3` 3.x) |
| Widget | `flutter_test` com repositórios falsos | Fedora e CI |
| Integração ponta a ponta | `integration_test` | Aparelho ou emulador |

- **Determinismo:** relógio, gerador de UUID, fuso e autenticação entram por interfaces injetáveis. Os testes usam versões falsas e nunca dependem da hora real nem do PIN do aparelho.
- **Cobertura mínima:** 90% no core, 80% em dados e providers. As telas são cobertas pelos fluxos principais nos testes de widget.
- **Migrações:** o schema 1 é exportado com o `drift_dev` no M2, para que toda migração futura tenha teste automático contra ele.
- **Estrutura:** a pasta `test/` espelha `lib/`; os testes ponta a ponta ficam em `integration_test/`.

---

## M0 · Ambiente de desenvolvimento

**Objetivo:** máquina Fedora pronta, projeto criado e pipeline de testes funcionando antes da primeira tela.

**Ferramentas**

- [x] Instalar o Flutter SDK (canal stable) e colocar no `PATH`; o Dart vem junto
- [x] Android Studio com os plugins Flutter e Dart
- [x] No SDK Manager: Android SDK, Platform-Tools, Command-line Tools e Build-Tools
- [x] `flutter doctor --android-licenses` e `flutter doctor` sem erros na parte Android
- [x] ~~Dependências de teste no Fedora: `sudo dnf install sqlite-devel lcov`~~ Só o `lcov` (relatório HTML de cobertura). O `sqlite3` 3.x embute o SQLite via hooks, então a `libsqlite3` do sistema não é mais necessária

**Aparelho**

- [x] Aparelho físico com depuração sem fio (`adb pair`), para o dia a dia
- [x] Emulador (AVD) como alternativa: conferir o acesso ao KVM (`ls -l /dev/kvm`) e, se precisar, adicionar o usuário ao grupo `kvm`

**Projeto**

- [x] `flutter create --org com.seudominio --platforms android ravix`, trocando `com.seudominio` pelo seu domínio reverso
- [x] Repositório git com o `.gitignore` do Flutter e uma convenção de commits
- [x] Dependências: `drift`, ~~`sqlite3_flutter_libs`~~ (obsoleto com o `sqlite3` 3.x), `flutter_riverpod`, `riverpod_annotation`, `go_router`, `local_auth`, `uuid`, `intl`, `path_provider`, `path`
- [x] Dependências de desenvolvimento: `drift_dev`, `riverpod_generator`, `build_runner`, `mocktail`, `integration_test` (do SDK) e o pacote de lint
- [x] Escolher o lint (`flutter_lints` ou `very_good_analysis`) e configurar o `analysis_options.yaml`
- [x] Estrutura de pastas: `lib/core`, `lib/data`, `lib/features/shell`, `lib/features/compra_avista`, `lib/features/tags`, com `test/` espelhando
- [x] `MainActivity` estendendo `FlutterFragmentActivity` (exigência do `local_auth`) e `minSdk` conferido na documentação do pacote
- [x] Atalhos (Makefile ou script) para gerar código, testar e gerar cobertura
- [x] CI (GitHub Actions ou equivalente): `pub get`, `build_runner`, `flutter analyze`, `flutter test --coverage`

**Testes automatizados**

- [x] Smoke test de widget: o app sobe e mostra a tela inicial
- [x] CI falha se o `analyze` ou algum teste falhar (validar forçando uma falha uma vez)

**Concluído em 24/10/2026:** Flutter 3.47.8, app `com.cintriano.ravix` rodando no Galaxy S23 Ultra (Android 16), lint `very_good_analysis`, CI no GitHub Actions verde e validado com uma falha proposital.

**Pronto quando:** `flutter doctor` sem erros na parte Android, app de exemplo rodando no aparelho e CI verde com o smoke test.

---

## M1 · Core

**Objetivo:** funções puras usadas pelo app inteiro, sem tela nem banco.

**Tarefas**

- [x] Normalização de texto: minúsculas, sem acento, espaços colapsados, sem `%` e `_` (base da `descricao_normalizada` e da busca)
- [x] Valor: digitação → centavos (`int`) e centavos → "R$ 1.234,56" com `intl` em pt_BR
- [x] Datas: data local em ISO (`YYYY-MM-DDTHH:MM:SS`), auditoria em UTC com `Z`, `fuso_minutos` do aparelho e intervalo de um mês (início inclusivo, fim exclusivo)
- [x] Interfaces injetáveis: relógio, gerador de UUID v4 e fuso

**Testes automatizados**

- [x] Normalização: "Açaí", "  PADARIA   do Zé ", texto com `%` e `_`, texto vazio
- [x] Valor: zero, 1 centavo, milhares, entradas inválidas rejeitadas, ida e volta centavos ↔ texto
- [x] Datas: virada de mês, dezembro → janeiro, fevereiro de ano bissexto, fusos −180 e +540, UTC sempre com `Z`

**Concluído em 24/10/2026:** `lib/core/` com `texto.dart`, `valor.dart`, `datas.dart` (inclui `Mes` e `instanteUtc`) e `ambiente.dart` (relógio, UUID e fuso); versões falsas em `test/helpers/ambiente_falso.dart`. 32 testes, cobertura de 100% no core.

**Pronto quando:** testes verdes e cobertura de 90% ou mais no core.

---

## M2 · Dados

**Objetivo:** o banco da v1 exatamente como na modelagem, com consultas e repositórios.

**Tarefas**

- [x] Arquivo `.drift` com o DDL da modelagem: 4 tabelas, `CHECK`s, FKs, índices, `descricao_normalizada` e `fuso_minutos`
- [x] Abertura em isolate separado (`NativeDatabase.createInBackground`)
- [x] PRAGMAs na abertura: `journal_mode = WAL`, `synchronous = NORMAL`, `foreign_keys = ON`
- [x] `schemaVersion = 1` e carga inicial (8 categorias, 34 subcategorias) só no `onCreate`
- [x] Consultas nomeadas: acumulado do mês, tabela do mês com filtros, sugestão pela descrição, tags ativas, registros por tag
- [x] `CompraAvistaRepository`: criar, editar, excluir, observar o mês, sugerir subcategoria
- [x] `TagRepository`: criar, renomear, remover (exclui sem registros, arquiva com registros)
- [x] `CategoriaRepository`: listar em ordem alfabética, com Diversos por último
- [x] Os repositórios preenchem `criado_em`/`atualizado_em` (UTC), `descricao_normalizada` e `fuso_minutos`; as telas nunca preenchem esses campos
- [x] Exportar o schema 1 com o `drift_dev`

**Testes automatizados** (banco em memória)

- [x] Schema: 4 tabelas criadas; carga com 8 categorias e 34 subcategorias, sem o ID 403
- [x] Constraints: rejeita valor ≤ 0, descrição vazia, forma de pagamento inválida, subcategoria incoerente com a categoria e fuso fora da faixa
- [x] FK: excluir tag com registro falha no banco; remover pelo repositório arquiva
- [x] Tag: nome repetido com maiúsculas diferentes é rejeitado; renomear não altera os registros
- [x] Mês: registro em 31/10 23:59:59 entra em outubro; 01/11 00:00:00 não
- [x] Filtros: categoria, subcategoria e tag, isolados e combinados; acumulado ignora os filtros
- [x] Sugestão: "contém", acentos ("acai" encontra "Açaí"), mais frequente vence, desempate pela mais recente, sem histórico não sugere
- [x] Ordenação: alfabética, com Diversos por último
- [x] Edição: atualiza `atualizado_em` e mantém `criado_em`; mantém o fuso se a data não mudar
- [x] Streams: inserir um registro emite o novo resultado na consulta do mês

**Concluído em 24/10/2026:**

- `lib/data/banco.drift` com o DDL da modelagem e as consultas nomeadas; `banco.dart` com a migração (carga só no `onCreate`), as PRAGMAs em `configurarConexao` e `abrirBancoRavix` (isolate separado).
- `carga_inicial.dart` guarda nomes e descrições das subcategorias (as descrições ficam só no app, como texto de ajuda).
- Repositórios: `CompraAvistaRepository`, `TagRepository`, `CategoriaRepository`.
- Schema 1 exportado em `drift_schemas/ravix/drift_schema_v1.json` (`dart run drift_dev make-migrations`).
- 54 testes novos (86 no total); cobertura de 96,5% no código escrito à mão de `lib/data` (o gerado `*.g.dart` fica fora da conta). Teste de integração `integration_test/banco_test.dart` roda no aparelho.
- Desvios: a remoção de tag conta os registros antes (em vez de tentar excluir e cair no erro da FK), porque o erro chega embrulhado quando o banco roda em outro isolate; a FK `RESTRICT` continua como rede de segurança. A unicidade do nome da tag é checada no repositório também, porque o `COLLATE NOCASE` do SQLite só ignora maiúsculas em ASCII ("Rolê" × "ROLÊ").

**Pronto quando:** testes verdes, cobertura de 80% ou mais e schema 1 exportado.

---

## M3 · Shell, navegação e bloqueio

**Objetivo:** a casca do app, onde as telas da v1 se encaixam.

**Tarefas**

- [x] `go_router` com `StatefulShellRoute`: na v1, só a aba À vista, com a estrutura pronta para Macro e Faturada da v2
- [x] Seletor de mês global como provider, com meses passados e futuros
- [x] Componentes padrão de estado de tela (carregando, vazio, erro), conforme E01-F02-T04
- [x] Botão flutuante de novo registro e navegação para Configuração
- [x] Serviço de bloqueio sobre o `local_auth` (credencial do aparelho), conforme E01-F01-T07

**Testes automatizados**

- [x] Widget: o shell mostra a aba, o botão flutuante abre o formulário, a navegação leva à Configuração
- [x] Provider: o seletor avança e volta o mês, inclusive na virada de ano
- [x] Bloqueio com serviço falso: sucesso libera; falha ou cancelamento mantém o app bloqueado
- [x] Estados de tela: cada componente aparece no estado certo

**Concluído em 24/10/2026** (com o tema CAPRA, antecipado do M7):

- Tema: `lib/core/tema/capra_tokens.dart` gerado do `capra-tokens.json` por `tool/gerar_tokens.dart` (um teste falha se o JSON mudar sem gerar de novo); `tema.dart` com o mapeamento do guia mobile para o Material 3, acento Peach, Inter embarcada (400 a 700) e os dois modos seguindo o sistema. Ícones Lucide no peso 300 (`Icones`).
- Ícone adaptativo (com camada monocromática), ícone legado e abertura do Android 12+ gerados dos SVGs da marca por `tool/gerar_icones.sh`. A marca ocupa 54% da camada do ícone, e não 58%: com 58% os arcos passam do círculo seguro de 66 dp.
- Shell com `StatefulShellRoute` (só a aba À vista; a barra inferior aparece quando houver duas abas ou mais), seletor de mês global (tocar no nome volta para hoje), botão flutuante "Novo gasto" e acesso à Configuração. Formulário e Configuração são telas provisórias até o M4 e o M5.
- Estados de tela: carregamento orbital (parado com animações reduzidas), vazio com espiral e erro com "Tentar de novo"; `ConteudoAssincrono` escolhe o estado a partir de um `AsyncValue`.
- Bloqueio: pede a credencial do aparelho ao abrir e ao voltar depois de 30 s ou mais em segundo plano; aparelho sem PIN abre direto. O conteúdo fica montado atrás da tela de bloqueio, sem perder a navegação.
- 135 testes; cobertura de 96% em telas e providers. Testado no Galaxy S23 Ultra (abertura, bloqueio e shell).
- Em aberto: a escolha Sistema / Escuro / Claro na Configuração (o guia pede; hoje o app só segue o sistema).

**Pronto quando:** testes verdes e app navegando no aparelho com o bloqueio real.

---

## M4 · Tags (Configuração > aba Tags)

**Objetivo:** gestão das tags, que o formulário do M5 vai usar.

**Tarefas**

- [x] Tela de Configuração com a aba Tags, deixando espaço para renda e cartões da v2
- [x] Listar, criar e renomear tags (E01-F07-T09)
- [x] Remover tag: arquiva se houver registros, exclui se não houver, com confirmação (E01-F07-T10)
- [x] Mensagem clara para nome repetido

**Testes automatizados**

- [x] Widget: criar, renomear e remover tag; nome repetido mostra a mensagem
- [x] Tag arquivada some da lista de ativas e continua aparecendo nos registros antigos

**Concluído em 24/10/2026:**

- `lib/features/tags/`: lista das tags ativas em ordem alfabética, "Nova tag" no botão flutuante, tocar renomeia, o botão da linha ou deslizar para a esquerda remove. A confirmação diz quantos gastos usam a tag e se ela será excluída ou arquivada; um aviso temporário confirma o resultado.
- Nome vazio ou repetido mostra a mensagem no próprio campo e o diálogo continua aberto.
- `TagRepository.contarUsos` decide o texto da confirmação.
- A Configuração abre direto na lista de Tags; a barra de abas entra quando a v2 trouxer renda e cartões.
- `tagsAtivasProvider` escrito sem `@riverpod`: o gerador não resolve tipos vindos do código do drift no mesmo build.
- 146 testes; cobertura de 97% em telas e providers.

**Pronto quando:** testes verdes e fluxo validado no aparelho.

---

## M5 · Formulário de registro (à vista)

**Objetivo:** o formulário único, no tipo à vista, nos modos criar e editar.

**Tarefas**

- [x] Componente parametrizado por tipo e modo (E01-F03-T01), na v1 só à vista
- [x] Data e hora preenchidas com o momento atual, editáveis, com datas futuras aceitas (T02)
- [x] Valor só com números, convertido para centavos (T03)
- [x] Descrição, forma de pagamento, categoria → subcategoria em ordem alfabética com Diversos por último (T04, T10)
- [x] Tag opcional, com criação inline (T15)
- [x] Sugestão pela descrição: a partir de 3 caracteres, espera de 300 ms, só preenche categoria e subcategoria se o usuário ainda não escolheu (T16)
- [x] Validação: todos os campos obrigatórios, exceto a tag (T14)
- [x] Modo editar e exclusão com confirmação (T05, T11)

**Testes automatizados**

- [x] Validação: cada campo obrigatório vazio bloqueia o salvar; valor rejeita letras; data futura é aceita
- [x] Sugestão (com `fakeAsync`): não consulta antes de 3 caracteres nem antes de 300 ms; preenche quando vazio; não sobrescreve escolha manual
- [x] Tag criada inline já fica selecionada
- [x] Editar carrega os valores salvos; excluir remove o registro só depois da confirmação
- [x] Formulário + banco em memória: salvar grava os campos calculados (centavos, normalização, fuso, UTC)

**Concluído em 24/10/2026** (falta só medir no aparelho o cadastro em menos de 10 s):

- `lib/features/compra_avista/`: `FormularioCompra` nos modos criar e editar (rotas `/registro/novo` e `/registro/:uuid`); `RascunhoCompra` concentra a validação; `MascaraValor` preenche da direita para a esquerda e ignora o que não é dígito.
- Campos na ordem: descrição, valor (prefixo R$, números tabulares), data e hora (seletores do sistema em português), forma de pagamento (sem padrão, para ser escolha consciente), categoria → subcategoria (descrição da subcategoria como ajuda), tag opcional com "Nova tag" no próprio formulário.
- Sugestão: espera de 300 ms e 3 caracteres; só preenche enquanto o usuário não escolheu a categoria; mostra "Sugerida pelo histórico". A consulta passa por `sugestaoDeSubcategoriaProvider` para os testes contarem as chamadas.
- Editar mostra a tag arquivada de um gasto antigo como "Nome (arquivada)". Excluir pede confirmação. Salvar e excluir avisam com uma mensagem temporária e vibração.
- Junto com o M5, a escolha de aparência do guia CAPRA: Configuração > Aparência (Sistema, Escuro, Claro), guardada com `shared_preferences` e lida antes de o app abrir. A Configuração virou uma lista (Aparência e Tags; Renda e Cartões entram na v2).
- `flutter_localizations`: datas, horas e textos do Material em português.
- 183 testes; cobertura de 96,5% em telas e providers.

**Pronto quando:** testes verdes e um gasto cadastrado no aparelho em menos de 10 s.

---

## M6 · Aba à vista

**Objetivo:** a tela principal da v1.

**Tarefas**

- [x] Acumulado do mês selecionado, que ignora os filtros (E01-F04-T01)
- [x] Tabela do mês com `ListView.builder`, mais recentes primeiro (T02)
- [x] Botão de edição em cada registro, abrindo o formulário no modo editar (T03)
- [x] Filtros de categoria, subcategoria e tag, que afetam só a tabela (T05)
- [x] Providers com `autoDispose` e estados de tela do M3

**Testes automatizados**

- [x] Acumulado correto e inalterado ao aplicar filtros
- [x] Filtros isolados e combinados na tabela
- [x] Trocar o mês atualiza acumulado e tabela
- [x] Estado vazio em mês sem registros
- [x] Salvar no formulário atualiza a aba sozinha, sem recarregar

**Concluído em 24/10/2026** (falta usar a aba no aparelho com dados reais):

- Total do mês em destaque (Display, números tabulares), que ignora os filtros.
- Gastos agrupados por dia ("Sábado, 10 de outubro"), mais recentes primeiro, numa lista preguiçosa (`SliverList.builder`). Cada linha: ícone da forma de pagamento, descrição, subcategoria · hora · tag e o valor. Tocar abre a edição.
- Filtros em chips (Categoria; Subcategoria aparece depois da categoria; Tag) com folha de escolha e "Todas"; trocar a categoria limpa a subcategoria; "Limpar" tira todos. O filtro de tag inclui as arquivadas, para alcançar gastos antigos. Filtro sem resultado oferece "Limpar filtros".
- `TagRepository.observarTodas` e `formatarDiaPorExtenso` no core.
- Testes que montam o app usam `testarApp`, que desmonta no fim (a aba observa o banco desde a abertura); quando o teste precisa de dados prontos, o banco é preparado antes de o app abrir.
- 197 testes; cobertura de 97% em telas e providers.

**Pronto quando:** testes verdes e a aba usada no aparelho com dados reais.

---

## M7 · Desempenho, integração e release

**Objetivo:** confirmar as metas do DP-36 e deixar a v1 instalada para uso.

**Tarefas**

- [ ] Comando de debug que gera cerca de 20 mil registros (cinco anos de uso)
- [ ] Medir em modo profile, no aparelho: abertura até a aba utilizável em menos de 2 s; salvar e ver a tabela atualizada em menos de 100 ms
- [ ] Ícone e nome do app
- [ ] Assinatura e build de release (APK ou AAB) e instalação no aparelho de uso

**Testes automatizados**

- [ ] Ponta a ponta (`integration_test`, com autenticação falsa): desbloquear → criar gasto → ver na tabela → filtrar → editar → excluir
- [ ] Ponta a ponta das tags: criar no formulário → usar em um gasto → remover na Configuração (arquiva)
- [ ] Benchmark com a massa de 20 mil registros: tempo da consulta do mês e da sugestão, registrado a cada execução, sem travar o CI (tempos variam entre máquinas)

**Pronto quando:** metas atingidas no aparelho, testes ponta a ponta verdes e v1 instalada para uso.

---

## Fora deste plano

- Backup dos dados (fora do escopo por enquanto, DP-36)
- Tudo o que está marcado como `v2` ou `v3` no backlog
