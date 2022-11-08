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
        <xsl:value-of select="substring-before($text, '{')"/>
        <xsl:call-template name="evaluate">
          <xsl:with-param name="path" select="substring-before(substring-after($text, '{'), '}')"/>
        </xsl:call-template>
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
    <xsl:variable name="attr" select="substring-after($path, '@')"/>
    <xsl:variable name="tag" select="translate(substring-before($path, '/@'),'./','')"/>
    <xsl:call-template name="expand">
      <xsl:with-param name="text">
        <xsl:if test="$tag = ''">
          <xsl:choose>
            <xsl:when test="starts-with($path, '../../../../../../@')">
              <xsl:value-of select="../../../../../../../@*[name()=$attr]"/>
            </xsl:when>
            <xsl:when test="starts-with($path, '../../../../../@')">
              <xsl:value-of select="../../../../../../@*[name()=$attr]"/>
            </xsl:when>
            <xsl:when test="starts-with($path, '../../../../@')">
              <xsl:value-of select="../../../../../@*[name()=$attr]"/>
            </xsl:when>
            <xsl:when test="starts-with($path, '../../../@')">
              <xsl:value-of select="../../../../@*[name()=$attr]"/>
            </xsl:when>
            <xsl:when test="starts-with($path, '../../@')">
              <xsl:value-of select="../../../@*[name()=$attr]"/>
            </xsl:when>
            <xsl:when test="starts-with($path, '../@')">
              <xsl:value-of select="../../@*[name()=$attr]"/>
            </xsl:when>
            <xsl:when test="starts-with($path, '@')">
              <xsl:value-of select="../@*[name()=$attr]"/>
            </xsl:when>
          </xsl:choose>
        </xsl:if>
        <xsl:if test="$tag != ''">
          <xsl:choose>
            <xsl:when test="starts-with($path, concat('../../../../../../',$tag,'/@'))">
              <xsl:value-of select="../../../../../../../*[name()=$tag]/@*[name()=$attr]"/>
            </xsl:when>
            <xsl:when test="starts-with($path, concat('../../../../../',$tag,'/@'))">
              <xsl:value-of select="../../../../../../*[name()=$tag]/@*[name()=$attr]"/>
            </xsl:when>
            <xsl:when test="starts-with($path, concat('../../../../',$tag,'/@'))">
              <xsl:value-of select="../../../../../*[name()=$tag]/@*[name()=$attr]"/>
            </xsl:when>
            <xsl:when test="starts-with($path, concat('../../../',$tag,'/@'))">
              <xsl:value-of select="../../../../*[name()=$tag]/@*[name()=$attr]"/>
            </xsl:when>
            <xsl:when test="starts-with($path, concat('../../',$tag,'/@'))">
              <xsl:value-of select="../../../*[name()=$tag]/@*[name()=$attr]"/>
            </xsl:when>
            <xsl:when test="starts-with($path, concat('../',$tag,'/@'))">
              <xsl:value-of select="../../*[name()=$tag]/@*[name()=$attr]"/>
            </xsl:when>
            <xsl:when test="starts-with($path, concat($tag,'/@'))">
              <xsl:value-of select="../*[name()=$tag]/@*[name()=$attr]"/>
            </xsl:when>
          </xsl:choose>
        </xsl:if>
      </xsl:with-param>
    </xsl:call-template>
  </xsl:template>

</xsl:stylesheet>