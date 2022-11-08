<xsl:stylesheet version="1.0" 
xmlns:xsl="http://www.w3.org/1999/XSL/Transform">
<xsl:output method="xml" version="1.0" encoding="UTF-8" indent="yes"/>
  <xsl:strip-space elements="*"/>
  <xsl:param name="fileName" select="'_036CE061.xml'" />
  <xsl:param name="updates" select="document($fileName)" />
  
  <!--transform starts here on input XML-->
  <xsl:template match="/">
    <xsl:apply-templates/>
  </xsl:template>
  
  <!--rules for general nodes()-->
  <xsl:template match="@*|node()">
    <xsl:copy>
      <xsl:apply-templates select="@*|node()"/>
    </xsl:copy>
  </xsl:template>

  <!--special rule for Chart elements-->      
  <xsl:template match="Widget">
    <xsl:variable name="context" select="."/>
    <!--Если все атрибуты key элементов Item (которые являются потомками дерева из файла 
    profile.xml, независимо от того, где они находятся в файле файла profile.xml) равны атрибуту 
    key элемента Item, который является первым потомком текущего узла (д.б. Chart)-->
    <xsl:if test="$updates//Item/@key = $context/ancestor-or-self::Item[1]/@key">
      <!--Тогда вывести все элементы Chart, которые являются потомком элемента Item с атрибутом
      key, равным значению атрибута key тега Item, который является первым потомком текущего узла
      (д.б. Chart), независимо от того, где они находятся в файле файла profile.xml. Теги Chart
      независят от того, где они находятся под элементом Item из файла profile.xml-->
      <xsl:copy-of select="($updates//Item[@key = $context/ancestor-or-self::Item[1]/@key])//Widget"/>
    </xsl:if>
  </xsl:template>
</xsl:stylesheet>
