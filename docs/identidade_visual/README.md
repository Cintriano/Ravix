# Ravix — Identidade visual

> Copiado do repositório da marca CAPRA (https://github.com/Cintriano/Capra, commit `9d5d188`, 24/10/2026).
> O Ravix é um produto com **logo filha** da CAPRA. Em caso de conflito, o manual de marca prevalece.

## Registro do produto

Linha do Ravix em `capra-logos-filhas/gerador/registro.csv`:

| Produto | Marca | Área | Neutro | Data | Observações |
| --- | --- | --- | --- | --- | --- |
| Ravix | R | financas | preto | 2026-10-10 | app de finanças |

- **Acento:** Finanças · Peach — `accentFinance` `#D7AFA3` (dark) / `#93503E` (light).
- **Neutro:** preto — fundo do ícone e da marca `#121416`.
- **Acento não é estado.** No Ravix, saldo negativo usa `danger` com o sinal "−", nunca Peach.
- **Dados sensíveis:** no modo sempre ligado (relógio), esconda os saldos.

## Tokens principais (dark first)

| Token | Dark | Light |
| --- | --- | --- |
| `background` | `#121416` | `#F3F5F6` |
| `surface` | `#181B1E` | `#FFFFFF` |
| `surfaceElevated` | `#202428` | `#E8ECEE` |
| `border` | `#2A3035` | `#D0D7DB` |
| `textPrimary` | `#E8ECEE` | `#121416` |
| `textSecondary` | `#AAB4B9` | `#55606A` |
| `accentFinance` (acento do Ravix) | `#D7AFA3` | `#93503E` |
| `success` (= `accentAutomation`) | `#9DBBAA` | `#45705A` |
| `warning` (= `accentInfra`) | `#D6C58F` | `#776220` |
| `danger` | `#E8877F` | `#B23A31` |

Raios: `radius-sm` 8 · `radius-md` 12 · `radius-lg` 16 · `radius-pill` 999. Tipografia: Inter. A lista completa (tipo, espaçamento, sombra, ícones, cores de dados e movimento) está em [`capra-tokens.json`](capra-tokens.json), que é a fonte única para gerar o tema Flutter (`capra-theme.dart`). Nenhum HEX dentro de componente.

## Conteúdo

| Arquivo | O que é |
| --- | --- |
| [`capra-identidade-visual-mobile.md`](capra-identidade-visual-mobile.md) | Guia da marca para apps mobile (Android, iOS, tablet, relógio): ícone, abertura, tema, componentes, lojas |
| [`capra-manual-de-marca-v1_6.md`](capra-manual-de-marca-v1_6.md) | Manual de marca CAPRA v1.6 completo (com figuras embutidas) |
| [`capra-tokens.json`](capra-tokens.json) | Design tokens |
| `logos/ravix-icone-app.svg` + PNG 1024/512/192/180 | Ícone de app (mestre 1024 × 1024, quadrado, sem cantos; cada sistema aplica a máscara) |
| `logos/ravix-icone-reduzido.svg` | Ícone abaixo de 32 px |
| `logos/ravix-favicon.svg` + PNG 48/32/16 | Favicon |
| `logos/ravix-marca.svg` | Marca sem fundo, só sobre o neutro preto |
| `logos/ravix-entrada.svg` | Entrada animada (0,8 s), regras na Parte 11 do manual |
| `fontes/Inter/` | Inter variável (normal e itálica) e licença OFL |

## Ícone no Android

Ícone adaptativo com camadas `background`, `foreground` e `monochrome`; camadas de 108 × 108 dp, marca dentro do círculo seguro de 66 dp, ocupando até 58% da largura (proposta). Detalhes na seção "Ícone de app" do guia mobile.

## Fora desta cópia

Ficaram só no repositório CAPRA: o kit de logos da marca-mãe, o alfabeto e o gerador de logos filhas (`capra-logos-filhas/`), as regras completas das logos filhas (`docs/08-logos-filhas.md`) e os guias para web, dashboards e TV.
