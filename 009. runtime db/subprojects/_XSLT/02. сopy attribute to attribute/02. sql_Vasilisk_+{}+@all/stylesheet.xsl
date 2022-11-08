<?xml version="1.0" encoding="utf-8"?>
 
<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform">
    <xsl:output method="xml" indent="yes" omit-xml-declaration="yes"/>
  
  <xsl:template match="*/@*">
    <xsl:attribute name="{name()}">
        <xsl:call-template name="replace">
          <xsl:with-param name="str" select="."/>
          <xsl:with-param name="find" select="'{@key}'"/>
          <xsl:with-param name="replace" select="../@key"/>
        </xsl:call-template>
    </xsl:attribute>
  </xsl:template>
  
    <!--Identity template-->
  <xsl:template match="@*|node()">
    <xsl:copy>
        <xsl:apply-templates select="@*|node()"/>
    </xsl:copy>
  </xsl:template>

  <xsl:template name="replace">
    <xsl:param name="str"/>
    <xsl:param name="find"/>
    <xsl:param name="replace"/>
    <xsl:choose>
      <xsl:when test="contains($str, $find)">
        <xsl:variable name="prefix" select="substring-before($str, $find)"/>
        <xsl:variable name="suffix">
          <xsl:call-template name="replace">
            <xsl:with-param name="str" select="substring-after($str, $find)"/>
            <xsl:with-param name="find" select="$find"/>
            <xsl:with-param name="replace" select="$replace"/>
          </xsl:call-template>
        </xsl:variable>
        <xsl:value-of select="concat($prefix, $replace, $suffix)"/>
      </xsl:when>
      <xsl:otherwise>
        <xsl:value-of select="$str"/>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>
</xsl:stylesheet>