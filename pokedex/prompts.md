## Modificación manual colaborativa
El script original forzaba a usar el ID numérico y devolvía el texto en crudo.
**Corrección aplicada:** 
Se quitó la expresión regular de solo números y se agregó `tr 'A-Z' 'a-z'` para permitir buscar por nombre. La salida final de `jq` se modificó para separar los datos por tabulaciones (`\t`) y se conectó con `awk` usando `printf` para generar una tabla alineada.
