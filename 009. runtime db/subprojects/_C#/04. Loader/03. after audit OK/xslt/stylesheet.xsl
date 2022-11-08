<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform">
  <xsl:output method="text" encoding="UTF-8"/>
  <xsl:variable name="apostrophe">'</xsl:variable>
  
  <xsl:template match="node()[@value and @type]">
    <xsl:for-each select="ancestor::*">
      <xsl:variable name="element" select="local-name()"/>
      <xsl:value-of select="$element"/>
      <xsl:if test="$element='Configuration' or $element='Item'">
        <xsl:value-of select="concat('[@key=', $apostrophe, @key, $apostrophe, ']')"/>
      </xsl:if>
      <xsl:text>/</xsl:text>
    </xsl:for-each>
    <xsl:value-of select="concat(local-name(), '')"/>
    <xsl:text>&#10;</xsl:text>
  </xsl:template>
  <xsl:template match="text()"/>
</xsl:stylesheet>