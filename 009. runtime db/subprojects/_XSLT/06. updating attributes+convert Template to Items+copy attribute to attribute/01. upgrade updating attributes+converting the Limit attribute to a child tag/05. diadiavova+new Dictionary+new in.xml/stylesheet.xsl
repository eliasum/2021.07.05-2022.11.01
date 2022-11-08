<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
  xmlns:exslt="http://exslt.org/common"
  exclude-result-prefixes="exslt"
  version="1.0">
  <xsl:output method="xml" indent="yes" omit-xml-declaration="yes"/>
  <xsl:strip-space  elements="*"/>

  <xsl:output method="xml" indent="yes" />
  <xsl:variable name="dictionary" select="document('Dictionary.xml')"/>

  <xsl:template match="@*|node()">
    <xsl:copy>
      <xsl:apply-templates select="@*|node()"/>
    </xsl:copy>
  </xsl:template>

  <xsl:template match="*">
    <xsl:copy>
      <xsl:apply-templates select="@*"/>
      <xsl:variable name="name" select="name()"/>
	  <!--
	  введение дополнительного ограничения на узлы Item и Template, которые присутствуют в 'Dictionary.xml', но атрибуты
	  которых не нужно копировать в соответствующие узлы выходного дерева
	  -->
      <xsl:apply-templates select="$dictionary//*[name(.) = $name and name(.)!= 'Item' and name(.)!= 'Template']/@*"/>

      <xsl:if test="self::node()[@Allowance]">
        <Allowance const="{@Allowance}">
          <xsl:copy-of select="$dictionary//Allowance/@*[name(.) != 'const']"/>
        </Allowance>
      </xsl:if>

      <xsl:if test="self::node()[@Limit]">
        <Limit>
          <xsl:copy-of select="$dictionary//Limit/@*[name(.) != 'const']"/>
          <xsl:call-template name="generation">
            <xsl:with-param name="value" select="@Limit"/>
          </xsl:call-template>
        </Limit>
      </xsl:if>

      <xsl:if test="self::node()[not(@Limit)]">
        <xsl:apply-templates/>
      </xsl:if>

    </xsl:copy>
  </xsl:template>

  <xsl:template name="generation">
    <xsl:param name="value"/>
    <xsl:param name="key" select="1"/>
    <xsl:variable name="range" select="substring-before(substring-after($value, '['), ']')"/>
    <xsl:variable name="template" select="$dictionary//Limit/*"/>
    <Item key="{$key}">
      <Minimum>
        <xsl:attribute name="const">
          <xsl:value-of select="substring-before($range, '-')"/>
        </xsl:attribute>
        <xsl:copy-of select="$template/*/@*[local-name() != 'const']"/>
      </Minimum>
      <Maximum>
        <xsl:attribute name="const">
          <xsl:value-of select="substring-after($range, '-')"/>
        </xsl:attribute>
        <xsl:copy-of select="$template/*/@*[local-name() != 'const']"/>
      </Maximum>
      <xsl:apply-templates/>
    </Item>
    <xsl:if test="contains($value, '][')">
      <xsl:call-template name="generation">
        <xsl:with-param name="key" select="$key+1"/>
        <xsl:with-param name="value" select="substring-after($value, ']')"/>
      </xsl:call-template>
    </xsl:if>
  </xsl:template>

  <xsl:template match="@Allowance" />
  <xsl:template match="@Limit" />

</xsl:stylesheet>