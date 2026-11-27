<?xml version="1.0" encoding="UTF-8"?>
<!-- Convierte catalogo.xml en JSON. Como XSLT 1.0 no tiene salida JSON, se escribe como texto. -->
<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform">

  <xsl:output method="text" encoding="UTF-8"/>

  <xsl:template match="/catalogo">
    <xsl:text>{&#10;</xsl:text>
    <xsl:text>  "actualizado": "</xsl:text>
    <xsl:value-of select="@actualizado"/>
    <xsl:text>",&#10;</xsl:text>
    <xsl:text>  "juegos": [&#10;</xsl:text>
    <xsl:for-each select="juego">
      <xsl:apply-templates select="."/>
      <xsl:if test="position() != last()">,</xsl:if>
      <xsl:text>&#10;</xsl:text>
    </xsl:for-each>
    <xsl:text>  ]&#10;}&#10;</xsl:text>
  </xsl:template>

  <xsl:template match="juego">
    <xsl:text>    {&#10;</xsl:text>
    <xsl:text>      "id": "</xsl:text><xsl:value-of select="@id"/><xsl:text>",&#10;</xsl:text>
    <xsl:text>      "titulo": </xsl:text>
    <xsl:call-template name="cadena"><xsl:with-param name="texto" select="titulo"/></xsl:call-template>
    <xsl:text>,&#10;</xsl:text>
    <xsl:text>      "estudio": { "nombre": </xsl:text>
    <xsl:call-template name="cadena"><xsl:with-param name="texto" select="estudio"/></xsl:call-template>
    <xsl:text>, "pais": "</xsl:text><xsl:value-of select="estudio/@pais"/><xsl:text>" },&#10;</xsl:text>
    <xsl:text>      "anio": </xsl:text><xsl:value-of select="number(anio)"/><xsl:text>,&#10;</xsl:text>
    <xsl:text>      "plataformas": [</xsl:text>
    <xsl:call-template name="lista"><xsl:with-param name="nodos" select="plataformas/plataforma"/></xsl:call-template>
    <xsl:text>],&#10;</xsl:text>
    <xsl:text>      "generos": [</xsl:text>
    <xsl:call-template name="lista"><xsl:with-param name="nodos" select="generos/genero"/></xsl:call-template>
    <xsl:text>],&#10;</xsl:text>
    <xsl:text>      "pegi": </xsl:text><xsl:value-of select="number(@pegi)"/><xsl:text>,&#10;</xsl:text>
    <!-- number() normaliza "0.00" a 0 y evita formatos que JSON no acepta, como ".5" -->
    <xsl:text>      "precio": </xsl:text><xsl:value-of select="number(precio)"/><xsl:text>,&#10;</xsl:text>
    <xsl:text>      "nota": </xsl:text><xsl:value-of select="number(nota)"/>
    <xsl:if test="descripcion">
      <xsl:text>,&#10;      "descripcion": </xsl:text>
      <xsl:call-template name="cadena"><xsl:with-param name="texto" select="descripcion"/></xsl:call-template>
    </xsl:if>
    <xsl:text>&#10;    }</xsl:text>
  </xsl:template>

  <!-- Array de cadenas a partir de un conjunto de nodos -->
  <xsl:template name="lista">
    <xsl:param name="nodos"/>
    <xsl:for-each select="$nodos">
      <xsl:call-template name="cadena"><xsl:with-param name="texto" select="."/></xsl:call-template>
      <xsl:if test="position() != last()">, </xsl:if>
    </xsl:for-each>
  </xsl:template>

  <!-- Cadena JSON entre comillas, escapando primero las barras y luego las comillas -->
  <xsl:template name="cadena">
    <xsl:param name="texto"/>
    <xsl:variable name="sinBarras">
      <xsl:call-template name="reemplazar">
        <xsl:with-param name="texto" select="normalize-space($texto)"/>
        <xsl:with-param name="buscar" select="'\'"/>
        <xsl:with-param name="poner" select="'\\'"/>
      </xsl:call-template>
    </xsl:variable>
    <xsl:text>"</xsl:text>
    <xsl:call-template name="reemplazar">
      <xsl:with-param name="texto" select="$sinBarras"/>
      <xsl:with-param name="buscar" select="'&quot;'"/>
      <xsl:with-param name="poner" select="'\&quot;'"/>
    </xsl:call-template>
    <xsl:text>"</xsl:text>
  </xsl:template>

  <!-- XSLT 1.0 no tiene replace(), así que se hace con recursividad -->
  <xsl:template name="reemplazar">
    <xsl:param name="texto"/>
    <xsl:param name="buscar"/>
    <xsl:param name="poner"/>
    <xsl:choose>
      <xsl:when test="contains($texto, $buscar)">
        <xsl:value-of select="substring-before($texto, $buscar)"/>
        <xsl:value-of select="$poner"/>
        <xsl:call-template name="reemplazar">
          <xsl:with-param name="texto" select="substring-after($texto, $buscar)"/>
          <xsl:with-param name="buscar" select="$buscar"/>
          <xsl:with-param name="poner" select="$poner"/>
        </xsl:call-template>
      </xsl:when>
      <xsl:otherwise>
        <xsl:value-of select="$texto"/>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>

</xsl:stylesheet>
