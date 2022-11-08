<?xml version="1.0" encoding="utf-8"?>

<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform">
  <xsl:output method="xml" indent="yes" omit-xml-declaration="yes"/>
  <xsl:variable name="filename" select="'profile.xml'" />
  
  <xsl:variable name="ancestors" select="document('profile.xml')//Widget/ancestor::*[1]" />
  
  <xsl:template match="@*|node()">
    <xsl:variable name="element" select="name()"/>
    
    <xsl:for-each select="$ancestors">
     <xsl:variable name="var" select="local-name()"/> 
      
     <xsl:if test="$element=$var">
        <xsl:copy-of select="(.)"/>
        <xsl:text>&#10;</xsl:text>
     </xsl:if>
     </xsl:for-each> 
          
     <xsl:copy>
      <xsl:apply-templates select="@*|node()"/>
     </xsl:copy>  

  </xsl:template>

</xsl:stylesheet>
