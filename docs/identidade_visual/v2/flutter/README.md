# Ravix: tema Flutter

Tema Material 3 com a identidade visual v2 do Ravix: cores, fontes, cantos chanfrados, componentes do monitoramento, ícone do app e splash.

Requer **Flutter 3.29 ou mais novo** (usa `CardThemeData`, `DialogThemeData` e `Color.withValues`).

> Este código não foi compilado: o Flutter não estava instalado na máquina onde ele foi escrito. Rode `flutter analyze` depois de copiar os arquivos.

## O que tem aqui

```
flutter/
├─ pubspec_ravix.yaml           trechos para juntar ao seu pubspec.yaml
├─ assets/
│  ├─ fonts/                    Chakra Petch, Archivo, Ravix Valores + licenças OFL
│  └─ brand/                    logo e símbolo (SVG) usados pelo app
│     ├─ icon/                  imagens de origem do ícone (flutter_launcher_icons)
│     └─ splash/                imagens de origem da splash (flutter_native_splash)
└─ lib/
   ├─ theme/
   │  ├─ ravix_theme.dart       RavixTheme.light / RavixTheme.dark (exporta os demais)
   │  ├─ ravix_colors.dart      paleta e ColorScheme claro/escuro
   │  ├─ ravix_typography.dart  famílias e escala de texto
   │  ├─ ravix_shapes.dart      chanfros e RavixCutInputBorder
   │  └─ ravix_tokens.dart      ThemeExtension (context.ravix)
   ├─ widgets/
   │  └─ ravix_brand.dart       RavixLogo, RavixSymbol, RavixSummaryCard, RavixExpenseTile,
   │                            RavixDayHeader, RavixCategoryIcon, formatBRL
   └─ ravix_preview.dart        app de exemplo com as duas telas
```

## Instalação

1. Copie `assets/` e `lib/theme/` e `lib/widgets/` para a raiz do projeto. Se já existir uma pasta `lib/widgets`, coloque o `ravix_brand.dart` dentro dela e ajuste o import do tema.
2. Junte os blocos de `pubspec_ravix.yaml` ao seu `pubspec.yaml` (dependências, `assets` e `fonts`).
3. Rode:
   ```
   flutter pub get
   dart run flutter_launcher_icons
   dart run flutter_native_splash:create
   ```
4. Aplique o tema:
   ```dart
   import 'theme/ravix_theme.dart';

   MaterialApp(
     theme: RavixTheme.light,
     darkTheme: RavixTheme.dark,
     themeMode: ThemeMode.system,
     // ...
   );
   ```
5. Para ver o resultado sem mexer nas telas atuais, rode `flutter run -t lib/ravix_preview.dart`.

Os ícones também já existem prontos em `brand/mobile/android/res` e `brand/mobile/ios`. Use **ou** os pacotes do passo 3 **ou** os arquivos prontos, não os dois.

## Uso

### Fontes

| Família | Uso | Onde aparece |
|---|---|---|
| `ChakraPetch` | Títulos e logotipo | `displaySmall` a `titleMedium`, título da AppBar |
| `Archivo` | Interface | Família padrão do tema: campos, listas, botões, rótulos |
| `RavixValores` | **Só valores em dinheiro** | `context.ravix.moneyHero` e `context.ravix.moneyList` |

A Chakra Petch tem dígitos de larguras diferentes e não tem a opção de algarismos tabulares. A **Ravix Valores** é uma derivada dela, permitida pela licença OFL e com outro nome, em que os dez dígitos têm a mesma largura. Assim os valores ficam alinhados nas listas.

### Valores

```dart
Text(formatBRL(119.9), style: context.ravix.moneyList)   // R$ 119,90
```

### Cantos chanfrados

```dart
Container(
  decoration: ShapeDecoration(
    color: Theme.of(context).colorScheme.surface,
    shape: RavixShapes.cut(RavixShapes.g),               // 4, 8 ou 12
  ),
)
```

Botões, campos, chips, cards, FAB, folhas, diálogos, snackbar e seletores de data e hora já vêm chanfrados pelo tema. Os campos usam o `RavixCutInputBorder`, com o rótulo flutuando dentro, como nas telas atuais.

### Cores que o ColorScheme não tem

```dart
final t = context.ravix;
t.budgetColor(0.82);   // atenção (#D9A441)
t.summaryBackground;   // Floresta, nos dois temas
t.chart;               // ordem das cores de categoria
```

### Ícones

Use as variantes **Sharp** do Material (`Icons.add_sharp`, `Icons.restaurant_sharp`...). Elas têm pontas retas e combinam com o desenho do símbolo. Para mais opções, o pacote `material_symbols_icons` tem o estilo `Symbols.*` com `MaterialSymbolStyle.sharp`.

### Logotipo

```dart
const RavixLogo(height: 28)                      // escolhe a versão pelo tema
const RavixLogo(tone: RavixLogoTone.negativo)    // sobre Floresta
```

Nunca escreva "Ravix" com a fonte para fazer o logotipo. O x com a seta só existe no SVG.

## Mapeamento da escala

| Estilo da marca | TextTheme | Fonte | sp |
|---|---|---|---|
| Valor destaque | `context.ravix.moneyHero` | Ravix Valores 700 | 40/44 |
| Título de tela | `headlineSmall` (AppBar) | Chakra Petch 700 | 24/28 |
| Seção | `titleMedium` | Chakra Petch 600 | 18/24 |
| Valor na lista | `context.ravix.moneyList` | Ravix Valores 600 | 16/20 |
| Corpo / campo | `bodyLarge` | Archivo 400 | 16/24 |
| Rótulo | `labelMedium` | Archivo 500 | 14/20 |
| Botão | `labelLarge` | Archivo 600 | 16/20 |
| Legenda | `bodySmall` | Archivo 500 | 12/16 |
| Sobretítulo / cabeçalho de dia | `context.ravix.overline` | Archivo 600 | 11.5/16, maiúsculas |
