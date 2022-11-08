<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform">
  <xsl:output method="text" encoding="UTF-8"/>
  <xsl:variable name="apostrophe">'</xsl:variable>
  <xsl:template match="/">
    <xsl:text>
-- PostgreSQL database dump
--"%PROGRAM_PATH%\PostgresPro\10\bin\psql" --username=alex -d postgres -f D:\TEMP\runtime.sql
\connect runtime
SET statement_timeout = 0;
SET lock_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SET check_function_bodies = false;
SET client_min_messages = warning;
SET row_security = off;

CREATE EXTENSION IF NOT EXISTS plpgsql WITH SCHEMA pg_catalog;
COMMENT ON EXTENSION plpgsql IS 'PL/pgSQL procedural language';

SET search_path = public, pg_catalog;
SET default_tablespace = '';
SET default_with_oids = false;

CREATE TABLE table_Glossary (
    key integer NOT NULL GENERATED ALWAYS AS IDENTITY ( INCREMENT 1 START 1 MINVALUE 1 MAXVALUE 2147483647 CACHE 1 ),
    configuration text NOT NULL,
    communication text,
    allowance float NOT NULL,
    tablename character(15) NOT NULL,
    CONSTRAINT "glossary_key" PRIMARY KEY (key)
);
COMMENT ON TABLE table_Glossary IS 'Словарь для индефикации переменных';
COMMENT ON COLUMN table_Glossary.key IS 'Уникальный ключ переменной для связи с друними таьлицами';
COMMENT ON COLUMN table_Glossary.configuration IS 'XPath - путь к переменной в XML-конфигурационном файле для ПО';
COMMENT ON COLUMN table_Glossary.communication IS 'XPath - путь к переменной в XML-конфигурационном файле для коммуникаций';
COMMENT ON COLUMN table_Glossary.allowance IS 'Допуск на изменение переменной';
COMMENT ON COLUMN table_Glossary.tablename IS 'Имя таблицы в которой хранятся значения переменной';

COPY table_Glossary (configuration, allowance, name) FROM stdin;
    </xsl:text>
    <xsl:apply-templates/>
    <xsl:text>
\.
    </xsl:text>
  </xsl:template>
  
  <xsl:template match="node()[@format]">
    <xsl:variable name="allowance" select="Allowance/@value"/>
    <xsl:for-each select="ancestor::*">
      <xsl:variable name="element" select="local-name()"/>
      <xsl:value-of select="$element"/>
      <xsl:if test="$element='Item'">
        <xsl:value-of select="concat('[@key=', $apostrophe, @key, $apostrophe, ']')"/>
      </xsl:if>
      <xsl:text>/</xsl:text>
    </xsl:for-each>
    <xsl:choose>
      <xsl:when test="starts-with(@format, 'N')">
        <xsl:value-of select="concat(local-name(), ' ', $allowance, ' table_Number')"/>
      </xsl:when>
      <xsl:when test="starts-with(@format, 'F')">
        <xsl:value-of select="concat(local-name(), ' ', $allowance, ' table_Float')"/>
      </xsl:when>
      <xsl:when test="starts-with(@format, 'D')">
        <xsl:value-of select="concat(local-name(), ' ', $allowance, ' table_Decimal')"/>
      </xsl:when>
      <xsl:otherwise>
        <xsl:value-of select="concat(local-name(), ' ', $allowance, ' table_String')"/>
      </xsl:otherwise>
    </xsl:choose>
    <xsl:text>&#10;</xsl:text>
  </xsl:template>
  <xsl:template match="text()"/>
</xsl:stylesheet>