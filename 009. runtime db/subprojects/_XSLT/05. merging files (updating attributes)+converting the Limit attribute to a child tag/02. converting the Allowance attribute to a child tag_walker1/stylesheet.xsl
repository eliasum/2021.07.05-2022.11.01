<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
  xmlns:exslt="http://exslt.org/common"
  exclude-result-prefixes="exslt"
  version="1.0">
  <xsl:output method="xml" indent="yes" omit-xml-declaration="yes"/>

  <xsl:param name="dictionary" select="document('Dictionary.xml')"/>
  <xsl:key name="replacement" match="*" use="local-name()"/>

  <!--Identity template-->
  <xsl:template match="@*|node()">
    <xsl:copy>
      <xsl:apply-templates select="@*|node()"/>
    </xsl:copy>
  </xsl:template>

  <xsl:template match="*">
    <xsl:copy>
      <xsl:apply-templates select="@*" />
      <xsl:variable name="element" select="."/>
      <xsl:for-each select="$dictionary">
        <xsl:choose>
          <xsl:when test="not($element[@Allowance])">
            <xsl:apply-templates select="key('replacement', local-name($element))/@*"/>
          </xsl:when>
          <xsl:otherwise>
            <xsl:apply-templates select="key('replacement', local-name($element))/@*"/>
            <xsl:variable name="const" select="$element/@Allowance"/>
            <Allowance>
              <xsl:copy>
                <xsl:attribute name="const">
                  <xsl:value-of select="$const"/>
                </xsl:attribute>
              </xsl:copy>
            </Allowance>
          </xsl:otherwise>
        </xsl:choose>
      </xsl:for-each>
      <xsl:apply-templates/>
    </xsl:copy>
  </xsl:template>

  <xsl:template match="@Allowance" />

</xsl:stylesheet>