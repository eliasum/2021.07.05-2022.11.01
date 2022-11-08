<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
  xmlns:exslt="http://exslt.org/common"
  exclude-result-prefixes="exslt"
  version="1.0">
  <xsl:output method="xml" indent="yes" omit-xml-declaration="yes"/>
  <xsl:strip-space  elements="*"/>

  <xsl:output method="xml" indent="yes" />
  <xsl:variable name="dictionary" select="document('Dictionary.xml')"/>
  <xsl:key name="replacement" match="*" use="local-name()"/>

  <xsl:template match="@*|node()">
    <xsl:copy>
      <xsl:apply-templates select="@*|node()"/>
    </xsl:copy>
  </xsl:template>

  <xsl:template match="*">
    <xsl:copy>

      <xsl:variable name="name" select="name()"/>
      <xsl:apply-templates select="$dictionary//*[name(.) = $name and 
                                                  name(.)!= 'Item' and 
                                                  name(.)!= 'Template' and
                                                  name(.)!= 'Minimum' and
                                                  name(.)!= 'Maximum']/@*"/>
      <xsl:apply-templates select="@*"/>

      <xsl:choose>
        <xsl:when test="self::node()[@Allowance]">
          <Allowance const="{@Allowance}">
            <xsl:copy-of select="$dictionary//Allowance/@*[name(.) != 'const']"/>
          </Allowance>
        </xsl:when>
        <xsl:otherwise>
          <xsl:if test="($dictionary//*[name(.) = $name])[@Allowance]">
            <Allowance>
              <xsl:attribute name="const">
                <xsl:value-of select="$dictionary//*[name(.) = $name]/@Allowance"/>
              </xsl:attribute>
              <xsl:copy-of select="$dictionary//Allowance/@*[name(.) != 'const']"/>
            </Allowance>
          </xsl:if>
        </xsl:otherwise>
      </xsl:choose>

      <xsl:choose>
        <xsl:when test="self::node()[@Locking]">
          <Locking const="{@Locking}">
            <xsl:copy-of select="$dictionary//Locking/@*[name(.) != 'const']"/>
          </Locking>
        </xsl:when>
        <xsl:otherwise>
          <xsl:if test="($dictionary//*[name(.) = $name])[@Locking]">
            <Locking>
              <xsl:attribute name="const">
                <xsl:value-of select="$dictionary//*[name(.) = $name]/@Locking"/>
              </xsl:attribute>
              <xsl:copy-of select="$dictionary//Locking/@*[name(.) != 'const']"/>
            </Locking>
          </xsl:if>
        </xsl:otherwise>
      </xsl:choose>

      <xsl:choose>
        <xsl:when test="self::node()[@Reaction]">
          <Reaction const="{@Reaction}">
            <xsl:copy-of select="$dictionary//Reaction/@*[name(.) != 'const']"/>
          </Reaction>
        </xsl:when>
        <xsl:otherwise>
          <xsl:if test="($dictionary//*[name(.) = $name])[@Reaction]">
            <Reaction>
              <xsl:attribute name="const">
                <xsl:value-of select="$dictionary//*[name(.) = $name]/@Reaction"/>
              </xsl:attribute>
              <xsl:copy-of select="$dictionary//Reaction/@*[name(.) != 'const']"/>
            </Reaction>
          </xsl:if>
        </xsl:otherwise>
      </xsl:choose>

      <xsl:choose>
        <xsl:when test="self::node()[@Holding]">
          <Holding const="{@Holding}">
            <xsl:copy-of select="$dictionary//Holding/@*[name(.) != 'const']"/>
          </Holding>
        </xsl:when>
        <xsl:otherwise>
          <xsl:if test="($dictionary//*[name(.) = $name])[@Holding]">
            <Holding>
              <xsl:attribute name="const">
                <xsl:value-of select="$dictionary//*[name(.) = $name]/@Holding"/>
              </xsl:attribute>
              <xsl:copy-of select="$dictionary//Holding/@*[name(.) != 'const']"/>
            </Holding>
          </xsl:if>
        </xsl:otherwise>
      </xsl:choose>

      <xsl:if test="self::node()[@Limit]">
        <Limit>
          <xsl:copy-of select="$dictionary//Limit/@*[name(.) != 'const']"/>
          <xsl:call-template name="generation">
            <xsl:with-param name="value" select="@Limit"/>
          </xsl:call-template>
        </Limit>
      </xsl:if>
      <xsl:apply-templates/>
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
    </Item>
    <xsl:if test="contains($value, '][')">
      <xsl:call-template name="generation">
        <xsl:with-param name="key" select="$key+1"/>
        <xsl:with-param name="value" select="substring-after($value, ']')"/>
      </xsl:call-template>
    </xsl:if>
  </xsl:template>

  <xsl:template match="@Allowance" />
  <xsl:template match="@Locking" />
  <xsl:template match="@Reaction" />
  <xsl:template match="@Holding" />
  <xsl:template match="@Limit" />

</xsl:stylesheet>