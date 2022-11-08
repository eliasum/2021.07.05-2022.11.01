<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
  xmlns:exslt="http://exslt.org/common"
  exclude-result-prefixes="exslt"
  version="1.0">
  <xsl:output method="xml" indent="yes" omit-xml-declaration="yes"/>
  <xsl:strip-space  elements="*"/>

  <xsl:param name="dictionary" select="document('Dictionary.xml')"/>
  <xsl:key name="replacement" match="*" use="local-name()"/>

  <xsl:template match="@Allowance" />
  <xsl:template match="@Limit" />

  <xsl:template match="*[not(node())]|*[not(@*)]">
    <xsl:variable name="name" select="local-name()"/>
    <xsl:copy>
      <xsl:apply-templates select="@*[local-name() != 'Allowance' and local-name() != 'Limit']"/>
      <xsl:apply-templates select="$dictionary//*[local-name() = $name and local-name() != 'Item']/@*"/>
      <xsl:apply-templates select="node()"/>
      <xsl:if test="boolean(@Allowance)">
        <xsl:element name="Allowance">
          <xsl:attribute name="const">
            <xsl:value-of select="@Allowance"/>
          </xsl:attribute>
          <xsl:apply-templates select="$dictionary//Allowance/@*[local-name() != 'const']"/>
        </xsl:element>
      </xsl:if>
      <xsl:if test="boolean(@Limit)">
        <xsl:element name="Limit">
          <xsl:apply-templates select="$dictionary//Limit/@*"/>
          <xsl:variable name="Limit_v" select="string(@Limit)" />
          <xsl:variable name="count">
            <xsl:call-template name="GetNoOfOccurance">
              <xsl:with-param name="String" select="$Limit_v"/>
              <xsl:with-param name="SubString" select="']['"/>
            </xsl:call-template>
          </xsl:variable>
          <xsl:variable name="count_v" select="string($count)+1" />
          <xsl:call-template name="tokenize">
            <xsl:with-param name="count" select="$count_v"/>
            <xsl:with-param name="text" select="$Limit_v"/>
            <xsl:with-param name="template" select="$dictionary//Limit/*"/>
          </xsl:call-template>
        </xsl:element>
      </xsl:if>
    </xsl:copy>
  </xsl:template>

  <xsl:template match="@*|node()">
    <xsl:copy>
      <xsl:apply-templates select="@*|node()"/>
    </xsl:copy>
  </xsl:template>

  <xsl:template name="GetNoOfOccurance">
    <xsl:param name="String"/>
    <xsl:param name="SubString"/>
    <xsl:param name="Counter" select="0" />
    <xsl:variable name="sa" select="substring-after($String, $SubString)" />
    <xsl:choose>
      <xsl:when test="$sa != '' or contains($String, $SubString)">
        <xsl:call-template name="GetNoOfOccurance">
          <xsl:with-param name="String"    select="$sa" />
          <xsl:with-param name="SubString" select="$SubString" />
          <xsl:with-param name="Counter"   select="$Counter + 1" />
        </xsl:call-template>
      </xsl:when>
      <xsl:otherwise>
        <xsl:value-of select="$Counter" />
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>

  <xsl:template name="enumerate">
    <xsl:param name="start"/>
    <xsl:param name="end"/>
    <xsl:param name="text"/>
    <xsl:param name="format"/>
    <xsl:param name="delimiter" select="']['"/>
    <xsl:param name="template"/>
    <xsl:variable name="before_token">
      <xsl:choose>
        <xsl:when test="contains($text, $delimiter)">
          <xsl:value-of select="substring-before($text, $delimiter)"/>
        </xsl:when>
        <xsl:otherwise>
          <xsl:value-of select="$text"/>
        </xsl:otherwise>
      </xsl:choose>
    </xsl:variable>
    <xsl:variable name="token">
      <xsl:choose>
        <xsl:when test="contains($before_token, '[')">
          <xsl:value-of select="translate($before_token, '[', '')"/>
        </xsl:when>
        <xsl:when test="contains($before_token, ']')">
          <xsl:value-of select="translate($before_token, ']', '')"/>
        </xsl:when>
        <xsl:otherwise>
          <xsl:value-of select="$before_token"/>
        </xsl:otherwise>
      </xsl:choose>
    </xsl:variable>
    <xsl:variable name="min" select="number(substring-before($token, '-'))"/>
    <xsl:variable name="max" select="number(substring-after($token, '-'))"/>
    <xsl:choose>
      <xsl:when test="$format = 0">
        <Item key="{format-number($start,'00')}" 
          title="{$dictionary//Limit/@title} № {format-number($start,'00')}"
          description="{$dictionary//Limit/@description} № {format-number($start,'00')}">
          <Minimum>
            <xsl:attribute name="const">
              <xsl:value-of select="$min"/>
            </xsl:attribute>
            <xsl:copy-of select="$template/*/@*[local-name() != 'const']"/>
            <xsl:apply-templates/>
          </Minimum>
          <Maximum>
            <xsl:attribute name="const">
              <xsl:value-of select="$max"/>
            </xsl:attribute>
            <xsl:copy-of select="$template/*/@*[local-name() != 'const']"/>
            <xsl:apply-templates/>
          </Maximum>
        </Item>
      </xsl:when>
      <xsl:otherwise>
      </xsl:otherwise>
    </xsl:choose>
    <xsl:variable name="text_minus">
      <xsl:if test="contains($text, $delimiter)">
        <xsl:value-of select = "substring-after($text, $delimiter)"/>
      </xsl:if>
    </xsl:variable>
    <xsl:if test="$start &lt; $end">
      <xsl:call-template name="enumerate">
        <xsl:with-param name="start" select="$start + 1"/>
        <xsl:with-param name="end" select="$end"/>
        <xsl:with-param name="text" select="$text_minus"/>
        <xsl:with-param name="format" select="$format"/>
        <xsl:with-param name="template" select="$template"/>
      </xsl:call-template>
    </xsl:if>
  </xsl:template>

  <xsl:template name="tokenize">
    <xsl:param name="count"/>
    <xsl:param name="delimiter" select="']['"/>
    <xsl:param name="text"/>
    <xsl:param name="template"/>
    <xsl:variable name="before_token">
      <xsl:choose>
        <xsl:when test="contains($text, $delimiter)">
          <xsl:value-of select="substring-before($text, $delimiter)"/>
        </xsl:when>
        <xsl:otherwise>
          <xsl:value-of select="$text"/>
        </xsl:otherwise>
      </xsl:choose>
    </xsl:variable>
    <xsl:variable name="token">
      <xsl:choose>
        <xsl:when test="contains($before_token, '[')">
          <xsl:value-of select="translate($before_token, '[', '')"/>
        </xsl:when>
        <xsl:when test="contains($before_token, ']')">
          <xsl:value-of select="translate($before_token, ']', '')"/>
        </xsl:when>
        <xsl:otherwise>
          <xsl:value-of select="$text"/>
        </xsl:otherwise>
      </xsl:choose>
    </xsl:variable>
    <xsl:choose>
      <xsl:when test="contains($token, '-')">
        <xsl:call-template name="enumerate">
          <xsl:with-param name="start" select="1"/>
          <xsl:with-param name="end" select="$count"/>
          <xsl:with-param name="text" select="$text"/>
          <xsl:with-param name="template" select="$template"/>
          <xsl:with-param name="format">
            <xsl:choose>
              <xsl:when test="starts-with($token, '0')">
                <xsl:value-of select="0"/>
              </xsl:when>
              <xsl:otherwise>
                <xsl:value-of select="1"/>
              </xsl:otherwise>
            </xsl:choose>
          </xsl:with-param>
        </xsl:call-template>
      </xsl:when>
      <xsl:otherwise>
      </xsl:otherwise>
    </xsl:choose>
    <xsl:if test="contains($text, $delimiter)">
      <xsl:call-template name="tokenize">
        <xsl:with-param name="text" select="substring-after($text, $delimiter)"/>
      </xsl:call-template>
    </xsl:if>
  </xsl:template>

</xsl:stylesheet>