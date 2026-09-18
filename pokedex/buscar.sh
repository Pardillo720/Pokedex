#!/bin/bash
if [ "$1" == "--quiz" ]; then
  echo "=== ¿QUÉ POKÉMON ERES SEGÚN TU PERSONALIDAD? ==="
  echo "1. ¿Cuál es tu plan ideal para un fin de semana?"
  echo "   a) Ir a la playa o nadar"
  echo "   b) Hacer una fogata o estar bajo el sol"
  echo "   c) Quedarme en casa con tecnología/videojuegos"
  echo "   d) Relajarme en un bosque o parque"
  echo "   e) Leer sobre misterios, el espacio o terror"
  read -p "Elige una opción (a/b/c/d/e) > " q1

  tipo="normal"
  case "$q1" in
    a|A) tipo="water" ;; b|B) tipo="fire" ;; c|C) tipo="electric" ;; d|D) tipo="grass" ;; e|E) tipo="ghost" ;;
  esac

  echo ""
  echo "2. Cuando te enfrentas a un problema difícil, ¿cómo reaccionas?"
  echo "   a) Voy de frente y lo ataco con fuerza (Ataque)"
  echo "   b) Mantengo la calma, me protejo y resisto (Defensa)"
  echo "   c) Pienso rápido y actúo antes de que empeore (Velocidad)"
  echo "   d) Confío en mi paciencia y energía inagotable (HP - Vida)"
  read -p "Elige una opción (a/b/c/d) > " q2

  col=3
  case "$q2" in
    a|A) col=3 ;; b|B) col=4 ;; c|C) col=5 ;; d|D) col=6 ;;
  esac

  echo ""
  echo "Analizando tu alma Pokémon en los archivos locales..."
  
  match=$(jq -r '[.name, ([.types[].type.name] | join("-")), .stats[1].base_stat, .stats[2].base_stat, .stats[5].base_stat, .stats[0].base_stat] | @csv' data/*.json | tr -d '"' | awk -F',' -v t="$tipo" 'tolower($2) ~ t' | sort -t',' -k"$col" -n -r | head -n 1)

  if [ -z "$match" ]; then
     echo "¡Eres tan único que no encontramos un match exacto! Probablemente seas un Mew."
  else
     nombre=$(echo "$match" | awk -F',' '{print $1}')
     val=$(echo "$match" | awk -F',' -v c="$col" '{print $c}')
     echo "⭐ ¡Felicidades! Tu personalidad resuena con: $(echo $nombre | tr 'a-z' 'A-Z') ⭐"
     echo "Comparten el tipo ($tipo) y dominan en su estilo de vida con un puntaje de $val."
  fi
  exit 0
fi

tipo=""; orden="id"
for arg in "$@"; do
  case "$arg" in
    --peso) orden="peso" ;;
    *) tipo=$(echo "$arg" | tr 'A-Z' 'a-z') ;;
  esac
done

echo "ID,NOMBRE,PESO_KG,TIPOS"
dataset=$(jq -r '[.id, .name, (.weight/10), ([.types[].type.name] | join("-"))] | @csv' data/*.json | tr -d '"')

if [ -n "$tipo" ]; then dataset=$(echo "$dataset" | awk -F',' -v t="$tipo" 'tolower($4) ~ t'); fi
if [ "$orden" == "peso" ]; then echo "$dataset" | sort -t',' -k3 -n -r; else echo "$dataset" | sort -t',' -k1 -n; fi

