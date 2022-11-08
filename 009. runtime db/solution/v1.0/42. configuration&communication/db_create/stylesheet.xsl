<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform">
  <xsl:output method="text" encoding="UTF-8"/>
  <xsl:variable name="apostrophe">'</xsl:variable>
  <xsl:variable name="quotes">"</xsl:variable>

  <xsl:template match="/">

    <xsl:variable name="dbname">
      <xsl:for-each select="descendant::*">
        <xsl:if test="Postgres">
          <xsl:value-of select="concat($quotes,'_', (substring-after(Postgres/Item/@key, '_')), $quotes)"/>
        </xsl:if>
      </xsl:for-each>
    </xsl:variable>

    <xsl:text>
--PostgreSQL database dump

--Database: </xsl:text>
    <xsl:value-of select="$dbname"/>
    <xsl:text>

--отменить привилегии CONNECT, чтобы избежать новых подключений
REVOKE CONNECT ON DATABASE </xsl:text>
    <xsl:value-of select="$dbname"/>
    <xsl:text> FROM PUBLIC, postgres;

--разорвать соединение
SELECT 
    pg_terminate_backend(pid) 
FROM 
    pg_stat_activity 
WHERE 
    pid &lt;&gt; pg_backend_pid() AND datname = '</xsl:text>
    <xsl:value-of select="$dbname"/>
    <xsl:text>';

--удалить БД
DROP DATABASE </xsl:text>
    <xsl:value-of select="$dbname"/>
    <xsl:text>;

--создать БД
CREATE DATABASE </xsl:text>
    <xsl:value-of select="$dbname"/>
    <xsl:text>
    WITH 
    OWNER = postgres
    ENCODING = 'UTF8'
    LC_COLLATE = 'Russian_Russia.1251'
    LC_CTYPE = 'Russian_Russia.1251'
    TABLESPACE = pg_default
    CONNECTION LIMIT = -1;

\connect </xsl:text>
    <xsl:value-of select="$dbname"/>
    <xsl:text>
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
-----------------------------------------------------------------------------------------------------
CREATE TABLE glossary (
    key SERIAL NOT NULL,
    communication TEXT NOT NULL UNIQUE,
    configuration TEXT,
    tablename VARCHAR(30) NOT NULL,
    CONSTRAINT "glossary_key" PRIMARY KEY (key)
);

COMMENT ON TABLE glossary IS 'Словарь для индефикации переменных';
COMMENT ON COLUMN glossary.key IS 'Уникальный ключ переменной для связи с друними таблицами';
COMMENT ON COLUMN glossary.configuration IS 'XPath - путь к переменной в XML-конфигурационном файле для ПО';
COMMENT ON COLUMN glossary.communication IS 'XPath - путь к переменной в XML-конфигурационном файле для коммуникаций';
COMMENT ON COLUMN glossary.tablename IS 'Имя таблицы в которой хранятся значения переменной';
-----------------------------------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION before_insert_in_glossary()
  RETURNS TRIGGER AS
$$
DECLARE 

	--переменные для:
	_TableName VARCHAR(30);		--значения 4-го поля таблицы glossary, формирующего _Table и _HyperTable    
	_Table VARCHAR(30);			--имени актуальной таблицы  
	_HyperTable VARCHAR(30);	--имени соответствующей гипертаблицы

BEGIN
	--NEW.tablename - значение поля tablename таблицы glossary, 
	--которое будет вставлено в новую запись glossary
	_TableName := NEW.tablename;
	
	_Table 		 := _TableName  || '_actual';
	_HyperTable  := _TableName	|| '_archive';
				
	--Создание актуальной и гипертаблицы, если они не существуют, 
	--исходя из значения поля tablename таблицы glossary	
	
	EXECUTE FORMAT('
	CREATE TABLE IF NOT EXISTS %I(
	key INTEGER NOT NULL,
	fix TIMESTAMP NOT NULL,
	value %s NOT NULL,
	FOREIGN KEY (key) REFERENCES glossary(key));

	SELECT create_hypertable(
	''%I'', ''fix'',
	chunk_time_interval => INTERVAL ''1 day'',
	if_not_exists => TRUE
	);

	CREATE TABLE IF NOT EXISTS %I( 
	key INTEGER NOT NULL,
	fix TIMESTAMP NOT NULL,
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
  
	CREATE TABLE synchronization(
    xpath TEXT NOT NULL,
    fix TIMESTAMP NOT NULL,
    status TEXT NOT NULL);

	CREATE TABLE IF NOT EXISTS order_actual(
	key INTEGER NOT NULL,
	fix TIMESTAMP NOT NULL,
	value TEXT NOT NULL,
	FOREIGN KEY (key) REFERENCES glossary(key));
	
	CREATE TABLE IF NOT EXISTS order_archive(
	key INTEGER NOT NULL,
	fix TIMESTAMP NOT NULL,
	value TEXT NOT NULL,
	FOREIGN KEY (key) REFERENCES glossary(key));
-----------------------------------------------------------------------------------------------------
INSERT INTO glossary (communication, configuration, tablename) VALUES --</xsl:text>
    <xsl:apply-templates/>
    <xsl:text>;
-----------------------------------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION _communication(xpath TEXT, valueNew anyelement) 
RETURNS VOID AS $$

	--Сбор информации с оборудования в БД

	--Использование функции:
	
	--1. если valueNew типа INTEGER или FLOAT, то
	--SELECT * FROM _communication('XPath',Value);
	
	--2. если valueNew типа TEXT, то
	--SELECT * FROM _communication('XPath','Value'::TEXT);

DECLARE 

	--переменные для:
	_TableName VARCHAR(30);			--значения 4-го поля таблицы glossary, формирующего _Table и _HyperTable    
	_Table VARCHAR(30);				--имени актуальной таблицы  
	_HyperTable VARCHAR(30);		--имени соответствующей гипер таблицы
	_ValueOld FLOAT;				--последнего значения 3-го поля val из гипертаблицы
	_DateOld DATE;					--даты последнего значения 2-го поля fix из гипертаблицы
	_Delta FLOAT;					--получения разницы в % между старым и новым значениями val гипертаблицы  
	_Key INTEGER;					--значения ключа таблицы glossary  
	_Existence BOOLEAN;				--признак существования в таблице _Table записи с ключом _Key
	_MaxFixArchive TIMESTAMP;		--последний фикс гипертаблицы по ключу _Key
	_MaxFixSynchro TIMESTAMP;		--последний фикс таблицы synchronization
	
BEGIN
									--получение имён актуальной и гипертаблицы
									
	--Получение значения поля 'key' таблицы glossary, используя входной аргумент XPath 
	IF (SELECT EXISTS(SELECT 1 from glossary WHERE configuration = xpath)) THEN
		_Key := (SELECT key FROM glossary WHERE configuration = xpath);
	ELSE
		_Key := (SELECT key FROM glossary WHERE communication = xpath);
	END IF;  	
			
	--Получение значения поля 'tablename' таблицы glossary, используя входной аргумент XPath 
	IF (SELECT EXISTS(SELECT 1 from glossary WHERE configuration = xpath)) THEN
		_TableName := (SELECT tablename FROM glossary WHERE configuration = xpath);
	ELSE
		_TableName := (SELECT tablename FROM glossary WHERE communication = xpath);
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
					
	--Приведение типа valueNew к INTEGER, если valueNew из таблицы integer_archive 
	IF(_TableName = 'integer') THEN
	valueNew := valueNew::INTEGER;
	END IF; 
	
	--Приведение типа valueNew к TEXT, если valueNew из таблицы text_archive 
	IF(_TableName = 'text') THEN
	valueNew := valueNew::TEXT;
	END IF; 
									--заполнение актуальной таблицы
									
	--Проверка существования в актуальной таблице _Table записи с ключом _Key 
	EXECUTE FORMAT('SELECT EXISTS(SELECT 1 from %I WHERE key = %s)', _Table, _Key) INTO _Existence;

	--Если valueNew не из таблицы text_archive
	IF(_TableName &lt;&gt; 'text') THEN
		IF (_Existence AND _Key &lt;&gt; 0) THEN
			EXECUTE FORMAT('UPDATE %I SET fix = NOW(), value = %s WHERE key = %s;', _Table, valueNew, _Key);
		ELSE
			EXECUTE FORMAT('INSERT INTO %I(key, fix, value) VALUES(%s, NOW(), %s);', _Table, _Key, valueNew);
		END IF; 
	ELSE
		IF (_Existence AND _Key &lt;&gt; 0) THEN
			EXECUTE FORMAT('UPDATE %I SET fix = NOW(), value = ''%s''::TEXT WHERE key = %s;', _Table, quote_ident(valueNew), _Key);
		ELSE
			EXECUTE FORMAT('INSERT INTO %I(key, fix, value) VALUES(%s, NOW(), ''%s''::TEXT);', _Table, _Key, quote_ident(valueNew));
		END IF; 
	END IF; 
									--заполнение гипертаблицы при синхронизации
									
	--Вычислить последние фиксы в гипертаблице и таблице synchronization
	EXECUTE FORMAT('SELECT MAX(fix) FROM %I;', _HyperTable) INTO _MaxFixArchive;
	
	IF (_MaxFixArchive IS NULL) THEN
		_MaxFixArchive := '-infinity'::timestamp;
	END IF;
	
	SELECT INTO _MaxFixSynchro (SELECT MAX(fix) FROM synchronization);	
	
	IF (_MaxFixSynchro IS NULL) THEN
		_MaxFixSynchro := '-infinity'::timestamp;
	END IF;

	--Если valueNew не из таблицы text_archive
	IF(_TableName &lt;&gt; 'text') THEN
		--Если после синхронизации не было записи в гипертаблицу, то сделать 2 записи в гипертаблице
		IF(_MaxFixSynchro > _MaxFixArchive) THEN
			EXECUTE FORMAT('INSERT INTO %I(key, fix, value) VALUES(%s, NOW(), %s);', _HyperTable, _Key, valueNew);
			EXECUTE FORMAT('INSERT INTO %I(key, fix, value) VALUES(%s, NOW() + interval ''10 millisecond'', %s);', _HyperTable, _Key, valueNew);
		END IF;	
	ELSE
			--Если после синхронизации не было записи в гипертаблицу, то сделать 2 записи в гипертаблице
		IF(_MaxFixSynchro > _MaxFixArchive) THEN
			EXECUTE FORMAT('INSERT INTO %I(key, fix, value) VALUES(%s, NOW(), ''%s''::TEXT);', _HyperTable, _Key, quote_ident(valueNew));
			EXECUTE FORMAT('INSERT INTO %I(key, fix, value) VALUES(%s, NOW() + interval ''10 millisecond'', ''%s''::TEXT);', _HyperTable, _Key, quote_ident(valueNew));
		END IF;	
	END IF;	
									--заполнение гипертаблицы после синхронизации
									
	--Если valueNew не из таблицы text_archive
	IF(_TableName &lt;&gt; 'text') THEN
		--Получение старого значения value из гипертаблицы
		EXECUTE FORMAT('SELECT value FROM %I WHERE key = %s ORDER BY fix DESC LIMIT 1;', _HyperTable, _Key) INTO _ValueOld;

		--Получение старого значения date из гипертаблицы
		EXECUTE FORMAT('SELECT fix::DATE FROM %I WHERE key = %s ORDER BY fix DESC LIMIT 1;', _HyperTable, _Key) INTO _DateOld;

		--Если старого значения в гипертаблице нет
		IF(_ValueOld IS NULL) THEN
			EXECUTE FORMAT('INSERT INTO %I(key, fix, value) VALUES(%s, NOW(), %s);', _HyperTable, _Key, valueNew);
			EXECUTE FORMAT('INSERT INTO %I(key, fix, value) VALUES(%s, NOW() + interval ''10 millisecond'', %s);', _HyperTable, _Key, valueNew);
		ELSE
			--Приведение типа _ValueOld к INTEGER, если _ValueOld из таблицы integer_archive 
			IF(_TableName = 'integer') THEN
			_ValueOld := _ValueOld::INTEGER;
			END IF; 
			
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
			
			--Если старое и новое значения различаются	
			IF(_Delta IS NOT NULL AND _Delta &lt;&gt; 0) THEN
				EXECUTE FORMAT('INSERT INTO %I(key, fix, value) VALUES(%s, NOW(), %s);', _HyperTable, _Key, valueNew);
				EXECUTE FORMAT('INSERT INTO %I(key, fix, value) VALUES(%s, NOW() + interval ''10 millisecond'', %s);', _HyperTable, _Key, valueNew);
			ELSE
				--Если старая и новая даты совпадают	
				IF(_DateOld = CURRENT_DATE) THEN
					EXECUTE FORMAT('UPDATE %I SET fix = NOW() WHERE fix = (SELECT MAX(fix) FROM %I WHERE key = %s) AND key = %s;', _HyperTable, _HyperTable, _Key, _Key);
				ELSE
					EXECUTE FORMAT('INSERT INTO %I(key, fix, value) VALUES(%s, NOW(), %s);', _HyperTable, _Key, valueNew);
					EXECUTE FORMAT('INSERT INTO %I(key, fix, value) VALUES(%s, NOW() + interval ''10 millisecond'', %s);', _HyperTable, _Key, valueNew);
				END IF;	
			END IF;	
		END IF;
	ELSE
		EXECUTE FORMAT('INSERT INTO %I(key, fix, value) VALUES(%s, NOW(), ''%s''::TEXT);', _HyperTable, _Key, quote_ident(valueNew));
		EXECUTE FORMAT('INSERT INTO %I(key, fix, value) VALUES(%s, NOW() + interval ''10 millisecond'', ''%s''::TEXT);', _HyperTable, _Key, quote_ident(valueNew));
	END IF;
END;

$$ LANGUAGE plpgsql;
-----------------------------------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION _refresh(xpath TEXT)
RETURNS RECORD AS $$

	--Обновление активной информации в ПО из БД, возврат одной записи из актуальной таблицы

	--Использование функции:
	--SELECT * FROM _refresh(XPath) AS (key INTEGER, fix TIMESTAMP, value FLOAT); - возврат записи из float_actual
	--SELECT * FROM _refresh(XPath) AS (key INTEGER, fix TIMESTAMP, value INTEGER); - возврат записи из integer_actual

DECLARE 

	--переменные для:
	_Key INTEGER;			--значения ключа таблицы glossary
	_TableName VARCHAR(30);	--значения 4-го поля таблицы glossary, формирующего _Table    
	_Table VARCHAR(30);		--имени актуальной таблицы  
	
	ret RECORD;				--возвращаемая запись
		
BEGIN
		
	--Получение значения поля 'key' таблицы glossary, используя входной аргумент XPath 
	IF (SELECT EXISTS(SELECT 1 from glossary WHERE configuration = xpath)) THEN
		_Key := (SELECT key FROM glossary WHERE configuration = xpath);
	ELSE
		_Key := (SELECT key FROM glossary WHERE communication = xpath);
	END IF;  	
			
	--Получение значения поля 'tablename' таблицы glossary, используя входной аргумент XPath 
	IF (SELECT EXISTS(SELECT 1 from glossary WHERE configuration = xpath)) THEN
		_TableName := (SELECT tablename FROM glossary WHERE configuration = xpath);
	ELSE
		_TableName := (SELECT tablename FROM glossary WHERE communication = xpath);
	END IF;  
	
	--Получение имени актуальной таблицы
	IF (_TableName IS NOT NULL) THEN 
		_Table := _TableName || '_actual';
	ELSE
		_Table := NULL;
	END IF;  

	--Получение одной записи из актуальной таблицы
	IF (_Table IS NOT NULL) THEN
		EXECUTE FORMAT('
		SELECT %I.key, %I.fix, %I.value
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
RETURNS TABLE (configuration TEXT, fix TIMESTAMP, value_float FLOAT, value_integer INTEGER) AS $$

	--Обновление активной информации в ПО из БД, возврат записей из всех активных таблиц

	--Использование функции:
	--SELECT * FROM _refresh();

DECLARE 
	
BEGIN
	
	RETURN QUERY EXECUTE FORMAT('
	SELECT g.configuration AS config, float_actual.fix AS fix, float_actual.value AS value_float, NULL AS value_integer
	FROM glossary AS g
	INNER JOIN float_actual ON g.key = float_actual.key 
	UNION
	SELECT g.configuration AS config, integer_actual.fix AS fix, NULL AS value_float, integer_actual.value AS value_integer
	FROM glossary AS g
	INNER JOIN integer_actual ON g.key = integer_actual.key;
	');			
	
END;

$$ LANGUAGE plpgsql;
-----------------------------------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION _refreshold(xpath TEXT, st TIMESTAMP, fin TIMESTAMP)
RETURNS TABLE (_key INTEGER, fix TIMESTAMP, _value FLOAT) AS $$

	--Обновление архивной информации в ПО из БД, возврат записей из гипертаблицы от st до fin
	
	--Использование функции:
	--SELECT * FROM _refreshold(XPath, St, Fin);

DECLARE 

	--переменные для:
	_Key INTEGER;				--значения ключа таблицы glossary
	_TableName VARCHAR(30);		--значения 4-го поля таблицы glossary, формирующего _HyperTable    
	_HyperTable VARCHAR(30);	--имени гипертаблицы  
		
BEGIN

	--Получение значения поля 'key' таблицы glossary, используя входной аргумент XPath 
	IF (SELECT EXISTS(SELECT 1 from glossary WHERE configuration = xpath)) THEN
		_Key := (SELECT key FROM glossary WHERE configuration = xpath);
	ELSE
		_Key := (SELECT key FROM glossary WHERE communication = xpath);
	END IF;  	
			
	--Получение значения поля 'tablename' таблицы glossary, используя входной аргумент XPath 
	IF (SELECT EXISTS(SELECT 1 from glossary WHERE configuration = xpath)) THEN
		_TableName := (SELECT tablename FROM glossary WHERE configuration = xpath);
	ELSE
		_TableName := (SELECT tablename FROM glossary WHERE communication = xpath);
	END IF;  
	
	--Получение имени гипертаблицы
	IF (_TableName IS NOT NULL) THEN 
		_HyperTable := _TableName || '_archive';
	ELSE
		_HyperTable := NULL;
	END IF; 

	RETURN QUERY EXECUTE FORMAT('	
	SELECT %I.key, %I.fix, %I.value
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
RETURNS TABLE (_key INTEGER, configuration TEXT, fix TIMESTAMP, value_float FLOAT, value_integer INTEGER) AS $$

	--Обновление архивной информации в ПО из БД, возврат записей из всех гипертаблиц от st до fin
	
	--Использование функции:
	--SELECT * FROM _refreshold(St, Fin);

DECLARE 
		
BEGIN

	--возврат записей из гипертаблицы от st до fin
	RETURN QUERY EXECUTE FORMAT('
	SELECT g.key AS key, g.configuration AS config, float_archive.fix AS fix, float_archive.value AS value_float, NULL AS value_integer
	FROM glossary AS g
	INNER JOIN float_archive ON g.key = float_archive.key 
	WHERE fix BETWEEN ''%s'' AND ''%s''
	UNION
	SELECT g.key AS key, configuration AS config, integer_archive.fix AS fix, NULL AS value_float, integer_archive.value AS value_integer
	FROM glossary AS g
	INNER JOIN integer_archive ON g.key = integer_archive.key 
	WHERE fix BETWEEN ''%s'' AND ''%s''
	ORDER BY key;
	', st, fin, st, fin);
	
END;

$$ LANGUAGE plpgsql;
-----------------------------------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION _synchronizer(_xpath TEXT, _status TEXT) 
RETURNS TIMESTAMP AS $$

	--Функция заполнения таблицы синхронизации synchronization table

	--Использование функции:
	--SELECT * FROM _communication(XPath,Status);
	
BEGIN
		
	INSERT INTO synchronization (xpath, fix, status) VALUES (_xpath, NOW(), _status);
	
	--очистить таблицы integer_actual и float_actual
	TRUNCATE integer_actual RESTART IDENTITY;
	TRUNCATE float_actual RESTART IDENTITY;
	
	RETURN NOW();

END;

$$ LANGUAGE plpgsql;
-----------------------------------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION _order(xpath TEXT, _value TEXT) 
RETURNS VOID AS $$

	--Функция заполнения таблиц order_actual и order_archive

	--Использование функции:
	--SELECT * FROM _order(XPath,Value);

DECLARE 

	--переменные для:
	_Key INTEGER;			--значения ключа таблицы glossary  
	_Existence BOOLEAN;		--признак существования в таблице order_actual записи с ключом _Key
	
BEGIN

	--Получение значения поля 'key' таблицы glossary, используя входной аргумент XPath 
	IF (SELECT EXISTS(SELECT 1 from glossary WHERE configuration = xpath)) THEN
		_Key := (SELECT key FROM glossary WHERE configuration = xpath);
	ELSE
		_Key := (SELECT key FROM glossary WHERE communication = xpath);
	END IF;  	

	--Проверка существования в таблице order_actual записи с ключом _Key 
	SELECT INTO _Existence (SELECT EXISTS(SELECT 1 from order_actual WHERE key = _Key));

	--order_actual
	IF (_Existence AND _Key &lt;&gt; 0) THEN
		UPDATE order_actual SET fix = NOW(), value = _value WHERE key = _Key;
    ELSE
		IF (_Key IS NOT NULL) THEN
			INSERT INTO order_actual(key, fix, value) VALUES(_Key, NOW(), _value);
		END IF;  
	END IF;

	--order_archive
	IF (_Existence AND _Key &lt;&gt; 0 AND _Key IS NOT NULL) THEN
		--вставить новую запись в таблицу order_archive
		INSERT INTO order_archive(key, fix, value) VALUES(_Key, NOW(), _value);
    END IF;  
    
END;

$$ LANGUAGE plpgsql;
-----------------------------------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION _order() 
RETURNS TABLE (_xpath TEXT, fix TIMESTAMP, _value TEXT) AS $$

	--Функция, возвращающая видоизменённую таблицу order_actual

	--Использование функции:
	--SELECT * FROM _order();
	
BEGIN

	RETURN QUERY 
		SELECT glossary.communication, order_actual.fix, order_actual.value
		FROM order_actual  
		INNER JOIN glossary ON order_actual.key = glossary.key;
		
	--очистить таблицу order_actual
	TRUNCATE order_actual RESTART IDENTITY;	
	
    RETURN;

END;

$$ LANGUAGE plpgsql;
	</xsl:text>
  </xsl:template>
  <xsl:template match="node()[@type]">
    <xsl:variable name="type" select="@type"/>
    <xsl:text>,&#10;</xsl:text>
    <xsl:value-of select="concat('(', $apostrophe)"/>
    <xsl:for-each select="ancestor::*">
      <xsl:variable name="element" select="local-name()"/>
      <xsl:value-of select="$element"/>
      <xsl:if test="$element='Configuration' or $element='Item' or $element='Equipment'">
        <xsl:value-of select="concat('[@key=', $apostrophe, $apostrophe, @key, $apostrophe, $apostrophe, ']')"/>
      </xsl:if>
      <xsl:text>/</xsl:text>
    </xsl:for-each>
    <xsl:value-of select="concat(local-name(), $apostrophe, ', ', 'NULL, ', $apostrophe, $type, $apostrophe, ')')"/>
    <xsl:text>&#10;</xsl:text>
  </xsl:template>
  <xsl:template match="text()"/>
</xsl:stylesheet>