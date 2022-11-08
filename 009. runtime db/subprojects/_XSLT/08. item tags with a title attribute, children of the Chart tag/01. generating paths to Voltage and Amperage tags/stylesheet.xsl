<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform">
  <xsl:output method="text" encoding="UTF-8"/>
  <xsl:variable name="apostrophe">'</xsl:variable>
    
  <xsl:template match="node()[@value and @type]">
    <xsl:value-of select="$apostrophe"/>
    <xsl:for-each select="ancestor::*">
      <xsl:variable name="element" select="node()[@key]/@title"/>
      <xsl:value-of select="$element"/>
      <xsl:if test="$element">
        <xsl:text>: </xsl:text>
      </xsl:if>
    </xsl:for-each>
    <xsl:value-of select="concat(@title, $apostrophe)"/>
    <xsl:text>&#10;</xsl:text>
  </xsl:template>
  <xsl:template match="text()"/>
</xsl:stylesheet>