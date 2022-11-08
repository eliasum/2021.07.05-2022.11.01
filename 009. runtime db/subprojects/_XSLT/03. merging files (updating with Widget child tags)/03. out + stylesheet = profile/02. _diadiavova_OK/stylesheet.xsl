<?xml version="1.0" encoding="utf-8"?>
 
<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform">
  <xsl:output method="xml" indent="yes" omit-xml-declaration="yes"/>
  <xsl:strip-space  elements="*"/>
 
  <xsl:param name="pNewType" select="'profile'"/>
 
  <!--Identity template-->
  <xsl:template match="@*|node()">
    <xsl:copy>
      <xsl:apply-templates select="@key|node()"/>  
    </xsl:copy>
  </xsl:template>
 
  <!--Замена узлов 'conf' на 'p'-->
  <xsl:template match="Configuration">
    <Profiler>
      <xsl:apply-templates select="@title|node()"/>
    </Profiler>
  </xsl:template>
  
  <!--Замена значения Profiler/@title-->
  <xsl:template match="*/@title">
    <xsl:attribute name='title'>Профиль пользователя</xsl:attribute>
  </xsl:template>
 
  <!--Удалить все атрибуты кроме @title и @key-->
  <xsl:template match="*[(ancestor-or-self::Widget)]">
      <xsl:copy>
          <xsl:copy-of select="@title | @key"/>
          <xsl:apply-templates/>
      </xsl:copy>
  </xsl:template>
 
  <!--Удалить всех непредков тега Widget-->
  <xsl:template match="*[not(.//Widget) and not(ancestor-or-self::Widget)]"/>
   
</xsl:stylesheet>