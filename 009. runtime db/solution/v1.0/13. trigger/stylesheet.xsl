<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform">
  <xsl:output method="text" encoding="UTF-8"/>
  <xsl:variable name="apostrophe">'</xsl:variable>
  <xsl:template match="/">
<xsl:text>
-- PostgreSQL database dump
--"%PROGRAM_PATH%\PostgresPro\13\bin\psql" --username=postgres -d postgres -f D:\TEMP\runtime.sql
\connect runtime
SET statement_timeout = 0;
SET lock_timeout = 0;
SET client_encoding = 'WIN1251';
SET standard_conforming_strings = on;
SET check_function_bodies = false;
SET client_min_messages = warning;
SET row_security = off;

CREATE EXTENSION IF NOT EXISTS plpgsql WITH SCHEMA pg_catalog;
COMMENT ON EXTENSION plpgsql IS 'PL/pgSQL procedural language';
CREATE extension IF NOT EXISTS timescaledb;

SET search_path = public, pg_catalog;
SET default_tablespace = '';
SET default_with_oids = false;
/*-------------------------------------------------------------------------------------------------*/
CREATE TABLE table_Glossary (
    key integer NOT NULL GENERATED ALWAYS AS IDENTITY ( INCREMENT 1 START 1 MINVALUE 1 MAXVALUE 2147483647 CACHE 1 ),
    configuration text NOT NULL,
    communication text,
    allowance float NOT NULL,
    tablename character(15) NOT NULL,
    CONSTRAINT "glossary_key" PRIMARY KEY (key)
);

COMMENT ON TABLE table_Glossary IS 'Словарь для индефикации переменных';
COMMENT ON COLUMN table_Glossary.key IS 'Уникальный ключ переменной для связи с друними таблицами';
COMMENT ON COLUMN table_Glossary.configuration IS 'XPath - путь к переменной в XML-конфигурационном файле для ПО';
COMMENT ON COLUMN table_Glossary.communication IS 'XPath - путь к переменной в XML-конфигурационном файле для коммуникаций';
COMMENT ON COLUMN table_Glossary.allowance IS 'Допуск на изменение переменной';
COMMENT ON COLUMN table_Glossary.tablename IS 'Имя таблицы в которой хранятся значения переменной';
/*-------------------------------------------------------------------------------------------------*/
INSERT INTO table_Glossary (configuration, communication, allowance, tablename) VALUES 
</xsl:text>
    <xsl:apply-templates/>
    <xsl:text>;
/*-------------------------------------------------------------------------------------------------*/
INSERT INTO number_actual (tstamp, val) 
select NOW(), number from generate_series(0,149) number;

INSERT INTO float_actual (tstamp, val) 
select NOW(), number from generate_series(0,149) number;
/*-------------------------------------------------------------------------------------------------*/
CREATE OR REPLACE FUNCTION _Refresh(xpath VARCHAR, valnew FLOAT)
RETURNS VOID AS $$
DECLARE 

	_Table TEXT;  
	_HyperTable TEXT;
	_Allowance FLOAT;
	_ValueOld FLOAT;
	_Count INTEGER;
	_1P FLOAT;
	_Delta FLOAT;
	_DeltaP FLOAT;
	
BEGIN
		
	/*Получение имени дочерней таблицы из XPath таблицы table_glossary*/
	IF (SELECT EXISTS(SELECT 1 from table_glossary WHERE configuration = xpath)) THEN
		_Table := (SELECT tablename FROM table_glossary WHERE configuration = xpath);
	ELSE
		_Table := NULL;
	END IF;  
	
	/*Получение allowance (допуска) из XPath таблицы table_glossary*/
	IF (SELECT EXISTS(SELECT 1 from table_glossary WHERE configuration = xpath)) THEN
		_Allowance := (SELECT allowance FROM table_glossary WHERE configuration = xpath);
	ELSE
		_Allowance := NULL;
	END IF;  
	
	/*Получение последнего значения val из актуальной таблицы*/
	EXECUTE FORMAT('SELECT val FROM %I ORDER BY key DESC LIMIT 1', _Table) INTO _ValueOld;
	
	/*Получение разницы в % между старым и новым значениями*/
	_1P := _ValueOld / 100; 
	_Delta := ABS(_ValueOld - valnew);
	_DeltaP := _Delta / _1P;
			
	/*Получение имени гипертаблицы в зависимости от имени актуальной таблицы*/
	CASE 
		  WHEN _Table = 'number_actual' 	THEN _HyperTable := 'table_number';
		  WHEN _Table = 'float_actual' 		THEN _HyperTable := 'table_float';
		  WHEN _Table = 'decimal_actual'	THEN _HyperTable := 'table_decimal';
		  WHEN _Table = 'string_actual' 	THEN _HyperTable := 'table_string';
	END CASE;
	
	/*Число строк в гипертаблице*/
	EXECUTE FORMAT('SELECT COUNT(*) FROM %I', _HyperTable) INTO _Count;
																	
	/*Если в допуске*/
	IF(_DeltaP &lt;= _Allowance) THEN
		/*Если число записей в гипертаблице не превышает 2*/
		IF(_Count &lt; 2) THEN
			EXECUTE format('INSERT INTO %I(tstamp, val) VALUES(NOW(), %s);', _Table, valnew);
		ELSE
			EXECUTE format('UPDATE %I SET tstamp = NOW() WHERE key = (SELECT MAX(key) from %I);', _Table, _Table);
		END IF;
	ELSE
		EXECUTE format('INSERT INTO %I(tstamp, val) VALUES(NOW(), %s);', _Table, valnew);
	END IF;
		
END;

$$ LANGUAGE plpgsql;
/*-------------------------------------------------------------------------------------------------*/
CREATE OR REPLACE FUNCTION before_insert_in_glossary()
  RETURNS TRIGGER AS
$$
DECLARE 

	_Table TEXT;  
	_HyperTable TEXT;
	_NamePK TEXT;

BEGIN
	/*NEW.tablename - значение поля tablename таблицы table_glossary, 
	которое будет вставлено в новую запись table_glossary*/
	_Table := NEW.tablename;
	_NamePK := NEW.tablename || '_key';
	
	/*Получение имени гипертаблицы в зависимости от имени актуальной таблицы*/
	CASE 
		  WHEN _Table = 'number_actual' 	THEN _HyperTable := 'table_number';
		  WHEN _Table = 'float_actual' 		THEN _HyperTable := 'table_float';
		  WHEN _Table = 'decimal_actual'	THEN _HyperTable := 'table_decimal';
		  WHEN _Table = 'string_actual' 	THEN _HyperTable := 'table_string';
	END CASE;
		
	/*Создание актуальной и гипертаблицы, если они не существуют, 
	исходя из значения поля tablename таблицы table_glossary*/	
	EXECUTE format('
	CREATE TABLE IF NOT EXISTS %I(
	key_number integer NOT NULL,
	tstamp timestamptz NOT NULL,
	val FLOAT NOT NULL);

	SELECT create_hypertable(
	''%I'', ''tstamp'',
	chunk_time_interval => INTERVAL ''1 day'',
	if_not_exists => TRUE
	);

	CREATE TABLE IF NOT EXISTS %I( 
	key integer NOT NULL GENERATED ALWAYS AS IDENTITY ( INCREMENT 1 START 1 MINVALUE 1 MAXVALUE 2147483647 CACHE 1 ),
	tstamp timestamptz NOT NULL,
	val FLOAT NOT NULL,
	CONSTRAINT %I PRIMARY KEY (key),
	FOREIGN KEY (key) REFERENCES table_glossary(key));',
	_HyperTable, _HyperTable, _Table, _NamePK);
	
	RETURN NEW;
	
END;

$$ LANGUAGE plpgsql;

CREATE TRIGGER existence_check_or_creation_table 
  BEFORE INSERT
  ON table_glossary
  FOR EACH ROW
  EXECUTE PROCEDURE before_insert_in_glossary();
	</xsl:text>
  </xsl:template>
  
  <xsl:template match="node()[@format]">
    <xsl:variable name="allowance" select="Allowance/@value"/>
    <xsl:value-of select="concat('(', $apostrophe)"/>
    <xsl:for-each select="ancestor::*">
      <xsl:variable name="element" select="local-name()"/>
      <xsl:value-of select="$element"/>
      <xsl:if test="$element='Item'">
        <xsl:value-of select="concat('[@key=', $apostrophe, $apostrophe, @key, $apostrophe, $apostrophe, ']')"/>
      </xsl:if>
      <xsl:text>/</xsl:text>
    </xsl:for-each>
    <xsl:choose>
      <xsl:when test="starts-with(@format, 'N')">
        <xsl:value-of select="concat(local-name(), $apostrophe, ', ', 'NULL, ', $allowance, ', ', $apostrophe, 'number_actual', $apostrophe, '),')"/>
      </xsl:when>
      <xsl:when test="starts-with(@format, 'F')">
        <xsl:value-of select="concat(local-name(), $apostrophe, ', ', 'NULL, ', $allowance, ', ', $apostrophe, 'float_actual', $apostrophe, '),')"/>
      </xsl:when>
      <xsl:when test="starts-with(@format, 'D')">
        <xsl:value-of select="concat(local-name(), $apostrophe, ', ', 'NULL, ', $allowance, ', ', $apostrophe, 'decimal_actual', $apostrophe, '),')"/>
      </xsl:when>
      <xsl:otherwise>
        <xsl:value-of select="concat(local-name(), $apostrophe, ', ', 'NULL, ', $allowance, ', ', $apostrophe, 'string_actual', $apostrophe, '),')"/>
      </xsl:otherwise>
    </xsl:choose>
    <xsl:text>&#10;</xsl:text>
  </xsl:template>
  <xsl:template match="text()"/>
</xsl:stylesheet>