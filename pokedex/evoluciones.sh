#!/usr/bin/env bash
#
# pokevo.sh - Muestra evoluciones, preevoluciones y metodo de evolucion
#             de un Pokemon a partir de su numero en la Pokedex.
#
# Uso: ./pokevo.sh <numero_pokedex>
# Requiere: curl, jq
#
set -euo pipefail

API="https://pokeapi.co/api/v2"

# ---------- validacion de argumentos ----------
if [[ $# -ne 1 ]]; then
  echo "Uso: $(basename "$0") <numero_pokedex>" >&2
  exit 1
fi

DEX="$1"
if ! [[ "$DEX" =~ ^[0-9]+$ ]] || [[ "$DEX" -lt 1 ]]; then
  echo "Error: '$DEX' no es un numero de Pokedex valido." >&2
  exit 1
fi

for bin in curl jq; do
  command -v "$bin" >/dev/null 2>&1 || { echo "Error: falta '$bin'." >&2; exit 1; }
done

# ---------- helper de red ----------
fetch() {
  local url="$1" resp code body
  resp=$(curl -sS -L -w $'\n%{http_code}' "$url") || {
    echo "Error de red consultando $url" >&2; exit 2; }
  code="${resp##*$'\n'}"
  body="${resp%$'\n'*}"
  if [[ "$code" != "200" ]]; then
    echo "Error HTTP $code consultando $url" >&2
    exit 3
  fi
  printf '%s' "$body"
}

# ---------- 1) Pokemon -> 2) especie -> 3) cadena evolutiva ----------
POKEMON=$(fetch "$API/pokemon/$DEX")
POKE_ID=$(jq -r '.id'          <<<"$POKEMON")
POKE_NAME=$(jq -r '.name'      <<<"$POKEMON")
SPECIES_URL=$(jq -r '.species.url' <<<"$POKEMON")

SPECIES=$(fetch "$SPECIES_URL")
SPECIES_NAME=$(jq -r '.name' <<<"$SPECIES")
CHAIN_URL=$(jq -r '.evolution_chain.url // empty' <<<"$SPECIES")

if [[ -z "$CHAIN_URL" ]]; then
  echo "id:$POKE_ID name:$POKE_NAME evolucion:ninguna preevolucion:ninguna metodo_de_evolucion:ninguno"
  exit 0
fi

CHAIN=$(fetch "$CHAIN_URL")

# ---------- 4) procesamiento con jq ----------
jq -r --arg id "$POKE_ID" --arg name "$POKE_NAME" --arg sp "$SPECIES_NAME" '

  # Traduce un objeto evolution_details a texto legible
  def detalle:
    [ (if (.min_level|type)        == "number" then "nivel \(.min_level)"                       else empty end),
      (if (.item|type)             == "object" then "usando \(.item.name)"                      else empty end),
      (if (.held_item|type)        == "object" then "equipando \(.held_item.name)"              else empty end),
      (if (.known_move|type)       == "object" then "conociendo \(.known_move.name)"            else empty end),
      (if (.known_move_type|type)  == "object" then "con movimiento tipo \(.known_move_type.name)" else empty end),
      (if (.min_happiness|type)    == "number" then "felicidad >= \(.min_happiness)"            else empty end),
      (if (.min_affection|type)    == "number" then "afecto >= \(.min_affection)"               else empty end),
      (if (.min_beauty|type)       == "number" then "belleza >= \(.min_beauty)"                 else empty end),
      (if ((.time_of_day // "") != "")         then "de \(.time_of_day)"                        else empty end),
      (if (.location|type)         == "object" then "en \(.location.name)"                      else empty end),
      (if (.party_species|type)    == "object" then "con \(.party_species.name) en el equipo"   else empty end),
      (if (.party_type|type)       == "object" then "con un tipo \(.party_type.name) en el equipo" else empty end),
      (if (.trade_species|type)    == "object" then "a cambio de \(.trade_species.name)"        else empty end),
      (if (.gender|type)           == "number" then (if .gender == 1 then "siendo hembra" else "siendo macho" end) else empty end),
      (if (.relative_physical_stats|type) == "number" then "stats fisicos (\(.relative_physical_stats))" else empty end),
      (if .needs_overworld_rain              then "con lluvia"                                  else empty end),
      (if .turn_upside_down                  then "con la consola boca abajo"                   else empty end)
    ] as $extras
    | (.trigger.name // "desconocido") as $trigger
    | if ($extras|length) == 0 then $trigger
      else "\($trigger): \($extras | join(", "))" end;

  # Une todos los detalles alternativos de una transicion
  def metodos:
    if (. == null) or (length == 0) then "ninguno"
    else [ .[] | detalle ] | join(" | ") end;

  # Aplana la cadena en {name, padre, detalles}
  def aplanar($padre):
    . as $n
    | { name: $n.species.name, padre: $padre, detalles: $n.evolution_details },
      ( $n.evolves_to[] | aplanar($n.species.name) );

  [ .chain | aplanar(null) ] as $nodos

  # El nodo de la cadena se identifica por el nombre de la especie
  | ( $nodos[] | select(.name == $sp) ) as $actual
  | ( $actual.padre // "ninguna" )                       as $pre
  | [ $nodos[] | select(.padre == $sp) ]                 as $hijos

  | if ($hijos | length) == 0 then
      "id:\($id) name:\($name) evolucion:ninguna preevolucion:\($pre) metodo_de_evolucion:ninguno"
    else
      $hijos[]
      | "id:\($id) name:\($name) evolucion:\(.name) preevolucion:\($pre) metodo_de_evolucion:\(.detalles | metodos)"
    end
' <<<"$CHAIN"
