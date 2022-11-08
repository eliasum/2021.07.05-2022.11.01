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
                                                  name(.)!= name(//Limit//*)]/@*"/>
      <xsl:apply-templates select="@*"/>

      <!--добавление тегов с атрибутом const="?" из Dictionary.xml дл¤ обработки-->
      <xsl:apply-templates select="." mode="compare">
        <xsl:with-param name="att" select="'Locking'"/>
      </xsl:apply-templates>

      <xsl:apply-templates select="." mode="compare">
        <xsl:with-param name="att" select="'Reaction'"/>
      </xsl:apply-templates>

      <xsl:apply-templates select="." mode="compare">
        <xsl:with-param name="att" select="'Holding'"/>
      </xsl:apply-templates>

      <xsl:apply-templates select="." mode="compare">
        <xsl:with-param name="att" select="'Allowance'"/>
      </xsl:apply-templates>

      <!--исключение - тег Limit-->
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

  <xsl:template match="*" mode="compare">
    <xsl:param name="att"/>
    <xsl:variable name="name" select="name()"/>
    <xsl:choose>
      <xsl:when test="self::node()[@*[name() = $att]]">
        <xsl:element name="{$att}">
          <xsl:attribute name="const">
            <xsl:value-of select="@*[name() = $att]"/>
          </xsl:attribute>
          <xsl:copy-of select="$dictionary//*[name() = $att]/@*[name(.) != 'const']"/>
        </xsl:element>
      </xsl:when>
      <xsl:otherwise>
        <xsl:if test="($dictionary//*[name(.) = $name])[@*[name() = $att]]">
          <xsl:element name="{$att}">
            <xsl:attribute name="const">
              <xsl:value-of select="$dictionary//*[name(.) = $name]/@*[name() = $att]"/>
            </xsl:attribute>
            <xsl:copy-of select="$dictionary//*[name() = $att]/@*[name(.) != 'const']"/>
          </xsl:element>
        </xsl:if>
      </xsl:otherwise>
    </xsl:choose>
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

      <xsl:when test="contains($text, '{@')">
        <xsl:value-of select="substring-before($text, '{')"/>
        <xsl:variable name="name" select="substring-before(substring-after($text, '{@'), '}')" />
        <xsl:call-template name="expand">
          <xsl:with-param name="text" select="../@*[name()=$name]"/>
        </xsl:call-template>
        <xsl:call-template name="expand">
          <xsl:with-param name="text" select="substring-after($text, '}')"/>
        </xsl:call-template>
      </xsl:when>

      <xsl:when test="contains($text, '{../@') ">
        <xsl:value-of select="substring-before($text, '{')"/>
        <xsl:variable name="name" select="substring-before(substring-after($text, '{../@'), '}')" />
        <xsl:call-template name="expand">
          <xsl:with-param name="text" select="../../@*[name()=$name]"/>
        </xsl:call-template>
        <xsl:call-template name="expand">
          <xsl:with-param name="text" select="substring-after($text, '}')"/>
        </xsl:call-template>
      </xsl:when>

      <xsl:when test="contains($text, '{../../@') ">
        <xsl:value-of select="substring-before($text, '{')"/>
        <xsl:variable name="name" select="substring-before(substring-after($text, '{../../@'), '}')" />
        <xsl:call-template name="expand">
          <xsl:with-param name="text" select="../../../@*[name()=$name]"/>
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

  <!--добавление тегов с атрибутом const="?" из Dictionary.xml дл¤ обработки-->
  <xsl:template match="@Locking" />
  <xsl:template match="@Reaction" />
  <xsl:template match="@Holding" />
  <xsl:template match="@Allowance" />

  <!--исключение - тег Limit-->
  <xsl:template match="@Limit" />

</xsl:stylesheet>