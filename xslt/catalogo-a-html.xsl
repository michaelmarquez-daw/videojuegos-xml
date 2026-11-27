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
        <title>Catálogo de videojuegos</title>
        <link rel="stylesheet" href="../css/estilos.css"/>
      </head>
      <body>
        <header class="cabecera">
          <div class="contenedor">
            <p class="cabecera__etiqueta">Catálogo generado con XSLT</p>
            <h1>Catálogo de videojuegos</h1>
            <p class="cabecera__texto">
              <xsl:text>Datos de catalogo.xml, actualizado el </xsl:text>
              <xsl:call-template name="fecha">
                <xsl:with-param name="iso" select="@actualizado"/>
              </xsl:call-template>
              <xsl:text>.</xsl:text>
            </p>
            <nav class="cabecera__enlaces" aria-label="Otras vistas">
              <a href="../web/index.html">Ver la versión web con filtros (JSON)</a>
            </nav>
          </div>
        </header>

        <main class="contenedor">
          <section aria-label="Resumen del catálogo">
            <dl class="resumen">
              <div>
                <dt>Juegos</dt>
                <dd><xsl:value-of select="count(juego)"/></dd>
              </div>
              <div>
                <dt>Nota media</dt>
                <dd><xsl:value-of select="format-number(sum(juego/nota) div count(juego), '0,0', 'es')"/></dd>
              </div>
              <div>
                <dt>Precio medio</dt>
                <dd><xsl:value-of select="concat(format-number(sum(juego/precio) div count(juego), '#.##0,00', 'es'), '&#160;€')"/></dd>
              </div>
              <div>
                <dt>Gratuitos</dt>
                <dd><xsl:value-of select="count(juego[precio = 0])"/></dd>
              </div>
            </dl>
          </section>

          <section aria-labelledby="titulo-tabla">
            <h2 id="titulo-tabla">Ordenados por nota</h2>
            <div class="tabla-envoltorio">
              <table class="tabla">
                <thead>
                  <tr>
                    <th scope="col">Nota</th>
                    <th scope="col">Título</th>
                    <th scope="col">Estudio</th>
                    <th scope="col">Año</th>
                    <th scope="col">Plataformas</th>
                    <th scope="col">Géneros</th>
                    <th scope="col">PEGI</th>
                    <th scope="col" class="num">Precio</th>
                  </tr>
                </thead>
                <tbody>
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
            <p>Práctica de Lenguajes de marcas. Precios orientativos y notas inventadas.</p>
          </div>
        </footer>
      </body>
    </html>
  </xsl:template>

  <xsl:template match="juego">
    <tr>
      <td data-etiqueta="Nota">
        <span>
          <xsl:attribute name="class">
            <xsl:text>nota</xsl:text>
            <xsl:if test="nota &gt;= 9.5"> nota--alta</xsl:if>
          </xsl:attribute>
          <xsl:value-of select="format-number(nota, '0,0', 'es')"/>
        </span>
      </td>
      <th scope="row" data-etiqueta="Título">
        <span class="tabla__titulo"><xsl:value-of select="titulo"/></span>
        <xsl:if test="descripcion">
          <span class="tabla__descripcion"><xsl:value-of select="descripcion"/></span>
        </xsl:if>
      </th>
      <td data-etiqueta="Estudio">
        <xsl:value-of select="estudio"/>
        <span class="pais"><xsl:value-of select="estudio/@pais"/></span>
      </td>
      <td data-etiqueta="Año"><xsl:value-of select="anio"/></td>
      <td data-etiqueta="Plataformas">
        <xsl:for-each select="plataformas/plataforma">
          <xsl:value-of select="."/>
          <xsl:if test="position() != last()">, </xsl:if>
        </xsl:for-each>
      </td>
      <td data-etiqueta="Géneros">
        <xsl:for-each select="generos/genero">
          <xsl:value-of select="."/>
          <xsl:if test="position() != last()">, </xsl:if>
        </xsl:for-each>
      </td>
      <td data-etiqueta="PEGI">
        <xsl:call-template name="insignia-pegi">
          <xsl:with-param name="pegi" select="@pegi"/>
        </xsl:call-template>
      </td>
      <td data-etiqueta="Precio" class="num">
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
