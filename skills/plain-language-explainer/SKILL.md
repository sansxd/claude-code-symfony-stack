---
name: plain-language-explainer
description: "Úsalo cuando el usuario pida explicar un bug, un diagnóstico, un cambio o una decisión técnica 'en lenguaje no técnico', 'en simple', 'para el cliente', 'para el jefe', 'para responder el ticket' o 'como si no supiera programar'."
---

# Explicar en simple

Traduce un hallazgo técnico a algo que una persona de negocio entiende y puede usar para decidir. El lector no sabe qué es una base de datos, una tabla, un join ni un deploy, y no le hace falta saberlo.

## Formato de la respuesta

Escríbela siempre con estas secciones, en este orden y con estos títulos:

1. **En una frase:** qué está pasando, sin jerga y en 25 palabras como máximo.
2. **Lo que se ve:** el síntoma tal como lo vive el usuario ("el reporte muestra la columna vacía").
3. **Por qué pasa:** la causa, con una analogía cotidiana (fichas, archivadores, listas, formularios en papel). Usa 2 a 4 frases.
4. **A quién afecta:** cuántos casos y si puede volver a ocurrir, con números concretos cuando los haya.
5. **Qué se puede hacer:** 1 a 3 opciones. Para cada una, di qué arregla, cuánto demora más o menos y qué no arregla.
6. **Recomendación:** cuál opción y por qué, en una o dos frases.

## Cómo traducir los términos

| Término técnico | Cómo decirlo |
|---|---|
| base de datos, tabla | el sistema donde se guarda la información, la ficha, el registro |
| columna o campo NULL | el dato quedó en blanco |
| join, relación, FK | el cruce o vínculo entre dos fichas |
| query, SQL | la búsqueda que hace el sistema para armar el reporte |
| deploy, pasar a producción | publicar el arreglo en el sistema que usan ustedes |
| migración, UPDATE | corrección directa de los datos guardados |
| bug | error del sistema |
| caché | copia guardada para responder más rápido |

Los nombres de usuario, los números de compra y los nombres de pantalla se dejan tal cual: el lector los reconoce.

## Errores comunes

- **Repetir el diagnóstico técnico con otras palabras.** El lector no necesita saber qué archivo ni qué línea; necesita entender qué pasa y qué decidir.
- **Echarle la culpa a una persona o a un equipo.** Habla del sistema y del dato, no de quién lo cargó.
- **Prometer plazos exactos.** Usa rangos ("hoy mismo", "en el próximo paso a producción").
- **Exagerar o minimizar.** Si es un solo caso, dilo; si se va a repetir, dilo también.
