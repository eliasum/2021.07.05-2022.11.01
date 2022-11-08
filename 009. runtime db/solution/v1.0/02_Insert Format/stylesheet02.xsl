<?xml version="1.0" encoding="utf-8"?>

<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform">
  <xsl:output method="text" indent="yes" omit-xml-declaration="yes"/>
  
<xsl:template match="/">           <!--Выбирает от корневого узла-->

  <xsl:text>
CREATE TABLE IF NOT EXISTS public."Dictionary"
(
    key integer NOT NULL GENERATED ALWAYS AS IDENTITY ( INCREMENT 1 START 1 MINVALUE 1 MAXVALUE 2147483647 CACHE 1 ),
    "XPath" character varying(200) COLLATE pg_catalog."default",
    "Format" character varying(100) COLLATE pg_catalog."default",
    CONSTRAINT "Dictionary_pkey" PRIMARY KEY (key)
)
  </xsl:text>
  <xsl:text>&#10;</xsl:text>

  <xsl:for-each select="//@format"> <!--обрабатываются все атрибуты format тегов внутри корневого узла-->
        <xsl:text>INSERT INTO public."Dictionary" ("Format") 
VALUES ('</xsl:text>
        <xsl:value-of select="."/> <!--Выбирает текущий узел-->
        <xsl:text>');</xsl:text>
        <xsl:text>&#10;</xsl:text> <!--Перенос строки в XML-->
  </xsl:for-each>
</xsl:template> 

</xsl:stylesheet>