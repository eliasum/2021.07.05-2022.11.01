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

  <xsl:template match="Adress|Channel|Voltage">
    <xsl:variable name="name" select="local-name()"/>
    <xsl:copy>
      <xsl:apply-templates select="@*[local-name() != 'Allowance' and local-name() != 'Limit']"/>
      <xsl:apply-templates select="$dictionary//*[local-name() = $name]/@*"/>
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
          <!-- I left this part for you.  Convert the delimited list in Limit from the 
             input file to a node-set and then for-each element.  Use the template  
             from the update file to output.  -->


        </xsl:element>
      </xsl:if>
    </xsl:copy>
  </xsl:template>

  <!--Identity template-->
  <xsl:template match="@*|node()">
    <xsl:copy>
      <xsl:apply-templates select="@*|node()"/>
    </xsl:copy>
  </xsl:template>


</xsl:stylesheet>