# Ravix: movimento

Animações da identidade v2. Um gesto só: **a haste desce, a seta sobe**. Tudo deriva dele.

Regras (as mesmas da marca): sem sombra, brilho, quique ou elástico. Só deslocamento, opacidade e cor. Curva única `cubic-bezier(.2, .8, .2, 1)`. Respeite "reduzir movimento": as animações viram troca imediata de estado.

| Token | Tempo | Uso |
|---|---|---|
| `rapido` | 120 ms | Toque (aperta a 97%), troca de rótulo |
| `padrao` | 220 ms | Entrada de linhas, aviso, troca de mês, cor da barra |
| `enfase` | 420 ms | Seta na confirmação, barra do orçamento, contagem de valores |
| `abertura` | 900 ms | Só a seta, na abertura |
| `stagger` | 40 ms | Entre linhas de uma lista (70 ms entre letras do logotipo) |

## Linha do tempo da abertura

| ms | O que acontece |
|---|---|
| 0 / 90 | As duas peças da haste descem pelo eixo (420 ms) |
| 240 | A seta sobe pelo próprio eixo, nascendo da linha de base (900 ms) |
| 520 + 70·n | As letras R, a, v, i sobem da linha de base (560 ms cada) |

## Arquivos

| Pasta ou arquivo | O que é |
|---|---|
| `ravix-motion.html` | Demonstração: abertura, splash, carregando, gasto salvo, orçamento, lista e gráficos. Tem botões de tema e de "reduzir movimento" |
| `ravix-motion.css` | Keyframes e classes para o site (`.rxm-play`, `.rxm-row`, `.rxm-bar`...). Usa `tokens/ravix.css` |
| `export/*.mp4`, `*.gif` | Abertura sobre Floresta e sobre Névoa (1920×1080), splash (1080×1920) e laço de carregamento (GIF 360×360) |
| `../flutter/lib/animations/` | Widgets Flutter, abaixo |

## Flutter

Copie `lib/animations/` junto com `lib/theme/` e `lib/widgets/`. Não precisa de pacote novo.

| Widget | Uso |
|---|---|
| `RavixMark.logo` / `RavixMark.symbol` | Marca desenhada por vetores, com `RavixMarkMotion.intro`, `confirm` ou `loop`. `markKey.currentState!.replay()` repete a confirmação |
| `RavixCountUp` | Valor em dinheiro que conta até o novo valor |
| `RavixBudgetBar` | Barra do orçamento com cor por estado (80% e 100%) |
| `RavixEnter` | Entrada de linha de lista (`index` define a defasagem; `fromTop` para gasto novo) |
| `RavixPress` | Toque do botão |
| `RavixMonthSwitcher` | Troca de mês |

```dart
// Splash: abre e segue para a home
RavixMark.logo(height: 56, tone: RavixLogoTone.negativo, onCompleted: goHome)

// Gasto salvo
final mark = GlobalKey<RavixMarkState>();
RavixMark.symbol(key: mark, height: 22, motion: RavixMarkMotion.confirm);
// ao salvar: mark.currentState!.replay();
```

> Este código não foi compilado: o Flutter não está instalado nesta máquina. Rode `flutter analyze` depois de copiar. A geometria e os tempos são os mesmos do CSS, que foi conferido no navegador.

## Regerar os vídeos

Os quadros vêm de `export/_frame.html`, que congela as animações CSS em cada instante (`at(ms)`). Basta capturar 30 quadros por segundo e juntar com o ffmpeg.
