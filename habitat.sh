
#!/bin/bash
#
# pokemon.sh - Consulta el id, nombre y habitat de un pokemon usando la PokeAPI
#
# Uso: ./pokemon.sh <nombre_pokemon>
#
# Requiere: curl, jq
 
set -euo pipefail
 
BASE_URL="https://pokeapi.co/api/v2"
 
# --- Validar argumento ---
if [ $# -eq 0 ]; then
    echo "Error: se necesita un argumento con el nombre del pokemon."
    echo "Uso: $0 <nombre_pokemon>"
    exit 1
fi
 
# Convertir a minúsculas
POKEMON_NAME=$(echo "$1" | tr '[:upper:]' '[:lower:]')
 
# --- Llamada al endpoint /pokemon/{name} ---
POKEMON_HTTP_CODE=$(curl -s -o /tmp/pokemon_response.json -w "%{http_code}" \
    "${BASE_URL}/pokemon/${POKEMON_NAME}")
 
if [ "$POKEMON_HTTP_CODE" -eq 404 ]; then
    echo "Error: el pokemon '${POKEMON_NAME}' no fue encontrado."
    rm -f /tmp/pokemon_response.json
    exit 1
elif [ "$POKEMON_HTTP_CODE" -ne 200 ]; then
    echo "Error: la API respondió con el código HTTP ${POKEMON_HTTP_CODE}."
    rm -f /tmp/pokemon_response.json
    exit 1
fi
 
POKEMON_ID=$(jq -r '.id' /tmp/pokemon_response.json)
POKEMON_NAME_RESULT=$(jq -r '.name' /tmp/pokemon_response.json)
rm -f /tmp/pokemon_response.json
 
# --- Llamada al endpoint /pokemon-species/{name} ---
SPECIES_HTTP_CODE=$(curl -s -o /tmp/species_response.json -w "%{http_code}" \
    "${BASE_URL}/pokemon-species/${POKEMON_NAME}")
 
if [ "$SPECIES_HTTP_CODE" -eq 404 ]; then
    echo "Error: el pokemon '${POKEMON_NAME}' no fue encontrado."
    rm -f /tmp/species_response.json
    exit 1
elif [ "$SPECIES_HTTP_CODE" -ne 200 ]; then
    echo "Error: la API respondió con el código HTTP ${SPECIES_HTTP_CODE}."
    rm -f /tmp/species_response.json
    exit 1
fi
 
HABITAT=$(jq -r '.habitat.name // empty' /tmp/species_response.json)
rm -f /tmp/species_response.json
 
# --- Imprimir resultado ---
echo "id:${POKEMON_ID}"
echo "name:${POKEMON_NAME_RESULT}"
 
if [ -z "$HABITAT" ]; then
    echo "El habitat no esta disponible para este pokemon."
else
    echo "habitat:${HABITAT}"
fi
