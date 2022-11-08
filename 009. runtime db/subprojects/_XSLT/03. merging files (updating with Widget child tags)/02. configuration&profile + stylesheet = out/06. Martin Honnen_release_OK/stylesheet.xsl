<?xml version="1.0" encoding="utf-8"?>

<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
  xmlns:exslt="http://exslt.org/common"
  exclude-result-prefixes="exslt"
  version="1.0">
  <xsl:output method="xml" indent="yes" omit-xml-declaration="yes"/>

  <xsl:param name="updates" select="document('profile.xml')"/>
  <xsl:key name="replacement" match="*[Widget]" use="local-name()"/>

  <!--Identity template-->
  <xsl:template match="@*|node()">
    <xsl:copy>
      <xsl:apply-templates select="@*|node()"/>
    </xsl:copy>
  </xsl:template>

  <xsl:template match="*[not(node())]">
    <xsl:variable name="element" select="(.)"/>
    <xsl:variable name="replacement">
      <xsl:for-each select="$updates">
        <xsl:copy-of select="key('replacement', local-name($element))"/>
      </xsl:for-each>
    </xsl:variable>
    <xsl:choose>
      <xsl:when test="exslt:node-set($replacement)/*">
        <xsl:copy-of select="$replacement"/>
      </xsl:when>
      <xsl:otherwise>
        <xsl:copy-of select="(.)"/>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>

</xsl:stylesheet>