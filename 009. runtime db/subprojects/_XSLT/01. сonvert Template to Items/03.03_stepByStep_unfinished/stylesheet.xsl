<?xml version="1.0" encoding="utf-8"?>
<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
xmlns:msxsl="urn:schemas-microsoft-com:xslt" exclude-result-prefixes="msxsl">
<xsl:output method="xml" indent="yes"/>

	<xsl:template match="@* | node()">
    <xsl:copy>
			<xsl:apply-templates select="@* | node()"/>
		</xsl:copy>
  </xsl:template>

  <xsl:template match="Template">
    <xsl:variable name="key" select="@key"/>
    <Item>
      <xsl:for-each select="@*">
        <xsl:variable name="text" select="."/>
        <xsl:variable name="element" select="local-name(.)"/>
        <xsl:choose>
          <xsl:when test="$element = 'key'">
            <xsl:attribute name="key">
              <xsl:value-of select="substring-before($key, '-')"/>
            </xsl:attribute>
          </xsl:when>
          <xsl:otherwise>
            <xsl:attribute name="{$element}">
              <xsl:value-of select="$text"/>
            </xsl:attribute>
          </xsl:otherwise>
        </xsl:choose>
      </xsl:for-each>
      <xsl:apply-templates select="node()"/>
    </Item>
  </xsl:template>


</xsl:stylesheet>

 
