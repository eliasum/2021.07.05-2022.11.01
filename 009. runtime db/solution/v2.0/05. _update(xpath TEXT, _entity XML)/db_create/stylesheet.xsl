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

	--таблицы order
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

	--таблицы entity
	CREATE TABLE IF NOT EXISTS entity_actual(
	key INTEGER NOT NULL,
	fix TIMESTAMP NOT NULL,
	entity XML NOT NULL,
	FOREIGN KEY (key) REFERENCES glossary(key));
	
	CREATE TABLE IF NOT EXISTS entity_archive(
	key INTEGER NOT NULL,
	fix TIMESTAMP NOT NULL,
	entity XML NOT NULL,
	FOREIGN KEY (key) REFERENCES glossary(key));
-----------------------------------------------------------------------------------------------------
INSERT INTO glossary (communication, configuration, tablename) VALUES --</xsl:text>
    <xsl:apply-templates/>
    <xsl:text>;
-----------------------------------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION _update(xpath TEXT, _entity XML) 
RETURNS VOID AS $$

	--Использование функции:
	
	--SELECT * FROM _update('XPath','Entity');
	
DECLARE 

	--переменные для:
	_EntityOld XML;					
	_Key INTEGER;					--значения ключа таблицы glossary  
	_Existence BOOLEAN;				--признак существования в таблице entity_actual записи с ключом _Key
	_Order BOOLEAN;
	
BEGIN
									
	IF (SELECT EXISTS(SELECT 1 from glossary WHERE configuration = xpath)) THEN
		_Key := (SELECT key FROM glossary WHERE configuration = xpath);
		
		--Проверка существования в любом узле xml-данных с ключом _Key столбца entity таблицы entity_actual атрибута @order 	
		EXECUTE FORMAT('SELECT xpath_exists(''*/@order'', entity) FROM entity_actual WHERE key = %s;', _Key) INTO _Order;
		
		IF(_Order) THEN
			UPDATE entity_actual SET fix = NOW(), entity = _entity WHERE key = _Key; 
		END IF;	
	END IF; 
   	IF (SELECT EXISTS(SELECT 1 from glossary WHERE communication = xpath)) THEN
        _Key := (SELECT key FROM glossary WHERE communication = xpath);
		
		--Проверка существования в любом узле xml-данных с ключом _Key столбца entity таблицы entity_actual атрибута @order 	
		EXECUTE FORMAT('SELECT xpath_exists(''*/@order'', entity) FROM entity_actual WHERE key = %s;', _Key) INTO _Order;
		
		IF(_Order = FALSE) THEN
			UPDATE entity_actual SET fix = NOW(), entity = _entity WHERE key = _Key; 
		END IF;			
    END IF; 
			
									--заполнение актуальной таблицы
									
	--Проверка существования в актуальной таблице entity_actual записи с ключом _Key 
	EXECUTE FORMAT('SELECT EXISTS(SELECT 1 from entity_actual WHERE key = %s)', _Key) INTO _Existence;

	--entity_actual
	IF (_Existence) THEN
		UPDATE entity_actual SET fix = NOW(), entity = _entity WHERE key = _Key;
	ELSE
		INSERT INTO entity_actual(key, fix, entity) VALUES(_Key, NOW(), _entity);
	END IF; 

									--заполнение гипертаблицы после синхронизации
									
	--Получение старого значения entity из гипертаблицы
	EXECUTE FORMAT('SELECT entity FROM entity_archive WHERE key = %s ORDER BY fix DESC LIMIT 1;', _Key) INTO _EntityOld;

	--Если старого значения в гипертаблице нет
	IF(_EntityOld IS NULL) THEN
		INSERT INTO entity_archive(key, fix, entity) VALUES(_Key, NOW(), _entity);
		INSERT INTO entity_archive(key, fix, entity) VALUES(_Key, NOW() + interval '10 millisecond', _entity);
	ELSE
		UPDATE entity_archive SET fix = NOW(), entity = _entity WHERE key = _Key; 
	END IF;

END;

$$ LANGUAGE plpgsql;
-----------------------------------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION _refresh()
RETURNS TABLE (entity XML, communication TEXT, configuration TEXT) AS $$

	--Использование функции:
	--SELECT * FROM _refresh();
	
BEGIN
	
	RETURN QUERY EXECUTE FORMAT('
	SELECT entity_actual.entity AS entity, g.communication AS config, g.configuration AS config
	FROM glossary AS g
	INNER JOIN entity_actual ON g.key = entity_actual.key;
	');	
	
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
    <xsl:value-of select="concat(local-name(), $apostrophe, ', NULL, ', $apostrophe, $type, $apostrophe, ')')"/>
    <xsl:text>&#10;</xsl:text>
  </xsl:template>
  <xsl:template match="text()"/>
</xsl:stylesheet>