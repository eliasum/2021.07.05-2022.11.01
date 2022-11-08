
--PostgreSQL database dump

--Database: "_036CE062"

--отменить привилегии CONNECT, чтобы избежать новых подключений
REVOKE CONNECT ON DATABASE "_036CE062" FROM PUBLIC, postgres;

--разорвать соединение
SELECT 
    pg_terminate_backend(pid) 
FROM 
    pg_stat_activity 
WHERE 
    pid <> pg_backend_pid() AND datname = '"_036CE062"';

--удалить БД
DROP DATABASE "_036CE062";

--создать БД
CREATE DATABASE "_036CE062"
    WITH 
    OWNER = postgres
    ENCODING = 'UTF8'
    LC_COLLATE = 'Russian_Russia.1251'
    LC_CTYPE = 'Russian_Russia.1251'
    TABLESPACE = pg_default
    CONNECTION LIMIT = -1;

\connect "_036CE062"
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

	--таблицы order
	CREATE TABLE IF NOT EXISTS order_actual(
	key INTEGER NOT NULL,
	fix TIMESTAMP NOT NULL,
	entity XML NOT NULL,
	FOREIGN KEY (key) REFERENCES glossary(key));
	
	CREATE TABLE IF NOT EXISTS order_archive(
	key INTEGER NOT NULL,
	fix TIMESTAMP NOT NULL,
	entity XML NOT NULL,
	FOREIGN KEY (key) REFERENCES glossary(key));

	--таблицы value
	CREATE TABLE IF NOT EXISTS value_actual(
	key INTEGER NOT NULL,
	fix TIMESTAMP NOT NULL,
	entity XML NOT NULL,
	FOREIGN KEY (key) REFERENCES glossary(key));
	
	CREATE TABLE IF NOT EXISTS value_archive(
	key INTEGER NOT NULL,
	fix TIMESTAMP NOT NULL,
	entity XML NOT NULL,
	FOREIGN KEY (key) REFERENCES glossary(key));
-----------------------------------------------------------------------------------------------------
INSERT INTO glossary (communication, configuration, tablename) VALUES --,
('Configuration[@key=''_036CE062.Communicator'']/Scale/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE062'']/Communication/Item[@key=''serialport'']/Modbus/Item[@key=''COM1'']/Board/Item[@key=''_045CE087'']/Adress/Item[@key=''40'']/Channel/Item[@key=''1'']/Voltage', NULL, 'integer')
,
('Configuration[@key=''_036CE062.Communicator'']/Scale/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE062'']/Communication/Item[@key=''serialport'']/Modbus/Item[@key=''COM1'']/Board/Item[@key=''_045CE087'']/Adress/Item[@key=''40'']/Channel/Item[@key=''1'']/Amperage', NULL, 'float')
,
('Configuration[@key=''_036CE062.Communicator'']/Scale/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE062'']/Communication/Item[@key=''serialport'']/Modbus/Item[@key=''COM1'']/Board/Item[@key=''_045CE087'']/Adress/Item[@key=''40'']/Channel/Item[@key=''B'']/State', NULL, 'bool')
,
('Configuration[@key=''_036CE062.Communicator'']/Scale/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE062'']/Communication/Item[@key=''serialport'']/Modbus/Item[@key=''COM1'']/Board/Item[@key=''Termodat'']/Adress/Item[@key=''0A'']/Channel/Item[@key=''01'']/Termodat/Command/Item[@key=''0001'']/Temperature', NULL, 'float')
,
('Configuration[@key=''_036CE062.Communicator'']/Scale/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE062'']/Communication/Item[@key=''serialport'']/Modbus/Item[@key=''COM1'']/Board/Item[@key=''Termodat'']/Adress/Item[@key=''0A'']/Channel/Item[@key=''01'']/Termodat/Command/Item[@key=''0001'']/Time', NULL, 'integer')
,
('Configuration[@key=''_036CE062.Communicator'']/Scale/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE062'']/Communication/Item[@key=''serialport'']/Modbus/Item[@key=''COM1'']/Board/Item[@key=''Termodat'']/Adress/Item[@key=''0A'']/Channel/Item[@key=''01'']/Termodat/Command/Item[@key=''0005'']/Temperature', NULL, 'float')
,
('Configuration[@key=''_036CE062.Communicator'']/Scale/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE062'']/Communication/Item[@key=''serialport'']/Modbus/Item[@key=''COM1'']/Board/Item[@key=''Termodat'']/Adress/Item[@key=''0A'']/Channel/Item[@key=''01'']/Termodat/Command/Item[@key=''0005'']/Rate', NULL, 'float')
,
('Configuration[@key=''_036CE062.Communicator'']/Scale/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE062'']/Communication/Item[@key=''serialport'']/Modbus/Item[@key=''COM1'']/Board/Item[@key=''Termodat'']/Adress/Item[@key=''0A'']/Channel/Item[@key=''01'']/Termodat/Command/Item[@key=''0006'']/Temperature', NULL, 'float')
,
('Configuration[@key=''_036CE062.Communicator'']/Scale/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE062'']/Communication/Item[@key=''serialport'']/Modbus/Item[@key=''COM1'']/Board/Item[@key=''Termodat'']/Adress/Item[@key=''0A'']/Channel/Item[@key=''01'']/Termodat/Command/Item[@key=''0006'']/Rate', NULL, 'float')
,
('Configuration[@key=''_036CE062.Communicator'']/Scale/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE062'']/Communication/Item[@key=''serialport'']/Modbus/Item[@key=''COM1'']/Board/Item[@key=''Termodat'']/Adress/Item[@key=''0A'']/Channel/Item[@key=''01'']/Termodat/Status/Temperature', NULL, 'float')
,
('Configuration[@key=''_036CE062.Communicator'']/Scale/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE062'']/Communication/Item[@key=''serialport'']/Modbus/Item[@key=''COM1'']/Board/Item[@key=''_045CE100'']/Adress/Item[@key=''31'']/Channel/Item[@key=''1'']/Amperage', NULL, 'float')
,
('Configuration[@key=''_036CE062.Communicator'']/Scale/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE062'']/Communication/Item[@key=''serialport'']/Modbus/Item[@key=''COM1'']/Board/Item[@key=''_045CE100'']/Adress/Item[@key=''31'']/Channel/Item[@key=''2'']/Amperage', NULL, 'float')
,
('Configuration[@key=''_036CE062.Communicator'']/Scale/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE062'']/Communication/Item[@key=''serialport'']/Modbus/Item[@key=''COM1'']/Board/Item[@key=''_045CE100'']/Adress/Item[@key=''31'']/Channel/Item[@key=''3'']/Amperage', NULL, 'float')
,
('Configuration[@key=''_036CE062.Communicator'']/Scale/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE062'']/Communication/Item[@key=''serialport'']/Modbus/Item[@key=''COM1'']/Board/Item[@key=''_045CE100'']/Adress/Item[@key=''31'']/Channel/Item[@key=''4'']/Amperage', NULL, 'float')
,
('Configuration[@key=''_036CE062.Communicator'']/Scale/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE062'']/Communication/Item[@key=''serialport'']/Modbus/Item[@key=''COM1'']/Board/Item[@key=''_045CE100'']/Adress/Item[@key=''31'']/Channel/Item[@key=''5'']/Amperage', NULL, 'float')
,
('Configuration[@key=''_036CE062.Communicator'']/Scale/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE062'']/Communication/Item[@key=''serialport'']/Modbus/Item[@key=''COM1'']/Board/Item[@key=''_045CE100'']/Adress/Item[@key=''31'']/Channel/Item[@key=''6'']/Amperage', NULL, 'float')
,
('Configuration[@key=''_036CE062.Communicator'']/Scale/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE062'']/Communication/Item[@key=''serialport'']/Modbus/Item[@key=''COM1'']/Board/Item[@key=''_045CE100'']/Adress/Item[@key=''31'']/Channel/Item[@key=''7'']/Amperage', NULL, 'float')
,
('Configuration[@key=''_036CE062.Communicator'']/Scale/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE062'']/Communication/Item[@key=''serialport'']/Modbus/Item[@key=''COM1'']/Board/Item[@key=''_045CE100'']/Adress/Item[@key=''31'']/Channel/Item[@key=''8'']/Amperage', NULL, 'float')
,
('Configuration[@key=''_036CE062.Communicator'']/Scale/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE062'']/Communication/Item[@key=''serialport'']/Modbus/Item[@key=''COM1'']/Board/Item[@key=''_045CE100'']/Adress/Item[@key=''31'']/Channel/Item[@key=''9'']/Amperage', NULL, 'float')
,
('Configuration[@key=''_036CE062.Communicator'']/Scale/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE062'']/Communication/Item[@key=''serialport'']/Modbus/Item[@key=''COM1'']/Board/Item[@key=''_045CE100'']/Adress/Item[@key=''31'']/Channel/Item[@key=''A'']/Amperage', NULL, 'float')
,
('Configuration[@key=''_036CE062.Communicator'']/Scale/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE062'']/Communication/Item[@key=''serialport'']/Modbus/Item[@key=''COM1'']/Board/Item[@key=''_045CE100'']/Adress/Item[@key=''31'']/Channel/Item[@key=''B'']/Amperage', NULL, 'float')
,
('Configuration[@key=''_036CE062.Communicator'']/Scale/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE062'']/Communication/Item[@key=''serialport'']/Modbus/Item[@key=''COM1'']/Board/Item[@key=''_045CE100'']/Adress/Item[@key=''31'']/Channel/Item[@key=''C'']/Amperage', NULL, 'float')
,
('Configuration[@key=''_036CE062.Communicator'']/Scale/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE062'']/Communication/Item[@key=''serialport'']/Modbus/Item[@key=''COM1'']/Board/Item[@key=''_045CE100'']/Adress/Item[@key=''31'']/Channel/Item[@key=''D'']/Amperage', NULL, 'float')
,
('Configuration[@key=''_036CE062.Communicator'']/Scale/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE062'']/Communication/Item[@key=''serialport'']/Modbus/Item[@key=''COM1'']/Board/Item[@key=''_045CE100'']/Adress/Item[@key=''31'']/Channel/Item[@key=''E'']/Amperage', NULL, 'float')
,
('Configuration[@key=''_036CE062.Communicator'']/Scale/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE062'']/Communication/Item[@key=''serialport'']/Modbus/Item[@key=''COM1'']/Board/Item[@key=''_045CE100'']/Adress/Item[@key=''31'']/Channel/Item[@key=''F'']/Amperage', NULL, 'float')
,
('Configuration[@key=''_036CE062.Communicator'']/Scale/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE062'']/Communication/Item[@key=''serialport'']/Modbus/Item[@key=''COM1'']/Board/Item[@key=''_045CE100'']/Adress/Item[@key=''32'']/Channel/Item[@key=''1'']/Amperage', NULL, 'float')
,
('Configuration[@key=''_036CE062.Communicator'']/Scale/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE062'']/Communication/Item[@key=''serialport'']/Modbus/Item[@key=''COM1'']/Board/Item[@key=''_045CE100'']/Adress/Item[@key=''32'']/Channel/Item[@key=''2'']/Amperage', NULL, 'float')
,
('Configuration[@key=''_036CE062.Communicator'']/Scale/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE062'']/Communication/Item[@key=''serialport'']/Modbus/Item[@key=''COM1'']/Board/Item[@key=''_045CE100'']/Adress/Item[@key=''32'']/Channel/Item[@key=''3'']/Amperage', NULL, 'float')
,
('Configuration[@key=''_036CE062.Communicator'']/Scale/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE062'']/Communication/Item[@key=''serialport'']/Modbus/Item[@key=''COM1'']/Board/Item[@key=''_045CE100'']/Adress/Item[@key=''32'']/Channel/Item[@key=''4'']/Amperage', NULL, 'float')
,
('Configuration[@key=''_036CE062.Communicator'']/Scale/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE062'']/Communication/Item[@key=''serialport'']/Modbus/Item[@key=''COM1'']/Board/Item[@key=''_045CE100'']/Adress/Item[@key=''32'']/Channel/Item[@key=''5'']/Amperage', NULL, 'float')
,
('Configuration[@key=''_036CE062.Communicator'']/Scale/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE062'']/Communication/Item[@key=''serialport'']/Modbus/Item[@key=''COM1'']/Board/Item[@key=''_045CE100'']/Adress/Item[@key=''32'']/Channel/Item[@key=''6'']/Amperage', NULL, 'float')
,
('Configuration[@key=''_036CE062.Communicator'']/Scale/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE062'']/Communication/Item[@key=''serialport'']/Modbus/Item[@key=''COM1'']/Board/Item[@key=''_045CE100'']/Adress/Item[@key=''32'']/Channel/Item[@key=''7'']/Amperage', NULL, 'float')
,
('Configuration[@key=''_036CE062.Communicator'']/Scale/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE062'']/Communication/Item[@key=''serialport'']/Modbus/Item[@key=''COM1'']/Board/Item[@key=''_045CE100'']/Adress/Item[@key=''32'']/Channel/Item[@key=''8'']/Amperage', NULL, 'float')
,
('Configuration[@key=''_036CE062.Communicator'']/Scale/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE062'']/Communication/Item[@key=''serialport'']/Modbus/Item[@key=''COM1'']/Board/Item[@key=''_045CE100'']/Adress/Item[@key=''32'']/Channel/Item[@key=''9'']/Amperage', NULL, 'float')
,
('Configuration[@key=''_036CE062.Communicator'']/Scale/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE062'']/Communication/Item[@key=''serialport'']/Modbus/Item[@key=''COM1'']/Board/Item[@key=''_045CE100'']/Adress/Item[@key=''32'']/Channel/Item[@key=''A'']/Amperage', NULL, 'float')
,
('Configuration[@key=''_036CE062.Communicator'']/Scale/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE062'']/Communication/Item[@key=''serialport'']/Modbus/Item[@key=''COM1'']/Board/Item[@key=''_045CE100'']/Adress/Item[@key=''32'']/Channel/Item[@key=''B'']/Amperage', NULL, 'float')
,
('Configuration[@key=''_036CE062.Communicator'']/Scale/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE062'']/Communication/Item[@key=''serialport'']/Modbus/Item[@key=''COM1'']/Board/Item[@key=''_045CE100'']/Adress/Item[@key=''32'']/Channel/Item[@key=''C'']/Amperage', NULL, 'float')
,
('Configuration[@key=''_036CE062.Communicator'']/Scale/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE062'']/Communication/Item[@key=''serialport'']/Modbus/Item[@key=''COM1'']/Board/Item[@key=''_045CE100'']/Adress/Item[@key=''32'']/Channel/Item[@key=''D'']/Amperage', NULL, 'float')
,
('Configuration[@key=''_036CE062.Communicator'']/Scale/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE062'']/Communication/Item[@key=''serialport'']/Modbus/Item[@key=''COM1'']/Board/Item[@key=''_045CE100'']/Adress/Item[@key=''32'']/Channel/Item[@key=''E'']/Amperage', NULL, 'float')
,
('Configuration[@key=''_036CE062.Communicator'']/Scale/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE062'']/Communication/Item[@key=''serialport'']/Modbus/Item[@key=''COM1'']/Board/Item[@key=''_045CE100'']/Adress/Item[@key=''32'']/Channel/Item[@key=''F'']/Amperage', NULL, 'float')
,
('Configuration[@key=''_036CE062.Communicator'']/Scale/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE062'']/Communication/Item[@key=''serialport'']/Modbus/Item[@key=''COM1'']/Board/Item[@key=''_045CE100'']/Adress/Item[@key=''33'']/Channel/Item[@key=''1'']/Amperage', NULL, 'float')
,
('Configuration[@key=''_036CE062.Communicator'']/Scale/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE062'']/Communication/Item[@key=''serialport'']/Modbus/Item[@key=''COM1'']/Board/Item[@key=''_045CE100'']/Adress/Item[@key=''33'']/Channel/Item[@key=''2'']/Amperage', NULL, 'float')
,
('Configuration[@key=''_036CE062.Communicator'']/Scale/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE062'']/Communication/Item[@key=''serialport'']/Modbus/Item[@key=''COM1'']/Board/Item[@key=''_045CE100'']/Adress/Item[@key=''33'']/Channel/Item[@key=''3'']/Amperage', NULL, 'float')
,
('Configuration[@key=''_036CE062.Communicator'']/Scale/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE062'']/Communication/Item[@key=''serialport'']/Modbus/Item[@key=''COM1'']/Board/Item[@key=''_045CE100'']/Adress/Item[@key=''33'']/Channel/Item[@key=''4'']/Amperage', NULL, 'float')
,
('Configuration[@key=''_036CE062.Communicator'']/Scale/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE062'']/Communication/Item[@key=''serialport'']/Modbus/Item[@key=''COM1'']/Board/Item[@key=''_045CE100'']/Adress/Item[@key=''33'']/Channel/Item[@key=''5'']/Amperage', NULL, 'float')
,
('Configuration[@key=''_036CE062.Communicator'']/Scale/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE062'']/Communication/Item[@key=''serialport'']/Modbus/Item[@key=''COM1'']/Board/Item[@key=''_045CE100'']/Adress/Item[@key=''33'']/Channel/Item[@key=''6'']/Amperage', NULL, 'float')
,
('Configuration[@key=''_036CE062.Communicator'']/Scale/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE062'']/Communication/Item[@key=''serialport'']/Modbus/Item[@key=''COM1'']/Board/Item[@key=''_045CE100'']/Adress/Item[@key=''33'']/Channel/Item[@key=''7'']/Amperage', NULL, 'float')
,
('Configuration[@key=''_036CE062.Communicator'']/Scale/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE062'']/Communication/Item[@key=''serialport'']/Modbus/Item[@key=''COM1'']/Board/Item[@key=''_045CE100'']/Adress/Item[@key=''33'']/Channel/Item[@key=''8'']/Amperage', NULL, 'float')
,
('Configuration[@key=''_036CE062.Communicator'']/Scale/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE062'']/Communication/Item[@key=''serialport'']/Modbus/Item[@key=''COM1'']/Board/Item[@key=''_045CE100'']/Adress/Item[@key=''33'']/Channel/Item[@key=''9'']/Amperage', NULL, 'float')
,
('Configuration[@key=''_036CE062.Communicator'']/Scale/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE062'']/Communication/Item[@key=''serialport'']/Modbus/Item[@key=''COM1'']/Board/Item[@key=''_045CE100'']/Adress/Item[@key=''33'']/Channel/Item[@key=''A'']/Amperage', NULL, 'float')
,
('Configuration[@key=''_036CE062.Communicator'']/Scale/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE062'']/Communication/Item[@key=''serialport'']/Modbus/Item[@key=''COM1'']/Board/Item[@key=''_045CE100'']/Adress/Item[@key=''33'']/Channel/Item[@key=''B'']/Amperage', NULL, 'float')
,
('Configuration[@key=''_036CE062.Communicator'']/Scale/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE062'']/Communication/Item[@key=''serialport'']/Modbus/Item[@key=''COM1'']/Board/Item[@key=''_045CE100'']/Adress/Item[@key=''33'']/Channel/Item[@key=''C'']/Amperage', NULL, 'float')
,
('Configuration[@key=''_036CE062.Communicator'']/Scale/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE062'']/Communication/Item[@key=''serialport'']/Modbus/Item[@key=''COM1'']/Board/Item[@key=''_045CE100'']/Adress/Item[@key=''33'']/Channel/Item[@key=''D'']/Amperage', NULL, 'float')
,
('Configuration[@key=''_036CE062.Communicator'']/Scale/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE062'']/Communication/Item[@key=''serialport'']/Modbus/Item[@key=''COM1'']/Board/Item[@key=''_045CE100'']/Adress/Item[@key=''33'']/Channel/Item[@key=''E'']/Amperage', NULL, 'float')
,
('Configuration[@key=''_036CE062.Communicator'']/Scale/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE062'']/Communication/Item[@key=''serialport'']/Modbus/Item[@key=''COM1'']/Board/Item[@key=''_045CE100'']/Adress/Item[@key=''33'']/Channel/Item[@key=''F'']/Amperage', NULL, 'float')
,
('Configuration[@key=''_036CE062.Communicator'']/Scale/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE062'']/Communication/Item[@key=''serialport'']/Modbus/Item[@key=''COM1'']/Board/Item[@key=''_045CE100'']/Adress/Item[@key=''34'']/Channel/Item[@key=''1'']/Amperage', NULL, 'float')
,
('Configuration[@key=''_036CE062.Communicator'']/Scale/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE062'']/Communication/Item[@key=''serialport'']/Modbus/Item[@key=''COM1'']/Board/Item[@key=''_045CE100'']/Adress/Item[@key=''34'']/Channel/Item[@key=''2'']/Amperage', NULL, 'float')
,
('Configuration[@key=''_036CE062.Communicator'']/Scale/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE062'']/Communication/Item[@key=''serialport'']/Modbus/Item[@key=''COM1'']/Board/Item[@key=''_045CE100'']/Adress/Item[@key=''34'']/Channel/Item[@key=''3'']/Amperage', NULL, 'float')
,
('Configuration[@key=''_036CE062.Communicator'']/Scale/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE062'']/Communication/Item[@key=''serialport'']/Modbus/Item[@key=''COM1'']/Board/Item[@key=''_045CE100'']/Adress/Item[@key=''34'']/Channel/Item[@key=''4'']/Amperage', NULL, 'float')
,
('Configuration[@key=''_036CE062.Communicator'']/Scale/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE062'']/Communication/Item[@key=''serialport'']/Modbus/Item[@key=''COM1'']/Board/Item[@key=''_045CE100'']/Adress/Item[@key=''34'']/Channel/Item[@key=''5'']/Amperage', NULL, 'float')
,
('Configuration[@key=''_036CE062.Communicator'']/Scale/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE062'']/Communication/Item[@key=''serialport'']/Modbus/Item[@key=''COM1'']/Board/Item[@key=''_045CE100'']/Adress/Item[@key=''34'']/Channel/Item[@key=''6'']/Amperage', NULL, 'float')
,
('Configuration[@key=''_036CE062.Communicator'']/Scale/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE062'']/Communication/Item[@key=''serialport'']/Modbus/Item[@key=''COM1'']/Board/Item[@key=''_045CE100'']/Adress/Item[@key=''34'']/Channel/Item[@key=''7'']/Amperage', NULL, 'float')
,
('Configuration[@key=''_036CE062.Communicator'']/Scale/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE062'']/Communication/Item[@key=''serialport'']/Modbus/Item[@key=''COM1'']/Board/Item[@key=''_045CE100'']/Adress/Item[@key=''34'']/Channel/Item[@key=''8'']/Amperage', NULL, 'float')
,
('Configuration[@key=''_036CE062.Communicator'']/Scale/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE062'']/Communication/Item[@key=''serialport'']/Modbus/Item[@key=''COM1'']/Board/Item[@key=''_045CE100'']/Adress/Item[@key=''34'']/Channel/Item[@key=''9'']/Amperage', NULL, 'float')
,
('Configuration[@key=''_036CE062.Communicator'']/Scale/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE062'']/Communication/Item[@key=''serialport'']/Modbus/Item[@key=''COM1'']/Board/Item[@key=''_045CE100'']/Adress/Item[@key=''34'']/Channel/Item[@key=''A'']/Amperage', NULL, 'float')
,
('Configuration[@key=''_036CE062.Communicator'']/Scale/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE062'']/Communication/Item[@key=''serialport'']/Modbus/Item[@key=''COM1'']/Board/Item[@key=''_045CE100'']/Adress/Item[@key=''34'']/Channel/Item[@key=''B'']/Amperage', NULL, 'float')
,
('Configuration[@key=''_036CE062.Communicator'']/Scale/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE062'']/Communication/Item[@key=''serialport'']/Modbus/Item[@key=''COM1'']/Board/Item[@key=''_045CE100'']/Adress/Item[@key=''34'']/Channel/Item[@key=''C'']/Amperage', NULL, 'float')
,
('Configuration[@key=''_036CE062.Communicator'']/Scale/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE062'']/Communication/Item[@key=''serialport'']/Modbus/Item[@key=''COM1'']/Board/Item[@key=''_045CE100'']/Adress/Item[@key=''34'']/Channel/Item[@key=''D'']/Amperage', NULL, 'float')
,
('Configuration[@key=''_036CE062.Communicator'']/Scale/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE062'']/Communication/Item[@key=''serialport'']/Modbus/Item[@key=''COM1'']/Board/Item[@key=''_045CE100'']/Adress/Item[@key=''34'']/Channel/Item[@key=''E'']/Amperage', NULL, 'float')
,
('Configuration[@key=''_036CE062.Communicator'']/Scale/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE062'']/Communication/Item[@key=''serialport'']/Modbus/Item[@key=''COM1'']/Board/Item[@key=''_045CE100'']/Adress/Item[@key=''34'']/Channel/Item[@key=''F'']/Amperage', NULL, 'float')
,
('Configuration[@key=''_036CE062.Communicator'']/Scale/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE062'']/Communication/Item[@key=''serialport'']/Modbus/Item[@key=''COM1'']/Board/Item[@key=''_045CE100'']/Adress/Item[@key=''35'']/Channel/Item[@key=''1'']/Amperage', NULL, 'float')
,
('Configuration[@key=''_036CE062.Communicator'']/Scale/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE062'']/Communication/Item[@key=''serialport'']/Modbus/Item[@key=''COM1'']/Board/Item[@key=''_045CE100'']/Adress/Item[@key=''35'']/Channel/Item[@key=''2'']/Amperage', NULL, 'float')
,
('Configuration[@key=''_036CE062.Communicator'']/Scale/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE062'']/Communication/Item[@key=''serialport'']/Modbus/Item[@key=''COM1'']/Board/Item[@key=''_045CE100'']/Adress/Item[@key=''35'']/Channel/Item[@key=''3'']/Amperage', NULL, 'float')
,
('Configuration[@key=''_036CE062.Communicator'']/Scale/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE062'']/Communication/Item[@key=''serialport'']/Modbus/Item[@key=''COM1'']/Board/Item[@key=''_045CE100'']/Adress/Item[@key=''35'']/Channel/Item[@key=''4'']/Amperage', NULL, 'float')
,
('Configuration[@key=''_036CE062.Communicator'']/Scale/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE062'']/Communication/Item[@key=''serialport'']/Modbus/Item[@key=''COM1'']/Board/Item[@key=''_045CE100'']/Adress/Item[@key=''35'']/Channel/Item[@key=''5'']/Amperage', NULL, 'float')
,
('Configuration[@key=''_036CE062.Communicator'']/Scale/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE062'']/Communication/Item[@key=''serialport'']/Modbus/Item[@key=''COM1'']/Board/Item[@key=''_045CE100'']/Adress/Item[@key=''35'']/Channel/Item[@key=''6'']/Amperage', NULL, 'float')
,
('Configuration[@key=''_036CE062.Communicator'']/Scale/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE062'']/Communication/Item[@key=''serialport'']/Modbus/Item[@key=''COM1'']/Board/Item[@key=''_045CE100'']/Adress/Item[@key=''35'']/Channel/Item[@key=''7'']/Amperage', NULL, 'float')
,
('Configuration[@key=''_036CE062.Communicator'']/Scale/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE062'']/Communication/Item[@key=''serialport'']/Modbus/Item[@key=''COM1'']/Board/Item[@key=''_045CE100'']/Adress/Item[@key=''35'']/Channel/Item[@key=''8'']/Amperage', NULL, 'float')
,
('Configuration[@key=''_036CE062.Communicator'']/Scale/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE062'']/Communication/Item[@key=''serialport'']/Modbus/Item[@key=''COM1'']/Board/Item[@key=''_045CE100'']/Adress/Item[@key=''35'']/Channel/Item[@key=''9'']/Amperage', NULL, 'float')
,
('Configuration[@key=''_036CE062.Communicator'']/Scale/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE062'']/Communication/Item[@key=''serialport'']/Modbus/Item[@key=''COM1'']/Board/Item[@key=''_045CE100'']/Adress/Item[@key=''35'']/Channel/Item[@key=''A'']/Amperage', NULL, 'float')
,
('Configuration[@key=''_036CE062.Communicator'']/Scale/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE062'']/Communication/Item[@key=''serialport'']/Modbus/Item[@key=''COM1'']/Board/Item[@key=''_045CE100'']/Adress/Item[@key=''35'']/Channel/Item[@key=''B'']/Amperage', NULL, 'float')
,
('Configuration[@key=''_036CE062.Communicator'']/Scale/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE062'']/Communication/Item[@key=''serialport'']/Modbus/Item[@key=''COM1'']/Board/Item[@key=''_045CE100'']/Adress/Item[@key=''35'']/Channel/Item[@key=''C'']/Amperage', NULL, 'float')
,
('Configuration[@key=''_036CE062.Communicator'']/Scale/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE062'']/Communication/Item[@key=''serialport'']/Modbus/Item[@key=''COM1'']/Board/Item[@key=''_045CE100'']/Adress/Item[@key=''35'']/Channel/Item[@key=''D'']/Amperage', NULL, 'float')
,
('Configuration[@key=''_036CE062.Communicator'']/Scale/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE062'']/Communication/Item[@key=''serialport'']/Modbus/Item[@key=''COM1'']/Board/Item[@key=''_045CE100'']/Adress/Item[@key=''35'']/Channel/Item[@key=''E'']/Amperage', NULL, 'float')
,
('Configuration[@key=''_036CE062.Communicator'']/Scale/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE062'']/Communication/Item[@key=''serialport'']/Modbus/Item[@key=''COM1'']/Board/Item[@key=''_045CE100'']/Adress/Item[@key=''35'']/Channel/Item[@key=''F'']/Amperage', NULL, 'float')
,
('Configuration[@key=''_036CE062.Communicator'']/Scale/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE062'']/Communication/Item[@key=''serialport'']/Modbus/Item[@key=''COM1'']/Board/Item[@key=''_045CE100'']/Adress/Item[@key=''36'']/Channel/Item[@key=''1'']/Amperage', NULL, 'float')
,
('Configuration[@key=''_036CE062.Communicator'']/Scale/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE062'']/Communication/Item[@key=''serialport'']/Modbus/Item[@key=''COM1'']/Board/Item[@key=''_045CE100'']/Adress/Item[@key=''36'']/Channel/Item[@key=''2'']/Amperage', NULL, 'float')
,
('Configuration[@key=''_036CE062.Communicator'']/Scale/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE062'']/Communication/Item[@key=''serialport'']/Modbus/Item[@key=''COM1'']/Board/Item[@key=''_045CE100'']/Adress/Item[@key=''36'']/Channel/Item[@key=''3'']/Amperage', NULL, 'float')
,
('Configuration[@key=''_036CE062.Communicator'']/Scale/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE062'']/Communication/Item[@key=''serialport'']/Modbus/Item[@key=''COM1'']/Board/Item[@key=''_045CE100'']/Adress/Item[@key=''36'']/Channel/Item[@key=''4'']/Amperage', NULL, 'float')
,
('Configuration[@key=''_036CE062.Communicator'']/Scale/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE062'']/Communication/Item[@key=''serialport'']/Modbus/Item[@key=''COM1'']/Board/Item[@key=''_045CE100'']/Adress/Item[@key=''36'']/Channel/Item[@key=''5'']/Amperage', NULL, 'float')
,
('Configuration[@key=''_036CE062.Communicator'']/Scale/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE062'']/Communication/Item[@key=''serialport'']/Modbus/Item[@key=''COM1'']/Board/Item[@key=''_045CE100'']/Adress/Item[@key=''36'']/Channel/Item[@key=''6'']/Amperage', NULL, 'float')
,
('Configuration[@key=''_036CE062.Communicator'']/Scale/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE062'']/Communication/Item[@key=''serialport'']/Modbus/Item[@key=''COM1'']/Board/Item[@key=''_045CE100'']/Adress/Item[@key=''36'']/Channel/Item[@key=''7'']/Amperage', NULL, 'float')
,
('Configuration[@key=''_036CE062.Communicator'']/Scale/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE062'']/Communication/Item[@key=''serialport'']/Modbus/Item[@key=''COM1'']/Board/Item[@key=''_045CE100'']/Adress/Item[@key=''36'']/Channel/Item[@key=''8'']/Amperage', NULL, 'float')
,
('Configuration[@key=''_036CE062.Communicator'']/Scale/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE062'']/Communication/Item[@key=''serialport'']/Modbus/Item[@key=''COM1'']/Board/Item[@key=''_045CE100'']/Adress/Item[@key=''36'']/Channel/Item[@key=''9'']/Amperage', NULL, 'float')
,
('Configuration[@key=''_036CE062.Communicator'']/Scale/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE062'']/Communication/Item[@key=''serialport'']/Modbus/Item[@key=''COM1'']/Board/Item[@key=''_045CE100'']/Adress/Item[@key=''36'']/Channel/Item[@key=''A'']/Amperage', NULL, 'float')
,
('Configuration[@key=''_036CE062.Communicator'']/Scale/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE062'']/Communication/Item[@key=''serialport'']/Modbus/Item[@key=''COM1'']/Board/Item[@key=''_045CE100'']/Adress/Item[@key=''36'']/Channel/Item[@key=''B'']/Amperage', NULL, 'float')
,
('Configuration[@key=''_036CE062.Communicator'']/Scale/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE062'']/Communication/Item[@key=''serialport'']/Modbus/Item[@key=''COM1'']/Board/Item[@key=''_045CE100'']/Adress/Item[@key=''36'']/Channel/Item[@key=''C'']/Amperage', NULL, 'float')
,
('Configuration[@key=''_036CE062.Communicator'']/Scale/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE062'']/Communication/Item[@key=''serialport'']/Modbus/Item[@key=''COM1'']/Board/Item[@key=''_045CE100'']/Adress/Item[@key=''36'']/Channel/Item[@key=''D'']/Amperage', NULL, 'float')
,
('Configuration[@key=''_036CE062.Communicator'']/Scale/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE062'']/Communication/Item[@key=''serialport'']/Modbus/Item[@key=''COM1'']/Board/Item[@key=''_045CE100'']/Adress/Item[@key=''36'']/Channel/Item[@key=''E'']/Amperage', NULL, 'float')
,
('Configuration[@key=''_036CE062.Communicator'']/Scale/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE062'']/Communication/Item[@key=''serialport'']/Modbus/Item[@key=''COM1'']/Board/Item[@key=''_045CE100'']/Adress/Item[@key=''36'']/Channel/Item[@key=''F'']/Amperage', NULL, 'float')
,
('Configuration[@key=''_036CE062.Communicator'']/Scale/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE062'']/Communication/Item[@key=''serialport'']/Modbus/Item[@key=''COM1'']/Board/Item[@key=''_045CE110'']/Adress/Item[@key=''01'']/Channel/Item[@key=''1'']/Voltage', NULL, 'integer')
,
('Configuration[@key=''_036CE062.Communicator'']/Scale/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE062'']/Communication/Item[@key=''serialport'']/Modbus/Item[@key=''COM1'']/Board/Item[@key=''_045CE110'']/Adress/Item[@key=''01'']/Channel/Item[@key=''1'']/Amperage', NULL, 'float')
,
('Configuration[@key=''_036CE062.Communicator'']/Scale/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE062'']/Communication/Item[@key=''serialport'']/Modbus/Item[@key=''COM1'']/Board/Item[@key=''_045CE110'']/Adress/Item[@key=''01'']/Channel/Item[@key=''2'']/Voltage', NULL, 'integer')
,
('Configuration[@key=''_036CE062.Communicator'']/Scale/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE062'']/Communication/Item[@key=''serialport'']/Modbus/Item[@key=''COM1'']/Board/Item[@key=''_045CE110'']/Adress/Item[@key=''01'']/Channel/Item[@key=''2'']/Amperage', NULL, 'float')
,
('Configuration[@key=''_036CE062.Communicator'']/Scale/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE062'']/Communication/Item[@key=''serialport'']/Modbus/Item[@key=''COM1'']/Board/Item[@key=''_045CE110'']/Adress/Item[@key=''01'']/Channel/Item[@key=''3'']/Voltage', NULL, 'integer')
,
('Configuration[@key=''_036CE062.Communicator'']/Scale/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE062'']/Communication/Item[@key=''serialport'']/Modbus/Item[@key=''COM1'']/Board/Item[@key=''_045CE110'']/Adress/Item[@key=''01'']/Channel/Item[@key=''3'']/Amperage', NULL, 'float')
,
('Configuration[@key=''_036CE062.Communicator'']/Scale/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE062'']/Communication/Item[@key=''serialport'']/Modbus/Item[@key=''COM1'']/Board/Item[@key=''_045CE110'']/Adress/Item[@key=''01'']/Channel/Item[@key=''4'']/Voltage', NULL, 'integer')
,
('Configuration[@key=''_036CE062.Communicator'']/Scale/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE062'']/Communication/Item[@key=''serialport'']/Modbus/Item[@key=''COM1'']/Board/Item[@key=''_045CE110'']/Adress/Item[@key=''01'']/Channel/Item[@key=''4'']/Amperage', NULL, 'float')
,
('Configuration[@key=''_036CE062.Communicator'']/Scale/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE062'']/Communication/Item[@key=''serialport'']/Modbus/Item[@key=''COM1'']/Board/Item[@key=''_045CE110'']/Adress/Item[@key=''02'']/Channel/Item[@key=''1'']/Voltage', NULL, 'integer')
,
('Configuration[@key=''_036CE062.Communicator'']/Scale/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE062'']/Communication/Item[@key=''serialport'']/Modbus/Item[@key=''COM1'']/Board/Item[@key=''_045CE110'']/Adress/Item[@key=''02'']/Channel/Item[@key=''1'']/Amperage', NULL, 'float')
,
('Configuration[@key=''_036CE062.Communicator'']/Scale/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE062'']/Communication/Item[@key=''serialport'']/Modbus/Item[@key=''COM1'']/Board/Item[@key=''_045CE110'']/Adress/Item[@key=''02'']/Channel/Item[@key=''2'']/Voltage', NULL, 'integer')
,
('Configuration[@key=''_036CE062.Communicator'']/Scale/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE062'']/Communication/Item[@key=''serialport'']/Modbus/Item[@key=''COM1'']/Board/Item[@key=''_045CE110'']/Adress/Item[@key=''02'']/Channel/Item[@key=''2'']/Amperage', NULL, 'float')
,
('Configuration[@key=''_036CE062.Communicator'']/Scale/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE062'']/Communication/Item[@key=''serialport'']/Modbus/Item[@key=''COM1'']/Board/Item[@key=''_045CE110'']/Adress/Item[@key=''02'']/Channel/Item[@key=''3'']/Voltage', NULL, 'integer')
,
('Configuration[@key=''_036CE062.Communicator'']/Scale/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE062'']/Communication/Item[@key=''serialport'']/Modbus/Item[@key=''COM1'']/Board/Item[@key=''_045CE110'']/Adress/Item[@key=''02'']/Channel/Item[@key=''3'']/Amperage', NULL, 'float')
,
('Configuration[@key=''_036CE062.Communicator'']/Scale/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE062'']/Communication/Item[@key=''serialport'']/Modbus/Item[@key=''COM1'']/Board/Item[@key=''_045CE110'']/Adress/Item[@key=''02'']/Channel/Item[@key=''4'']/Voltage', NULL, 'integer')
,
('Configuration[@key=''_036CE062.Communicator'']/Scale/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE062'']/Communication/Item[@key=''serialport'']/Modbus/Item[@key=''COM1'']/Board/Item[@key=''_045CE110'']/Adress/Item[@key=''02'']/Channel/Item[@key=''4'']/Amperage', NULL, 'float')
,
('Configuration[@key=''_036CE062.Communicator'']/Scale/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE062'']/Communication/Item[@key=''serialport'']/Modbus/Item[@key=''COM1'']/Board/Item[@key=''_045CE110'']/Adress/Item[@key=''03'']/Channel/Item[@key=''1'']/Voltage', NULL, 'integer')
,
('Configuration[@key=''_036CE062.Communicator'']/Scale/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE062'']/Communication/Item[@key=''serialport'']/Modbus/Item[@key=''COM1'']/Board/Item[@key=''_045CE110'']/Adress/Item[@key=''03'']/Channel/Item[@key=''1'']/Amperage', NULL, 'float')
,
('Configuration[@key=''_036CE062.Communicator'']/Scale/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE062'']/Communication/Item[@key=''serialport'']/Modbus/Item[@key=''COM1'']/Board/Item[@key=''_045CE110'']/Adress/Item[@key=''03'']/Channel/Item[@key=''2'']/Voltage', NULL, 'integer')
,
('Configuration[@key=''_036CE062.Communicator'']/Scale/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE062'']/Communication/Item[@key=''serialport'']/Modbus/Item[@key=''COM1'']/Board/Item[@key=''_045CE110'']/Adress/Item[@key=''03'']/Channel/Item[@key=''2'']/Amperage', NULL, 'float')
,
('Configuration[@key=''_036CE062.Communicator'']/Scale/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE062'']/Communication/Item[@key=''serialport'']/Modbus/Item[@key=''COM1'']/Board/Item[@key=''_045CE110'']/Adress/Item[@key=''03'']/Channel/Item[@key=''3'']/Voltage', NULL, 'integer')
,
('Configuration[@key=''_036CE062.Communicator'']/Scale/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE062'']/Communication/Item[@key=''serialport'']/Modbus/Item[@key=''COM1'']/Board/Item[@key=''_045CE110'']/Adress/Item[@key=''03'']/Channel/Item[@key=''3'']/Amperage', NULL, 'float')
,
('Configuration[@key=''_036CE062.Communicator'']/Scale/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE062'']/Communication/Item[@key=''serialport'']/Modbus/Item[@key=''COM1'']/Board/Item[@key=''_045CE110'']/Adress/Item[@key=''03'']/Channel/Item[@key=''4'']/Voltage', NULL, 'integer')
,
('Configuration[@key=''_036CE062.Communicator'']/Scale/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE062'']/Communication/Item[@key=''serialport'']/Modbus/Item[@key=''COM1'']/Board/Item[@key=''_045CE110'']/Adress/Item[@key=''03'']/Channel/Item[@key=''4'']/Amperage', NULL, 'float')
,
('Configuration[@key=''_036CE062.Communicator'']/Scale/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE062'']/Communication/Item[@key=''serialport'']/Modbus/Item[@key=''COM1'']/Board/Item[@key=''_045CE110'']/Adress/Item[@key=''04'']/Channel/Item[@key=''1'']/Voltage', NULL, 'integer')
,
('Configuration[@key=''_036CE062.Communicator'']/Scale/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE062'']/Communication/Item[@key=''serialport'']/Modbus/Item[@key=''COM1'']/Board/Item[@key=''_045CE110'']/Adress/Item[@key=''04'']/Channel/Item[@key=''1'']/Amperage', NULL, 'float')
,
('Configuration[@key=''_036CE062.Communicator'']/Scale/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE062'']/Communication/Item[@key=''serialport'']/Modbus/Item[@key=''COM1'']/Board/Item[@key=''_045CE110'']/Adress/Item[@key=''04'']/Channel/Item[@key=''2'']/Voltage', NULL, 'integer')
,
('Configuration[@key=''_036CE062.Communicator'']/Scale/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE062'']/Communication/Item[@key=''serialport'']/Modbus/Item[@key=''COM1'']/Board/Item[@key=''_045CE110'']/Adress/Item[@key=''04'']/Channel/Item[@key=''2'']/Amperage', NULL, 'float')
,
('Configuration[@key=''_036CE062.Communicator'']/Scale/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE062'']/Communication/Item[@key=''serialport'']/Modbus/Item[@key=''COM1'']/Board/Item[@key=''_045CE110'']/Adress/Item[@key=''04'']/Channel/Item[@key=''3'']/Voltage', NULL, 'integer')
,
('Configuration[@key=''_036CE062.Communicator'']/Scale/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE062'']/Communication/Item[@key=''serialport'']/Modbus/Item[@key=''COM1'']/Board/Item[@key=''_045CE110'']/Adress/Item[@key=''04'']/Channel/Item[@key=''3'']/Amperage', NULL, 'float')
,
('Configuration[@key=''_036CE062.Communicator'']/Scale/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE062'']/Communication/Item[@key=''serialport'']/Modbus/Item[@key=''COM1'']/Board/Item[@key=''_045CE110'']/Adress/Item[@key=''04'']/Channel/Item[@key=''4'']/Voltage', NULL, 'integer')
,
('Configuration[@key=''_036CE062.Communicator'']/Scale/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE062'']/Communication/Item[@key=''serialport'']/Modbus/Item[@key=''COM1'']/Board/Item[@key=''_045CE110'']/Adress/Item[@key=''04'']/Channel/Item[@key=''4'']/Amperage', NULL, 'float')
,
('Configuration[@key=''_036CE062.Communicator'']/Scale/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE062'']/Communication/Item[@key=''serialport'']/Modbus/Item[@key=''COM1'']/Board/Item[@key=''_045CE110'']/Adress/Item[@key=''05'']/Channel/Item[@key=''1'']/Voltage', NULL, 'integer')
,
('Configuration[@key=''_036CE062.Communicator'']/Scale/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE062'']/Communication/Item[@key=''serialport'']/Modbus/Item[@key=''COM1'']/Board/Item[@key=''_045CE110'']/Adress/Item[@key=''05'']/Channel/Item[@key=''1'']/Amperage', NULL, 'float')
,
('Configuration[@key=''_036CE062.Communicator'']/Scale/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE062'']/Communication/Item[@key=''serialport'']/Modbus/Item[@key=''COM1'']/Board/Item[@key=''_045CE110'']/Adress/Item[@key=''05'']/Channel/Item[@key=''2'']/Voltage', NULL, 'integer')
,
('Configuration[@key=''_036CE062.Communicator'']/Scale/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE062'']/Communication/Item[@key=''serialport'']/Modbus/Item[@key=''COM1'']/Board/Item[@key=''_045CE110'']/Adress/Item[@key=''05'']/Channel/Item[@key=''2'']/Amperage', NULL, 'float')
,
('Configuration[@key=''_036CE062.Communicator'']/Scale/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE062'']/Communication/Item[@key=''serialport'']/Modbus/Item[@key=''COM1'']/Board/Item[@key=''_045CE110'']/Adress/Item[@key=''05'']/Channel/Item[@key=''3'']/Voltage', NULL, 'integer')
,
('Configuration[@key=''_036CE062.Communicator'']/Scale/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE062'']/Communication/Item[@key=''serialport'']/Modbus/Item[@key=''COM1'']/Board/Item[@key=''_045CE110'']/Adress/Item[@key=''05'']/Channel/Item[@key=''3'']/Amperage', NULL, 'float')
,
('Configuration[@key=''_036CE062.Communicator'']/Scale/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE062'']/Communication/Item[@key=''serialport'']/Modbus/Item[@key=''COM1'']/Board/Item[@key=''_045CE110'']/Adress/Item[@key=''05'']/Channel/Item[@key=''4'']/Voltage', NULL, 'integer')
,
('Configuration[@key=''_036CE062.Communicator'']/Scale/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE062'']/Communication/Item[@key=''serialport'']/Modbus/Item[@key=''COM1'']/Board/Item[@key=''_045CE110'']/Adress/Item[@key=''05'']/Channel/Item[@key=''4'']/Amperage', NULL, 'float')
,
('Configuration[@key=''_036CE062.Communicator'']/Scale/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE062'']/Communication/Item[@key=''serialport'']/Modbus/Item[@key=''COM1'']/Board/Item[@key=''_045CE110'']/Adress/Item[@key=''06'']/Channel/Item[@key=''1'']/Voltage', NULL, 'integer')
,
('Configuration[@key=''_036CE062.Communicator'']/Scale/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE062'']/Communication/Item[@key=''serialport'']/Modbus/Item[@key=''COM1'']/Board/Item[@key=''_045CE110'']/Adress/Item[@key=''06'']/Channel/Item[@key=''1'']/Amperage', NULL, 'float')
,
('Configuration[@key=''_036CE062.Communicator'']/Scale/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE062'']/Communication/Item[@key=''serialport'']/Modbus/Item[@key=''COM1'']/Board/Item[@key=''_045CE110'']/Adress/Item[@key=''06'']/Channel/Item[@key=''2'']/Voltage', NULL, 'integer')
,
('Configuration[@key=''_036CE062.Communicator'']/Scale/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE062'']/Communication/Item[@key=''serialport'']/Modbus/Item[@key=''COM1'']/Board/Item[@key=''_045CE110'']/Adress/Item[@key=''06'']/Channel/Item[@key=''2'']/Amperage', NULL, 'float')
,
('Configuration[@key=''_036CE062.Communicator'']/Scale/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE062'']/Communication/Item[@key=''serialport'']/Modbus/Item[@key=''COM1'']/Board/Item[@key=''_045CE110'']/Adress/Item[@key=''06'']/Channel/Item[@key=''3'']/Voltage', NULL, 'integer')
,
('Configuration[@key=''_036CE062.Communicator'']/Scale/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE062'']/Communication/Item[@key=''serialport'']/Modbus/Item[@key=''COM1'']/Board/Item[@key=''_045CE110'']/Adress/Item[@key=''06'']/Channel/Item[@key=''3'']/Amperage', NULL, 'float')
,
('Configuration[@key=''_036CE062.Communicator'']/Scale/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE062'']/Communication/Item[@key=''serialport'']/Modbus/Item[@key=''COM1'']/Board/Item[@key=''_045CE110'']/Adress/Item[@key=''06'']/Channel/Item[@key=''4'']/Voltage', NULL, 'integer')
,
('Configuration[@key=''_036CE062.Communicator'']/Scale/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE062'']/Communication/Item[@key=''serialport'']/Modbus/Item[@key=''COM1'']/Board/Item[@key=''_045CE110'']/Adress/Item[@key=''06'']/Channel/Item[@key=''4'']/Amperage', NULL, 'float')
,
('Configuration[@key=''_036CE062.Communicator'']/Scale/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE062'']/Communication/Item[@key=''serialport'']/Modbus/Item[@key=''COM1'']/Board/Item[@key=''_045CE110'']/Adress/Item[@key=''07'']/Channel/Item[@key=''1'']/Voltage', NULL, 'integer')
,
('Configuration[@key=''_036CE062.Communicator'']/Scale/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE062'']/Communication/Item[@key=''serialport'']/Modbus/Item[@key=''COM1'']/Board/Item[@key=''_045CE110'']/Adress/Item[@key=''07'']/Channel/Item[@key=''1'']/Amperage', NULL, 'float')
,
('Configuration[@key=''_036CE062.Communicator'']/Scale/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE062'']/Communication/Item[@key=''serialport'']/Modbus/Item[@key=''COM1'']/Board/Item[@key=''_045CE110'']/Adress/Item[@key=''07'']/Channel/Item[@key=''2'']/Voltage', NULL, 'integer')
,
('Configuration[@key=''_036CE062.Communicator'']/Scale/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE062'']/Communication/Item[@key=''serialport'']/Modbus/Item[@key=''COM1'']/Board/Item[@key=''_045CE110'']/Adress/Item[@key=''07'']/Channel/Item[@key=''2'']/Amperage', NULL, 'float')
,
('Configuration[@key=''_036CE062.Communicator'']/Scale/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE062'']/Communication/Item[@key=''serialport'']/Modbus/Item[@key=''COM1'']/Board/Item[@key=''_045CE110'']/Adress/Item[@key=''07'']/Channel/Item[@key=''3'']/Voltage', NULL, 'integer')
,
('Configuration[@key=''_036CE062.Communicator'']/Scale/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE062'']/Communication/Item[@key=''serialport'']/Modbus/Item[@key=''COM1'']/Board/Item[@key=''_045CE110'']/Adress/Item[@key=''07'']/Channel/Item[@key=''3'']/Amperage', NULL, 'float')
,
('Configuration[@key=''_036CE062.Communicator'']/Scale/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE062'']/Communication/Item[@key=''serialport'']/Modbus/Item[@key=''COM1'']/Board/Item[@key=''_045CE110'']/Adress/Item[@key=''07'']/Channel/Item[@key=''4'']/Voltage', NULL, 'integer')
,
('Configuration[@key=''_036CE062.Communicator'']/Scale/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE062'']/Communication/Item[@key=''serialport'']/Modbus/Item[@key=''COM1'']/Board/Item[@key=''_045CE110'']/Adress/Item[@key=''07'']/Channel/Item[@key=''4'']/Amperage', NULL, 'float')
,
('Configuration[@key=''_036CE062.Communicator'']/Scale/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE062'']/Communication/Item[@key=''serialport'']/Modbus/Item[@key=''COM1'']/Board/Item[@key=''_045CE110'']/Adress/Item[@key=''08'']/Channel/Item[@key=''1'']/Voltage', NULL, 'integer')
,
('Configuration[@key=''_036CE062.Communicator'']/Scale/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE062'']/Communication/Item[@key=''serialport'']/Modbus/Item[@key=''COM1'']/Board/Item[@key=''_045CE110'']/Adress/Item[@key=''08'']/Channel/Item[@key=''1'']/Amperage', NULL, 'float')
,
('Configuration[@key=''_036CE062.Communicator'']/Scale/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE062'']/Communication/Item[@key=''serialport'']/Modbus/Item[@key=''COM1'']/Board/Item[@key=''_045CE110'']/Adress/Item[@key=''08'']/Channel/Item[@key=''2'']/Voltage', NULL, 'integer')
,
('Configuration[@key=''_036CE062.Communicator'']/Scale/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE062'']/Communication/Item[@key=''serialport'']/Modbus/Item[@key=''COM1'']/Board/Item[@key=''_045CE110'']/Adress/Item[@key=''08'']/Channel/Item[@key=''2'']/Amperage', NULL, 'float')
,
('Configuration[@key=''_036CE062.Communicator'']/Scale/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE062'']/Communication/Item[@key=''serialport'']/Modbus/Item[@key=''COM1'']/Board/Item[@key=''_045CE110'']/Adress/Item[@key=''08'']/Channel/Item[@key=''3'']/Voltage', NULL, 'integer')
,
('Configuration[@key=''_036CE062.Communicator'']/Scale/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE062'']/Communication/Item[@key=''serialport'']/Modbus/Item[@key=''COM1'']/Board/Item[@key=''_045CE110'']/Adress/Item[@key=''08'']/Channel/Item[@key=''3'']/Amperage', NULL, 'float')
,
('Configuration[@key=''_036CE062.Communicator'']/Scale/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE062'']/Communication/Item[@key=''serialport'']/Modbus/Item[@key=''COM1'']/Board/Item[@key=''_045CE110'']/Adress/Item[@key=''08'']/Channel/Item[@key=''4'']/Voltage', NULL, 'integer')
,
('Configuration[@key=''_036CE062.Communicator'']/Scale/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE062'']/Communication/Item[@key=''serialport'']/Modbus/Item[@key=''COM1'']/Board/Item[@key=''_045CE110'']/Adress/Item[@key=''08'']/Channel/Item[@key=''4'']/Amperage', NULL, 'float')
,
('Configuration[@key=''_036CE062.Communicator'']/Scale/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE062'']/Communication/Item[@key=''serialport'']/Modbus/Item[@key=''COM1'']/Board/Item[@key=''_045CE110'']/Adress/Item[@key=''09'']/Channel/Item[@key=''1'']/Voltage', NULL, 'integer')
,
('Configuration[@key=''_036CE062.Communicator'']/Scale/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE062'']/Communication/Item[@key=''serialport'']/Modbus/Item[@key=''COM1'']/Board/Item[@key=''_045CE110'']/Adress/Item[@key=''09'']/Channel/Item[@key=''1'']/Amperage', NULL, 'float')
,
('Configuration[@key=''_036CE062.Communicator'']/Scale/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE062'']/Communication/Item[@key=''serialport'']/Modbus/Item[@key=''COM1'']/Board/Item[@key=''_045CE110'']/Adress/Item[@key=''09'']/Channel/Item[@key=''2'']/Voltage', NULL, 'integer')
,
('Configuration[@key=''_036CE062.Communicator'']/Scale/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE062'']/Communication/Item[@key=''serialport'']/Modbus/Item[@key=''COM1'']/Board/Item[@key=''_045CE110'']/Adress/Item[@key=''09'']/Channel/Item[@key=''2'']/Amperage', NULL, 'float')
,
('Configuration[@key=''_036CE062.Communicator'']/Scale/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE062'']/Communication/Item[@key=''serialport'']/Modbus/Item[@key=''COM1'']/Board/Item[@key=''_045CE110'']/Adress/Item[@key=''09'']/Channel/Item[@key=''3'']/Voltage', NULL, 'integer')
,
('Configuration[@key=''_036CE062.Communicator'']/Scale/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE062'']/Communication/Item[@key=''serialport'']/Modbus/Item[@key=''COM1'']/Board/Item[@key=''_045CE110'']/Adress/Item[@key=''09'']/Channel/Item[@key=''3'']/Amperage', NULL, 'float')
,
('Configuration[@key=''_036CE062.Communicator'']/Scale/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE062'']/Communication/Item[@key=''serialport'']/Modbus/Item[@key=''COM1'']/Board/Item[@key=''_045CE110'']/Adress/Item[@key=''09'']/Channel/Item[@key=''4'']/Voltage', NULL, 'integer')
,
('Configuration[@key=''_036CE062.Communicator'']/Scale/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE062'']/Communication/Item[@key=''serialport'']/Modbus/Item[@key=''COM1'']/Board/Item[@key=''_045CE110'']/Adress/Item[@key=''09'']/Channel/Item[@key=''4'']/Amperage', NULL, 'float')
,
('Configuration[@key=''_036CE062.Communicator'']/Scale/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE062'']/Communication/Item[@key=''serialport'']/Modbus/Item[@key=''COM1'']/Board/Item[@key=''_045CE110'']/Adress/Item[@key=''10'']/Channel/Item[@key=''1'']/Voltage', NULL, 'integer')
,
('Configuration[@key=''_036CE062.Communicator'']/Scale/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE062'']/Communication/Item[@key=''serialport'']/Modbus/Item[@key=''COM1'']/Board/Item[@key=''_045CE110'']/Adress/Item[@key=''10'']/Channel/Item[@key=''1'']/Amperage', NULL, 'float')
,
('Configuration[@key=''_036CE062.Communicator'']/Scale/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE062'']/Communication/Item[@key=''serialport'']/Modbus/Item[@key=''COM1'']/Board/Item[@key=''_045CE110'']/Adress/Item[@key=''10'']/Channel/Item[@key=''2'']/Voltage', NULL, 'integer')
,
('Configuration[@key=''_036CE062.Communicator'']/Scale/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE062'']/Communication/Item[@key=''serialport'']/Modbus/Item[@key=''COM1'']/Board/Item[@key=''_045CE110'']/Adress/Item[@key=''10'']/Channel/Item[@key=''2'']/Amperage', NULL, 'float')
,
('Configuration[@key=''_036CE062.Communicator'']/Scale/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE062'']/Communication/Item[@key=''serialport'']/Modbus/Item[@key=''COM1'']/Board/Item[@key=''_045CE110'']/Adress/Item[@key=''10'']/Channel/Item[@key=''3'']/Voltage', NULL, 'integer')
,
('Configuration[@key=''_036CE062.Communicator'']/Scale/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE062'']/Communication/Item[@key=''serialport'']/Modbus/Item[@key=''COM1'']/Board/Item[@key=''_045CE110'']/Adress/Item[@key=''10'']/Channel/Item[@key=''3'']/Amperage', NULL, 'float')
,
('Configuration[@key=''_036CE062.Communicator'']/Scale/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE062'']/Communication/Item[@key=''serialport'']/Modbus/Item[@key=''COM1'']/Board/Item[@key=''_045CE110'']/Adress/Item[@key=''10'']/Channel/Item[@key=''4'']/Voltage', NULL, 'integer')
,
('Configuration[@key=''_036CE062.Communicator'']/Scale/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE062'']/Communication/Item[@key=''serialport'']/Modbus/Item[@key=''COM1'']/Board/Item[@key=''_045CE110'']/Adress/Item[@key=''10'']/Channel/Item[@key=''4'']/Amperage', NULL, 'float')
,
('Configuration[@key=''_036CE062.Communicator'']/Scale/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE062'']/Communication/Item[@key=''serialport'']/Modbus/Item[@key=''COM1'']/Board/Item[@key=''_045CE110'']/Adress/Item[@key=''11'']/Channel/Item[@key=''1'']/Voltage', NULL, 'integer')
,
('Configuration[@key=''_036CE062.Communicator'']/Scale/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE062'']/Communication/Item[@key=''serialport'']/Modbus/Item[@key=''COM1'']/Board/Item[@key=''_045CE110'']/Adress/Item[@key=''11'']/Channel/Item[@key=''1'']/Amperage', NULL, 'float')
,
('Configuration[@key=''_036CE062.Communicator'']/Scale/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE062'']/Communication/Item[@key=''serialport'']/Modbus/Item[@key=''COM1'']/Board/Item[@key=''_045CE110'']/Adress/Item[@key=''11'']/Channel/Item[@key=''2'']/Voltage', NULL, 'integer')
,
('Configuration[@key=''_036CE062.Communicator'']/Scale/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE062'']/Communication/Item[@key=''serialport'']/Modbus/Item[@key=''COM1'']/Board/Item[@key=''_045CE110'']/Adress/Item[@key=''11'']/Channel/Item[@key=''2'']/Amperage', NULL, 'float')
,
('Configuration[@key=''_036CE062.Communicator'']/Scale/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE062'']/Communication/Item[@key=''serialport'']/Modbus/Item[@key=''COM1'']/Board/Item[@key=''_045CE110'']/Adress/Item[@key=''11'']/Channel/Item[@key=''3'']/Voltage', NULL, 'integer')
,
('Configuration[@key=''_036CE062.Communicator'']/Scale/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE062'']/Communication/Item[@key=''serialport'']/Modbus/Item[@key=''COM1'']/Board/Item[@key=''_045CE110'']/Adress/Item[@key=''11'']/Channel/Item[@key=''3'']/Amperage', NULL, 'float')
,
('Configuration[@key=''_036CE062.Communicator'']/Scale/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE062'']/Communication/Item[@key=''serialport'']/Modbus/Item[@key=''COM1'']/Board/Item[@key=''_045CE110'']/Adress/Item[@key=''11'']/Channel/Item[@key=''4'']/Voltage', NULL, 'integer')
,
('Configuration[@key=''_036CE062.Communicator'']/Scale/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE062'']/Communication/Item[@key=''serialport'']/Modbus/Item[@key=''COM1'']/Board/Item[@key=''_045CE110'']/Adress/Item[@key=''11'']/Channel/Item[@key=''4'']/Amperage', NULL, 'float')
,
('Configuration[@key=''_036CE062.Communicator'']/Scale/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE062'']/Communication/Item[@key=''serialport'']/Modbus/Item[@key=''COM1'']/Board/Item[@key=''_045CE110'']/Adress/Item[@key=''12'']/Channel/Item[@key=''1'']/Voltage', NULL, 'integer')
,
('Configuration[@key=''_036CE062.Communicator'']/Scale/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE062'']/Communication/Item[@key=''serialport'']/Modbus/Item[@key=''COM1'']/Board/Item[@key=''_045CE110'']/Adress/Item[@key=''12'']/Channel/Item[@key=''1'']/Amperage', NULL, 'float')
,
('Configuration[@key=''_036CE062.Communicator'']/Scale/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE062'']/Communication/Item[@key=''serialport'']/Modbus/Item[@key=''COM1'']/Board/Item[@key=''_045CE110'']/Adress/Item[@key=''12'']/Channel/Item[@key=''2'']/Voltage', NULL, 'integer')
,
('Configuration[@key=''_036CE062.Communicator'']/Scale/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE062'']/Communication/Item[@key=''serialport'']/Modbus/Item[@key=''COM1'']/Board/Item[@key=''_045CE110'']/Adress/Item[@key=''12'']/Channel/Item[@key=''2'']/Amperage', NULL, 'float')
,
('Configuration[@key=''_036CE062.Communicator'']/Scale/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE062'']/Communication/Item[@key=''serialport'']/Modbus/Item[@key=''COM1'']/Board/Item[@key=''_045CE110'']/Adress/Item[@key=''12'']/Channel/Item[@key=''3'']/Voltage', NULL, 'integer')
,
('Configuration[@key=''_036CE062.Communicator'']/Scale/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE062'']/Communication/Item[@key=''serialport'']/Modbus/Item[@key=''COM1'']/Board/Item[@key=''_045CE110'']/Adress/Item[@key=''12'']/Channel/Item[@key=''3'']/Amperage', NULL, 'float')
,
('Configuration[@key=''_036CE062.Communicator'']/Scale/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE062'']/Communication/Item[@key=''serialport'']/Modbus/Item[@key=''COM1'']/Board/Item[@key=''_045CE110'']/Adress/Item[@key=''12'']/Channel/Item[@key=''4'']/Voltage', NULL, 'integer')
,
('Configuration[@key=''_036CE062.Communicator'']/Scale/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE062'']/Communication/Item[@key=''serialport'']/Modbus/Item[@key=''COM1'']/Board/Item[@key=''_045CE110'']/Adress/Item[@key=''12'']/Channel/Item[@key=''4'']/Amperage', NULL, 'float')
,
('Configuration[@key=''_036CE062.Communicator'']/Scale/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE062'']/Communication/Item[@key=''serialport'']/Modbus/Item[@key=''COM1'']/Board/Item[@key=''_045CE110'']/Adress/Item[@key=''13'']/Channel/Item[@key=''1'']/Voltage', NULL, 'integer')
,
('Configuration[@key=''_036CE062.Communicator'']/Scale/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE062'']/Communication/Item[@key=''serialport'']/Modbus/Item[@key=''COM1'']/Board/Item[@key=''_045CE110'']/Adress/Item[@key=''13'']/Channel/Item[@key=''1'']/Amperage', NULL, 'float')
,
('Configuration[@key=''_036CE062.Communicator'']/Scale/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE062'']/Communication/Item[@key=''serialport'']/Modbus/Item[@key=''COM1'']/Board/Item[@key=''_045CE110'']/Adress/Item[@key=''13'']/Channel/Item[@key=''2'']/Voltage', NULL, 'integer')
,
('Configuration[@key=''_036CE062.Communicator'']/Scale/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE062'']/Communication/Item[@key=''serialport'']/Modbus/Item[@key=''COM1'']/Board/Item[@key=''_045CE110'']/Adress/Item[@key=''13'']/Channel/Item[@key=''2'']/Amperage', NULL, 'float')
,
('Configuration[@key=''_036CE062.Communicator'']/Scale/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE062'']/Communication/Item[@key=''serialport'']/Modbus/Item[@key=''COM1'']/Board/Item[@key=''_045CE110'']/Adress/Item[@key=''13'']/Channel/Item[@key=''3'']/Voltage', NULL, 'integer')
,
('Configuration[@key=''_036CE062.Communicator'']/Scale/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE062'']/Communication/Item[@key=''serialport'']/Modbus/Item[@key=''COM1'']/Board/Item[@key=''_045CE110'']/Adress/Item[@key=''13'']/Channel/Item[@key=''3'']/Amperage', NULL, 'float')
,
('Configuration[@key=''_036CE062.Communicator'']/Scale/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE062'']/Communication/Item[@key=''serialport'']/Modbus/Item[@key=''COM1'']/Board/Item[@key=''_045CE110'']/Adress/Item[@key=''13'']/Channel/Item[@key=''4'']/Voltage', NULL, 'integer')
,
('Configuration[@key=''_036CE062.Communicator'']/Scale/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE062'']/Communication/Item[@key=''serialport'']/Modbus/Item[@key=''COM1'']/Board/Item[@key=''_045CE110'']/Adress/Item[@key=''13'']/Channel/Item[@key=''4'']/Amperage', NULL, 'float')
,
('Configuration[@key=''_036CE062.Communicator'']/Scale/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE062'']/Communication/Item[@key=''serialport'']/Modbus/Item[@key=''COM1'']/Board/Item[@key=''_045CE110'']/Adress/Item[@key=''14'']/Channel/Item[@key=''1'']/Voltage', NULL, 'integer')
,
('Configuration[@key=''_036CE062.Communicator'']/Scale/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE062'']/Communication/Item[@key=''serialport'']/Modbus/Item[@key=''COM1'']/Board/Item[@key=''_045CE110'']/Adress/Item[@key=''14'']/Channel/Item[@key=''1'']/Amperage', NULL, 'float')
,
('Configuration[@key=''_036CE062.Communicator'']/Scale/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE062'']/Communication/Item[@key=''serialport'']/Modbus/Item[@key=''COM1'']/Board/Item[@key=''_045CE110'']/Adress/Item[@key=''14'']/Channel/Item[@key=''2'']/Voltage', NULL, 'integer')
,
('Configuration[@key=''_036CE062.Communicator'']/Scale/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE062'']/Communication/Item[@key=''serialport'']/Modbus/Item[@key=''COM1'']/Board/Item[@key=''_045CE110'']/Adress/Item[@key=''14'']/Channel/Item[@key=''2'']/Amperage', NULL, 'float')
,
('Configuration[@key=''_036CE062.Communicator'']/Scale/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE062'']/Communication/Item[@key=''serialport'']/Modbus/Item[@key=''COM1'']/Board/Item[@key=''_045CE110'']/Adress/Item[@key=''14'']/Channel/Item[@key=''3'']/Voltage', NULL, 'integer')
,
('Configuration[@key=''_036CE062.Communicator'']/Scale/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE062'']/Communication/Item[@key=''serialport'']/Modbus/Item[@key=''COM1'']/Board/Item[@key=''_045CE110'']/Adress/Item[@key=''14'']/Channel/Item[@key=''3'']/Amperage', NULL, 'float')
,
('Configuration[@key=''_036CE062.Communicator'']/Scale/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE062'']/Communication/Item[@key=''serialport'']/Modbus/Item[@key=''COM1'']/Board/Item[@key=''_045CE110'']/Adress/Item[@key=''14'']/Channel/Item[@key=''4'']/Voltage', NULL, 'integer')
,
('Configuration[@key=''_036CE062.Communicator'']/Scale/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE062'']/Communication/Item[@key=''serialport'']/Modbus/Item[@key=''COM1'']/Board/Item[@key=''_045CE110'']/Adress/Item[@key=''14'']/Channel/Item[@key=''4'']/Amperage', NULL, 'float')
,
('Configuration[@key=''_036CE062.Communicator'']/Scale/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE062'']/Communication/Item[@key=''serialport'']/Modbus/Item[@key=''COM1'']/Board/Item[@key=''_045CE110'']/Adress/Item[@key=''15'']/Channel/Item[@key=''1'']/Voltage', NULL, 'integer')
,
('Configuration[@key=''_036CE062.Communicator'']/Scale/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE062'']/Communication/Item[@key=''serialport'']/Modbus/Item[@key=''COM1'']/Board/Item[@key=''_045CE110'']/Adress/Item[@key=''15'']/Channel/Item[@key=''1'']/Amperage', NULL, 'float')
,
('Configuration[@key=''_036CE062.Communicator'']/Scale/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE062'']/Communication/Item[@key=''serialport'']/Modbus/Item[@key=''COM1'']/Board/Item[@key=''_045CE110'']/Adress/Item[@key=''15'']/Channel/Item[@key=''2'']/Voltage', NULL, 'integer')
,
('Configuration[@key=''_036CE062.Communicator'']/Scale/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE062'']/Communication/Item[@key=''serialport'']/Modbus/Item[@key=''COM1'']/Board/Item[@key=''_045CE110'']/Adress/Item[@key=''15'']/Channel/Item[@key=''2'']/Amperage', NULL, 'float')
,
('Configuration[@key=''_036CE062.Communicator'']/Scale/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE062'']/Communication/Item[@key=''serialport'']/Modbus/Item[@key=''COM1'']/Board/Item[@key=''_045CE110'']/Adress/Item[@key=''15'']/Channel/Item[@key=''3'']/Voltage', NULL, 'integer')
,
('Configuration[@key=''_036CE062.Communicator'']/Scale/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE062'']/Communication/Item[@key=''serialport'']/Modbus/Item[@key=''COM1'']/Board/Item[@key=''_045CE110'']/Adress/Item[@key=''15'']/Channel/Item[@key=''3'']/Amperage', NULL, 'float')
,
('Configuration[@key=''_036CE062.Communicator'']/Scale/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE062'']/Communication/Item[@key=''serialport'']/Modbus/Item[@key=''COM1'']/Board/Item[@key=''_045CE110'']/Adress/Item[@key=''15'']/Channel/Item[@key=''4'']/Voltage', NULL, 'integer')
,
('Configuration[@key=''_036CE062.Communicator'']/Scale/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE062'']/Communication/Item[@key=''serialport'']/Modbus/Item[@key=''COM1'']/Board/Item[@key=''_045CE110'']/Adress/Item[@key=''15'']/Channel/Item[@key=''4'']/Amperage', NULL, 'float')
,
('Configuration[@key=''_036CE062.Communicator'']/Scale/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE062'']/Communication/Item[@key=''serialport'']/Modbus/Item[@key=''COM1'']/Board/Item[@key=''_045CE110'']/Adress/Item[@key=''16'']/Channel/Item[@key=''1'']/Voltage', NULL, 'integer')
,
('Configuration[@key=''_036CE062.Communicator'']/Scale/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE062'']/Communication/Item[@key=''serialport'']/Modbus/Item[@key=''COM1'']/Board/Item[@key=''_045CE110'']/Adress/Item[@key=''16'']/Channel/Item[@key=''1'']/Amperage', NULL, 'float')
,
('Configuration[@key=''_036CE062.Communicator'']/Scale/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE062'']/Communication/Item[@key=''serialport'']/Modbus/Item[@key=''COM1'']/Board/Item[@key=''_045CE110'']/Adress/Item[@key=''16'']/Channel/Item[@key=''2'']/Voltage', NULL, 'integer')
,
('Configuration[@key=''_036CE062.Communicator'']/Scale/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE062'']/Communication/Item[@key=''serialport'']/Modbus/Item[@key=''COM1'']/Board/Item[@key=''_045CE110'']/Adress/Item[@key=''16'']/Channel/Item[@key=''2'']/Amperage', NULL, 'float')
,
('Configuration[@key=''_036CE062.Communicator'']/Scale/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE062'']/Communication/Item[@key=''serialport'']/Modbus/Item[@key=''COM1'']/Board/Item[@key=''_045CE110'']/Adress/Item[@key=''16'']/Channel/Item[@key=''3'']/Voltage', NULL, 'integer')
,
('Configuration[@key=''_036CE062.Communicator'']/Scale/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE062'']/Communication/Item[@key=''serialport'']/Modbus/Item[@key=''COM1'']/Board/Item[@key=''_045CE110'']/Adress/Item[@key=''16'']/Channel/Item[@key=''3'']/Amperage', NULL, 'float')
,
('Configuration[@key=''_036CE062.Communicator'']/Scale/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE062'']/Communication/Item[@key=''serialport'']/Modbus/Item[@key=''COM1'']/Board/Item[@key=''_045CE110'']/Adress/Item[@key=''16'']/Channel/Item[@key=''4'']/Voltage', NULL, 'integer')
,
('Configuration[@key=''_036CE062.Communicator'']/Scale/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE062'']/Communication/Item[@key=''serialport'']/Modbus/Item[@key=''COM1'']/Board/Item[@key=''_045CE110'']/Adress/Item[@key=''16'']/Channel/Item[@key=''4'']/Amperage', NULL, 'float')
,
('Configuration[@key=''_036CE062.Communicator'']/Scale/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE062'']/Communication/Item[@key=''serialport'']/Modbus/Item[@key=''COM1'']/Board/Item[@key=''_045CE110'']/Adress/Item[@key=''17'']/Channel/Item[@key=''1'']/Voltage', NULL, 'integer')
,
('Configuration[@key=''_036CE062.Communicator'']/Scale/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE062'']/Communication/Item[@key=''serialport'']/Modbus/Item[@key=''COM1'']/Board/Item[@key=''_045CE110'']/Adress/Item[@key=''17'']/Channel/Item[@key=''1'']/Amperage', NULL, 'float')
,
('Configuration[@key=''_036CE062.Communicator'']/Scale/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE062'']/Communication/Item[@key=''serialport'']/Modbus/Item[@key=''COM1'']/Board/Item[@key=''_045CE110'']/Adress/Item[@key=''17'']/Channel/Item[@key=''2'']/Voltage', NULL, 'integer')
,
('Configuration[@key=''_036CE062.Communicator'']/Scale/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE062'']/Communication/Item[@key=''serialport'']/Modbus/Item[@key=''COM1'']/Board/Item[@key=''_045CE110'']/Adress/Item[@key=''17'']/Channel/Item[@key=''2'']/Amperage', NULL, 'float')
,
('Configuration[@key=''_036CE062.Communicator'']/Scale/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE062'']/Communication/Item[@key=''serialport'']/Modbus/Item[@key=''COM1'']/Board/Item[@key=''_045CE110'']/Adress/Item[@key=''17'']/Channel/Item[@key=''3'']/Voltage', NULL, 'integer')
,
('Configuration[@key=''_036CE062.Communicator'']/Scale/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE062'']/Communication/Item[@key=''serialport'']/Modbus/Item[@key=''COM1'']/Board/Item[@key=''_045CE110'']/Adress/Item[@key=''17'']/Channel/Item[@key=''3'']/Amperage', NULL, 'float')
,
('Configuration[@key=''_036CE062.Communicator'']/Scale/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE062'']/Communication/Item[@key=''serialport'']/Modbus/Item[@key=''COM1'']/Board/Item[@key=''_045CE110'']/Adress/Item[@key=''17'']/Channel/Item[@key=''4'']/Voltage', NULL, 'integer')
,
('Configuration[@key=''_036CE062.Communicator'']/Scale/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE062'']/Communication/Item[@key=''serialport'']/Modbus/Item[@key=''COM1'']/Board/Item[@key=''_045CE110'']/Adress/Item[@key=''17'']/Channel/Item[@key=''4'']/Amperage', NULL, 'float')
,
('Configuration[@key=''_036CE062.Communicator'']/Scale/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE062'']/Communication/Item[@key=''serialport'']/Modbus/Item[@key=''COM1'']/Board/Item[@key=''_045CE110'']/Adress/Item[@key=''18'']/Channel/Item[@key=''1'']/Voltage', NULL, 'integer')
,
('Configuration[@key=''_036CE062.Communicator'']/Scale/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE062'']/Communication/Item[@key=''serialport'']/Modbus/Item[@key=''COM1'']/Board/Item[@key=''_045CE110'']/Adress/Item[@key=''18'']/Channel/Item[@key=''1'']/Amperage', NULL, 'float')
,
('Configuration[@key=''_036CE062.Communicator'']/Scale/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE062'']/Communication/Item[@key=''serialport'']/Modbus/Item[@key=''COM1'']/Board/Item[@key=''_045CE110'']/Adress/Item[@key=''18'']/Channel/Item[@key=''2'']/Voltage', NULL, 'integer')
,
('Configuration[@key=''_036CE062.Communicator'']/Scale/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE062'']/Communication/Item[@key=''serialport'']/Modbus/Item[@key=''COM1'']/Board/Item[@key=''_045CE110'']/Adress/Item[@key=''18'']/Channel/Item[@key=''2'']/Amperage', NULL, 'float')
,
('Configuration[@key=''_036CE062.Communicator'']/Scale/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE062'']/Communication/Item[@key=''serialport'']/Modbus/Item[@key=''COM1'']/Board/Item[@key=''_045CE110'']/Adress/Item[@key=''18'']/Channel/Item[@key=''3'']/Voltage', NULL, 'integer')
,
('Configuration[@key=''_036CE062.Communicator'']/Scale/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE062'']/Communication/Item[@key=''serialport'']/Modbus/Item[@key=''COM1'']/Board/Item[@key=''_045CE110'']/Adress/Item[@key=''18'']/Channel/Item[@key=''3'']/Amperage', NULL, 'float')
,
('Configuration[@key=''_036CE062.Communicator'']/Scale/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE062'']/Communication/Item[@key=''serialport'']/Modbus/Item[@key=''COM1'']/Board/Item[@key=''_045CE110'']/Adress/Item[@key=''18'']/Channel/Item[@key=''4'']/Voltage', NULL, 'integer')
,
('Configuration[@key=''_036CE062.Communicator'']/Scale/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE062'']/Communication/Item[@key=''serialport'']/Modbus/Item[@key=''COM1'']/Board/Item[@key=''_045CE110'']/Adress/Item[@key=''18'']/Channel/Item[@key=''4'']/Amperage', NULL, 'float')
,
('Configuration[@key=''_036CE062.Communicator'']/Scale/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE062'']/Communication/Item[@key=''serialport'']/Modbus/Item[@key=''COM1'']/Board/Item[@key=''_045CE110'']/Adress/Item[@key=''19'']/Channel/Item[@key=''1'']/Voltage', NULL, 'integer')
,
('Configuration[@key=''_036CE062.Communicator'']/Scale/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE062'']/Communication/Item[@key=''serialport'']/Modbus/Item[@key=''COM1'']/Board/Item[@key=''_045CE110'']/Adress/Item[@key=''19'']/Channel/Item[@key=''1'']/Amperage', NULL, 'float')
,
('Configuration[@key=''_036CE062.Communicator'']/Scale/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE062'']/Communication/Item[@key=''serialport'']/Modbus/Item[@key=''COM1'']/Board/Item[@key=''_045CE110'']/Adress/Item[@key=''19'']/Channel/Item[@key=''2'']/Voltage', NULL, 'integer')
,
('Configuration[@key=''_036CE062.Communicator'']/Scale/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE062'']/Communication/Item[@key=''serialport'']/Modbus/Item[@key=''COM1'']/Board/Item[@key=''_045CE110'']/Adress/Item[@key=''19'']/Channel/Item[@key=''2'']/Amperage', NULL, 'float')
,
('Configuration[@key=''_036CE062.Communicator'']/Scale/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE062'']/Communication/Item[@key=''serialport'']/Modbus/Item[@key=''COM1'']/Board/Item[@key=''_045CE110'']/Adress/Item[@key=''19'']/Channel/Item[@key=''3'']/Voltage', NULL, 'integer')
,
('Configuration[@key=''_036CE062.Communicator'']/Scale/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE062'']/Communication/Item[@key=''serialport'']/Modbus/Item[@key=''COM1'']/Board/Item[@key=''_045CE110'']/Adress/Item[@key=''19'']/Channel/Item[@key=''3'']/Amperage', NULL, 'float')
,
('Configuration[@key=''_036CE062.Communicator'']/Scale/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE062'']/Communication/Item[@key=''serialport'']/Modbus/Item[@key=''COM1'']/Board/Item[@key=''_045CE110'']/Adress/Item[@key=''19'']/Channel/Item[@key=''4'']/Voltage', NULL, 'integer')
,
('Configuration[@key=''_036CE062.Communicator'']/Scale/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE062'']/Communication/Item[@key=''serialport'']/Modbus/Item[@key=''COM1'']/Board/Item[@key=''_045CE110'']/Adress/Item[@key=''19'']/Channel/Item[@key=''4'']/Amperage', NULL, 'float')
,
('Configuration[@key=''_036CE062.Communicator'']/Scale/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE062'']/Communication/Item[@key=''serialport'']/Modbus/Item[@key=''COM1'']/Board/Item[@key=''_045CE110'']/Adress/Item[@key=''20'']/Channel/Item[@key=''1'']/Voltage', NULL, 'integer')
,
('Configuration[@key=''_036CE062.Communicator'']/Scale/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE062'']/Communication/Item[@key=''serialport'']/Modbus/Item[@key=''COM1'']/Board/Item[@key=''_045CE110'']/Adress/Item[@key=''20'']/Channel/Item[@key=''1'']/Amperage', NULL, 'float')
,
('Configuration[@key=''_036CE062.Communicator'']/Scale/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE062'']/Communication/Item[@key=''serialport'']/Modbus/Item[@key=''COM1'']/Board/Item[@key=''_045CE110'']/Adress/Item[@key=''20'']/Channel/Item[@key=''2'']/Voltage', NULL, 'integer')
,
('Configuration[@key=''_036CE062.Communicator'']/Scale/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE062'']/Communication/Item[@key=''serialport'']/Modbus/Item[@key=''COM1'']/Board/Item[@key=''_045CE110'']/Adress/Item[@key=''20'']/Channel/Item[@key=''2'']/Amperage', NULL, 'float')
,
('Configuration[@key=''_036CE062.Communicator'']/Scale/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE062'']/Communication/Item[@key=''serialport'']/Modbus/Item[@key=''COM1'']/Board/Item[@key=''_045CE110'']/Adress/Item[@key=''20'']/Channel/Item[@key=''3'']/Voltage', NULL, 'integer')
,
('Configuration[@key=''_036CE062.Communicator'']/Scale/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE062'']/Communication/Item[@key=''serialport'']/Modbus/Item[@key=''COM1'']/Board/Item[@key=''_045CE110'']/Adress/Item[@key=''20'']/Channel/Item[@key=''3'']/Amperage', NULL, 'float')
,
('Configuration[@key=''_036CE062.Communicator'']/Scale/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE062'']/Communication/Item[@key=''serialport'']/Modbus/Item[@key=''COM1'']/Board/Item[@key=''_045CE110'']/Adress/Item[@key=''20'']/Channel/Item[@key=''4'']/Voltage', NULL, 'integer')
,
('Configuration[@key=''_036CE062.Communicator'']/Scale/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE062'']/Communication/Item[@key=''serialport'']/Modbus/Item[@key=''COM1'']/Board/Item[@key=''_045CE110'']/Adress/Item[@key=''20'']/Channel/Item[@key=''4'']/Amperage', NULL, 'float')
,
('Configuration[@key=''_036CE062.Communicator'']/Scale/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE062'']/Communication/Item[@key=''serialport'']/Modbus/Item[@key=''COM1'']/Board/Item[@key=''_045CE110'']/Adress/Item[@key=''21'']/Channel/Item[@key=''1'']/Voltage', NULL, 'integer')
,
('Configuration[@key=''_036CE062.Communicator'']/Scale/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE062'']/Communication/Item[@key=''serialport'']/Modbus/Item[@key=''COM1'']/Board/Item[@key=''_045CE110'']/Adress/Item[@key=''21'']/Channel/Item[@key=''1'']/Amperage', NULL, 'float')
,
('Configuration[@key=''_036CE062.Communicator'']/Scale/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE062'']/Communication/Item[@key=''serialport'']/Modbus/Item[@key=''COM1'']/Board/Item[@key=''_045CE110'']/Adress/Item[@key=''21'']/Channel/Item[@key=''2'']/Voltage', NULL, 'integer')
,
('Configuration[@key=''_036CE062.Communicator'']/Scale/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE062'']/Communication/Item[@key=''serialport'']/Modbus/Item[@key=''COM1'']/Board/Item[@key=''_045CE110'']/Adress/Item[@key=''21'']/Channel/Item[@key=''2'']/Amperage', NULL, 'float')
,
('Configuration[@key=''_036CE062.Communicator'']/Scale/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE062'']/Communication/Item[@key=''serialport'']/Modbus/Item[@key=''COM1'']/Board/Item[@key=''_045CE110'']/Adress/Item[@key=''21'']/Channel/Item[@key=''3'']/Voltage', NULL, 'integer')
,
('Configuration[@key=''_036CE062.Communicator'']/Scale/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE062'']/Communication/Item[@key=''serialport'']/Modbus/Item[@key=''COM1'']/Board/Item[@key=''_045CE110'']/Adress/Item[@key=''21'']/Channel/Item[@key=''3'']/Amperage', NULL, 'float')
,
('Configuration[@key=''_036CE062.Communicator'']/Scale/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE062'']/Communication/Item[@key=''serialport'']/Modbus/Item[@key=''COM1'']/Board/Item[@key=''_045CE110'']/Adress/Item[@key=''21'']/Channel/Item[@key=''4'']/Voltage', NULL, 'integer')
,
('Configuration[@key=''_036CE062.Communicator'']/Scale/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE062'']/Communication/Item[@key=''serialport'']/Modbus/Item[@key=''COM1'']/Board/Item[@key=''_045CE110'']/Adress/Item[@key=''21'']/Channel/Item[@key=''4'']/Amperage', NULL, 'float')
,
('Configuration[@key=''_036CE062.Communicator'']/Scale/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE062'']/Communication/Item[@key=''serialport'']/Modbus/Item[@key=''COM1'']/Board/Item[@key=''_045CE110'']/Adress/Item[@key=''22'']/Channel/Item[@key=''1'']/Voltage', NULL, 'integer')
,
('Configuration[@key=''_036CE062.Communicator'']/Scale/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE062'']/Communication/Item[@key=''serialport'']/Modbus/Item[@key=''COM1'']/Board/Item[@key=''_045CE110'']/Adress/Item[@key=''22'']/Channel/Item[@key=''1'']/Amperage', NULL, 'float')
,
('Configuration[@key=''_036CE062.Communicator'']/Scale/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE062'']/Communication/Item[@key=''serialport'']/Modbus/Item[@key=''COM1'']/Board/Item[@key=''_045CE110'']/Adress/Item[@key=''22'']/Channel/Item[@key=''2'']/Voltage', NULL, 'integer')
,
('Configuration[@key=''_036CE062.Communicator'']/Scale/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE062'']/Communication/Item[@key=''serialport'']/Modbus/Item[@key=''COM1'']/Board/Item[@key=''_045CE110'']/Adress/Item[@key=''22'']/Channel/Item[@key=''2'']/Amperage', NULL, 'float')
,
('Configuration[@key=''_036CE062.Communicator'']/Scale/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE062'']/Communication/Item[@key=''serialport'']/Modbus/Item[@key=''COM1'']/Board/Item[@key=''_045CE110'']/Adress/Item[@key=''22'']/Channel/Item[@key=''3'']/Voltage', NULL, 'integer')
,
('Configuration[@key=''_036CE062.Communicator'']/Scale/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE062'']/Communication/Item[@key=''serialport'']/Modbus/Item[@key=''COM1'']/Board/Item[@key=''_045CE110'']/Adress/Item[@key=''22'']/Channel/Item[@key=''3'']/Amperage', NULL, 'float')
,
('Configuration[@key=''_036CE062.Communicator'']/Scale/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE062'']/Communication/Item[@key=''serialport'']/Modbus/Item[@key=''COM1'']/Board/Item[@key=''_045CE110'']/Adress/Item[@key=''22'']/Channel/Item[@key=''4'']/Voltage', NULL, 'integer')
,
('Configuration[@key=''_036CE062.Communicator'']/Scale/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE062'']/Communication/Item[@key=''serialport'']/Modbus/Item[@key=''COM1'']/Board/Item[@key=''_045CE110'']/Adress/Item[@key=''22'']/Channel/Item[@key=''4'']/Amperage', NULL, 'float')
,
('Configuration[@key=''_036CE062.Communicator'']/Scale/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE062'']/Communication/Item[@key=''serialport'']/Modbus/Item[@key=''COM1'']/Board/Item[@key=''_045CE110'']/Adress/Item[@key=''23'']/Channel/Item[@key=''1'']/Voltage', NULL, 'integer')
,
('Configuration[@key=''_036CE062.Communicator'']/Scale/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE062'']/Communication/Item[@key=''serialport'']/Modbus/Item[@key=''COM1'']/Board/Item[@key=''_045CE110'']/Adress/Item[@key=''23'']/Channel/Item[@key=''1'']/Amperage', NULL, 'float')
,
('Configuration[@key=''_036CE062.Communicator'']/Scale/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE062'']/Communication/Item[@key=''serialport'']/Modbus/Item[@key=''COM1'']/Board/Item[@key=''_045CE110'']/Adress/Item[@key=''23'']/Channel/Item[@key=''2'']/Voltage', NULL, 'integer')
,
('Configuration[@key=''_036CE062.Communicator'']/Scale/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE062'']/Communication/Item[@key=''serialport'']/Modbus/Item[@key=''COM1'']/Board/Item[@key=''_045CE110'']/Adress/Item[@key=''23'']/Channel/Item[@key=''2'']/Amperage', NULL, 'float')
,
('Configuration[@key=''_036CE062.Communicator'']/Scale/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE062'']/Communication/Item[@key=''serialport'']/Modbus/Item[@key=''COM1'']/Board/Item[@key=''_045CE110'']/Adress/Item[@key=''23'']/Channel/Item[@key=''3'']/Voltage', NULL, 'integer')
,
('Configuration[@key=''_036CE062.Communicator'']/Scale/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE062'']/Communication/Item[@key=''serialport'']/Modbus/Item[@key=''COM1'']/Board/Item[@key=''_045CE110'']/Adress/Item[@key=''23'']/Channel/Item[@key=''3'']/Amperage', NULL, 'float')
,
('Configuration[@key=''_036CE062.Communicator'']/Scale/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE062'']/Communication/Item[@key=''serialport'']/Modbus/Item[@key=''COM1'']/Board/Item[@key=''_045CE110'']/Adress/Item[@key=''23'']/Channel/Item[@key=''4'']/Voltage', NULL, 'integer')
,
('Configuration[@key=''_036CE062.Communicator'']/Scale/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE062'']/Communication/Item[@key=''serialport'']/Modbus/Item[@key=''COM1'']/Board/Item[@key=''_045CE110'']/Adress/Item[@key=''23'']/Channel/Item[@key=''4'']/Amperage', NULL, 'float')
,
('Configuration[@key=''_036CE062.Communicator'']/Scale/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE062'']/Communication/Item[@key=''serialport'']/Modbus/Item[@key=''COM1'']/Board/Item[@key=''_045CE110'']/Adress/Item[@key=''24'']/Channel/Item[@key=''1'']/Voltage', NULL, 'integer')
,
('Configuration[@key=''_036CE062.Communicator'']/Scale/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE062'']/Communication/Item[@key=''serialport'']/Modbus/Item[@key=''COM1'']/Board/Item[@key=''_045CE110'']/Adress/Item[@key=''24'']/Channel/Item[@key=''1'']/Amperage', NULL, 'float')
,
('Configuration[@key=''_036CE062.Communicator'']/Scale/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE062'']/Communication/Item[@key=''serialport'']/Modbus/Item[@key=''COM1'']/Board/Item[@key=''_045CE110'']/Adress/Item[@key=''24'']/Channel/Item[@key=''2'']/Voltage', NULL, 'integer')
,
('Configuration[@key=''_036CE062.Communicator'']/Scale/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE062'']/Communication/Item[@key=''serialport'']/Modbus/Item[@key=''COM1'']/Board/Item[@key=''_045CE110'']/Adress/Item[@key=''24'']/Channel/Item[@key=''2'']/Amperage', NULL, 'float')
,
('Configuration[@key=''_036CE062.Communicator'']/Scale/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE062'']/Communication/Item[@key=''serialport'']/Modbus/Item[@key=''COM1'']/Board/Item[@key=''_045CE110'']/Adress/Item[@key=''24'']/Channel/Item[@key=''3'']/Voltage', NULL, 'integer')
,
('Configuration[@key=''_036CE062.Communicator'']/Scale/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE062'']/Communication/Item[@key=''serialport'']/Modbus/Item[@key=''COM1'']/Board/Item[@key=''_045CE110'']/Adress/Item[@key=''24'']/Channel/Item[@key=''3'']/Amperage', NULL, 'float')
,
('Configuration[@key=''_036CE062.Communicator'']/Scale/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE062'']/Communication/Item[@key=''serialport'']/Modbus/Item[@key=''COM1'']/Board/Item[@key=''_045CE110'']/Adress/Item[@key=''24'']/Channel/Item[@key=''4'']/Voltage', NULL, 'integer')
,
('Configuration[@key=''_036CE062.Communicator'']/Scale/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE062'']/Communication/Item[@key=''serialport'']/Modbus/Item[@key=''COM1'']/Board/Item[@key=''_045CE110'']/Adress/Item[@key=''24'']/Channel/Item[@key=''4'']/Amperage', NULL, 'float')
,
('Configuration[@key=''_036CE062.Communicator'']/Scale/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE062'']/Communication/Item[@key=''serialport'']/Modbus/Item[@key=''COM1'']/Board/Item[@key=''_045CE110'']/Adress/Item[@key=''25'']/Channel/Item[@key=''1'']/Voltage', NULL, 'integer')
,
('Configuration[@key=''_036CE062.Communicator'']/Scale/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE062'']/Communication/Item[@key=''serialport'']/Modbus/Item[@key=''COM1'']/Board/Item[@key=''_045CE110'']/Adress/Item[@key=''25'']/Channel/Item[@key=''1'']/Amperage', NULL, 'float')
,
('Configuration[@key=''_036CE062.Communicator'']/Scale/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE062'']/Communication/Item[@key=''serialport'']/Modbus/Item[@key=''COM1'']/Board/Item[@key=''_045CE110'']/Adress/Item[@key=''25'']/Channel/Item[@key=''2'']/Voltage', NULL, 'integer')
,
('Configuration[@key=''_036CE062.Communicator'']/Scale/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE062'']/Communication/Item[@key=''serialport'']/Modbus/Item[@key=''COM1'']/Board/Item[@key=''_045CE110'']/Adress/Item[@key=''25'']/Channel/Item[@key=''2'']/Amperage', NULL, 'float')
,
('Configuration[@key=''_036CE062.Communicator'']/Scale/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE062'']/Communication/Item[@key=''serialport'']/Modbus/Item[@key=''COM1'']/Board/Item[@key=''_045CE110'']/Adress/Item[@key=''25'']/Channel/Item[@key=''3'']/Voltage', NULL, 'integer')
,
('Configuration[@key=''_036CE062.Communicator'']/Scale/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE062'']/Communication/Item[@key=''serialport'']/Modbus/Item[@key=''COM1'']/Board/Item[@key=''_045CE110'']/Adress/Item[@key=''25'']/Channel/Item[@key=''3'']/Amperage', NULL, 'float')
,
('Configuration[@key=''_036CE062.Communicator'']/Scale/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE062'']/Communication/Item[@key=''serialport'']/Modbus/Item[@key=''COM1'']/Board/Item[@key=''_045CE110'']/Adress/Item[@key=''25'']/Channel/Item[@key=''4'']/Voltage', NULL, 'integer')
,
('Configuration[@key=''_036CE062.Communicator'']/Scale/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE062'']/Communication/Item[@key=''serialport'']/Modbus/Item[@key=''COM1'']/Board/Item[@key=''_045CE110'']/Adress/Item[@key=''25'']/Channel/Item[@key=''4'']/Amperage', NULL, 'float')
,
('Configuration[@key=''_036CE062.Communicator'']/Scale/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE062'']/Communication/Item[@key=''serialport'']/Modbus/Item[@key=''COM1'']/Board/Item[@key=''_045CE110'']/Adress/Item[@key=''26'']/Channel/Item[@key=''1'']/Voltage', NULL, 'integer')
,
('Configuration[@key=''_036CE062.Communicator'']/Scale/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE062'']/Communication/Item[@key=''serialport'']/Modbus/Item[@key=''COM1'']/Board/Item[@key=''_045CE110'']/Adress/Item[@key=''26'']/Channel/Item[@key=''1'']/Amperage', NULL, 'float')
,
('Configuration[@key=''_036CE062.Communicator'']/Scale/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE062'']/Communication/Item[@key=''serialport'']/Modbus/Item[@key=''COM1'']/Board/Item[@key=''_045CE110'']/Adress/Item[@key=''26'']/Channel/Item[@key=''2'']/Voltage', NULL, 'integer')
,
('Configuration[@key=''_036CE062.Communicator'']/Scale/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE062'']/Communication/Item[@key=''serialport'']/Modbus/Item[@key=''COM1'']/Board/Item[@key=''_045CE110'']/Adress/Item[@key=''26'']/Channel/Item[@key=''2'']/Amperage', NULL, 'float')
,
('Configuration[@key=''_036CE062.Communicator'']/Scale/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE062'']/Communication/Item[@key=''serialport'']/Modbus/Item[@key=''COM1'']/Board/Item[@key=''_045CE110'']/Adress/Item[@key=''26'']/Channel/Item[@key=''3'']/Voltage', NULL, 'integer')
,
('Configuration[@key=''_036CE062.Communicator'']/Scale/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE062'']/Communication/Item[@key=''serialport'']/Modbus/Item[@key=''COM1'']/Board/Item[@key=''_045CE110'']/Adress/Item[@key=''26'']/Channel/Item[@key=''3'']/Amperage', NULL, 'float')
,
('Configuration[@key=''_036CE062.Communicator'']/Scale/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE062'']/Communication/Item[@key=''serialport'']/Modbus/Item[@key=''COM1'']/Board/Item[@key=''_045CE110'']/Adress/Item[@key=''26'']/Channel/Item[@key=''4'']/Voltage', NULL, 'integer')
,
('Configuration[@key=''_036CE062.Communicator'']/Scale/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE062'']/Communication/Item[@key=''serialport'']/Modbus/Item[@key=''COM1'']/Board/Item[@key=''_045CE110'']/Adress/Item[@key=''26'']/Channel/Item[@key=''4'']/Amperage', NULL, 'float')
,
('Configuration[@key=''_036CE062.Communicator'']/Scale/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE062'']/Communication/Item[@key=''serialport'']/Modbus/Item[@key=''COM1'']/Board/Item[@key=''_045CE110'']/Adress/Item[@key=''27'']/Channel/Item[@key=''1'']/Voltage', NULL, 'integer')
,
('Configuration[@key=''_036CE062.Communicator'']/Scale/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE062'']/Communication/Item[@key=''serialport'']/Modbus/Item[@key=''COM1'']/Board/Item[@key=''_045CE110'']/Adress/Item[@key=''27'']/Channel/Item[@key=''1'']/Amperage', NULL, 'float')
,
('Configuration[@key=''_036CE062.Communicator'']/Scale/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE062'']/Communication/Item[@key=''serialport'']/Modbus/Item[@key=''COM1'']/Board/Item[@key=''_045CE110'']/Adress/Item[@key=''27'']/Channel/Item[@key=''2'']/Voltage', NULL, 'integer')
,
('Configuration[@key=''_036CE062.Communicator'']/Scale/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE062'']/Communication/Item[@key=''serialport'']/Modbus/Item[@key=''COM1'']/Board/Item[@key=''_045CE110'']/Adress/Item[@key=''27'']/Channel/Item[@key=''2'']/Amperage', NULL, 'float')
,
('Configuration[@key=''_036CE062.Communicator'']/Scale/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE062'']/Communication/Item[@key=''serialport'']/Modbus/Item[@key=''COM1'']/Board/Item[@key=''_045CE110'']/Adress/Item[@key=''27'']/Channel/Item[@key=''3'']/Voltage', NULL, 'integer')
,
('Configuration[@key=''_036CE062.Communicator'']/Scale/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE062'']/Communication/Item[@key=''serialport'']/Modbus/Item[@key=''COM1'']/Board/Item[@key=''_045CE110'']/Adress/Item[@key=''27'']/Channel/Item[@key=''3'']/Amperage', NULL, 'float')
,
('Configuration[@key=''_036CE062.Communicator'']/Scale/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE062'']/Communication/Item[@key=''serialport'']/Modbus/Item[@key=''COM1'']/Board/Item[@key=''_045CE110'']/Adress/Item[@key=''27'']/Channel/Item[@key=''4'']/Voltage', NULL, 'integer')
,
('Configuration[@key=''_036CE062.Communicator'']/Scale/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE062'']/Communication/Item[@key=''serialport'']/Modbus/Item[@key=''COM1'']/Board/Item[@key=''_045CE110'']/Adress/Item[@key=''27'']/Channel/Item[@key=''4'']/Amperage', NULL, 'float')
,
('Configuration[@key=''_036CE062.Communicator'']/Scale/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE062'']/Communication/Item[@key=''serialport'']/Modbus/Item[@key=''COM1'']/Board/Item[@key=''_045CE110'']/Adress/Item[@key=''28'']/Channel/Item[@key=''1'']/Voltage', NULL, 'integer')
,
('Configuration[@key=''_036CE062.Communicator'']/Scale/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE062'']/Communication/Item[@key=''serialport'']/Modbus/Item[@key=''COM1'']/Board/Item[@key=''_045CE110'']/Adress/Item[@key=''28'']/Channel/Item[@key=''1'']/Amperage', NULL, 'float')
,
('Configuration[@key=''_036CE062.Communicator'']/Scale/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE062'']/Communication/Item[@key=''serialport'']/Modbus/Item[@key=''COM1'']/Board/Item[@key=''_045CE110'']/Adress/Item[@key=''28'']/Channel/Item[@key=''2'']/Voltage', NULL, 'integer')
,
('Configuration[@key=''_036CE062.Communicator'']/Scale/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE062'']/Communication/Item[@key=''serialport'']/Modbus/Item[@key=''COM1'']/Board/Item[@key=''_045CE110'']/Adress/Item[@key=''28'']/Channel/Item[@key=''2'']/Amperage', NULL, 'float')
,
('Configuration[@key=''_036CE062.Communicator'']/Scale/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE062'']/Communication/Item[@key=''serialport'']/Modbus/Item[@key=''COM1'']/Board/Item[@key=''_045CE110'']/Adress/Item[@key=''28'']/Channel/Item[@key=''3'']/Voltage', NULL, 'integer')
,
('Configuration[@key=''_036CE062.Communicator'']/Scale/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE062'']/Communication/Item[@key=''serialport'']/Modbus/Item[@key=''COM1'']/Board/Item[@key=''_045CE110'']/Adress/Item[@key=''28'']/Channel/Item[@key=''3'']/Amperage', NULL, 'float')
,
('Configuration[@key=''_036CE062.Communicator'']/Scale/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE062'']/Communication/Item[@key=''serialport'']/Modbus/Item[@key=''COM1'']/Board/Item[@key=''_045CE110'']/Adress/Item[@key=''28'']/Channel/Item[@key=''4'']/Voltage', NULL, 'integer')
,
('Configuration[@key=''_036CE062.Communicator'']/Scale/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE062'']/Communication/Item[@key=''serialport'']/Modbus/Item[@key=''COM1'']/Board/Item[@key=''_045CE110'']/Adress/Item[@key=''28'']/Channel/Item[@key=''4'']/Amperage', NULL, 'float')
,
('Configuration[@key=''_036CE062.Communicator'']/Scale/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE062'']/Communication/Item[@key=''serialport'']/Modbus/Item[@key=''COM1'']/Board/Item[@key=''_045CE110'']/Adress/Item[@key=''29'']/Channel/Item[@key=''1'']/Voltage', NULL, 'integer')
,
('Configuration[@key=''_036CE062.Communicator'']/Scale/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE062'']/Communication/Item[@key=''serialport'']/Modbus/Item[@key=''COM1'']/Board/Item[@key=''_045CE110'']/Adress/Item[@key=''29'']/Channel/Item[@key=''1'']/Amperage', NULL, 'float')
,
('Configuration[@key=''_036CE062.Communicator'']/Scale/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE062'']/Communication/Item[@key=''serialport'']/Modbus/Item[@key=''COM1'']/Board/Item[@key=''_045CE110'']/Adress/Item[@key=''29'']/Channel/Item[@key=''2'']/Voltage', NULL, 'integer')
,
('Configuration[@key=''_036CE062.Communicator'']/Scale/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE062'']/Communication/Item[@key=''serialport'']/Modbus/Item[@key=''COM1'']/Board/Item[@key=''_045CE110'']/Adress/Item[@key=''29'']/Channel/Item[@key=''2'']/Amperage', NULL, 'float')
,
('Configuration[@key=''_036CE062.Communicator'']/Scale/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE062'']/Communication/Item[@key=''serialport'']/Modbus/Item[@key=''COM1'']/Board/Item[@key=''_045CE110'']/Adress/Item[@key=''29'']/Channel/Item[@key=''3'']/Voltage', NULL, 'integer')
,
('Configuration[@key=''_036CE062.Communicator'']/Scale/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE062'']/Communication/Item[@key=''serialport'']/Modbus/Item[@key=''COM1'']/Board/Item[@key=''_045CE110'']/Adress/Item[@key=''29'']/Channel/Item[@key=''3'']/Amperage', NULL, 'float')
,
('Configuration[@key=''_036CE062.Communicator'']/Scale/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE062'']/Communication/Item[@key=''serialport'']/Modbus/Item[@key=''COM1'']/Board/Item[@key=''_045CE110'']/Adress/Item[@key=''29'']/Channel/Item[@key=''4'']/Voltage', NULL, 'integer')
,
('Configuration[@key=''_036CE062.Communicator'']/Scale/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE062'']/Communication/Item[@key=''serialport'']/Modbus/Item[@key=''COM1'']/Board/Item[@key=''_045CE110'']/Adress/Item[@key=''29'']/Channel/Item[@key=''4'']/Amperage', NULL, 'float')
,
('Configuration[@key=''_036CE062.Communicator'']/Scale/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE062'']/Communication/Item[@key=''serialport'']/Modbus/Item[@key=''COM1'']/Board/Item[@key=''_045CE110'']/Adress/Item[@key=''30'']/Channel/Item[@key=''1'']/Voltage', NULL, 'integer')
,
('Configuration[@key=''_036CE062.Communicator'']/Scale/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE062'']/Communication/Item[@key=''serialport'']/Modbus/Item[@key=''COM1'']/Board/Item[@key=''_045CE110'']/Adress/Item[@key=''30'']/Channel/Item[@key=''1'']/Amperage', NULL, 'float')
,
('Configuration[@key=''_036CE062.Communicator'']/Scale/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE062'']/Communication/Item[@key=''serialport'']/Modbus/Item[@key=''COM1'']/Board/Item[@key=''_045CE110'']/Adress/Item[@key=''30'']/Channel/Item[@key=''2'']/Voltage', NULL, 'integer')
,
('Configuration[@key=''_036CE062.Communicator'']/Scale/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE062'']/Communication/Item[@key=''serialport'']/Modbus/Item[@key=''COM1'']/Board/Item[@key=''_045CE110'']/Adress/Item[@key=''30'']/Channel/Item[@key=''2'']/Amperage', NULL, 'float')
,
('Configuration[@key=''_036CE062.Communicator'']/Scale/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE062'']/Communication/Item[@key=''serialport'']/Modbus/Item[@key=''COM1'']/Board/Item[@key=''_045CE110'']/Adress/Item[@key=''30'']/Channel/Item[@key=''3'']/Voltage', NULL, 'integer')
,
('Configuration[@key=''_036CE062.Communicator'']/Scale/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE062'']/Communication/Item[@key=''serialport'']/Modbus/Item[@key=''COM1'']/Board/Item[@key=''_045CE110'']/Adress/Item[@key=''30'']/Channel/Item[@key=''3'']/Amperage', NULL, 'float')
,
('Configuration[@key=''_036CE062.Communicator'']/Scale/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE062'']/Communication/Item[@key=''serialport'']/Modbus/Item[@key=''COM1'']/Board/Item[@key=''_045CE110'']/Adress/Item[@key=''30'']/Channel/Item[@key=''4'']/Voltage', NULL, 'integer')
,
('Configuration[@key=''_036CE062.Communicator'']/Scale/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE062'']/Communication/Item[@key=''serialport'']/Modbus/Item[@key=''COM1'']/Board/Item[@key=''_045CE110'']/Adress/Item[@key=''30'']/Channel/Item[@key=''4'']/Amperage', NULL, 'float')
;
-----------------------------------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION _set_order(xpath TEXT, _entity XML) 
RETURNS BOOLEAN AS $$
	
	--Использование функции:
	
	--SELECT * FROM _set_order('XPath','Entity');
	
DECLARE 

	_Key INTEGER;
	_Existence BOOLEAN;
	
BEGIN
						
	IF (SELECT EXISTS(SELECT 1 from glossary WHERE configuration = xpath)) THEN
		_Key := (SELECT key FROM glossary WHERE configuration = xpath); 
							
		--Проверка существования в актуальной таблице entity_actual записи с ключом _Key 							
		EXECUTE FORMAT('SELECT EXISTS(SELECT 1 from order_actual WHERE key = %s)', _Key) INTO _Existence;

		IF (_Existence) THEN
			UPDATE order_actual SET fix = NOW(), entity = _entity WHERE key = _Key;
		ELSE
			INSERT INTO order_actual(key, fix, entity) VALUES(_Key, NOW(), _entity);
		END IF; 
		
		--order_archive
		IF (_Key <> 0 AND _Key IS NOT NULL) THEN
			--вставить новую запись в таблицу order_archive из таблицы order_actual
			INSERT INTO order_archive(key, fix, entity) SELECT * FROM order_actual WHERE KEY = _Key;
		END IF;  
		
		RETURN true;
		
	END IF; 
	
	RETURN false;

END;

$$ LANGUAGE plpgsql;
-----------------------------------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION _set_value(xpath TEXT, _entity XML) 
RETURNS BOOLEAN AS $$
	
	--Использование функции:
	
	--SELECT * FROM _set_value('XPath','Entity');
	
DECLARE 

	_Key INTEGER;
	_Existence BOOLEAN;
	
BEGIN
						
	IF (SELECT EXISTS(SELECT 1 from glossary WHERE communication = xpath)) THEN
		_Key := (SELECT key FROM glossary WHERE communication = xpath); 
								
		EXECUTE FORMAT('SELECT EXISTS(SELECT 1 from value_actual WHERE key = %s)', _Key) INTO _Existence;

		IF (_Existence) THEN
			UPDATE value_actual SET fix = NOW(), entity = _entity WHERE key = _Key;
		ELSE
			INSERT INTO value_actual(key, fix, entity) VALUES(_Key, NOW(), _entity);
		END IF; 
		
		--value_archive
		IF (_Key <> 0 AND _Key IS NOT NULL) THEN
			--вставить новую запись в таблицу value_archive из таблицы value_actual
			INSERT INTO value_archive(key, fix, entity) SELECT * FROM value_actual WHERE KEY = _Key;
		END IF;  
		
		RETURN true;
		
	END IF; 
	
	RETURN false;

END;

$$ LANGUAGE plpgsql;
-----------------------------------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION _get_order()
RETURNS TABLE (entity XML, communication TEXT) AS $$
	
	--Использование функции:
	
	--SELECT * FROM _get_order();
	
BEGIN
	
	DROP TABLE IF EXISTS tem;
	
	CREATE TEMPORARY TABLE tem AS	
	SELECT order_actual.entity AS entity, g.communication AS communication, g.Key AS Key
	FROM glossary AS g INNER JOIN order_actual ON g.key = order_actual.key;
	    
	DELETE FROM order_actual WHERE order_actual.key IN (SELECT key FROM tem);
	   
	RETURN QUERY SELECT t.entity, t.communication FROM tem AS t;
	
END;

$$ LANGUAGE plpgsql;
-----------------------------------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION _get_value()
RETURNS TABLE (entity XML, configuration TEXT) AS $$
	
	--Использование функции:
	
	--SELECT * FROM _get_value();
	
BEGIN
		
	RETURN QUERY
		SELECT value_actual.entity AS entity, g.configuration AS configuration
		FROM glossary AS g INNER JOIN value_actual ON g.key = value_actual.key;	

END;

$$ LANGUAGE plpgsql;
-----------------------------------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION _synchronizer(_xpath TEXT) 
RETURNS TIMESTAMP AS $$

	--Использование функции:
	--SELECT * FROM _synchronizer('Xpath');
	
DECLARE 

	--переменные для:
	_Key INTEGER;			--значения ключа таблицы glossary  
	
BEGIN

	--Получение значения поля 'key' таблицы glossary, используя входной аргумент XPath 
	IF (SELECT EXISTS(SELECT 1 from glossary WHERE configuration = _xpath)) THEN
		_Key := (SELECT key FROM glossary WHERE configuration = _xpath);
	ELSE
		_Key := (SELECT key FROM glossary WHERE communication = _xpath);
	END IF;
	
	--value_archive
	IF (_Key <> 0 AND _Key IS NOT NULL) THEN
		--вставить новую запись в таблицу value_archive из таблицы value_actual
		INSERT INTO value_archive(key, fix, entity) SELECT * FROM value_actual WHERE KEY = _Key;
	END IF;  
	
	--order_archive
	IF (_Key <> 0 AND _Key IS NOT NULL) THEN
		--вставить новую запись в таблицу order_archive из таблицы order_actual
		INSERT INTO order_archive(key, fix, entity) SELECT * FROM order_actual WHERE KEY = _Key;
    END IF; 

	--очистить таблицы value_actual и order_actual
	TRUNCATE value_actual RESTART IDENTITY;
	TRUNCATE order_actual RESTART IDENTITY;
	
	RETURN NOW();

END;

$$ LANGUAGE plpgsql;
-----------------------------------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION _clear(_xpath TEXT)
RETURNS VOID AS $$

	--Очищение записи по ключу из таблицы glossary в таблице 
	--order_actual и внесение этой записи в таблицу order_archive

	--Использование функции:
	--SELECT * FROM _clear('Xpath');

DECLARE 

	--переменные для:
	_Key INTEGER;			--значения ключа таблицы glossary  
	
	
BEGIN

	--Получение значения поля 'key' таблицы glossary, используя входной аргумент XPath 
	IF (SELECT EXISTS(SELECT 1 from glossary WHERE configuration = _xpath)) THEN
		_Key := (SELECT key FROM glossary WHERE configuration = _xpath);
	ELSE
		_Key := (SELECT key FROM glossary WHERE communication = _xpath);
	END IF;
	
	--order_archive
	IF (_Key <> 0 AND _Key IS NOT NULL) THEN
		--вставить новую запись в таблицу order_archive из таблицы order_actual
		INSERT INTO order_archive(key, fix, entity) SELECT * FROM order_actual WHERE KEY = _Key;
    END IF;  
	
	--очистить запись по ключу из таблицы order_actual
	DELETE FROM order_actual WHERE KEY = _Key;
END;

$$ LANGUAGE plpgsql;
	