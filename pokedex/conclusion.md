# Análisis de la Trayectoria de Datos

1. **Extracción (La Red al Script):** Los datos inician como JSON en los servidores de PokeAPI y se extraen con `curl`. Para verificar la descarga pura en la terminal, se usa: `curl -s https://pokeapi.co/api/v2/pokemon/pikachu | head -n 20`.
2. **Almacenamiento (Memoria a Disco):** Los datos se guardan en `data/` como una caché local de 151 archivos. Para confirmar que ningún archivo se descargó corrupto o vacío, se ejecuta: `find data -size 0`.
3. **Transformación (Disco a Pantalla):** `jq` extrae campos específicos (incluyendo ramas anidadas como `.stats[]`) y los aplana a formato CSV. Luego, `awk` y `sort` manipulan el texto para encontrar coincidencias de personalidad o pesos. Para auditar la estructura final extraída por jq antes del filtro, se usa: `./buscar.sh --peso | head -n 5`.

