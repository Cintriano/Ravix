#!/usr/bin/env bash
# Gera ícone, abertura e marca do app a partir dos SVGs oficiais da marca
# (docs/identidade_visual/logos). Precisa do ImageMagick com librsvg.
#
# Uso (na pasta App_ravix): bash tool/gerar_icones.sh
#
# Medidas do guia mobile CAPRA:
# - Ícone adaptativo: camadas de 108 dp, marca em até 58% da largura. Os
#   arcos da marca passam do círculo seguro de 66 dp a 58%; com 54% cabem.
# - Abertura (Android 12+): área de 288 dp, marca dentro do círculo de 192 dp;
#   fundo no neutro do produto (#121416) nos dois temas.
set -euo pipefail

LOGOS=../docs/identidade_visual/logos
RES=android/app/src/main/res
FUNDO='#121416'
MARCA="$LOGOS/ravix-marca.svg"
ICONE="$LOGOS/ravix-icone-app.svg"

declare -A ESCALA=([mdpi]=1 [hdpi]=1.5 [xhdpi]=2 [xxhdpi]=3 [xxxhdpi]=4)

px() { python3 -c "print(round($1 * $2))"; }

# Marca centralizada numa tela transparente: $1 svg, $2 marca px, $3 tela px,
# $4 saída, $5 cor opcional (silhueta numa cor só).
marca_em_tela() {
  local cor=()
  if [[ -n "${5:-}" ]]; then cor=(-fill "$5" -colorize 100); fi
  magick -background none -density 1200 "$1" -resize "${2}x${2}" "${cor[@]}" \
    -gravity center -extent "${3}x${3}" -strip "PNG32:$4"
}

for d in "${!ESCALA[@]}"; do
  e=${ESCALA[$d]}
  mkdir -p "$RES/mipmap-$d" "$RES/drawable-$d"

  camada=$(px 108 "$e")
  marca=$(px 108*0.54 "$e")
  marca_em_tela "$MARCA" "$marca" "$camada" "$RES/mipmap-$d/ic_launcher_foreground.png"
  marca_em_tela "$MARCA" "$marca" "$camada" "$RES/mipmap-$d/ic_launcher_monochrome.png" white

  legado=$(px 48 "$e")
  magick -background none -density 600 "$ICONE" -resize "${legado}x${legado}" \
    -strip "PNG32:$RES/mipmap-$d/ic_launcher.png"

  marca_em_tela "$MARCA" "$(px 288*0.58 "$e")" "$(px 288 "$e")" \
    "$RES/drawable-$d/abertura_marca.png"
  marca_em_tela "$MARCA" "$(px 120 "$e")" "$(px 120 "$e")" \
    "$RES/drawable-$d/abertura_marca_legado.png"
done

# Marca para a tela de bloqueio (96 dp), em 1x, 2x e 3x.
mkdir -p assets/marca/2.0x assets/marca/3.0x
marca_em_tela "$MARCA" 96 96 assets/marca/ravix-marca.png
marca_em_tela "$MARCA" 192 192 assets/marca/2.0x/ravix-marca.png
marca_em_tela "$MARCA" 288 288 assets/marca/3.0x/ravix-marca.png

echo "Ícones gerados. Fundo do ícone e da abertura: $FUNDO"
