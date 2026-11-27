<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform">

  <!-- XSLT 1.0 no sabe escribir <!DOCTYPE html>; about:legacy-compat es la forma admitida por HTML5 -->
  <xsl:output method="html" encoding="UTF-8" indent="yes" doctype-system="about:legacy-compat"/>

  <!-- Formato de números a la española: 1.234,56 -->
  <xsl:decimal-format name="es" decimal-separator="," grouping-separator="."/>

  <!-- Clave para agrupar por PEGI (método Muenchian) -->
  <xsl:key name="juegos-por-pegi" match="juego" use="@pegi"/>

  <xsl:template match="/catalogo">
    <html lang="es">
      <head>
        <meta name="viewport" content="width=device-width, initial-scale=1"/>
        <meta name="description" content="Catálogo de videojuegos hecho en XML y validado con DTD y XSD. Esta versión la genera XSLT directamente desde el XML."/>
        <title>Catálogo de videojuegos</title>
        <link rel="stylesheet" href="../css/estilos.css"/>
      </head>
      <body>
        <header class="cabecera">
          <div class="contenedor">
            <h1>Catálogo de videojuegos</h1>
            <p class="cabecera__texto">
              <xsl:text>Práctica de Lenguajes de marcas: un catálogo de videojuegos en XML que valido con DTD y XSD, consulto con XPath y transformo con XSLT en HTML y en JSON. Esta versión la genera XSLT directamente desde el XML (datos del </xsl:text>
              <xsl:call-template name="fecha">
                <xsl:with-param name="iso" select="@actualizado"/>
              </xsl:call-template>
              <xsl:text>).</xsl:text>
            </p>
            <nav class="cabecera__enlaces" aria-label="Otras vistas">
              <a href="../web/index.html">Ver la versión web con filtros (JSON)</a>
            </nav>
          </div>
        </header>

        <main class="contenedor">
          <p class="resumen">
            <xsl:value-of select="count(juego)"/>
            <xsl:text> juegos · nota media </xsl:text>
            <xsl:value-of select="format-number(sum(juego/nota) div count(juego), '0,0', 'es')"/>
            <xsl:text> · precio medio </xsl:text>
            <xsl:value-of select="concat(format-number(sum(juego/precio) div count(juego), '#.##0,00', 'es'), '&#160;€')"/>
            <xsl:text> · </xsl:text>
            <xsl:value-of select="count(juego[precio = 0])"/>
            <xsl:text> gratis</xsl:text>
          </p>

          <section aria-labelledby="titulo-tabla">
            <h2 id="titulo-tabla">Ordenados por nota</h2>
            <div class="tabla-envoltorio">
              <!-- Los role repiten lo que ya dice la tabla: en móvil el CSS la pasa a display: block
                   y Safari deja de tratarla como tabla si no se le indica así -->
              <table class="tabla" role="table">
                <thead role="rowgroup">
                  <tr role="row">
                    <th scope="col" role="columnheader">Nota</th>
                    <th scope="col" role="columnheader">Título</th>
                    <th scope="col" role="columnheader">Estudio</th>
                    <th scope="col" role="columnheader">Año</th>
                    <th scope="col" role="columnheader">Plataformas</th>
                    <th scope="col" role="columnheader">Géneros</th>
                    <th scope="col" role="columnheader">PEGI</th>
                    <th scope="col" role="columnheader" class="num">Precio</th>
                  </tr>
                </thead>
                <tbody role="rowgroup">
                  <xsl:apply-templates select="juego">
                    <xsl:sort select="nota" data-type="number" order="descending"/>
                    <xsl:sort select="titulo"/>
                  </xsl:apply-templates>
                </tbody>
              </table>
            </div>
          </section>

          <section aria-labelledby="titulo-pegi">
            <h2 id="titulo-pegi">Por clasificación PEGI</h2>
            <div class="grupos">
              <!-- Solo el primer juego de cada PEGI: así sale un grupo por valor -->
              <xsl:for-each select="juego[generate-id() = generate-id(key('juegos-por-pegi', @pegi)[1])]">
                <xsl:sort select="@pegi" data-type="number"/>
                <xsl:variable name="grupo" select="key('juegos-por-pegi', @pegi)"/>
                <div class="grupo">
                  <h3>
                    <xsl:call-template name="insignia-pegi">
                      <xsl:with-param name="pegi" select="@pegi"/>
                    </xsl:call-template>
                    <span class="grupo__total">
                      <xsl:value-of select="count($grupo)"/>
                      <xsl:choose>
                        <xsl:when test="count($grupo) = 1"> juego</xsl:when>
                        <xsl:otherwise> juegos</xsl:otherwise>
                      </xsl:choose>
                    </span>
                  </h3>
                  <ul>
                    <xsl:for-each select="$grupo">
                      <xsl:sort select="titulo"/>
                      <li><xsl:value-of select="titulo"/></li>
                    </xsl:for-each>
                  </ul>
                </div>
              </xsl:for-each>
            </div>
          </section>

          <section aria-labelledby="titulo-espana">
            <h2 id="titulo-espana">Hechos en España</h2>
            <ul class="lista-simple">
              <xsl:for-each select="juego[estudio/@pais = 'ES']">
                <xsl:sort select="anio" data-type="number"/>
                <li>
                  <strong><xsl:value-of select="titulo"/></strong>
                  <xsl:text> (</xsl:text>
                  <xsl:value-of select="anio"/>
                  <xsl:text>), de </xsl:text>
                  <xsl:value-of select="estudio"/>
                </li>
              </xsl:for-each>
            </ul>
          </section>
        </main>

        <footer class="pie">
          <div class="contenedor">
            <p>Práctica de Lenguajes de marcas. Precios orientativos y notas inventadas. Las notas de 9,5 o más van en rojo.</p>
            <p>Hecho por Michael Márquez Calvo · <a href="https://github.com/michaelmarquez-daw/videojuegos-xml">Código en GitHub</a> · <a href="https://michaelmarquez-daw.github.io/">Volver al portfolio</a></p>
          </div>
        </footer>
      </body>
    </html>
  </xsl:template>

  <xsl:template match="juego">
    <tr role="row">
      <td role="cell" data-etiqueta="Nota">
        <span>
          <xsl:attribute name="class">
            <xsl:text>nota</xsl:text>
            <xsl:if test="nota &gt;= 9.5"> nota--alta</xsl:if>
          </xsl:attribute>
          <xsl:value-of select="format-number(nota, '0,0', 'es')"/>
        </span>
      </td>
      <th scope="row" role="rowheader" data-etiqueta="Título">
        <span class="tabla__titulo"><xsl:value-of select="titulo"/></span>
        <xsl:if test="descripcion">
          <span class="tabla__descripcion"><xsl:value-of select="descripcion"/></span>
        </xsl:if>
      </th>
      <td role="cell" data-etiqueta="Estudio">
        <xsl:value-of select="estudio"/>
        <xsl:text> (</xsl:text>
        <xsl:value-of select="estudio/@pais"/>
        <xsl:text>)</xsl:text>
      </td>
      <td role="cell" data-etiqueta="Año"><xsl:value-of select="anio"/></td>
      <td role="cell" data-etiqueta="Plataformas">
        <xsl:for-each select="plataformas/plataforma">
          <xsl:value-of select="."/>
          <xsl:if test="position() != last()">, </xsl:if>
        </xsl:for-each>
      </td>
      <td role="cell" data-etiqueta="Géneros">
        <xsl:for-each select="generos/genero">
          <xsl:value-of select="."/>
          <xsl:if test="position() != last()">, </xsl:if>
        </xsl:for-each>
      </td>
      <td role="cell" data-etiqueta="PEGI">
        <xsl:call-template name="insignia-pegi">
          <xsl:with-param name="pegi" select="@pegi"/>
        </xsl:call-template>
      </td>
      <td role="cell" data-etiqueta="Precio" class="num">
        <xsl:choose>
          <xsl:when test="precio = 0">Gratis</xsl:when>
          <xsl:otherwise>
            <xsl:value-of select="concat(format-number(precio, '#.##0,00', 'es'), '&#160;€')"/>
          </xsl:otherwise>
        </xsl:choose>
      </td>
    </tr>
  </xsl:template>

  <!-- Colores como los de PEGI: verde (3 y 7), naranja (12 y 16) y rojo (18) -->
  <xsl:template name="insignia-pegi">
    <xsl:param name="pegi"/>
    <span>
      <xsl:attribute name="class">
        <xsl:text>pegi </xsl:text>
        <xsl:choose>
          <xsl:when test="$pegi &lt;= 7">pegi--verde</xsl:when>
          <xsl:when test="$pegi &lt;= 16">pegi--naranja</xsl:when>
          <xsl:otherwise>pegi--rojo</xsl:otherwise>
        </xsl:choose>
      </xsl:attribute>
      <span class="visualmente-oculto">PEGI </span>
      <xsl:value-of select="$pegi"/>
    </span>
  </xsl:template>

  <!-- 2026-11-20 pasa a 20/11/2026 -->
  <xsl:template name="fecha">
    <xsl:param name="iso"/>
    <xsl:value-of select="concat(substring($iso, 9, 2), '/', substring($iso, 6, 2), '/', substring($iso, 1, 4))"/>
  </xsl:template>

</xsl:stylesheet>
