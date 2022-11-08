<?xml version="1.0" encoding="utf-8"?>
 
<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform">
  <xsl:output method="xml" indent="yes" omit-xml-declaration="yes"/>
 
  <xsl:param name="pNewType" select="'profile'"/>
 
  <!--Identity template-->
  <xsl:template match="@*|node()">
    <xsl:copy>
      <xsl:apply-templates select="@*|node()"/>  
    </xsl:copy>
  </xsl:template>
 
  <!--Замена узлов 'conf' на 'p'-->
  <xsl:template match="conf">
    <p>
      <xsl:apply-templates select="@*|node()"/>
    </p>
  </xsl:template>
  
  <!--Замена занчения p/@title-->
  <xsl:template match="*/@title">
    <xsl:attribute name='title'>Profile</xsl:attribute>
  </xsl:template>
 
  <!--Удалить все атрибуты кроме @title и @key-->
  <xsl:template match="*">
      <xsl:copy>
          <xsl:copy-of select="@title | @key"/>
          <xsl:apply-templates/>
      </xsl:copy>
  </xsl:template>
 
  <!--Удалить всех непредков тега Chart-->
  <xsl:template match="node()[(ancestor::Test)]"/>
 
</xsl:stylesheet>