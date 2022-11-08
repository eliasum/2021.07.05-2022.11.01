<?xml version="1.0" encoding="utf-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
  xmlns:exslt="http://exslt.org/common"
  exclude-result-prefixes="exslt"
  version="1.0">
  <xsl:output method="xml"/>
  
  <xsl:param name="updates" select="document('profile.xml')"/>
  <xsl:key name="replacement" match="*[Widget]" use="local-name()"/>

  <xsl:template match="@* | node()">
    <xsl:copy>
      <xsl:apply-templates select="@* | node()"/>
    </xsl:copy>
  </xsl:template>

  <xsl:template match="*[Widget]">

    <xsl:variable name="this" select="."/>
    <xsl:variable name="descendants" select="./*"/>

    <xsl:variable name="desc">
      <xsl:for-each select="$descendants">
        <xsl:if test="name(.)!='Widget'">
          <xsl:copy-of select="(.)"/>
        </xsl:if>
      </xsl:for-each>
    </xsl:variable>

    <xsl:variable name="replacement">
      <xsl:for-each select="$updates">
        <xsl:copy-of select="key('replacement', local-name($this))"/>
      </xsl:for-each>
    </xsl:variable>

    <xsl:variable name="wrapNodeSet" select="exslt:node-set($replacement)/node()"/>

    <xsl:choose>
      <xsl:when test="exslt:node-set($replacement)/*">
        <xsl:value-of disable-output-escaping="yes" select="string('&lt;')"/>
        <xsl:value-of select="local-name($this)"/>
        <xsl:value-of disable-output-escaping="yes" select="string('&gt;')"/>
        <xsl:copy-of select="$desc"/>
        <xsl:copy-of select="$wrapNodeSet/*"/>
        <xsl:value-of disable-output-escaping="yes" select="string('&lt;')"/>
        <xsl:value-of disable-output-escaping="yes" select="string('/')"/>
        <xsl:value-of select="local-name($this)"/>
        <xsl:value-of disable-output-escaping="yes" select="string('&gt;')"/>
      </xsl:when>
      <xsl:otherwise>
        <xsl:copy-of select="."/>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>

</xsl:stylesheet>
