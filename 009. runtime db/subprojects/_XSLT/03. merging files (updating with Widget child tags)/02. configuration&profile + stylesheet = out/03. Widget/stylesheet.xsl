<?xml version="1.0" encoding="utf-8"?>

<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform">
  <xsl:output method="xml" indent="yes" omit-xml-declaration="yes"/>
  <xsl:variable name="filename" select="'_036CE061.xml'" />
  <xsl:strip-space elements="*"/>
  
  <xsl:template match="/">
    

    <xsl:value-of select="$filename" />
    <xsl:copy-of select="document($filename)" />
    
  </xsl:template>
  
  <!--special rule for Chart elements-->      
  <xsl:template match="Widget">
    <xsl:variable name="context" select="."/>
    <xsl:if test="$filename//Item/@key = $context/ancestor-or-self::Item[1]/@key">
      <xsl:copy-of select="($filename//Item[@key = $context/ancestor-or-self::Item[1]/@key])//Widget"/>
    </xsl:if>
  </xsl:template>
  
</xsl:stylesheet>
