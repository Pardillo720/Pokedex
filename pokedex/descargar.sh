#!/bin/bash
LIMIT=151
mkdir -p data

pokemon_list=$(curl -s "https://pokeapi.co/api/v2/pokemon?limit=$LIMIT" | jq -r '.results[].name')
counter=0

for name in $pokemon_list; do
  ((counter++))
  file="data/$name.json"
  
  if [ -s "$file" ]; then
    echo "[$counter/$LIMIT] $name (cached)"
    continue
  fi
  
  echo "[$counter/$LIMIT] Downloading $name..."
  curl -s -f "https://pokeapi.co/api/v2/pokemon/$name" -o "$file" || \
  { sleep 1; curl -s -f "https://pokeapi.co/api/v2/pokemon/$name" -o "$file" || rm -f "$file"; }
  sleep 0.2
done
echo "Download complete! $(ls data | wc -l) files inside data/"

