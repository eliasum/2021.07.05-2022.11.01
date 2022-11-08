<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet version="1.0"
  xmlns:xsl="http://www.w3.org/1999/XSL/Transform">
  <xsl:output method="xml" version="1.0" encoding="UTF-8" indent="yes"/>

  <xsl:param name="fileName" select="'profile.xml'" />
  <xsl:variable name="updates" select="document($fileName)" />

  <xsl:key name="item" match="Item" use="@key"/>

  <xsl:template match="@*|node()">
    <xsl:copy>
      <xsl:apply-templates select="@*|node()"/>
    </xsl:copy>
  </xsl:template>

  <xsl:template match="Chart">
    <xsl:variable name="key"      select="ancestor::*[@key][1]/@key"/>
    <xsl:variable name="chartFromUpdate">
      <!-- Since the lookup is in an different document we have to change the context -->
      <xsl:for-each select="$updates">
        <xsl:copy-of select="key('item', $key)/Supply/Chart"/>
      </xsl:for-each>
    </xsl:variable>
    <xsl:choose>
      <xsl:when test="$chartFromUpdate">
        <xsl:copy-of select="$chartFromUpdate"/>
      </xsl:when>
      <xsl:otherwise>
        <xsl:copy-of select="."/>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>

</xsl:stylesheet>
