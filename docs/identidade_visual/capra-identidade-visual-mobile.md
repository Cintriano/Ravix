# CAPRA — Identidade Visual para Aplicativos Mobile

Oct 10, 2026 · @Danilo Fernandes

## Introdução

Este documento leva o manual de marca CAPRA v1.6 para apps de smartphone, tablet e relógio inteligente. Ele não muda nenhuma regra do manual: converte medidas para pt e dp, diz o que muda em cada dispositivo e lista o que entregar às lojas.

Vale para o app da CAPRA e para os produtos com logo filha (Diem, Ravix, Melope, Clam e DW\_APOLO). A área e o neutro de cada produto vêm do registro de produtos (`registro.csv`). Em caso de conflito, o manual de marca prevalece.

| Dispositivo | Plataformas | Unidade de layout | Unidade de texto | Tema |
| --- | --- | --- | --- | --- |
| Smartphone | iOS, Android | pt (iOS), dp (Android) | pt, sp | Segue o sistema; dark é a referência |
| Tablet | iPadOS, Android | pt, dp | pt, sp | Segue o sistema; dark é a referência |
| Relógio | watchOS, Wear OS | pt, dp | pt, sp | Só dark, com fundo preto (ver Relógios inteligentes) |

**Conversão.** 1 px do manual = 1 pt no iOS = 1 dp no Android. Espaços, raios, ícones e tamanhos mínimos do logo usam o mesmo número. Texto usa sp no Android para acompanhar a escala de fonte do sistema.

**Itens marcados como proposta** não existem no manual v1.6. Eles precisam de aprovação antes de entrar nele.

## Princípios de adaptação

No celular, a marca aparece forte no ícone e na abertura e discreta dentro do app. Na interface, quem domina é o conteúdo; a marca vive na cor de fundo, no acento, na tipografia e nas curvas.

- **Dark first continua valendo.** As telas são desenhadas e revisadas primeiro no tema dark. O app segue a aparência escolhida no sistema; o tema claro usa os tokens Light do manual.
- **Um acento por app.** Cada app usa o acento da sua área, mais as cores de estado. O limite de dois acentos do manual vale só para telas que mostram produtos diferentes.
- **Toque, não cursor.** Sem hover no celular e no relógio: os estados são pressionado, selecionado, foco e desabilitado.
- **Convenção da plataforma primeiro.** Gestos, navegação e controles seguem iOS e Android. A marca muda cor, forma e tipo, não o comportamento.
- **Fonte única de tokens.** `capra-tokens.json` gera o tema Flutter (`capra-theme.dart`) e, para relógios, as cores nativas de SwiftUI e Compose. Nenhum HEX dentro de componente.
- **Menos em telas menores.** Quanto menor a tela, menos elementos de marca: no relógio, só o ícone, o acento e os arcos.

| Elemento de marca | Smartphone | Tablet | Relógio |
| --- | --- | --- | --- |
| Ícone de app | Sim | Sim | Sim, circular |
| Assinatura na abertura | Ícone centralizado | Ícone centralizado | Ícone centralizado |
| Assinatura no cabeçalho | Só na tela inicial ou Sobre | Só na tela inicial ou Sobre | Não |
| Linguagem gráfica (espirais, pontos) | Vazios, onboarding, carregamento | Vazios, onboarding, painéis largos | Só arcos de progresso |
| Tema claro | Sim | Sim | Não |

## Ícone de app

Todo ícone nasce de um mestre 1024 × 1024 em SVG, quadrado, sem cantos e sem sombra: cada sistema aplica a própria máscara. Os dois mestres do manual já servem para todos os dispositivos, inclusive relógios.

| Marca | Mestre | Fundo | Marca ocupa |
| --- | --- | --- | --- |
| CAPRA | `capra-icone-app.svg` | `background` #121416 | 64% da largura, símbolo reduzido |
| Produto (logo filha) | Ícone gerado pelo gerador ou pelo script | Neutro do produto: #121416 ou #FFFFFF | 68% da largura, marca completa |

[image: Ícone do Ravix: neutro preto, disco Peach, letra R recortada e dois braços\]

Exemplo: o ícone do Ravix usa o neutro preto e o acento de Finanças (Peach #D7AFA3).

### Por plataforma

| Plataforma | O que entregar | Medidas | Regra CAPRA |
| --- | --- | --- | --- |
| iOS e iPadOS | Arquivo do Icon Composer montado a partir do mestre | Tela de 1024 × 1024 | Uma camada de fundo sólida e a marca em camadas separadas por cor |
| watchOS | O mesmo arquivo do Icon Composer | Tela de 1024 × 1024, exibida em círculo | Os dois mestres já cabem no círculo; confira no preview |
| Android (celular e tablet) | Ícone adaptativo com camadas `background`, `foreground` e `monochrome` | Camadas de 108 × 108 dp; marca dentro do círculo seguro de 66 dp | CAPRA: símbolo reduzido em até 58% da largura. Logo filha: até 58% (proposta) |
| Wear OS | O mesmo ícone adaptativo do Android | Iguais ao Android | Sem arquivo separado |
| Google Play | PNG 512 × 512, 32 bits, sRGB, até 1024 KB | Quadrado cheio | Sem cantos e sem sombra: a loja aplica os dois |

### Aparências do ícone

iOS, iPadOS e watchOS mostram o ícone em seis aparências: padrão, dark, clear claro, clear escuro, tinted claro e tinted escuro. O Android 13 ou superior pinta o ícone com a cor do tema quando o app fornece a camada `monochrome`.

| Aparência | CAPRA | Logo filha |
| --- | --- | --- |
| Padrão | Mestre colorido | Mestre no neutro do produto |
| Dark | Igual ao padrão; o ícone já é escuro | Igual ao padrão. Nunca trocar o neutro: ele diferencia produtos da mesma área |
| Clear e tinted (Apple) | Símbolo em uma cor, a partir de `capra-simbolo-mono-claro.svg` | Disco, letra vazada e braços em uma cor |
| Monochrome (Android) | Mesma silhueta em uma cor, sem fundo | Mesma silhueta em uma cor, sem fundo |

**Acabamento Liquid Glass.** Use o mínimo que o Icon Composer permite: sem sombra extra, sem desfoque e sem translucidez nas camadas da marca. O manual proíbe glow, sombra e bisel; o brilho de borda que o sistema aplica é da plataforma e é aceito.

### Não fazer

- Arredondar cantos, aplicar sombra ou moldura no arquivo enviado.
- Escrever o nome do produto ou usar a assinatura horizontal dentro do ícone.
- Aumentar a marca além de 64% (CAPRA) ou 68% (logo filha) para "preencher" o ícone.
- Criar versão sazonal, com badge ou com cor fora da paleta.
- Usar o símbolo colorido sobre fundo pastel.

## Logotipo no app

Dentro do app, a marca aparece em três lugares: tela de abertura, tela inicial e tela Sobre. Nas demais telas, o título da tela ocupa o cabeçalho, como manda a convenção de cada plataforma.

### Tela de abertura

Fundo liso e a marca centralizada, sem texto, sem slogan e sem animação longa. O Android 12 ou superior monta essa tela a partir do ícone; no iOS, a tela de abertura é desenhada para ficar igual.

| App | Tema dark | Tema claro |
| --- | --- | --- |
| CAPRA | Fundo #121416 e `capra-simbolo.svg` | Fundo #F3F5F6 e `capra-simbolo-fundo-claro.svg` |
| Produto | Fundo no neutro do produto e `-marca.svg` | Igual ao dark: a marca sem fundo só pode aparecer sobre o próprio neutro |

- **Android:** a área do ícone é de 288 × 288 dp e a marca cabe num círculo de 192 dp. Cor de fundo da janela = a cor da tabela.
- **Animação (opcional):** a entrada curta da Parte 11 do manual: 800 ms (`motion-brand-short`), só opacidade e escala de 90% a 100%. Produtos usam a entrada da logo filha, também de 800 ms. Nunca girar a marca.
- **Flutter:** gere as telas nativas das duas plataformas a partir dos mesmos arquivos, para não haver salto de cor ao abrir o app.

### Cabeçalho e tela Sobre

- **App CAPRA:** assinatura horizontal só na tela inicial, com área de proteção de 0,5X.
- **Produto:** assinatura do app (marca + nome em Inter SemiBold, espaçamento −2%). Com nome em 18 pt, a marca tem 27 pt e fica a 6 pt do nome.
- **Tela Sobre:** assinatura com endosso (marca, nome, fio, "por" e logotipo CAPRA) e a versão do app em `caption` `textSecondary`.
- O nome CAPRA nunca é digitado como título de tela: use o arquivo do logotipo.

### Tamanhos mínimos em tela

Os mínimos digitais do manual valem em pt e dp, com o mesmo número.

| Versão | Mínimo (pt/dp) |
| --- | --- |
| Assinatura horizontal | 120 de largura |
| Assinatura vertical | 80 de largura |
| Logotipo | 72 de largura |
| Símbolo | 24 de largura |
| Símbolo reduzido | 16 a 23 |
| Logo filha completa | 32 |
| Logo filha reduzida (disco + letra) | 16 a 31 |

## Cores

Os apps usam exatamente os tokens do manual, nos dois temas, mapeados para os papéis de cor de cada plataforma. Nenhuma cor nova entra no app; o único acréscimo é o fundo preto dos relógios, tratado em Relógios inteligentes.

### Mapeamento para Flutter (Material 3)

| Token CAPRA | `ColorScheme` | Onde aparece |
| --- | --- | --- |
| `background` | `surface` e fundo do `Scaffold` | Fundo das telas |
| `surface` | `surfaceContainer` | Cartões, barra de navegação inferior |
| `surfaceElevated` | `surfaceContainerHigh` e `secondaryContainer` | Folhas inferiores, menus, botão secundário, indicador do item ativo |
| `border` | `outlineVariant` | Divisórias |
| `borderStrong` | `outline` | Bordas de campos, chaves e caixas de seleção |
| `textPrimary` | `onSurface` | Texto e ícones principais |
| `textSecondary` | `onSurfaceVariant` | Metadados, rótulos, ícones inativos |
| Acento da área | `primary` e `onSecondaryContainer` | Botão primário, item ativo, foco, links |
| `onAccent` | `onPrimary` e `onError` | Texto sobre acento e sobre `danger` |
| `danger` | `error` | Erros e ações destrutivas |

- Defina `surfaceTint` como transparente. Sem isso, o Material 3 tinge as superfícies elevadas com o acento e foge da base neutra.
- No watchOS (SwiftUI) e no Wear OS (Compose), os mesmos tokens viram cores nativas geradas de `capra-tokens.json`.

### Regras no app

- **Aparência.** O app segue o sistema e oferece a escolha Sistema, Escuro ou Claro nas configurações.
- **Barras do sistema.** Barra de status e de navegação transparentes, com ícones claros no tema dark e escuros no tema claro.
- **Um acento por app.** O acento da área marca ação principal, navegação ativa e foco. Gráficos podem usar um segundo tom, como Cyan e Lilac em dados.
- **Gradientes** (Cyan → Lilac, Lilac → Peach, Mint → Cyan) só em ilustrações, telas vazias e onboarding. Nunca em botões, cartões ou texto.
- **Acento não é estado.** No Ravix, saldo negativo usa `danger` com o sinal "−", nunca Peach. Em apps de Automação e Infraestrutura, todo estado leva ícone e texto, porque o acento coincide com `success` ou `warning`.

## Tipografia

Inter continua sendo a fonte de todo o texto e JetBrains Mono a de código. A escala mobile abaixo é uma proposta: o corpo de 14 px do manual fica pequeno no celular, onde iOS e Android usam 16 a 17 como padrão.

| Nível | Celular e tablet (pt/sp) | Relógio (pt/sp) | Peso | Uso |
| --- | --- | --- | --- | --- |
| Display | 34 / 40 | 30 / 34 | Bold 700 | Número principal, onboarding |
| H1 | 28 / 34 | 20 / 24 | Bold 700 | Título da tela |
| H2 | 20 / 26 | 17 / 22 | Bold 700 | Seções e títulos de cartão |
| Body | 16 / 24 | 16 / 20 | Regular 400 | Texto de interface |
| Rótulo | 16 / 20 | 15 / 18 | Medium 500 | Botões e campos |
| Caption | 13 / 18 | 13 / 16 | Regular 400 | Metadados, legendas, rótulos da barra inferior |
| Code | 13 / 20 | Não usar | JetBrains Mono 400 | Códigos, tokens, texto cifrado |

Valores em tamanho / entrelinha, com a fonte do sistema no tamanho padrão.

### Regras

- **Tamanho do sistema.** Todo texto acompanha o tamanho de fonte do usuário. Teste em 200% no Android e no maior tamanho de acessibilidade do iOS; no Flutter, nunca trave o `textScaler` em 1.0.
- **Layout que cresce.** Texto quebra linha em vez de ser cortado. Botões e linhas de lista crescem em altura.
- **Fontes embarcadas.** Inter (400, 500, 600 e 700) e JetBrains Mono (400) vão dentro do app, sem download na primeira abertura.
- **Números tabulares** em valores, horários, durações e contadores (`FontFeature.tabularFigures()` no Flutter).
- **Caixa de frase** em títulos, botões e abas. Nada em caixa alta.
- **Largura de leitura.** No tablet, colunas de texto com até 80 caracteres, cerca de 640 pt.
- **Relógio.** Complicações e tiles usam a fonte do sistema, que o watchOS e o Wear OS ajustam para leitura rápida.

## Grid, espaçamento e áreas seguras

O espaçamento usa a escala de tokens do manual (4, 8, 16, 24, 32 e 48) em pt e dp. A margem lateral e o número de colunas mudam com a largura da janela, não com o aparelho.

| Largura da janela | Exemplos | Margem lateral | Espaço entre colunas | Colunas |
| --- | --- | --- | --- | --- |
| Menos de 600 dp | Celular em retrato | 16 (`space-md`) | 16 | 4 |
| 600 a 839 dp | Tablet em retrato, celular dobrável aberto | 24 (`space-lg`) | 24 | 8 |
| 840 dp ou mais | Tablet em paisagem | 32 (`space-xl`) | 24 | 12 |
| Relógio | Tela redonda ou quadrada | Em %, nunca em valor fixo; no mínimo 5,2% nas laterais em tela redonda | — | 1 |

### Toque

- Área de toque mínima de 44 × 44 pt no iOS e watchOS e de 48 × 48 dp no Android e Wear OS, mesmo quando o desenho é menor.
- Pelo menos 8 pt/dp entre dois alvos de toque vizinhos.
- Proposta de alturas: botão e campo com 48 (o manual define 40 para web), linha de lista com 56 em uma linha e 72 em duas.

### Áreas seguras

- Fundos e imagens vão até a borda da tela; texto e controles ficam dentro da área segura (recorte da câmera, Dynamic Island, barra de gestos, indicador de início).
- Android 15 ou superior exige layout de borda a borda: desenhe as barras do sistema sobre o fundo `background`.
- Com o teclado aberto, o campo em foco e o botão principal continuam visíveis.

### Raios no app

| Token | Valor | Uso no app |
| --- | --- | --- |
| `radius-sm` | 8 | Campos, chips, miniaturas |
| `radius-md` | 12 | Botões e cartões |
| `radius-lg` | 16 | Cantos superiores de folhas inferiores, diálogos, widgets internos |
| `radius-pill` | 999 | Badges, chaves, indicador da aba ativa, botões no relógio |

Cantos de tela, de widgets da tela inicial e de ícones são do sistema: não desenhe por cima.

## Componentes de interface

Os componentes do manual valem no app com alturas para toque; os de navegação mobile seguem a mesma lógica: superfícies neutras, sem sombra, acento só no que está ativo.

| Componente | Especificação |
| --- | --- |
| Botão primário | Acento da área, texto `onAccent`, rótulo 16 Medium, altura 48, `radius-md`. Um por tela; em formulários, largura total no rodapé da tela |
| Botão secundário | `surfaceElevated`, borda 1 `borderStrong`, texto `textPrimary` |
| Botão discreto | Sem fundo, texto no acento |
| Botão destrutivo | `danger` com texto `onAccent`, só para ação irreversível e sempre com confirmação |
| Campo | `surface`, borda 1 `borderStrong`, `radius-sm`, altura 48. Rótulo acima em 13 Medium `textSecondary`; teclado adequado ao tipo (número, e-mail, senha) |
| Cartão | `surface`, borda 1 `border`, `radius-md`, padding 16, sem sombra |
| Barra superior | Fundo `background`, sem sombra; ao rolar, ganha divisória `border`. Título H1 na tela raiz e H2 nas internas |
| Navegação inferior | `surface`, 3 a 5 destinos, ícone 24 e rótulo `caption`. Ativo: ícone e rótulo no acento sobre indicador em pílula `surfaceElevated`. Inativo: `textSecondary` |
| Lista | Linhas de 56 ou 72, divisória `border` recuada 16. Ação de deslizar para excluir em `danger`, com ícone |
| Folha inferior | `surfaceElevated`, cantos superiores `radius-lg`, alça de 32 × 4 em `borderStrong` |
| Aviso temporário | `surfaceElevated`, texto `textPrimary`, ícone de estado e ação no acento |
| Chave, seleção e rádio | Ligado: acento com marca `onAccent`. Desligado: borda `borderStrong` |
| Badge | Pílula de 24, contorno 1 e texto 12 Medium na cor do estado ou do contexto |
| Carregando | Arco de 2 no acento com um ponto orbital; listas e cartões usam blocos `surfaceElevated` no lugar do conteúdo |
| Estado vazio | Fragmento de espiral com 2 a 5 pontos, título H2, uma frase e uma ação |

### Estados

| Estado | Regra |
| --- | --- |
| Pressionado | Só muda a luminosidade, cerca de 8%. No Android, o efeito de toque usa `textPrimary` em baixa opacidade, nunca o acento |
| Selecionado | Acento no ícone e no texto, indicador `surfaceElevated` |
| Foco por teclado ou controle | `focus-ring`: respiro na cor do fundo e anel de 2 no acento |
| Desabilitado | Proposta: componente inteiro a 38% de opacidade, sem resposta ao toque |
| Erro | Borda e mensagem em `danger`, com ícone; a mensagem diz o que corrigir |

## Smartphone

No celular, cada tela tem um objetivo, um título e no máximo um botão primário, ao alcance do polegar. É a referência de layout: tablet e relógio partem dele.

### Layout e navegação

- Uma coluna, em retrato. Paisagem só onde ajuda, como gráficos e mídia.
- Barra de navegação inferior com 3 a 5 destinos. Mais que isso vai para uma tela "Mais" ou para o perfil.
- Ações frequentes na metade de baixo da tela; ações raras e configurações em cima.
- Conteúdo agrupado em cartões e listas com respiro de 24 entre grupos (`space-lg`).

### Fora do app

| Superfície | Regra |
| --- | --- |
| Ícone de notificação (Android) | Silhueta de uma cor, 24 × 24 dp, sem fundo: símbolo reduzido (CAPRA) ou disco com letra vazada (produto). Cor de destaque = acento da área |
| Notificação (iOS) | Usa o ícone do app; o texto segue as regras de escrita do manual |
| Widget da tela inicial | Fundo `surface`, um dado principal em Display com números tabulares, acento em um só elemento. Sem logo: o sistema já mostra o nome do app |
| Widget em modo tinted ou clear (iOS) | O widget continua legível sem cor: hierarquia por tamanho e peso, não pelo acento |
| Atividade ao vivo e Dynamic Island (iOS) | Marca reduzida à esquerda, dado principal à direita, acento em um só elemento |

- **Sem cor dinâmica.** Não adote as cores do papel de parede (Material You) dentro do app. As cores da marca não mudam com o aparelho.

## Tablet

No tablet, o espaço extra vira mais conteúdo lado a lado, não elementos maiores. Tipografia, ícones e alturas de componentes são os mesmos do celular.

| Largura da janela | Navegação | Layout |
| --- | --- | --- |
| Menos de 600 dp | Barra inferior, como no celular | Uma coluna |
| 600 a 839 dp | Trilho lateral só com ícones e rótulos curtos | Uma coluna centralizada ou grade de 2 cartões |
| 840 dp ou mais | Barra lateral fixa com rótulos (no iPadOS, a barra lateral do sistema) | Lista e detalhe lado a lado: lista com 320 a 400, detalhe no restante |

- **Multitarefa.** O app funciona em tela dividida e janelas redimensionáveis. Ele troca de layout pela largura da janela, nunca pela orientação.
- **Teclado, mouse e trackpad.** Aqui existe hover: vale a regra do manual, cerca de 8% de luminosidade. Foco por teclado usa `focus-ring`, e as ações principais ganham atalho.
- **Painéis de dados.** Grade de cartões em 2 ou 3 colunas, uma cor principal por visualização, gráficos sobre fundo neutro.
- **Linguagem gráfica.** Telas vazias e onboarding podem usar a espiral saindo do enquadramento, como nos banners do manual, sempre com o conteúdo em primeiro plano.

## Relógios inteligentes

No relógio, a marca se resume a fundo preto, um acento e arcos; cada tela responde a uma pergunta em poucos segundos. Não há tema claro, nem assinatura, nem logotipo dentro do app.

### Fundo preto (proposta)

Proposta para o manual: token `backgroundWatch` = #000000, só para relógios. Em tela OLED, o preto apaga os pixels, economiza bateria e funde a tela com a borda do aparelho. Com #121416, o contorno da tela fica visível no escuro, principalmente em telas redondas.

Cartões continuam em `surface` e botões secundários em `surfaceElevated`. Texto e acentos ganham contraste sobre o preto, então todas as combinações do manual continuam válidas.

### Layout

- **Uma ideia por tela.** Um dado principal em Display, no máximo três ações, rolagem vertical.
- **watchOS.** Listas roladas pela Digital Crown; navegação em pilha ou em páginas verticais.
- **Wear OS.** Desenhe primeiro para o menor relógio redondo (204 a 216 dp). Margens em porcentagem; ação principal no botão que acompanha a borda inferior da tela.
- **Botões** em pílula (`radius-pill`), largura total, acento no primário.
- **Texto curto centralizado** em tela redonda; textos longos alinhados à esquerda.

### Arcos

Anéis e arcos de progresso acompanham a borda da tela e são a forma mais direta da linguagem gráfica no pulso. Arco no acento sobre trilho `surfaceElevated`, ponta com corte reto, como os braços do símbolo, e no máximo um ponto orbital.

### Fora do app

| Superfície | Regra |
| --- | --- |
| Complicações (watchOS) | Funcionam em uma cor nos modos acentuado e vibrante. Mostre o dado; marca só quando não houver dado (símbolo reduzido ou disco com letra) |
| Complicações e tiles (Wear OS) | Layouts do sistema com margens percentuais, acento em um elemento, ícone do app no topo do tile |
| Notificações | Ícone do app e nome; texto curto; ações com verbo, como "Marcar como paga" |
| Modo sempre ligado / ambiente | Quase tudo preto, contornos em vez de preenchimentos, texto em `textSecondary`, sem animação. Esconda dados sensíveis, como saldos do Ravix, quando o pulso baixa |

### Tecnologia

O watchOS exige app nativo em SwiftUI, porque o Flutter não roda no relógio da Apple. No Wear OS, o Google indica Compose para Wear OS. Os dois leem as cores e medidas de `capra-tokens.json`.

## Iconografia de interface

Os ícones seguem o manual: lineares, com pontas e cantos arredondados, nas grades de 16, 20 e 24. No relógio, crescem e engrossam o traço para leitura no pulso.

| Contexto | Tamanho (pt/dp) | Traço |
| --- | --- | --- |
| Barras superior e inferior, ações principais | 24 | 1,5 |
| Botões e campos | 20 | 1,5 |
| Dentro de texto e badges | 16 | 1,5 |
| Relógio | 24 a 32 | 2 |
| Notificação no Android | 24 | Silhueta preenchida, exigida pelo sistema |

- **Ativo muda a cor, não o desenho.** O ícone selecionado fica no acento; o traço e a forma não mudam, então não há versão preenchida.
- **Ícones de sistema** (voltar, compartilhar, mais opções) mantêm a forma que cada plataforma usa, desenhados no traço CAPRA.
- **Rótulo junto.** Na navegação, todo ícone tem rótulo visível. Ícone sozinho só para ações universais, como fechar e buscar.
- **Área de toque** de 44 pt ou 48 dp em volta do ícone, mesmo com o desenho em 20 ou 24.
- **Em aberto:** o manual não define uma biblioteca. Proposta: um conjunto linear de cantos arredondados, como Lucide, com traço ajustado para 1,5, e ícones próprios desenhados na mesma grade.

## Movimento e retorno háptico

O movimento segue a Parte 11 do manual v1.6: tokens de duração e curva, entrada do logo, carregamento orbital, regras de interface e movimento reduzido. Aqui fica só o que é próprio dos apps.

- **Transições de tela** seguem a plataforma, em `motion-screen` (300 ms): empilhar no iOS, deslizar e esvanecer no Android.
- **Flutter:** use os valores dos tokens em `Duration`, `Cubic(0.2, 0, 0, 1)` na entrada e `Cubic(0.3, 0, 1, 1)` na saída. O Flutter não reproduz SVG animado: a entrada do logo e das logos filhas é montada com os arquivos estáticos e os mesmos tempos.
- **Carregamento:** o carregamento orbital do manual (`capra-carregamento.svg` como referência), com o texto "Carregando…" para leitores de tela.
- **Reduzir movimento:** com `MediaQuery.of(context).disableAnimations` ligado, deslocamentos viram esvanecimento, as entradas de marca viram esvanecimento de 200 ms e o carregamento fica parado.

### Retorno háptico

| Momento | Retorno |
| --- | --- |
| Mudar seleção em seletor, chave ou aba | Toque leve de seleção |
| Ação concluída (salvar, pagar, enviar) | Padrão de sucesso do sistema |
| Erro que bloqueia a ação | Padrão de erro, junto da mensagem em `danger` |
| Relógio: lembrete ou conclusão | Padrões do watchOS e do Wear OS, nunca vibração própria |

Háptico sempre acompanha uma mudança visível e respeita a configuração do sistema. Nunca é decoração.

## Acessibilidade

A paleta já passa nos testes de contraste; o que falta garantir no app é leitor de tela, tamanho de fonte e as configurações de acessibilidade do sistema. Cada produto é validado nos dois temas antes de cada versão.

| Configuração do sistema | O que o app faz |
| --- | --- |
| Leitor de tela (VoiceOver, TalkBack) | Marca lida como "CAPRA" ou pelo nome do produto; espirais, pontos e arcos decorativos ficam ocultos; ícone sem texto tem rótulo; valores são lidos com unidade e sinal |
| Tamanho de fonte | Layout cresce até 200% sem cortar texto (ver Tipografia) |
| Texto em negrito (iOS) | O app troca Inter 400 por 600 e 600 por 700, porque fontes embarcadas não engrossam sozinhas |
| Aumentar contraste / texto de alto contraste | Divisórias e cartões passam de `border` para `borderStrong` |
| Reduzir movimento | Deslocamentos viram esvanecimento; animações em repetição param |
| Acesso por teclado, botão ou voz | Foco visível com `focus-ring` em todo controle, na ordem de leitura |

- **Contraste.** Use só os pares do manual: texto e acentos passam de 7:1 no dark e de 4,5:1 no claro; `borderStrong` passa de 3:1. Nada de texto em acento com opacidade reduzida.
- **Cor nunca sozinha.** Estado sempre com ícone e texto; valor negativo sempre com sinal.
- **Alvos de toque** de 44 pt ou 48 dp, com 8 de distância entre eles.
- **Teste em aparelho real** com leitor de tela ligado, fonte no máximo e os dois temas.

## Materiais para lojas de aplicativos

Nas lojas, a vitrine é feita de capturas reais do app sobre o fundo Void, com um título curto e o acento da área. Cada produto aparece com o próprio nome; o desenvolvedor é sempre CAPRA.

| Loja | Item | Medidas | Formato e regras |
| --- | --- | --- | --- |
| App Store | Ícone | Vai dentro do app, 1024 × 1024 | Trocar o ícone exige nova versão do app |
| App Store | Capturas de iPhone (6,9") | 1320 × 2868, 1290 × 2796 ou 1260 × 2736 | JPEG ou PNG sem transparência, 1 a 10 por idioma |
| App Store | Capturas de iPad (13") | 2064 × 2752 ou 2048 × 2732 | Obrigatórias se o app roda no iPad |
| App Store | Capturas de Apple Watch | Um tamanho por série, de 422 × 514 (Ultra 3) a 312 × 390 (Series 3) | Mesmo tamanho em todos os idiomas |
| Google Play | Ícone | 512 × 512 | PNG 32 bits, sRGB, até 1024 KB, quadrado cheio, sem sombra |
| Google Play | Gráfico de destaque | 1024 × 500 | JPEG ou PNG 24 bits sem transparência; obrigatório |
| Google Play | Capturas de celular | Recomendado 1080 × 1920 (9:16) | 2 a 8; pelo menos 4 para aparecer em destaques |
| Google Play | Capturas de tablet | Entre 1080 e 7680 px, 16:9 ou 9:16 | Pelo menos 4 |
| Google Play | Capturas de Wear OS | 1:1, mínimo 384 × 384 | Só a interface, sem moldura, sem máscara e sem texto extra |

### Capturas de tela

- Fundo `background`, título em Inter Bold `textPrimary` com até 20% da altura da imagem, caixa de frase.
- A primeira captura mostra a função principal, nunca abertura ou login.
- Dados fictícios em todas as telas, nunca dados de pessoas reais.
- Um acento por produto; fragmentos de espiral e pontos só nas bordas.
- Sem selos de loja, sem "melhor", "nº 1" ou "baixe agora". No Google Play, sem moldura de aparelho.

### Gráfico de destaque (Google Play)

O Google recomenda evitar fundo preto ou cinza escuro, porque ele some no fundo da loja. Solução CAPRA: a base continua Void, mas a espiral e um gradiente da paleta (por exemplo, Cyan → Lilac) ocupam as bordas, como nos banners do manual. No centro, só um título curto; não repita o ícone como marca principal, porque ele já aparece ao lado.

## Checklist de entrega

Use esta lista em cada versão de cada app. A última parte reúne as propostas deste documento que ainda precisam de aprovação para entrar no manual.

### Ícone e marca

- [ ] Ícone gerado do mestre SVG, sem cantos, sem sombra, sem texto
- [ ] Aparências dark, clear e tinted conferidas no Icon Composer
- [ ] Ícone adaptativo do Android com camada `monochrome` e marca dentro do círculo de 66 dp
- [ ] Ícone conferido em círculo (watchOS e Wear OS)
- [ ] Ícone de notificação do Android em silhueta de uma cor
- [ ] Tela de abertura com o fundo da tabela e sem salto de cor ao abrir

### Interface

- [ ] Nenhum HEX dentro de componente: tudo vem de `capra-tokens.json`
- [ ] `surfaceTint` transparente e sem cor dinâmica do sistema
- [ ] Um acento por app; todo estado com ícone e texto
- [ ] Todas as telas revisadas nos temas dark e claro
- [ ] Layout testado em celular, tablet em retrato e paisagem, e tela dividida

### Acessibilidade

- [ ] Fonte em 200% sem texto cortado
- [ ] Leitor de tela com rótulos em marca, ícones e valores
- [ ] Alvos de toque de 44 pt ou 48 dp
- [ ] Reduzir movimento e texto em negrito respeitados
- [ ] Tela de abertura e carregamento conforme a Parte 11 do manual

### Lojas

- [ ] Capturas nos tamanhos da tabela, com dados fictícios
- [ ] Gráfico de destaque de 1024 × 500 com a espiral nas bordas
- [ ] Textos sem "melhor", "nº 1" ou "baixe agora"

### Aprovar para o manual

- [ ] Escala tipográfica mobile (corpo de 16)
- [ ] Altura de 48 para botão e campo no app
- [ ] Token `backgroundWatch` #000000 para relógios
- [ ] Estado desabilitado a 38% de opacidade
- [ ] Logo filha em até 58% no ícone adaptativo do Android
- [ ] Biblioteca de ícones de interface

## Fontes

- Manual de marca CAPRA v1.6 (`capra-manual-de-marca-v1_6.md`)
- [Apple: Create icons with Icon Composer (WWDC25)](https://developer.apple.com/videos/play/wwdc2025/361)
- [Apple: Icon Composer group lab (WWDC26)](https://developer.apple.com/videos/play/wwdc2026/8012/)
- [Android Developers: Adaptive icons](https://developer.android.com/guide/practices/ui_guidelines/icon_design_adaptive)
- [Android Developers: Wear OS adaptive design](https://developer.android.com/design/ui/wear/guides/foundations/adaptive-design)
- [Android Developers: Wear OS design quality tiers](https://developer.android.com/design/ui/wear/guides/foundations/quality-tiers)
- [SAP Fiori for Wear OS: Layout](https://www.sap.com/design-system/fiori-design-android/sap-fiori-for-wear-os/foundation/wear-os-layout) (margem mínima de 5,2%)
- [Google Play Console Help: Add preview assets](https://support.google.com/googleplay/android-developer/answer/9866151?hl=en-GB)
- [AxonBuild: App Store screenshot and icon sizes](https://axonbuild.com/blog/app-store-screenshot-and-icon-sizes/) (medidas conferidas nas páginas da Apple em 16/08/2026)

As medidas da tela de abertura do Android e a regra de borda a borda do Android 15 vêm da documentação do Android e não foram reconferidas nesta versão.
