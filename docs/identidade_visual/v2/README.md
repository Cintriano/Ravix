# Ravix: identidade visual v2

Manual da marca Ravix, um app mobile de gestão financeira pessoal com duas funções principais: **registro de gastos** e **monitoramento** do mês. O mesmo manual vale para o site do app.

- Versão: 2.0, 06/11/2026
- Versão visual desta documentação: [`ravix-identidade.html`](ravix-identidade.html)
- Tokens para desenvolvimento: [`tokens/tokens.json`](tokens/tokens.json) (app) e [`tokens/ravix.css`](tokens/ravix.css) (site)

---

## 1. A marca

### Conceito

O símbolo é o **x com a seta**: o ponto onde o gasto encontra o crescimento.

| Elemento | Desenho | Significado |
|---|---|---|
| Haste de saída | A haste descendente do x da Chakra Petch Bold, sem alterações, com um vão onde a seta passa | O dinheiro que sai, o gasto registrado |
| Haste de crescimento | Espelho da haste de saída, com a mesma espessura (149 unidades), que passa por cima e vira seta | O capital que aumenta |
| Ponta da seta | Termina na altura do topo do pingo do i (712 unidades) | O crescimento passa da linha do texto |

Medidas em unidades da fonte (1000 por em): linha de base em 0, altura do x em 498, maiúsculas em 700 e ponta da seta em 712. O vão no cruzamento é de 30 unidades.

O símbolo foi desenhado a partir do x da própria fonte, por isso ele tem a mesma espessura e o mesmo ângulo das outras letras. Assim o logotipo funciona como uma palavra só, sem parecer uma letra colada de outra fonte.

### Versões do logotipo

| Arquivo | Letras e haste | Seta | Onde usar |
|---|---|---|---|
| `logo/svg/ravix-logo.svg` | Floresta `#163730` | Menta 600 `#3FB282` | Fundos claros (principal) |
| `logo/svg/ravix-logo-negativo.svg` | Névoa `#EEF4F0` | Menta `#78CFA5` | Fundo Floresta ou escuro |
| `logo/svg/ravix-logo-floresta.svg` | Floresta | Floresta | Uma cor só (carimbo, gravação) |
| `logo/svg/ravix-logo-branco.svg` | Branco | Branco | Uma cor só sobre foto ou cor |
| `logo/svg/ravix-logo-fundo-*.svg` | — | — | Já com fundo e área de proteção (claro, Floresta, Petróleo) |

Os PNGs ficam em `logo/png/` com 600, 1200 e 2400 px de largura e fundo transparente.

### Símbolo e ícone

- `simbolo/`: só o x com a seta, nas mesmas quatro variações de cor, em SVG e em PNG (256, 512 e 1024 px de altura).
- `icone/`: ícone com cantos arredondados para apresentações e materiais (Floresta, claro e Menta). **Não envie esses arquivos para as lojas.** Use os da pasta `mobile/`.

### Regras

1. **Use os arquivos.** Não digite "Ravix" na Chakra Petch para fazer o logo. O x é desenhado à parte e só existe nos arquivos.
2. **Área de proteção:** deixe um espaço livre igual à altura do x em volta do logotipo.
3. **Tamanho mínimo:** o logotipo completo precisa de 24 dp de altura no app e 72 px de largura no site. O símbolo sozinho pode ir até 16 px (favicon).
4. **A seta sempre sobe.** Não espelhe, gire nem troque as cores das hastes.
5. **Uma cor de destaque:** só a haste de crescimento recebe Menta.
6. Não aplique sombra, contorno, gradiente ou efeito 3D.

---

## 2. Cores

As cores da proposta anterior foram mantidas. Os códigos escritos na imagem da proposta estavam errados (por exemplo, `#343600` no quadrado verde-escuro), então os valores abaixo foram medidos direto nos quadrados de cor.

### Paleta da marca

| Nome | Hex | RGB | Função | Proporção |
|---|---|---|---|---|
| **Floresta** | `#163730` | 22, 55, 48 | Base da marca, cabeçalhos, botão principal, fundo do ícone | 25% |
| **Menta** | `#78CFA5` | 120, 207, 165 | Seta, ações, progresso, economia | 8% |
| **Petróleo** | `#22727B` | 34, 114, 123 | Gráficos, links, foco | 12% |
| **Areia** | `#C9AD78` | 201, 173, 120 | Categorias, detalhes | 5% |
| Névoa | `#EEF4F0` | 238, 244, 240 | Neutro claro, texto sobre Floresta | 50% (neutros) |
| Tinta | `#0C2420` | 12, 36, 32 | Texto sobre Menta | — |
| Menta 600 | `#3FB282` | 63, 178, 130 | Menta mais escura, para texto e seta em fundo claro | — |

### Estados do orçamento

| Estado | Hex | Regra |
|---|---|---|
| Dentro do orçamento | `#3FB282` | Abaixo de 80% |
| Perto do limite | `#D9A441` | De 80% a 100% |
| Orçamento estourado | `#D0614E` | Acima de 100%. Só para alertas |

### Temas

| Token | Claro | Escuro | Uso |
|---|---|---|---|
| `background` | `#F4F7F4` | `#0D1C19` | Fundo da tela |
| `surface` | `#FFFFFF` | `#132823` | Campos, cards, folhas |
| `surfaceAlt` | `#E9F0EC` | `#1B3530` | Áreas secundárias |
| `text` | `#11241F` | `#E7F0EC` | Texto principal |
| `textMuted` | `#5B6F69` | `#93A9A2` | Rótulos e textos de apoio |
| `line` | `#D2DFD8` | `#244038` | Contornos e divisórias |
| `primary` | `#163730` | `#78CFA5` | Botão principal |
| `onPrimary` | `#EEF4F0` | `#0C2420` | Texto no botão principal |
| `accent` | `#3FB282` | `#78CFA5` | Destaques e ícones ativos |
| `info` | `#22727B` | `#6CC1C8` | Foco, links, gráficos |

No tema escuro, o botão principal passa a ser Menta, porque o Floresta some no fundo escuro.

Ordem das cores nos gráficos: `#78CFA5`, `#22727B`, `#C9AD78`, `#4FA3A0`, `#163730` e `#A9C9BC`.

---

## 3. Tipografia

| Papel | Fonte | Pesos | Uso |
|---|---|---|---|
| Display | **Chakra Petch** | 500, 600, 700 | Logotipo, títulos, valores em destaque |
| Texto | **Archivo** | 400, 500, 600 | Interface, rótulos, listas, botões, textos longos |

A Chakra Petch tem cantos chanfrados a 45° e cortes retos, os mesmos ângulos do símbolo. A Archivo é uma grotesca de terminais retos que mantém o tom anguloso e continua legível em 12 px. As duas são gratuitas no Google Fonts e têm licença OFL, que permite incluir as fontes dentro do app. Os arquivos `.ttf` e as licenças estão em `fontes/`.

Valores em dinheiro sempre usam **algarismos tabulares**, para que os números fiquem alinhados nas listas. Como a Chakra Petch não tem essa opção, o app usa a **Ravix Valores**, uma derivada dela com os dez dígitos na mesma largura (`fontes/RavixValores-*.ttf`). No site, use a Archivo com `font-variant-numeric: tabular-nums` em tabelas de valores.

### Escala no app (sp)

| Estilo | Fonte | Peso | Tamanho/linha |
|---|---|---|---|
| Valor destaque | Chakra Petch | 700 | 40/44 |
| Título de tela | Chakra Petch | 700 | 24/28 |
| Seção | Chakra Petch | 600 | 18/24 |
| Valor na lista | Chakra Petch | 600 | 16/20 |
| Corpo | Archivo | 400 | 16/24 |
| Rótulo | Archivo | 500 | 14/20 |
| Legenda | Archivo | 500 | 12/16 |
| Sobretítulo | Archivo | 600 | 11/16, maiúsculas, +10% de espaçamento |

### Escala no site (px)

| Estilo | Fonte | Peso | Desktop | Celular |
|---|---|---|---|---|
| Display | Chakra Petch | 700 | 64/66 | 40 |
| H1 | Chakra Petch | 700 | 44/48 | 32 |
| H2 | Chakra Petch | 700 | 32/36 | 26 |
| H3 | Chakra Petch | 600 | 22/28 | 22 |
| Lead | Archivo | 400 | 19/30 | 18 |
| Corpo | Archivo | 400 | 17/27 | 16 |
| Pequeno | Archivo | 500 | 14/20 | 14 |

---

## 4. Forma

### Cantos chanfrados

Botões, campos, cards e chips têm **cantos cortados a 45°**, e não cantos arredondados. É o mesmo corte das letras e do símbolo.

| Token | Tamanho | Onde |
|---|---|---|
| `chanfroP` | 4 dp | Chips, ícone de categoria |
| `chanfroM` | 8 dp | Botões, campos |
| `chanfroG` | 12 dp | Cards, FAB, card de resumo |

Como implementar:

- **Jetpack Compose:** `CutCornerShape(8.dp)`
- **Flutter:** `BeveledRectangleBorder(borderRadius: BorderRadius.circular(8))`
- **React Native:** use `react-native-svg` com um `Path` chanfrado, ou uma `View` com `clip-path` no web
- **SwiftUI:** um `Shape` customizado com oito pontos
- **Site:** classe `.rx-cut` em `tokens/ravix.css` (usa `clip-path`). Como o `clip-path` corta o `outline`, o foco usa sombra interna.

### Ícones

- Traço de 2 dp numa grade de 24 dp
- Pontas retas (`linecap: square`) e junções em ângulo (`linejoin: miter`)
- Sem cantos arredondados, para combinar com a fonte
- O fundo do ícone de categoria é um quadrado de 36 dp com chanfro de 4 dp e a cor da categoria a 15–25% de opacidade

### Espaçamento e tamanhos

Grade de 4 dp: 4, 8, 12, 16, 20, 24, 32, 40, 48, 64 e 96.

| Elemento | Tamanho |
|---|---|
| Área de toque mínima | 48 dp |
| Botão | 52 dp de altura |
| Campo | 56 dp de altura |
| Item de lista | 64 dp de altura |
| Margem lateral da tela | 16 dp (app), 24–28 px (site) |

### Movimento

| Token | Duração e curva | Uso |
|---|---|---|
| `rapido` | 120 ms `cubic-bezier(.2,.8,.2,1)` | Toque, troca de estado |
| `padrao` | 220 ms | Abrir e fechar folhas, trocar de mês |
| `enfase` | 420 ms | Seta subindo na abertura e na confirmação do gasto |

Respeite a opção de reduzir movimento do sistema.

---

## 5. App mobile

### Tela de registro

- O **valor** vem primeiro e em destaque (Chakra Petch 700), porque é o que a pessoa já sabe na hora de anotar.
- Depois vêm descrição, data e hora, forma de pagamento (Pix, Débito, Dinheiro, Voucher), categoria, subcategoria e tag opcional.
- O botão **Salvar gasto** é Floresta no tema claro e Menta no escuro, com chanfro de 8 dp.

### Tela de monitoramento

- **Card de resumo** no topo, em Floresta: o gasto do mês, uma barra do orçamento usado com o quanto resta, e a divisão por categoria.
- A lista fica agrupada por dia, com o **subtotal do dia** à direita do cabeçalho.
- Cada item mostra o ícone da categoria, a descrição, o detalhe (categoria · hora · tag) e o valor.
- O botão **Novo gasto** é Menta, com chanfro de 12 dp, no canto inferior direito.
- O rosa do app atual sai. Todo destaque usa a paleta da marca.

### Ícone e splash: Android

| Arquivo | Descrição |
|---|---|
| `mobile/android/res/mipmap-{mdpi…xxxhdpi}/ic_launcher.png` | Ícone legado quadrado (48 a 192 px) |
| `…/ic_launcher_round.png` | Ícone legado redondo |
| `…/ic_launcher_foreground.png` | Frente do ícone adaptativo (108 a 432 px, transparente) |
| `…/ic_launcher_monochrome.png` | Ícone temático (Android 13+) |
| `mipmap-anydpi-v26/ic_launcher.xml` e `ic_launcher_round.xml` | Ícone adaptativo com fundo `@color/ravix_floresta` |
| `res/drawable-*/splash_icon.png` | Ícone da splash do Android 12+ (288 dp) |
| `res/values/ravix_colors.xml` | Cores da marca como recursos |
| `res/values/ravix_splash.xml` | Tema da splash (requer `androidx.core:core-splashscreen`) |
| `play-store-icon-512.png` | Ícone da Play Store (512 px, sem transparência) |
| `play-feature-graphic-1024x500.png` | Imagem de destaque da Play Store |

No ícone adaptativo, o símbolo ocupa 40% da altura do quadro de 108 dp e fica dentro do círculo seguro de 66 dp.

Para instalar, copie a pasta `mobile/android/res/` por cima de `app/src/main/res/`.

### Ícone e splash: iOS

| Arquivo | Descrição |
|---|---|
| `mobile/ios/AppIcon.appiconset/` | Todos os tamanhos de iPhone e iPad, mais o de 1024 px para a App Store, sem transparência, com o `Contents.json` |
| `AppIcon-1024-dark.png` e `AppIcon-1024-tinted.png` | Variantes escura e tingida (iOS 18+). Adicione as duas pelo Xcode em Appearances |
| `mobile/splash/launch-*.png` | Telas de abertura em 1290×2796, 1179×2556 e 1080×2400 |
| `mobile/splash/launch-logo@3x.png` | Símbolo isolado para montar a Launch Screen no storyboard, sobre o Floresta |

Para instalar, arraste a pasta `AppIcon.appiconset` para o `Assets.xcassets` do projeto. O iOS aplica o arredondamento sozinho, por isso os PNGs são quadrados.

### Flutter

O app é feito em Flutter. O tema pronto está em [`flutter/`](flutter/README.md):

- `RavixTheme.light` e `RavixTheme.dark` (Material 3), com todos os componentes já chanfrados
- `RavixCutInputBorder` para os campos, com o rótulo flutuando dentro
- `context.ravix` para estados do orçamento, card de resumo, cores de gráfico e estilos de valor
- Widgets `RavixLogo`, `RavixSummaryCard`, `RavixExpenseTile`, `RavixDayHeader` e `RavixCategoryIcon`, e a função `formatBRL`
- Configuração do `flutter_launcher_icons` e do `flutter_native_splash` com as imagens da marca
- **Ravix Valores**: derivada da Chakra Petch com dígitos de largura igual, porque a Chakra Petch não tem algarismos tabulares e os valores nas listas ficariam desalinhados

---

## 6. Site

### Diretrizes

- O site apresenta o app e leva a pessoa para a loja. Ele usa as mesmas cores, fontes e chanfros do app.
- **Cabeçalho:** logotipo completo à esquerda, até três links e o botão **Baixar o app** (Floresta).
- **Primeira dobra:** título em Chakra Petch 700 ("Cada gasto anotado. Cada mês sob controle."), um parágrafo curto e os botões **Baixar para Android** e **Baixar para iPhone**. Ao lado, o card de resumo do mês mostra o produto sem precisar de um print de tela.
- Use os botões oficiais das lojas quando forem publicados, ao lado ou no lugar dos botões da marca.
- Largura máxima do conteúdo: 1120–1200 px, com grade de 12 colunas e espaçamento de 24 px.
- Os temas claro e escuro seguem os tokens da seção 2 via `prefers-color-scheme`.

### Arquivos

| Arquivo | Uso |
|---|---|
| `web/favicon.ico` | 16, 32 e 48 px, para navegadores antigos |
| `web/favicon.svg` | Favicon vetorial |
| `web/favicon-16x16.png`, `-32x32`, `-48x48` | PNGs avulsos |
| `web/apple-touch-icon.png` | 180 px, para atalho na tela inicial do iPhone |
| `web/icon-192.png`, `web/icon-512.png` | Ícones do PWA |
| `web/icon-maskable-512.png` | Ícone maskable do PWA (Android) |
| `web/site.webmanifest` | Manifesto com nome, cores e ícones |
| `web/og-image-1200x630.png` | Imagem de compartilhamento em redes e WhatsApp |
| `web/head-snippet.html` | Tags prontas para colar no `<head>` |
| `tokens/ravix.css` | Variáveis CSS, temas, chanfro e botão |

---

## 7. Como o Ravix fala

Frases curtas, números exatos e nenhum julgamento sobre o que a pessoa gastou.

| Situação | Evite | Use |
|---|---|---|
| Confirmação | Transação registrada com sucesso! | Gasto salvo. Restam R$ 338,11 no mês. |
| Alerta | Atenção! Você está gastando demais. | Você já usou 82% do orçamento de novembro. |
| Lista vazia | Nenhum dado encontrado. | Nenhum gasto neste mês. Toque em Novo gasto para anotar o primeiro. |
| Erro | Erro ao salvar. | Falta o valor. Preencha para salvar o gasto. |

- Diga "gasto", não "transação" ou "lançamento".
- Escreva valores como `R$ 1.234,56`, com espaço depois do R$.
- Escreva datas como "Quarta, 4 de novembro" nas listas e `04/11/2026` nos campos.

---

## 8. Estrutura de arquivos

```
brand/
├─ README.md
├─ ravix-identidade.html
├─ logo/
│  ├─ svg/   ravix-logo, -negativo, -floresta, -branco, -fundo-claro, -fundo-floresta, -fundo-petroleo
│  └─ png/   mesmas versões em 600w, 1200w, 2400w (fundos: 1600w)
├─ simbolo/
│  ├─ svg/   ravix-simbolo, -negativo, -floresta, -branco
│  └─ png/   256h, 512h, 1024h
├─ icone/    svg + png 1024 (Floresta, claro, Menta) para apresentações
├─ mobile/
│  ├─ android/
│  │  ├─ res/mipmap-{mdpi,hdpi,xhdpi,xxhdpi,xxxhdpi}/  ic_launcher, _round, _foreground, _monochrome
│  │  ├─ res/mipmap-anydpi-v26/                        ic_launcher.xml, ic_launcher_round.xml
│  │  ├─ res/drawable-*/splash_icon.png
│  │  ├─ res/values/ravix_colors.xml, ravix_splash.xml
│  │  ├─ play-store-icon-512.png
│  │  └─ play-feature-graphic-1024x500.png
│  ├─ ios/AppIcon.appiconset/   PNGs + Contents.json
│  └─ splash/                   launch-1290x2796, launch-1179x2556, launch-1080x2400, launch-logo@3x
├─ web/       favicon.ico/.svg/png, apple-touch-icon, icon-192/512, icon-maskable-512, og-image, site.webmanifest, head-snippet.html
├─ tokens/    tokens.json, ravix.css
├─ flutter/   tema Flutter (lib/theme, lib/widgets), assets, pubspec_ravix.yaml, app de exemplo
└─ fontes/    ChakraPetch-Medium/SemiBold/Bold.ttf, RavixValores-SemiBold/Bold.ttf, Archivo-Variable.ttf, OFL-*.txt
```

Os SVGs têm o texto convertido em contornos, então abrem iguais em qualquer computador. A geometria do símbolo foi gerada a partir dos contornos da Chakra Petch Bold.
