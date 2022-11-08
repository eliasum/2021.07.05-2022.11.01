<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform">
  <xsl:output method="text" encoding="UTF-8"/>
  <xsl:variable name="apostrophe">'</xsl:variable>
  <xsl:template match="/">
<xsl:text>
-- Поменять кодировку файла на UTF-8

-- PostgreSQL database dump
-- psql --username=postgres -d postgres -f D:\TEMP\runtime.sql

-- Database: runtime

-- DROP DATABASE runtime;

CREATE DATABASE runtime
    WITH 
    OWNER = postgres
    ENCODING = 'UTF8'
    LC_COLLATE = 'Russian_Russia.1251'
    LC_CTYPE = 'Russian_Russia.1251'
    TABLESPACE = pg_default
    CONNECTION LIMIT = -1;

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
CREATE EXTENSION IF NOT EXISTS timescaledb;

SET search_path = public, pg_catalog;
SET default_tablespace = '';
SET default_with_oids = false;

CREATE TYPE T_REC AS (
  tkey INTEGER,
  ts TIMESTAMPTZ,
  val FLOAT
);
-----------------------------------------------------------------------------------------------------
CREATE TABLE glossary (
    key INTEGER NOT NULL GENERATED ALWAYS AS IDENTITY ( INCREMENT 1 START 1 MINVALUE 1 MAXVALUE 2147483647 CACHE 1 ),
    configuration TEXT NOT NULL,
    communication TEXT,
    allowance FLOAT NOT NULL,
    tablename CHARACTER(15) NOT NULL,
    CONSTRAINT "glossary_key" PRIMARY KEY (key)
);

COMMENT ON TABLE glossary IS 'Словарь для индефикации переменных';
COMMENT ON COLUMN glossary.key IS 'Уникальный ключ переменной для связи с друними таблицами';
COMMENT ON COLUMN glossary.configuration IS 'XPath - путь к переменной в XML-конфигурационном файле для ПО';
COMMENT ON COLUMN glossary.communication IS 'XPath - путь к переменной в XML-конфигурационном файле для коммуникаций';
COMMENT ON COLUMN glossary.allowance IS 'Допуск на изменение переменной';
COMMENT ON COLUMN glossary.tablename IS 'Имя таблицы в которой хранятся значения переменной';
-----------------------------------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION before_insert_in_glossary()
  RETURNS TRIGGER AS
$$
DECLARE 

	--переменные для:
	_TableName TEXT;		--значения 4-го поля таблицы glossary, формирующего _Table и _HyperTable    
	
	_Table TEXT;  			--имени актуальной таблицы  
	_HyperTable TEXT;		--имени соответствующей гипертаблицы
	
	_KEY_actual TEXT;		--имени ключа актуальной таблицы 
	_KEY_archive TEXT;		--имени ключа гипертаблицы
	
	_TS_actual TEXT;		--фиксированного момента актуальной таблицы 
	_TS_archive TEXT;		--фиксированного момента гипертаблицы

	_VAL_actual TEXT;		--фиксированного значения актуальной таблицы 
	_VAL_archive TEXT;		--фиксированного значения гипертаблицы	

BEGIN
	--NEW.tablename - значение поля tablename таблицы glossary, 
	--которое будет вставлено в новую запись glossary
	_TableName := NEW.tablename;
	
	_Table 		 := _TableName  || '_actual';
	_HyperTable  := _TableName	|| '_archive';
	
	_KEY_actual  := _Table 		|| '_key';
	_KEY_archive := _HyperTable || '_key';
	
	_TS_actual 	 := _Table 		|| '_tstamp';
	_TS_archive	 := _HyperTable	|| '_tstamp';
	
	_VAL_actual  := _Table 		|| '_val';
	_VAL_archive := _HyperTable || '_val';
				
	--Создание актуальной и гипертаблицы, если они не существуют, 
	--исходя из значения поля tablename таблицы glossary	
	
	EXECUTE format('
	CREATE TABLE IF NOT EXISTS %I(
	%I INTEGER NOT NULL,
	%I TIMESTAMPTZ NOT NULL,
	%I %s NOT NULL);

	SELECT create_hypertable(
	''%I'', ''%I'',
	chunk_time_interval => INTERVAL ''1 day'',
	if_not_exists => TRUE
	);

	CREATE TABLE IF NOT EXISTS %I( 
	%I INTEGER NOT NULL GENERATED ALWAYS AS IDENTITY ( INCREMENT 1 START 1 MINVALUE 1 MAXVALUE 2147483647 CACHE 1 ),
	%I TIMESTAMPTZ NOT NULL,
	%I %s NOT NULL,
	FOREIGN KEY (%I) REFERENCES glossary(key));',
	_HyperTable, 	
	_KEY_archive, 	
	_TS_archive, 	
	_VAL_archive,
	_TableName,
	
	_HyperTable,	
	_TS_archive, 	
	
	_Table,			
	_KEY_actual,	
	_TS_actual,		
	_VAL_actual,
	_TableName,	
	_KEY_actual);	
	
	RETURN NEW; 
	
END;

$$ LANGUAGE plpgsql;

CREATE TRIGGER existence_check_or_creation_table 
  BEFORE INSERT
  ON glossary
  FOR EACH ROW
  EXECUTE PROCEDURE before_insert_in_glossary();
-----------------------------------------------------------------------------------------------------
INSERT INTO glossary (configuration, communication, allowance, tablename) VALUES --</xsl:text><xsl:apply-templates/>
    <xsl:text>;
-----------------------------------------------------------------------------------------------------
CREATE OR REPLACE PROCEDURE _communication(xpath VARCHAR, valnew anyelement) AS $$

--Сбор информации с оборудования в БД

DECLARE 

	--переменные для:
	_TableName TEXT;		--значения 4-го поля таблицы glossary, формирующего _Table и _HyperTable    
	_Table TEXT;  			--имени актуальной таблицы  
	_HyperTable TEXT;		--имени соответствующей гипертаблицы
	_Allowance FLOAT;		--допуска, значения 3-его поле таблицы glossary
	_ValueOld FLOAT;		--последнего значения 3-го поля val из актуальной таблицы
	_Count INTEGER;			--числа строк в гипертаблице
	_1P FLOAT;				--получения разницы в % между старым и новым значениями val актуальной таблицы  
	_Delta FLOAT;
	_DeltaP FLOAT;
	_KEY_actual TEXT;		--имени ключа актуальной таблицы 
	_TS_actual TEXT;		--фиксированного момента актуальной таблицы 
	_VAL_actual TEXT;		--фиксированного значения актуальной таблицы 
	
BEGIN
		
	--Получение значения поля 'tablename' таблицы glossary, используя входной аргумент XPath 
	IF (SELECT EXISTS(SELECT 1 from glossary WHERE configuration = xpath)) THEN
		_TableName := (SELECT tablename FROM glossary WHERE configuration = xpath);
	ELSE
		_TableName := NULL;
	END IF;  
	
	--Получение имени актуальной таблицы
	IF (_TableName IS NOT NULL) THEN 
		_Table 		:= _TableName || '_actual';
	ELSE
		_TableName := NULL;
	END IF;  
	
	--Получение имени гипертаблицы
	IF (_TableName IS NOT NULL) THEN
		_HyperTable := _TableName || '_archive';
	ELSE
		_HyperTable := NULL;
	END IF; 
	
	_KEY_actual  := _Table 		  || '_key';
	_TS_actual 	 := _Table 		  || '_tstamp';
	_VAL_actual  := _Table 		  || '_val';
	
	--Получение allowance (допуска) из XPath таблицы glossary
	IF (SELECT EXISTS(SELECT 1 from glossary WHERE configuration = xpath)) THEN
		_Allowance := (SELECT allowance FROM glossary WHERE configuration = xpath);
	ELSE
		_Allowance := NULL;
	END IF;  
	
	--Получение последнего значения val из актуальной таблицы
	EXECUTE FORMAT('SELECT %I FROM %I ORDER BY %I DESC LIMIT 1', _VAL_actual, _Table, _KEY_actual) INTO _ValueOld;
	
	--Получение разницы в % между старым и новым значениями
	_1P := _ValueOld / 100; 
	_Delta := ABS(_ValueOld - valnew);
	_DeltaP := _Delta / _1P;
				
	--Число строк в гипертаблице
	EXECUTE FORMAT('SELECT COUNT(*) FROM %I', _HyperTable) INTO _Count;
	
	--Если в допуске
	IF(_DeltaP &lt;= _Allowance) THEN
		--Если число записей в гипертаблице не превышает 2
		IF(_Count &lt; 2) THEN
			EXECUTE FORMAT('INSERT INTO %I(%I, %I) VALUES(NOW(), %s);', _Table, _TS_actual, _VAL_actual, valnew);
		ELSE
			EXECUTE FORMAT('UPDATE %I SET %I = NOW() WHERE %I = (SELECT MAX(%I) from %I);', _Table, _TS_actual, _KEY_actual, _KEY_actual, _Table);
		END IF;
	ELSE
		EXECUTE FORMAT('INSERT INTO %I(%I, %I) VALUES(NOW(), %s);', _Table, _TS_actual, _VAL_actual, valnew);
	END IF;

END;

$$ LANGUAGE plpgsql;
-----------------------------------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION _refresh(xpath VARCHAR)
RETURNS TABLE (rkey INTEGER, rtstamp TIMESTAMPTZ, rval FLOAT) AS $$

--Обновление активной информации в ПО из БД, возврат одной записи из актуальной таблицы

DECLARE 

	--переменные для:
	_Key INTEGER;			--значения ключа актуальной таблицы
	_TableName TEXT;		--значения 4-го поля таблицы glossary, формирующего _Table    
	_Table TEXT;  			--имени актуальной таблицы  
	_Value FLOAT;			--значения 3-го поля val из актуальной таблицы
	_KEY_actual TEXT;		--имени ключа актуальной таблицы 
	_TS_actual TEXT;		--фиксированного момента актуальной таблицы 
	_VAL_actual TEXT;		--фиксированного значения актуальной таблицы 
		
BEGIN
		
	--Получение значения поля 'key' таблицы glossary, используя входной аргумент XPath 
	IF (SELECT EXISTS(SELECT 1 from glossary WHERE configuration = xpath)) THEN
		_Key := (SELECT key FROM glossary WHERE configuration = xpath);
	ELSE
		_Key := NULL;
	END IF;  
		
	--Получение значения поля 'tablename' таблицы glossary, используя входной аргумент XPath 
	IF (SELECT EXISTS(SELECT 1 from glossary WHERE configuration = xpath)) THEN
		_TableName := (SELECT tablename FROM glossary WHERE configuration = xpath);
	ELSE
		_TableName := NULL;
	END IF;  
	
	--Получение имени актуальной таблицы
	IF (_TableName IS NOT NULL) THEN 
		_Table := _TableName || '_actual';
	ELSE
		_Table := NULL;
	END IF;  
	
	_KEY_actual := _Table   || '_key';
	_TS_actual	:= _Table   || '_tstamp';
	_VAL_actual := _Table   || '_val';
			
	--Получение одной записи из актуальной таблицы
	IF (_Table IS NOT NULL) THEN
		RETURN QUERY EXECUTE FORMAT('SELECT * FROM %I WHERE %I = %s;', _Table, _KEY_actual, _Key);
	ELSE
		RETURN QUERY EXECUTE FORMAT(NULL);
	END IF;  
	
END;

$$ LANGUAGE plpgsql;
-----------------------------------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION _refresh()
RETURNS TABLE (rkey INTEGER, rconfig TEXT, fix TIMESTAMPTZ, rvalf FLOAT, rvaln INTEGER) AS $$

--Обновление активной информации в ПО из БД, возврат записей из всех активных таблиц

DECLARE 
	
BEGIN
	
	RETURN QUERY EXECUTE FORMAT('
	SELECT gl.key AS key, configuration AS config, float_actual_tstamp AS fix, float_actual_val AS float_val, NULL AS integer_val
	FROM glossary AS gl 
	INNER JOIN float_actual ON key = float_actual_key 
	UNION
	SELECT gl.key AS key, configuration AS conf, integer_actual_tstamp AS fix, NULL AS float_val, integer_actual_val AS val
	FROM glossary AS gl 
	INNER JOIN integer_actual ON key = integer_actual_key 
	ORDER BY key;
	');
						
END;

$$ LANGUAGE plpgsql;
-----------------------------------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION _refreshold(xpath VARCHAR, st TIMESTAMP, fin TIMESTAMP)
RETURNS TABLE (rkey INTEGER, rtstamp TIMESTAMPTZ, rval FLOAT) AS $$

--Обновление архивной информации в ПО из БД, возврат записей из гипертаблицы от st до fin

DECLARE 

	--переменные для:
	_Key INTEGER;			--значения ключа гипертаблицы
	_TableName TEXT;		--значения 4-го поля таблицы glossary, формирующего _HyperTable    
	_HyperTable TEXT;  		--имени гипертаблицы  
	_KEY_archive TEXT;		--имени ключа гипертаблицы
	_TS_archive TEXT;		--фиксированного момента гипертаблицы
	_VAL_archive TEXT;		--фиксированного значения гипертаблицы	
		
BEGIN

	--Получение значения поля 'key' таблицы glossary, используя входной аргумент XPath 
	IF (SELECT EXISTS(SELECT 1 from glossary WHERE configuration = xpath)) THEN
		_Key := (SELECT key FROM glossary WHERE configuration = xpath);
	ELSE
		_Key := NULL;
	END IF;  
		
	--Получение значения поля 'tablename' таблицы glossary, используя входной аргумент XPath 
	IF (SELECT EXISTS(SELECT 1 from glossary WHERE configuration = xpath)) THEN
		_TableName := (SELECT tablename FROM glossary WHERE configuration = xpath);
	ELSE
		_TableName := NULL;
	END IF;  
	
	--Получение имени гипертаблицы
	IF (_TableName IS NOT NULL) THEN 
		_HyperTable := _TableName || '_archive';
	ELSE
		_HyperTable := NULL;
	END IF; 
	
	_KEY_archive := _HyperTable   || '_key';
	_TS_archive	 := _HyperTable   || '_tstamp';
	_VAL_archive := _HyperTable   || '_val';
	
	--возврат записей из гипертаблицы от st до fin
	RETURN QUERY EXECUTE FORMAT('
	SELECT %I, %I, %I
	FROM %I 
	WHERE %I BETWEEN ''%s'' AND ''%s'';
	', 
	_KEY_archive, _TS_archive, _VAL_archive,
	_HyperTable,
	_TS_archive, st, fin);

END;

$$ LANGUAGE plpgsql;
-----------------------------------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION _refreshold(st TIMESTAMP, fin TIMESTAMP)
RETURNS TABLE (rkey INTEGER, rconfig TEXT, fix TIMESTAMPTZ, rvalf FLOAT, rvaln INTEGER) AS $$

--Обновление архивной информации в ПО из БД, возврат записей из всех гипертаблиц от st до fin

DECLARE 
		
BEGIN

	--возврат записей из гипертаблицы от st до fin
	RETURN QUERY EXECUTE FORMAT('
	SELECT gl.key AS key, configuration AS config, float_archive_tstamp AS fix, float_archive_val AS float_val, NULL AS integer_val
	FROM glossary AS gl 
	INNER JOIN float_archive ON key = float_archive_key 
	WHERE float_archive_tstamp BETWEEN ''%s'' AND ''%s''
	UNION
	SELECT gl.key AS key, configuration AS conf, integer_archive_tstamp AS fix, NULL AS float_val, integer_archive_val AS val
	FROM glossary AS gl 
	INNER JOIN integer_archive ON key = integer_archive_key 
	WHERE integer_archive_tstamp BETWEEN ''%s'' AND ''%s''
	ORDER BY key;
	', st, fin, st, fin);

END;

$$ LANGUAGE plpgsql;
	</xsl:text>
  </xsl:template>
  
  <xsl:template match="node()[@format]">
    <xsl:variable name="allowance" select="Allowance/@value"/>
	<xsl:text>,&#10;</xsl:text>
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
        <xsl:value-of select="concat(local-name(), $apostrophe, ', ', 'NULL, ', $allowance, ', ', $apostrophe, 'integer', $apostrophe, ')')"/>
      </xsl:when>
      <xsl:when test="starts-with(@format, 'F')">
        <xsl:value-of select="concat(local-name(), $apostrophe, ', ', 'NULL, ', $allowance, ', ', $apostrophe, 'float', $apostrophe, ')')"/>
      </xsl:when>
      <xsl:when test="starts-with(@format, 'D')">
        <xsl:value-of select="concat(local-name(), $apostrophe, ', ', 'NULL, ', $allowance, ', ', $apostrophe, 'decimal', $apostrophe, ')')"/>
      </xsl:when>
      <xsl:otherwise>
        <xsl:value-of select="concat(local-name(), $apostrophe, ', ', 'NULL, ', $allowance, ', ', $apostrophe, 'varchar', $apostrophe, ')')"/>
      </xsl:otherwise>
    </xsl:choose>
    <xsl:text>&#10;</xsl:text>
  </xsl:template>
  <xsl:template match="text()"/>
</xsl:stylesheet>