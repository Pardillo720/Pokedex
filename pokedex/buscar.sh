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

  # CHANGE: added third question (tiebreaker) that influences the match.
  # It picks a secondary type used to narrow down the pool of candidates.
  echo ""
  echo "3. En un grupo de amigos, ¿qué rol sueles tomar?"
  echo "   a) El líder que toma la iniciativa"
  echo "   b) El que cuida y protege a los demás"
  echo "   c) El bromista impredecible"
  echo "   d) El tranquilo que observa desde lejos"
  read -p "Elige una opción (a/b/c/d) > " q3
 
  # CHANGE: q3 maps to a secondary type ("tipo2") used to refine the match below.
  tipo2="normal"
  case "$q3" in
    a|A) tipo2="fighting" ;; b|B) tipo2="steel" ;; c|C) tipo2="dark" ;; d|D) tipo2="psychic" ;;
  esac
 
  echo ""
  echo "Analizando tu alma Pokémon en los archivos locales..."
 
  # CHANGE: build the full ranked list (same query/sort as before) so we can
  # try to narrow it down using tipo2, and still have a runner-up available.
  matches=$(jq -r '[.name, ([.types[].type.name] | join("-")), .stats[1].base_stat, .stats[2].base_stat, .stats[5].base_stat, .stats[0].base_stat] | @csv' data/*.json | tr -d '"' | awk -F',' -v t="$tipo" 'tolower($2) ~ t' | sort -t',' -k"$col" -n -r)
 
  # CHANGE: try to refine using tipo2 (Q3's answer) — prefer Pokémon whose
  # types also match the secondary type from question 3.
  refined=$(echo "$matches" | awk -F',' -v t2="$tipo2" 'tolower($2) ~ t2')
 
  if [ -n "$refined" ]; then
    # A refined match exists: use it as the primary result.
    match=$(echo "$refined" | sed -n '1p')
    runner_up=$(echo "$matches" | sed -n '1p')
  else
    # No overlap with tipo2: fall back to the original tipo-only ranking.
    match=$(echo "$matches" | sed -n '1p')
    runner_up=$(echo "$matches" | sed -n '2p')
  fi
 
  if [ -z "$match" ]; then
     echo "¡Eres tan único que no encontramos un match exacto! Probablemente seas un Mew."
  else
     nombre=$(echo "$match" | awk -F',' '{print $1}')
     val=$(echo "$match" | awk -F',' -v c="$col" '{print $c}')
     echo "⭐ ¡Felicidades! Tu personalidad resuena con: $(echo $nombre | tr 'a-z' 'A-Z') ⭐"
     echo "Comparten el tipo ($tipo) y dominan en su estilo de vida con un puntaje de $val."

     # CHANGE: result reasoning — explains why this Pokémon was chosen.
     echo ""
     echo "🧠 Por qué este resultado:"
     echo "  - Tu tipo principal según la pregunta 1 fue: $tipo"
     echo "  - Tu estadística dominante según la pregunta 2 fue la columna $col (mayor puntaje: $val)"
     if [ -n "$refined" ]; then
       echo "  - Tu respuesta de la pregunta 3 (tipo secundario: $tipo2) coincidió con este Pokémon, afinando el resultado"
     else
       echo "  - Tu respuesta de la pregunta 3 (tipo secundario: $tipo2) no tuvo coincidencias, así que se usó el mejor match por tipo y estadística"
     fi
 
     # CHANGE: show runner-up (name + stat value) as a close second.
     if [ -n "$runner_up" ]; then
        nombre2=$(echo "$runner_up" | awk -F',' '{print $1}')
        val2=$(echo "$runner_up" | awk -F',' -v c="$col" '{print $c}')
        echo ""
        echo "🥈 Muy de cerca también podrías ser: $(echo $nombre2 | tr 'a-z' 'A-Z') (puntaje: $val2)"
     fi 
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
