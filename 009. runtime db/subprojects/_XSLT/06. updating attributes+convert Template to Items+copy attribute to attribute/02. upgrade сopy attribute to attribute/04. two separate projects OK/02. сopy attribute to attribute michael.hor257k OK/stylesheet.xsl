<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="1.0"
  xmlns:msxsl="urn:schemas-microsoft-com:xslt">
  <xsl:output method="xml" indent="yes" omit-xml-declaration="yes"/>
  <xsl:strip-space  elements="*"/>

  <xsl:template match="node()">
    <xsl:copy>
      <xsl:apply-templates select="@*|node()"/>
    </xsl:copy>
  </xsl:template>

  <xsl:template match="@*">
    <xsl:attribute name="{name()}">
      <xsl:call-template name="expand">
        <xsl:with-param name="text" select="."/>
      </xsl:call-template>
    </xsl:attribute>
  </xsl:template>

  <xsl:template name="expand">
    <xsl:param name="text"/>
    <xsl:choose>
      <xsl:when test="contains($text, '{') ">
        <!-- text before reference -->
        <xsl:value-of select="substring-before($text, '{')"/>
        <!-- reference -->
        <xsl:call-template name="evaluate">
          <xsl:with-param name="path" select="substring-before(substring-after($text, '{'), '}')"/>
        </xsl:call-template>
        <!-- recursive call with text after reference -->
        <xsl:call-template name="expand">
          <xsl:with-param name="text" select="substring-after($text, '}')"/>
        </xsl:call-template>
      </xsl:when>
      <xsl:otherwise>
        <xsl:value-of select="$text"/>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>

  <xsl:template name="evaluate">
    <xsl:param name="path"/>
    <xsl:variable name="name" select="substring-after($path, '@')"/>
    <xsl:call-template name="expand">
      <xsl:with-param name="text">
        <xsl:choose>
          <xsl:when test="starts-with($path, '../../@')">
            <xsl:value-of select="../../../@*[name()=$name]"/>
          </xsl:when>
          <xsl:when test="starts-with($path, '../@')">
            <xsl:value-of select="../../@*[name()=$name]"/>
          </xsl:when>
          <xsl:when test="starts-with($path, '@')">
            <xsl:value-of select="../@*[name()=$name]"/>
          </xsl:when>
        </xsl:choose>
      </xsl:with-param>
    </xsl:call-template>
  </xsl:template>

</xsl:stylesheet>