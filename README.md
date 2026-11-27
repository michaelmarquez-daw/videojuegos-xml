# Catálogo de videojuegos en XML

Catálogo de 16 videojuegos guardado en XML, validado con DTD y con XSD, consultado con XPath y transformado con XSLT en una página HTML y en un fichero JSON. El JSON lo usa una pequeña página web con filtros hecha en JavaScript, así que se ve el recorrido completo XML → JSON → web.

![Catálogo generado con XSLT](docs/captura.png)

## Qué practica

Módulo de **Lenguajes de marcas y sistemas de gestión de información** (1º de DAW):

- XML bien formado y válido: elementos frente a atributos, DOCTYPE.
- DTD: `ELEMENT`, `ATTLIST`, `ID`, atributos enumerados y `#FIXED`, cardinalidad `+` y `?`.
- XSD: tipos simples y complejos, `simpleContent` con atributos, restricciones (`enumeration`, `pattern`, `minInclusive`/`maxInclusive`, `fractionDigits`, `maxLength`), `minOccurs`/`maxOccurs`, `xs:key` y `xs:unique` (ids y títulos únicos, y plataformas o géneros sin repetir dentro de un juego).
- XPath 1.0: predicados, funciones (`count`, `sum`, `not`, `string`, `boolean`) y tipos de resultado.
- XSLT 1.0: `xsl:for-each`, `xsl:sort`, `xsl:if`, `xsl:choose`, `xsl:value-of`, plantillas con nombre y parámetros, agrupación con `xsl:key` (método Muenchian), `format-number`.
- JSON y JSON Schema.
- Java con las APIs estándar de XML (`javax.xml.validation`, DOM, `javax.xml.xpath`, `javax.xml.transform`).
- JavaScript: `fetch`, `async/await`, `filter`, `sort`, `<template>`.

## Tecnologías

XML, DTD, XSD, XPath, XSLT 1.0, JSON, JSON Schema, Java 21 (solo JDK), HTML5, CSS3 y JavaScript sin librerías.

## Cómo ejecutarlo (Windows)

Hace falta el JDK 21 o superior. No hace falta Maven ni ninguna librería.

1. Abre una terminal (cmd, PowerShell o la de VS Code) en la carpeta del proyecto.
2. Comprueba Java:

   ```
   java -version
   ```

3. Ejecuta la herramienta. Java 21 compila y ejecuta el fichero directamente:

   ```
   java herramientas/Procesar.java
   ```

   Valida `datos/catalogo.xml` con la DTD y con el XSD, muestra las 10 consultas XPath y genera `salida/catalogo.html` y `datos/catalogo.json`.

4. Para ver cómo se informa de los errores, prueba con el XML que tiene fallos a propósito (pasa la DTD pero no el XSD):

   ```
   java herramientas/Procesar.java pruebas/catalogo-con-errores.xml
   ```

   Con un XML que no sea `datos/catalogo.xml` solo se valida y se consulta: no se regeneran el HTML ni el JSON.

5. Para abrir las páginas hace falta un servidor local, porque `fetch` no funciona abriendo el HTML con doble clic. Cualquiera de estas opciones vale:
   - VS Code con la extensión Live Server: clic derecho en `web/index.html` y "Open with Live Server".
   - PHP de XAMPP desde la carpeta del proyecto: `C:\xampp\php\php.exe -S localhost:8000` y abrir `http://localhost:8000/web/index.html`.
   - Copiar la carpeta a `C:\xampp\htdocs\` y abrir `http://localhost/videojuegos-xml/web/index.html`.

   El catálogo generado con XSLT está en `salida/catalogo.html`.

6. Para comprobar el JSON con su JSON Schema, pega `datos/catalogo.schema.json` y `datos/catalogo.json` en https://www.jsonschemavalidator.net (draft 2020-12). Si tienes Python con la librería `jsonschema` (`pip install jsonschema`), también vale esta línea desde la carpeta del proyecto:

   ```
   python -c "import json, jsonschema; jsonschema.validate(json.load(open('datos/catalogo.json', encoding='utf-8')), json.load(open('datos/catalogo.schema.json', encoding='utf-8'))); print('JSON valido')"
   ```

Si en la consola de Git Bash salen mal las tildes, añade `-Dstdout.encoding=UTF-8` después de `java`.

## Estructura

```
videojuegos-xml/
├── datos/
│   ├── catalogo.xml           datos originales
│   ├── catalogo.dtd
│   ├── catalogo.xsd
│   ├── catalogo.json          generado con XSLT
│   └── catalogo.schema.json   JSON Schema del JSON
├── xslt/
│   ├── catalogo-a-html.xsl
│   └── catalogo-a-json.xsl
├── xpath/
│   └── consultas-xpath.md     las 10 consultas con su resultado
├── herramientas/
│   └── Procesar.java          valida, consulta y transforma
├── salida/
│   └── catalogo.html          generado con XSLT
├── web/
│   ├── index.html             lista con filtros que lee el JSON
│   └── app.js
├── css/
│   └── estilos.css            compartido por las dos páginas
├── pruebas/
│   └── catalogo-con-errores.xml
└── docs/
    └── captura.png
```

`salida/catalogo.html` y `datos/catalogo.json` se generan, pero los dejo en el repositorio para que la web funcione sin tener que ejecutar nada antes.

## Decisiones técnicas

- **DTD y XSD a la vez.** La DTD solo comprueba la estructura y no sabe de tipos: acepta un precio con tres decimales o una plataforma inventada. El fichero de `pruebas/` lo demuestra: pasa la DTD y el XSD saca 13 mensajes que corresponden a 7 fallos (Xerces da dos mensajes por cada valor incorrecto: uno por la restricción y otro por el atributo o elemento).
- **Atributos para metadatos y elementos para contenido.** `id`, `pegi`, `pais` y `moneda` son atributos porque son valores cortos que describen al dato. Título, plataformas o géneros son elementos porque pueden repetirse o tener estructura.
- **Solo el JDK.** Java ya incluye validación, XPath y un procesador XSLT, así que no he usado Saxon ni Maven. La pega es que solo hay XSLT 1.0: sin `replace()`, sin salida JSON y sin `for-each-group`, por eso hay una plantilla recursiva para escapar comillas y la agrupación por PEGI usa `xsl:key`.
- **El JSON se genera con XSLT** en lugar de escribirlo a mano o con código Java, para que el XML sea la única fuente de datos. En el JSON Schema quité `multipleOf: 0.01` para los precios porque con números en coma flotante falla (19.99 no es múltiplo exacto de 0.01 en binario).
- **`textContent` en vez de `innerHTML`** al pintar las fichas en la web, para que un texto del JSON nunca se interprete como HTML.
