<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform">
  <xsl:output method="text" encoding="UTF-8"/>
  <xsl:variable name="apostrophe">'</xsl:variable>
  <xsl:template match="/">
    <xsl:text>
-- Поменять кодировку файла на UTF-8

-- PostgreSQL database dump
-- psql --username=postgres -d postgres -f C:\TEMP\runtime.sql

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

--Пользовательские типы данных
CREATE TYPE min_type AS
 (
	imin INTEGER,
	fmin FLOAT
 );
 
CREATE TYPE max_type AS
 (
	imax INTEGER,
	fmax FLOAT
 );
-----------------------------------------------------------------------------------------------------
CREATE TABLE glossary (
    key SERIAL NOT NULL,
    configuration TEXT NOT NULL,
    communication TEXT,
    allowance FLOAT NOT NULL,
    tablename VARCHAR NOT NULL,
	unit VARCHAR NOT NULL,
	formatt VARCHAR NOT NULL,
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

BEGIN
	--NEW.tablename - значение поля tablename таблицы glossary, 
	--которое будет вставлено в новую запись glossary
	_TableName := NEW.tablename;
	
	_Table 		 := _TableName  || '_actual';
	_HyperTable  := _TableName	|| '_archive';
				
	--Создание актуальной и гипертаблицы, если они не существуют, 
	--исходя из значения поля tablename таблицы glossary	
	
	EXECUTE format('
	CREATE TABLE IF NOT EXISTS %I(
	key INTEGER NOT NULL,
	fix TIMESTAMPTZ NOT NULL,
	value %s NOT NULL,
	FOREIGN KEY (key) REFERENCES glossary(key));

	SELECT create_hypertable(
	''%I'', ''fix'',
	chunk_time_interval => INTERVAL ''1 day'',
	if_not_exists => TRUE
	);

	CREATE TABLE IF NOT EXISTS %I( 
	key INTEGER NOT NULL,
	fix TIMESTAMPTZ NOT NULL,
	value %s NOT NULL,
	FOREIGN KEY (key) REFERENCES glossary(key));',
	_HyperTable, 	
	_TableName,
	
	_HyperTable,	
	
	_Table,			
	_TableName);	
	
	RETURN NEW; 
	
END;

$$ LANGUAGE plpgsql;

CREATE TRIGGER existence_check_or_creation_table 
  BEFORE INSERT
  ON glossary
  FOR EACH ROW
  EXECUTE PROCEDURE before_insert_in_glossary();
  
CREATE TABLE synchronization (
    xpath TEXT NOT NULL,
    fix TIMESTAMPTZ NOT NULL,
    status INTEGER NOT NULL
);

CREATE TABLE _limit (
    key INTEGER NOT NULL,
	min min_type,
	max max_type,
	unit VARCHAR NOT NULL,
	formatt VARCHAR NOT NULL,
	FOREIGN KEY (key) REFERENCES glossary(key)
);
-----------------------------------------------------------------------------------------------------
INSERT INTO glossary (configuration, communication, allowance, tablename, unit, formatt) VALUES --</xsl:text>
    <xsl:apply-templates/>
    <xsl:text>;
-----------------------------------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION _communication(xpath VARCHAR, valueNew anyelement) 
RETURNS VOID AS $$

--Сбор информации с оборудования в БД

--Использование функции:
--SELECT * FROM _communication(XPath,Value);

DECLARE 

	--переменные для:
	_TableName TEXT;		--значения 4-го поля таблицы glossary, формирующего _Table и _HyperTable    
	_Table TEXT;  			--имени актуальной таблицы  
	_HyperTable TEXT;		--имени соответствующей гипер таблицы
	_Allowance FLOAT;		--допуска, значения 3-его поле таблицы glossary
	_ValueOld FLOAT;		--последнего значения 3-го поля val из гипер таблицы
	_Count INTEGER;			--числа строк в гипер таблице
	_Delta FLOAT;			--получения разницы в % между старым и новым значениями val гипер таблицы  
	_Key INTEGER;			--значения ключа таблицы glossary  
	_Existence BOOLEAN;		--признак существования в таблице _Table записи с ключом _Key
	
BEGIN
		
	--Получение значения поля 'key' таблицы glossary, используя входной аргумент XPath 
	IF (SELECT EXISTS(SELECT 1 from glossary WHERE communication = xpath)) THEN
		_Key := (SELECT key FROM glossary WHERE communication = xpath);
	ELSE
		_Key := NULL;
	END IF;  	
		
	--Получение значения поля 'tablename' таблицы glossary, используя входной аргумент XPath 
	IF (SELECT EXISTS(SELECT 1 from glossary WHERE communication = xpath)) THEN
		_TableName := (SELECT tablename FROM glossary WHERE communication = xpath);
	ELSE
		_TableName := NULL;
	END IF;  
	
	--Получение имени актуальной таблицы
	IF (_TableName IS NOT NULL) THEN 
		_Table 		:= _TableName || '_actual';
	ELSE
		_Table 		:= NULL;
	END IF;  
	
	--Получение имени гипертаблицы
	IF (_TableName IS NOT NULL) THEN
		_HyperTable := _TableName || '_archive';
	ELSE
		_HyperTable := NULL;
	END IF; 
		
	--Получение allowance (допуска) из XPath таблицы glossary
	IF (SELECT EXISTS(SELECT 1 from glossary WHERE communication = xpath)) THEN
		_Allowance := (SELECT allowance FROM glossary WHERE communication = xpath);
	ELSE	
		_Allowance := NULL;
	END IF;  
	
	--Получение старого значения value из гипер таблицы
	EXECUTE FORMAT('SELECT value FROM %I WHERE key = %s ORDER BY fix DESC LIMIT 1;', _HyperTable, _Key) INTO _ValueOld;
		
	--Приведение типа к INTEGER, если _ValueOld и valueNew из таблиц integer_ 
	IF(_TableName = 'integer') THEN
	_ValueOld := _ValueOld::INTEGER;
	END IF; 
	
	IF(_TableName = 'integer') THEN
	valueNew := valueNew::INTEGER;
	END IF; 
	
	--Число строк в гипер таблице
	EXECUTE FORMAT('SELECT COUNT(*) FROM %I', _HyperTable) INTO _Count;
	
	--Проверка существования в таблице _Table записи с ключом _Key 
	EXECUTE FORMAT('SELECT EXISTS(SELECT 1 from %I WHERE key = %s)', _Table, _Key) INTO _Existence;

	IF (_Existence) THEN
		EXECUTE FORMAT('UPDATE %I SET fix = NOW(), value = %s WHERE key = %s;', _Table, valueNew, _Key);
	ELSE
		EXECUTE FORMAT('INSERT INTO %I(key, fix, value) VALUES(%s, NOW(), %s);', _Table, _Key, valueNew);
	END IF;  

	--Если старого значения нет
	IF(_ValueOld IS NULL) THEN
		EXECUTE FORMAT('INSERT INTO %I(key, fix, value) VALUES(%s, NOW(), %s);', _HyperTable, _Key, valueNew);
	ELSE
		--Получение разницы в % между старым и новым значениями:
		--Если старое значение не равно 0
		IF(_ValueOld &lt;&gt; 0) THEN
			_Delta := ABS(_ValueOld - valueNew) * 100 / _ValueOld;
		ELSE
			--Если новое значение не равно 0
			IF(valueNew &lt;&gt; 0) THEN
				_Delta := ABS(_ValueOld - valueNew) * 100 / valueNew;
			ELSE
				_Delta := NULL;
			END IF;
		END IF;	
	END IF;
		
	IF(_Delta IS NOT NULL) THEN
		--Если число записей в гипер таблице не превышает 2
		IF(_Count &lt; 2) THEN
			EXECUTE FORMAT('INSERT INTO %I(key, fix, value) VALUES(%s, NOW(), %s);', _HyperTable, _Key, valueNew);
		ELSE
			--Если в допуске
			IF(_Delta &lt;= _Allowance) THEN
				EXECUTE FORMAT('UPDATE %I SET fix = NOW() WHERE fix = (SELECT MAX(fix) FROM %I WHERE key = %s);', _HyperTable, _HyperTable, _Key);
			ELSE
				EXECUTE FORMAT('INSERT INTO %I(key, fix, value) VALUES(%s, NOW(), %s);', _HyperTable, _Key, valueNew);
			END IF;
		END IF;
	END IF;	
		
END;

$$ LANGUAGE plpgsql;
-----------------------------------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION _refresh(xpath VARCHAR)
RETURNS RECORD AS $$

--Обновление активной информации в ПО из БД, возврат одной записи из актуальной таблицы

--Использование функции:
--SELECT * FROM _refresh(XPath) AS (rkey INTEGER, rfix TIMESTAMPTZ, rvalue FLOAT, unit VARCHAR, formatt VARCHAR); - возврат записи из float_actual
--SELECT * FROM _refresh(XPath) AS (rkey INTEGER, rfix TIMESTAMPTZ, rvalue INTEGER, unit VARCHAR, formatt VARCHAR); - возврат записи из integer_actual

DECLARE 

	--переменные для:
	_Key INTEGER;			--значения ключа таблицы glossary
	_TableName TEXT;		--значения 4-го поля таблицы glossary, формирующего _Table    
	_Table TEXT;  			--имени актуальной таблицы  
	
	ret RECORD;				--возвращаемая запись
		
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

	--Получение одной записи из актуальной таблицы + glossary.unit, glossary.formatt
	IF (_Table IS NOT NULL) THEN
		EXECUTE FORMAT('
		SELECT %I.key, %I.fix, %I.value, glossary.unit, glossary.formatt 
		FROM %I 
		INNER JOIN glossary ON %I.key = %s
		', _Table, _Table, _Table
		 , _Table
		 , _Table, _Key) INTO ret;
	END IF;  
	
	--Возврат записи
	RETURN ret;
	
END;

$$ LANGUAGE plpgsql;
-----------------------------------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION _refresh()
RETURNS TABLE (rconfig TEXT, runit VARCHAR, rformat VARCHAR, rfix TIMESTAMPTZ, value_float FLOAT, value_integer INTEGER) AS $$

--Обновление активной информации в ПО из БД, возврат записей из всех активных таблиц

--Использование функции:
--SELECT * FROM _refresh();

DECLARE 
	
BEGIN
	
	RETURN QUERY EXECUTE FORMAT('
	SELECT g.configuration AS config, g.unit, g.formatt, float_actual.fix AS fix, float_actual.value AS float_value, NULL AS integer_value
	FROM glossary AS g
	INNER JOIN float_actual ON g.key = float_actual.key 
	UNION
	SELECT g.configuration AS config, g.unit, g.formatt, integer_actual.fix AS fix, NULL AS float_value, integer_actual.value AS integer_value
	FROM glossary AS g
	INNER JOIN integer_actual ON g.key = integer_actual.key;
	');			
	
END;

$$ LANGUAGE plpgsql;
-----------------------------------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION _refreshold(xpath VARCHAR, st TIMESTAMP, fin TIMESTAMP)
RETURNS TABLE (rkey INTEGER, rfix TIMESTAMPTZ, rvalue FLOAT, runit VARCHAR, rformat VARCHAR) AS $$

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

	RETURN QUERY EXECUTE FORMAT('	
	SELECT %I.key, %I.fix, %I.value, glossary.unit, glossary.formatt 
	FROM %I 
	INNER JOIN glossary ON %I.key = %s
	WHERE %I.fix BETWEEN ''%s'' AND ''%s'';
	', _HyperTable, _HyperTable, _HyperTable,
	_HyperTable,
	_HyperTable, _Key,
	_HyperTable, st, fin);

END;

$$ LANGUAGE plpgsql;
-----------------------------------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION _refreshold(st TIMESTAMP, fin TIMESTAMP)
RETURNS TABLE (rkey INTEGER, rconfig TEXT, runit VARCHAR, rformat VARCHAR, fix TIMESTAMPTZ, value_float FLOAT, value_integer INTEGER) AS $$

--Обновление архивной информации в ПО из БД, возврат записей из всех гипертаблиц от st до fin

DECLARE 
		
BEGIN

	--возврат записей из гипертаблицы от st до fin
	RETURN QUERY EXECUTE FORMAT('
	SELECT g.key AS key, g.configuration AS config, g.unit, g.formatt, float_archive.fix AS fix, float_archive.value AS float_value, NULL AS integer_value
	FROM glossary AS g
	INNER JOIN float_archive ON g.key = float_archive.key 
	WHERE fix BETWEEN ''%s'' AND ''%s''
	UNION
	SELECT g.key AS key, configuration AS config, g.unit, g.formatt, integer_archive.fix AS fix, NULL AS float_value, integer_archive.value AS integer_value
	FROM glossary AS g
	INNER JOIN integer_archive ON g.key = integer_archive.key 
	WHERE fix BETWEEN ''%s'' AND ''%s''
	ORDER BY key;
	', st, fin, st, fin);
	
END;

$$ LANGUAGE plpgsql;
-----------------------------------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION synchronizer(_xpath VARCHAR, _status INTEGER) 
RETURNS VOID AS $$

--Функция заполнения таблицы синхронизации synchronization table

--Использование функции:
--SELECT * FROM _communication(XPath,Status);
	
BEGIN
		
	INSERT INTO synchronization (xpath, fix, status) VALUES (_xpath, Now(), _status);
	
	TRUNCATE actual_integer RESTART IDENTITY;
	TRUNCATE actual_float RESTART IDENTITY;

END;

$$ LANGUAGE plpgsql;
	</xsl:text>
  </xsl:template>

  <!--шаблон соответствует любому узлу, кроме корневого, со значением атрибута type равным 'integer'
  или 'float'-->
  <xsl:template match="node()[@type='integer' or @type='float']">
    <!--переменные, хранящие значения атрибутов-->
    <xsl:variable name="allowance" select="Allowance/@value"/>
    <xsl:variable name="unit" select="@unit"/>
    <!--запятая и перенос строки-->
    <xsl:text>,&#10;</xsl:text>
    <!--символ '(' и апостроф-->
    <xsl:value-of select="concat('(', $apostrophe)"/>
    <!--цикл для каждого предка текущего узла (построение пути XPath)-->
    <xsl:for-each select="ancestor::*">
      <xsl:variable name="element" select="local-name()"/>
      <!--переменная, хранящая имя узла-->
      <xsl:value-of select="$element"/>
      <!--текущий узел это 'Configuration' или 'Item'-->
      <xsl:if test="$element='Configuration' or $element='Item'">
        <!--тогда распечатать его в генерируемом XPath с атрибутом key и его значением-->
        <xsl:value-of select="concat('[@key=', $apostrophe, $apostrophe, @key, $apostrophe, $apostrophe, ']')"/>
      </xsl:if>
      <!--символ '/'-->
      <xsl:text>/</xsl:text>
    </xsl:for-each>
    <!--дальнейшее заполнение столбцов таблицы glossary для каждой записи в зависимости от начального
    символа значения трибута type-->
    <xsl:choose>
      <xsl:when test="starts-with(@type, 'i')">
        <xsl:value-of select="concat(local-name(), '/@value', $apostrophe, ', ', 'NULL, ', $allowance, ', ', $apostrophe, 'integer', $apostrophe, ', ', $unit, ')')"/>
      </xsl:when>
      <xsl:when test="starts-with(@type, 'f')">
        <xsl:value-of select="concat(local-name(), '/@value', $apostrophe, ', ', 'NULL, ', $allowance, ', ', $apostrophe, 'float', $apostrophe, ', ', $unit, ')')"/>
      </xsl:when>
      <xsl:when test="starts-with(@type, 'd')">
        <xsl:value-of select="concat(local-name(), '/@value', $apostrophe, ', ', 'NULL, ', $allowance, ', ', $apostrophe, 'decimal', $apostrophe, ', ', $unit, ')')"/>
      </xsl:when>
      <xsl:otherwise>
        <xsl:value-of select="concat(local-name(), '/@value', $apostrophe, ', ', 'NULL, ', $allowance, ', ', $apostrophe, 'varchar', $apostrophe, ', ', $unit, ')')"/>
      </xsl:otherwise>
    </xsl:choose>
    <xsl:text>&#10;</xsl:text>
  <!--перенос строки-->
  </xsl:template>
  <xsl:template match="text()"/>
</xsl:stylesheet>