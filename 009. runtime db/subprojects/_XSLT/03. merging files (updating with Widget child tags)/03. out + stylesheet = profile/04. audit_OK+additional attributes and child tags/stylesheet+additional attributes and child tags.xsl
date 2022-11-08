<?xml version="1.0" encoding="utf-8"?>

<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform">
  <xsl:output method="xml" indent="yes" omit-xml-declaration="yes"/>
  <xsl:strip-space  elements="*"/>

  <xsl:param name="pNewType" select="'profile'"/>

  <!--Identity template-->
  <xsl:template match="@*|node()">
    <!--скопировать в выходной файл все узлы и их атрибуты @key-->
    <xsl:copy>
      <xsl:apply-templates select="@key|node()"/>
    </xsl:copy>
  </xsl:template>

  <!--Обёртка всего дерева в тег Profile-->
  <xsl:template match='/'>
    <Profile>
      <xsl:attribute name='title'>Профиль пользователя</xsl:attribute>
      <xsl:apply-templates select="@*|node()"/>
    </Profile>
  </xsl:template>

  <!--выбрать все узлы, для которых предком является тег Widget и сам тег Widget-->
  <xsl:template match="*[ancestor-or-self::Widget]">
    <!--скопировать все атрибуты-->
    <xsl:copy>
      <xsl:copy-of select="@*"/>
      <xsl:apply-templates/>
    </xsl:copy>
  </xsl:template>

  <!--Удалить всех непредков тега Widget-->
  <xsl:template match="*[not(.//Widget) and not(ancestor-or-self::Widget)]"/>

</xsl:stylesheet>