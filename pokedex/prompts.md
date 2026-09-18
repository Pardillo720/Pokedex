## Prompt 1: pokedex.sh
Bash script `pokedex.sh`. Takes one argument (pokemon name). 
Fetches data from https://pokeapi.co/api/v2/pokemon/{name} using curl.
Uses jq to print: id, name, height, weight, and types.
Also, I need jq to calculate the BMI. Formula: weight in kg divided by height in meters squared. 
If HTTP 404, print "Error 404" and exit with code 1. One file.

### Resultado
El cálculo del BMI fallaba con `Cannot divide by zero` por los paréntesis en la fórmula matemática.

### Corrección
"I got a math error in the jq filter. Write a custom `def bmi:` function inside the jq string to handle the division carefully with the conversion factors (/10)."

### Me quedé con
La lógica matemática de `def bmi:` generada por la IA y la extracción segura del código 404.


## Prompt Especial: buscar.sh (Modo Test de Personalidad)
"Modifica el script `buscar.sh`. Si el argumento es `--quiz`, haz un menú interactivo. 
Haz 2 preguntas. La primera mapea opciones (playa, bosque) a tipos (water, grass). La segunda mapea reacciones (fuerza, resistencia) a los stats de PokeAPI (attack, defense).
Usa `jq` para extraer .name, tipos y los stats base (.stats[1].base_stat) de `data/*.json`. 
Filtra con `awk` por el tipo elegido y usa `sort` para encontrar el stat más alto."

### Resultado
El script funcionó, pero `jq` usando `@csv` imprimía comillas dobles, lo que hacía fallar el filtro de `awk`.

### Corrección
"La salida de jq con `@csv` incluye comillas. ¿Cómo puedo quitarlas antes de pasarlas a awk?" (IA sugirió `tr -d '"'`).

### Me quedé con
La estructura completa de navegación de JSON usando `.stats[X].base_stat`. Demuestra un mejor uso de `jq`.

