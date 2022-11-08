<?xml version="1.0" encoding="utf-8"?>

<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform">
  <xsl:output method="text" indent="yes" omit-xml-declaration="yes"/>

<xsl:template match="/">           <!--Выбирает от корневого узла-->
 <xsl:for-each select="//Template/@key"> <!--обрабатываются все атрибуты key тегов Template внутри корневого узла-->
        <xsl:value-of select="."/> <!--Выбирает текущий узел-->
        <xsl:text>&#10;</xsl:text> <!--Перенос строки в XML-->
  </xsl:for-each>
</xsl:template> 

</xsl:stylesheet>