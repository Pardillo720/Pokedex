#!/bin/bash
if [ -z "$1" ]; then
  echo "Usage: $0 <pokemon_name>"; exit 1
fi

target=$(echo "$1" | tr 'A-Z' 'a-z')
url="https://pokeapi.co/api/v2/pokemon/$target"

response=$(curl -s -w '\n%{http_code}' "$url")
status_code=$(echo "$response" | tail -n 1)
json_data=$(echo "$response" | sed '$d')

if [ "$status_code" != "200" ]; then
  echo "Error 404: Pokemon '$target' not found."
  exit 1
fi

echo "$json_data" | jq -r '
  def bmi: (.weight / 10) / ((.height / 10) * (.height / 10));
  "--- POKEMON PROFILE ---",
  "ID:      #\(.id)",
  "Name:    \(.name | ascii_upcase)",
  "Height:  \(.height / 10) m",
  "Weight:  \(.weight / 10) kg",
  "BMI:     \(bmi | round)",
  "Types:   \([.types[].type.name] | join(", "))"
'

