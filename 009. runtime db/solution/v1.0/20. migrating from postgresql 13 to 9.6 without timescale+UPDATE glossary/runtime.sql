
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
--CREATE EXTENSION IF NOT EXISTS timescaledb;

SET search_path = public, pg_catalog;
SET default_tablespace = '';
SET default_with_oids = false;
-----------------------------------------------------------------------------------------------------
CREATE TABLE glossary (
    key SERIAL NOT NULL,
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

	CREATE TABLE IF NOT EXISTS %I( 
	key INTEGER NOT NULL,
	fix TIMESTAMPTZ NOT NULL,
	value %s NOT NULL,
	FOREIGN KEY (key) REFERENCES glossary(key));',
	_HyperTable, 	
	_TableName,
	
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
-----------------------------------------------------------------------------------------------------
INSERT INTO glossary (configuration, communication, allowance, tablename) VALUES --,
('Configuration/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE061.Runtime'']/Equipment/Slot/Item[@key=''1'']/Supply/Item[@key=''photocathode'']/Amperage', NULL, 3, 'float')
,
('Configuration/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE061.Runtime'']/Equipment/Slot/Item[@key=''1'']/Supply/Item[@key=''photocathode'']/Voltage', NULL, 3, 'integer')
,
('Configuration/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE061.Runtime'']/Equipment/Slot/Item[@key=''1'']/Supply/Item[@key=''microchannelplate1'']/Amperage', NULL, 3, 'float')
,
('Configuration/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE061.Runtime'']/Equipment/Slot/Item[@key=''1'']/Supply/Item[@key=''microchannelplate1'']/Voltage', NULL, 3, 'integer')
,
('Configuration/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE061.Runtime'']/Equipment/Slot/Item[@key=''1'']/Supply/Item[@key=''microchannelplate12'']/Amperage', NULL, 3, 'float')
,
('Configuration/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE061.Runtime'']/Equipment/Slot/Item[@key=''1'']/Supply/Item[@key=''microchannelplate12'']/Voltage', NULL, 3, 'integer')
,
('Configuration/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE061.Runtime'']/Equipment/Slot/Item[@key=''1'']/Supply/Item[@key=''microchannelplate2'']/Amperage', NULL, 3, 'float')
,
('Configuration/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE061.Runtime'']/Equipment/Slot/Item[@key=''1'']/Supply/Item[@key=''microchannelplate2'']/Voltage', NULL, 3, 'integer')
,
('Configuration/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE061.Runtime'']/Equipment/Slot/Item[@key=''1'']/Supply/Item[@key=''anode'']/Amperage', NULL, 3, 'float')
,
('Configuration/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE061.Runtime'']/Equipment/Slot/Item[@key=''1'']/Supply/Item[@key=''anode'']/Voltage', NULL, 3, 'integer')
,
('Configuration/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE061.Runtime'']/Equipment/Slot/Item[@key=''2'']/Supply/Item[@key=''photocathode'']/Amperage', NULL, 3, 'float')
,
('Configuration/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE061.Runtime'']/Equipment/Slot/Item[@key=''2'']/Supply/Item[@key=''photocathode'']/Voltage', NULL, 3, 'integer')
,
('Configuration/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE061.Runtime'']/Equipment/Slot/Item[@key=''2'']/Supply/Item[@key=''microchannelplate1'']/Amperage', NULL, 3, 'float')
,
('Configuration/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE061.Runtime'']/Equipment/Slot/Item[@key=''2'']/Supply/Item[@key=''microchannelplate1'']/Voltage', NULL, 3, 'integer')
,
('Configuration/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE061.Runtime'']/Equipment/Slot/Item[@key=''2'']/Supply/Item[@key=''microchannelplate12'']/Amperage', NULL, 3, 'float')
,
('Configuration/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE061.Runtime'']/Equipment/Slot/Item[@key=''2'']/Supply/Item[@key=''microchannelplate12'']/Voltage', NULL, 3, 'integer')
,
('Configuration/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE061.Runtime'']/Equipment/Slot/Item[@key=''2'']/Supply/Item[@key=''microchannelplate2'']/Amperage', NULL, 3, 'float')
,
('Configuration/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE061.Runtime'']/Equipment/Slot/Item[@key=''2'']/Supply/Item[@key=''microchannelplate2'']/Voltage', NULL, 3, 'integer')
,
('Configuration/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE061.Runtime'']/Equipment/Slot/Item[@key=''2'']/Supply/Item[@key=''anode'']/Amperage', NULL, 3, 'float')
,
('Configuration/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE061.Runtime'']/Equipment/Slot/Item[@key=''2'']/Supply/Item[@key=''anode'']/Voltage', NULL, 3, 'integer')
,
('Configuration/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE061.Runtime'']/Equipment/Slot/Item[@key=''3'']/Supply/Item[@key=''photocathode'']/Amperage', NULL, 3, 'float')
,
('Configuration/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE061.Runtime'']/Equipment/Slot/Item[@key=''3'']/Supply/Item[@key=''photocathode'']/Voltage', NULL, 3, 'integer')
,
('Configuration/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE061.Runtime'']/Equipment/Slot/Item[@key=''3'']/Supply/Item[@key=''microchannelplate1'']/Amperage', NULL, 3, 'float')
,
('Configuration/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE061.Runtime'']/Equipment/Slot/Item[@key=''3'']/Supply/Item[@key=''microchannelplate1'']/Voltage', NULL, 3, 'integer')
,
('Configuration/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE061.Runtime'']/Equipment/Slot/Item[@key=''3'']/Supply/Item[@key=''microchannelplate12'']/Amperage', NULL, 3, 'float')
,
('Configuration/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE061.Runtime'']/Equipment/Slot/Item[@key=''3'']/Supply/Item[@key=''microchannelplate12'']/Voltage', NULL, 3, 'integer')
,
('Configuration/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE061.Runtime'']/Equipment/Slot/Item[@key=''3'']/Supply/Item[@key=''microchannelplate2'']/Amperage', NULL, 3, 'float')
,
('Configuration/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE061.Runtime'']/Equipment/Slot/Item[@key=''3'']/Supply/Item[@key=''microchannelplate2'']/Voltage', NULL, 3, 'integer')
,
('Configuration/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE061.Runtime'']/Equipment/Slot/Item[@key=''3'']/Supply/Item[@key=''anode'']/Amperage', NULL, 3, 'float')
,
('Configuration/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE061.Runtime'']/Equipment/Slot/Item[@key=''3'']/Supply/Item[@key=''anode'']/Voltage', NULL, 3, 'integer')
,
('Configuration/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE061.Runtime'']/Equipment/Slot/Item[@key=''4'']/Supply/Item[@key=''photocathode'']/Amperage', NULL, 3, 'float')
,
('Configuration/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE061.Runtime'']/Equipment/Slot/Item[@key=''4'']/Supply/Item[@key=''photocathode'']/Voltage', NULL, 3, 'integer')
,
('Configuration/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE061.Runtime'']/Equipment/Slot/Item[@key=''4'']/Supply/Item[@key=''microchannelplate1'']/Amperage', NULL, 3, 'float')
,
('Configuration/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE061.Runtime'']/Equipment/Slot/Item[@key=''4'']/Supply/Item[@key=''microchannelplate1'']/Voltage', NULL, 3, 'integer')
,
('Configuration/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE061.Runtime'']/Equipment/Slot/Item[@key=''4'']/Supply/Item[@key=''microchannelplate12'']/Amperage', NULL, 3, 'float')
,
('Configuration/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE061.Runtime'']/Equipment/Slot/Item[@key=''4'']/Supply/Item[@key=''microchannelplate12'']/Voltage', NULL, 3, 'integer')
,
('Configuration/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE061.Runtime'']/Equipment/Slot/Item[@key=''4'']/Supply/Item[@key=''microchannelplate2'']/Amperage', NULL, 3, 'float')
,
('Configuration/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE061.Runtime'']/Equipment/Slot/Item[@key=''4'']/Supply/Item[@key=''microchannelplate2'']/Voltage', NULL, 3, 'integer')
,
('Configuration/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE061.Runtime'']/Equipment/Slot/Item[@key=''4'']/Supply/Item[@key=''anode'']/Amperage', NULL, 3, 'float')
,
('Configuration/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE061.Runtime'']/Equipment/Slot/Item[@key=''4'']/Supply/Item[@key=''anode'']/Voltage', NULL, 3, 'integer')
,
('Configuration/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE061.Runtime'']/Equipment/Slot/Item[@key=''5'']/Supply/Item[@key=''photocathode'']/Amperage', NULL, 3, 'float')
,
('Configuration/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE061.Runtime'']/Equipment/Slot/Item[@key=''5'']/Supply/Item[@key=''photocathode'']/Voltage', NULL, 3, 'integer')
,
('Configuration/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE061.Runtime'']/Equipment/Slot/Item[@key=''5'']/Supply/Item[@key=''microchannelplate1'']/Amperage', NULL, 3, 'float')
,
('Configuration/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE061.Runtime'']/Equipment/Slot/Item[@key=''5'']/Supply/Item[@key=''microchannelplate1'']/Voltage', NULL, 3, 'integer')
,
('Configuration/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE061.Runtime'']/Equipment/Slot/Item[@key=''5'']/Supply/Item[@key=''microchannelplate12'']/Amperage', NULL, 3, 'float')
,
('Configuration/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE061.Runtime'']/Equipment/Slot/Item[@key=''5'']/Supply/Item[@key=''microchannelplate12'']/Voltage', NULL, 3, 'integer')
,
('Configuration/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE061.Runtime'']/Equipment/Slot/Item[@key=''5'']/Supply/Item[@key=''microchannelplate2'']/Amperage', NULL, 3, 'float')
,
('Configuration/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE061.Runtime'']/Equipment/Slot/Item[@key=''5'']/Supply/Item[@key=''microchannelplate2'']/Voltage', NULL, 3, 'integer')
,
('Configuration/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE061.Runtime'']/Equipment/Slot/Item[@key=''5'']/Supply/Item[@key=''anode'']/Amperage', NULL, 3, 'float')
,
('Configuration/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE061.Runtime'']/Equipment/Slot/Item[@key=''5'']/Supply/Item[@key=''anode'']/Voltage', NULL, 3, 'integer')
,
('Configuration/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE061.Runtime'']/Equipment/Slot/Item[@key=''6'']/Supply/Item[@key=''photocathode'']/Amperage', NULL, 3, 'float')
,
('Configuration/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE061.Runtime'']/Equipment/Slot/Item[@key=''6'']/Supply/Item[@key=''photocathode'']/Voltage', NULL, 3, 'integer')
,
('Configuration/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE061.Runtime'']/Equipment/Slot/Item[@key=''6'']/Supply/Item[@key=''microchannelplate1'']/Amperage', NULL, 3, 'float')
,
('Configuration/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE061.Runtime'']/Equipment/Slot/Item[@key=''6'']/Supply/Item[@key=''microchannelplate1'']/Voltage', NULL, 3, 'integer')
,
('Configuration/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE061.Runtime'']/Equipment/Slot/Item[@key=''6'']/Supply/Item[@key=''microchannelplate12'']/Amperage', NULL, 3, 'float')
,
('Configuration/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE061.Runtime'']/Equipment/Slot/Item[@key=''6'']/Supply/Item[@key=''microchannelplate12'']/Voltage', NULL, 3, 'integer')
,
('Configuration/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE061.Runtime'']/Equipment/Slot/Item[@key=''6'']/Supply/Item[@key=''microchannelplate2'']/Amperage', NULL, 3, 'float')
,
('Configuration/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE061.Runtime'']/Equipment/Slot/Item[@key=''6'']/Supply/Item[@key=''microchannelplate2'']/Voltage', NULL, 3, 'integer')
,
('Configuration/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE061.Runtime'']/Equipment/Slot/Item[@key=''6'']/Supply/Item[@key=''anode'']/Amperage', NULL, 3, 'float')
,
('Configuration/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE061.Runtime'']/Equipment/Slot/Item[@key=''6'']/Supply/Item[@key=''anode'']/Voltage', NULL, 3, 'integer')
,
('Configuration/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE061.Runtime'']/Equipment/Slot/Item[@key=''7'']/Supply/Item[@key=''photocathode'']/Amperage', NULL, 3, 'float')
,
('Configuration/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE061.Runtime'']/Equipment/Slot/Item[@key=''7'']/Supply/Item[@key=''photocathode'']/Voltage', NULL, 3, 'integer')
,
('Configuration/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE061.Runtime'']/Equipment/Slot/Item[@key=''7'']/Supply/Item[@key=''microchannelplate1'']/Amperage', NULL, 3, 'float')
,
('Configuration/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE061.Runtime'']/Equipment/Slot/Item[@key=''7'']/Supply/Item[@key=''microchannelplate1'']/Voltage', NULL, 3, 'integer')
,
('Configuration/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE061.Runtime'']/Equipment/Slot/Item[@key=''7'']/Supply/Item[@key=''microchannelplate12'']/Amperage', NULL, 3, 'float')
,
('Configuration/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE061.Runtime'']/Equipment/Slot/Item[@key=''7'']/Supply/Item[@key=''microchannelplate12'']/Voltage', NULL, 3, 'integer')
,
('Configuration/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE061.Runtime'']/Equipment/Slot/Item[@key=''7'']/Supply/Item[@key=''microchannelplate2'']/Amperage', NULL, 3, 'float')
,
('Configuration/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE061.Runtime'']/Equipment/Slot/Item[@key=''7'']/Supply/Item[@key=''microchannelplate2'']/Voltage', NULL, 3, 'integer')
,
('Configuration/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE061.Runtime'']/Equipment/Slot/Item[@key=''7'']/Supply/Item[@key=''anode'']/Amperage', NULL, 3, 'float')
,
('Configuration/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE061.Runtime'']/Equipment/Slot/Item[@key=''7'']/Supply/Item[@key=''anode'']/Voltage', NULL, 3, 'integer')
,
('Configuration/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE061.Runtime'']/Equipment/Slot/Item[@key=''8'']/Supply/Item[@key=''photocathode'']/Amperage', NULL, 3, 'float')
,
('Configuration/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE061.Runtime'']/Equipment/Slot/Item[@key=''8'']/Supply/Item[@key=''photocathode'']/Voltage', NULL, 3, 'integer')
,
('Configuration/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE061.Runtime'']/Equipment/Slot/Item[@key=''8'']/Supply/Item[@key=''microchannelplate1'']/Amperage', NULL, 3, 'float')
,
('Configuration/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE061.Runtime'']/Equipment/Slot/Item[@key=''8'']/Supply/Item[@key=''microchannelplate1'']/Voltage', NULL, 3, 'integer')
,
('Configuration/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE061.Runtime'']/Equipment/Slot/Item[@key=''8'']/Supply/Item[@key=''microchannelplate12'']/Amperage', NULL, 3, 'float')
,
('Configuration/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE061.Runtime'']/Equipment/Slot/Item[@key=''8'']/Supply/Item[@key=''microchannelplate12'']/Voltage', NULL, 3, 'integer')
,
('Configuration/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE061.Runtime'']/Equipment/Slot/Item[@key=''8'']/Supply/Item[@key=''microchannelplate2'']/Amperage', NULL, 3, 'float')
,
('Configuration/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE061.Runtime'']/Equipment/Slot/Item[@key=''8'']/Supply/Item[@key=''microchannelplate2'']/Voltage', NULL, 3, 'integer')
,
('Configuration/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE061.Runtime'']/Equipment/Slot/Item[@key=''8'']/Supply/Item[@key=''anode'']/Amperage', NULL, 3, 'float')
,
('Configuration/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE061.Runtime'']/Equipment/Slot/Item[@key=''8'']/Supply/Item[@key=''anode'']/Voltage', NULL, 3, 'integer')
,
('Configuration/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE061.Runtime'']/Equipment/Slot/Item[@key=''9'']/Supply/Item[@key=''photocathode'']/Amperage', NULL, 3, 'float')
,
('Configuration/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE061.Runtime'']/Equipment/Slot/Item[@key=''9'']/Supply/Item[@key=''photocathode'']/Voltage', NULL, 3, 'integer')
,
('Configuration/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE061.Runtime'']/Equipment/Slot/Item[@key=''9'']/Supply/Item[@key=''microchannelplate1'']/Amperage', NULL, 3, 'float')
,
('Configuration/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE061.Runtime'']/Equipment/Slot/Item[@key=''9'']/Supply/Item[@key=''microchannelplate1'']/Voltage', NULL, 3, 'integer')
,
('Configuration/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE061.Runtime'']/Equipment/Slot/Item[@key=''9'']/Supply/Item[@key=''microchannelplate12'']/Amperage', NULL, 3, 'float')
,
('Configuration/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE061.Runtime'']/Equipment/Slot/Item[@key=''9'']/Supply/Item[@key=''microchannelplate12'']/Voltage', NULL, 3, 'integer')
,
('Configuration/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE061.Runtime'']/Equipment/Slot/Item[@key=''9'']/Supply/Item[@key=''microchannelplate2'']/Amperage', NULL, 3, 'float')
,
('Configuration/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE061.Runtime'']/Equipment/Slot/Item[@key=''9'']/Supply/Item[@key=''microchannelplate2'']/Voltage', NULL, 3, 'integer')
,
('Configuration/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE061.Runtime'']/Equipment/Slot/Item[@key=''9'']/Supply/Item[@key=''anode'']/Amperage', NULL, 3, 'float')
,
('Configuration/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE061.Runtime'']/Equipment/Slot/Item[@key=''9'']/Supply/Item[@key=''anode'']/Voltage', NULL, 3, 'integer')
,
('Configuration/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE061.Runtime'']/Equipment/Slot/Item[@key=''10'']/Supply/Item[@key=''photocathode'']/Amperage', NULL, 3, 'float')
,
('Configuration/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE061.Runtime'']/Equipment/Slot/Item[@key=''10'']/Supply/Item[@key=''photocathode'']/Voltage', NULL, 3, 'integer')
,
('Configuration/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE061.Runtime'']/Equipment/Slot/Item[@key=''10'']/Supply/Item[@key=''microchannelplate1'']/Amperage', NULL, 3, 'float')
,
('Configuration/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE061.Runtime'']/Equipment/Slot/Item[@key=''10'']/Supply/Item[@key=''microchannelplate1'']/Voltage', NULL, 3, 'integer')
,
('Configuration/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE061.Runtime'']/Equipment/Slot/Item[@key=''10'']/Supply/Item[@key=''microchannelplate12'']/Amperage', NULL, 3, 'float')
,
('Configuration/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE061.Runtime'']/Equipment/Slot/Item[@key=''10'']/Supply/Item[@key=''microchannelplate12'']/Voltage', NULL, 3, 'integer')
,
('Configuration/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE061.Runtime'']/Equipment/Slot/Item[@key=''10'']/Supply/Item[@key=''microchannelplate2'']/Amperage', NULL, 3, 'float')
,
('Configuration/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE061.Runtime'']/Equipment/Slot/Item[@key=''10'']/Supply/Item[@key=''microchannelplate2'']/Voltage', NULL, 3, 'integer')
,
('Configuration/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE061.Runtime'']/Equipment/Slot/Item[@key=''10'']/Supply/Item[@key=''anode'']/Amperage', NULL, 3, 'float')
,
('Configuration/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE061.Runtime'']/Equipment/Slot/Item[@key=''10'']/Supply/Item[@key=''anode'']/Voltage', NULL, 3, 'integer')
,
('Configuration/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE061.Runtime'']/Equipment/Slot/Item[@key=''11'']/Supply/Item[@key=''photocathode'']/Amperage', NULL, 3, 'float')
,
('Configuration/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE061.Runtime'']/Equipment/Slot/Item[@key=''11'']/Supply/Item[@key=''photocathode'']/Voltage', NULL, 3, 'integer')
,
('Configuration/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE061.Runtime'']/Equipment/Slot/Item[@key=''11'']/Supply/Item[@key=''microchannelplate1'']/Amperage', NULL, 3, 'float')
,
('Configuration/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE061.Runtime'']/Equipment/Slot/Item[@key=''11'']/Supply/Item[@key=''microchannelplate1'']/Voltage', NULL, 3, 'integer')
,
('Configuration/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE061.Runtime'']/Equipment/Slot/Item[@key=''11'']/Supply/Item[@key=''microchannelplate12'']/Amperage', NULL, 3, 'float')
,
('Configuration/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE061.Runtime'']/Equipment/Slot/Item[@key=''11'']/Supply/Item[@key=''microchannelplate12'']/Voltage', NULL, 3, 'integer')
,
('Configuration/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE061.Runtime'']/Equipment/Slot/Item[@key=''11'']/Supply/Item[@key=''microchannelplate2'']/Amperage', NULL, 3, 'float')
,
('Configuration/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE061.Runtime'']/Equipment/Slot/Item[@key=''11'']/Supply/Item[@key=''microchannelplate2'']/Voltage', NULL, 3, 'integer')
,
('Configuration/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE061.Runtime'']/Equipment/Slot/Item[@key=''11'']/Supply/Item[@key=''anode'']/Amperage', NULL, 3, 'float')
,
('Configuration/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE061.Runtime'']/Equipment/Slot/Item[@key=''11'']/Supply/Item[@key=''anode'']/Voltage', NULL, 3, 'integer')
,
('Configuration/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE061.Runtime'']/Equipment/Slot/Item[@key=''12'']/Supply/Item[@key=''photocathode'']/Amperage', NULL, 3, 'float')
,
('Configuration/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE061.Runtime'']/Equipment/Slot/Item[@key=''12'']/Supply/Item[@key=''photocathode'']/Voltage', NULL, 3, 'integer')
,
('Configuration/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE061.Runtime'']/Equipment/Slot/Item[@key=''12'']/Supply/Item[@key=''microchannelplate1'']/Amperage', NULL, 3, 'float')
,
('Configuration/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE061.Runtime'']/Equipment/Slot/Item[@key=''12'']/Supply/Item[@key=''microchannelplate1'']/Voltage', NULL, 3, 'integer')
,
('Configuration/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE061.Runtime'']/Equipment/Slot/Item[@key=''12'']/Supply/Item[@key=''microchannelplate12'']/Amperage', NULL, 3, 'float')
,
('Configuration/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE061.Runtime'']/Equipment/Slot/Item[@key=''12'']/Supply/Item[@key=''microchannelplate12'']/Voltage', NULL, 3, 'integer')
,
('Configuration/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE061.Runtime'']/Equipment/Slot/Item[@key=''12'']/Supply/Item[@key=''microchannelplate2'']/Amperage', NULL, 3, 'float')
,
('Configuration/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE061.Runtime'']/Equipment/Slot/Item[@key=''12'']/Supply/Item[@key=''microchannelplate2'']/Voltage', NULL, 3, 'integer')
,
('Configuration/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE061.Runtime'']/Equipment/Slot/Item[@key=''12'']/Supply/Item[@key=''anode'']/Amperage', NULL, 3, 'float')
,
('Configuration/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE061.Runtime'']/Equipment/Slot/Item[@key=''12'']/Supply/Item[@key=''anode'']/Voltage', NULL, 3, 'integer')
,
('Configuration/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE061.Runtime'']/Equipment/Slot/Item[@key=''13'']/Supply/Item[@key=''photocathode'']/Amperage', NULL, 3, 'float')
,
('Configuration/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE061.Runtime'']/Equipment/Slot/Item[@key=''13'']/Supply/Item[@key=''photocathode'']/Voltage', NULL, 3, 'integer')
,
('Configuration/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE061.Runtime'']/Equipment/Slot/Item[@key=''13'']/Supply/Item[@key=''microchannelplate1'']/Amperage', NULL, 3, 'float')
,
('Configuration/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE061.Runtime'']/Equipment/Slot/Item[@key=''13'']/Supply/Item[@key=''microchannelplate1'']/Voltage', NULL, 3, 'integer')
,
('Configuration/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE061.Runtime'']/Equipment/Slot/Item[@key=''13'']/Supply/Item[@key=''microchannelplate12'']/Amperage', NULL, 3, 'float')
,
('Configuration/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE061.Runtime'']/Equipment/Slot/Item[@key=''13'']/Supply/Item[@key=''microchannelplate12'']/Voltage', NULL, 3, 'integer')
,
('Configuration/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE061.Runtime'']/Equipment/Slot/Item[@key=''13'']/Supply/Item[@key=''microchannelplate2'']/Amperage', NULL, 3, 'float')
,
('Configuration/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE061.Runtime'']/Equipment/Slot/Item[@key=''13'']/Supply/Item[@key=''microchannelplate2'']/Voltage', NULL, 3, 'integer')
,
('Configuration/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE061.Runtime'']/Equipment/Slot/Item[@key=''13'']/Supply/Item[@key=''anode'']/Amperage', NULL, 3, 'float')
,
('Configuration/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE061.Runtime'']/Equipment/Slot/Item[@key=''13'']/Supply/Item[@key=''anode'']/Voltage', NULL, 3, 'integer')
,
('Configuration/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE061.Runtime'']/Equipment/Slot/Item[@key=''14'']/Supply/Item[@key=''photocathode'']/Amperage', NULL, 3, 'float')
,
('Configuration/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE061.Runtime'']/Equipment/Slot/Item[@key=''14'']/Supply/Item[@key=''photocathode'']/Voltage', NULL, 3, 'integer')
,
('Configuration/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE061.Runtime'']/Equipment/Slot/Item[@key=''14'']/Supply/Item[@key=''microchannelplate1'']/Amperage', NULL, 3, 'float')
,
('Configuration/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE061.Runtime'']/Equipment/Slot/Item[@key=''14'']/Supply/Item[@key=''microchannelplate1'']/Voltage', NULL, 3, 'integer')
,
('Configuration/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE061.Runtime'']/Equipment/Slot/Item[@key=''14'']/Supply/Item[@key=''microchannelplate12'']/Amperage', NULL, 3, 'float')
,
('Configuration/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE061.Runtime'']/Equipment/Slot/Item[@key=''14'']/Supply/Item[@key=''microchannelplate12'']/Voltage', NULL, 3, 'integer')
,
('Configuration/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE061.Runtime'']/Equipment/Slot/Item[@key=''14'']/Supply/Item[@key=''microchannelplate2'']/Amperage', NULL, 3, 'float')
,
('Configuration/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE061.Runtime'']/Equipment/Slot/Item[@key=''14'']/Supply/Item[@key=''microchannelplate2'']/Voltage', NULL, 3, 'integer')
,
('Configuration/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE061.Runtime'']/Equipment/Slot/Item[@key=''14'']/Supply/Item[@key=''anode'']/Amperage', NULL, 3, 'float')
,
('Configuration/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE061.Runtime'']/Equipment/Slot/Item[@key=''14'']/Supply/Item[@key=''anode'']/Voltage', NULL, 3, 'integer')
,
('Configuration/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE061.Runtime'']/Equipment/Slot/Item[@key=''15'']/Supply/Item[@key=''photocathode'']/Amperage', NULL, 3, 'float')
,
('Configuration/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE061.Runtime'']/Equipment/Slot/Item[@key=''15'']/Supply/Item[@key=''photocathode'']/Voltage', NULL, 3, 'integer')
,
('Configuration/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE061.Runtime'']/Equipment/Slot/Item[@key=''15'']/Supply/Item[@key=''microchannelplate1'']/Amperage', NULL, 3, 'float')
,
('Configuration/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE061.Runtime'']/Equipment/Slot/Item[@key=''15'']/Supply/Item[@key=''microchannelplate1'']/Voltage', NULL, 3, 'integer')
,
('Configuration/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE061.Runtime'']/Equipment/Slot/Item[@key=''15'']/Supply/Item[@key=''microchannelplate12'']/Amperage', NULL, 3, 'float')
,
('Configuration/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE061.Runtime'']/Equipment/Slot/Item[@key=''15'']/Supply/Item[@key=''microchannelplate12'']/Voltage', NULL, 3, 'integer')
,
('Configuration/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE061.Runtime'']/Equipment/Slot/Item[@key=''15'']/Supply/Item[@key=''microchannelplate2'']/Amperage', NULL, 3, 'float')
,
('Configuration/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE061.Runtime'']/Equipment/Slot/Item[@key=''15'']/Supply/Item[@key=''microchannelplate2'']/Voltage', NULL, 3, 'integer')
,
('Configuration/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE061.Runtime'']/Equipment/Slot/Item[@key=''15'']/Supply/Item[@key=''anode'']/Amperage', NULL, 3, 'float')
,
('Configuration/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE061.Runtime'']/Equipment/Slot/Item[@key=''15'']/Supply/Item[@key=''anode'']/Voltage', NULL, 3, 'integer')
,
('Configuration/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE061.Runtime'']/Equipment/Slot/Item[@key=''16'']/Supply/Item[@key=''photocathode'']/Amperage', NULL, 3, 'float')
,
('Configuration/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE061.Runtime'']/Equipment/Slot/Item[@key=''16'']/Supply/Item[@key=''photocathode'']/Voltage', NULL, 3, 'integer')
,
('Configuration/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE061.Runtime'']/Equipment/Slot/Item[@key=''16'']/Supply/Item[@key=''microchannelplate1'']/Amperage', NULL, 3, 'float')
,
('Configuration/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE061.Runtime'']/Equipment/Slot/Item[@key=''16'']/Supply/Item[@key=''microchannelplate1'']/Voltage', NULL, 3, 'integer')
,
('Configuration/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE061.Runtime'']/Equipment/Slot/Item[@key=''16'']/Supply/Item[@key=''microchannelplate12'']/Amperage', NULL, 3, 'float')
,
('Configuration/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE061.Runtime'']/Equipment/Slot/Item[@key=''16'']/Supply/Item[@key=''microchannelplate12'']/Voltage', NULL, 3, 'integer')
,
('Configuration/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE061.Runtime'']/Equipment/Slot/Item[@key=''16'']/Supply/Item[@key=''microchannelplate2'']/Amperage', NULL, 3, 'float')
,
('Configuration/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE061.Runtime'']/Equipment/Slot/Item[@key=''16'']/Supply/Item[@key=''microchannelplate2'']/Voltage', NULL, 3, 'integer')
,
('Configuration/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE061.Runtime'']/Equipment/Slot/Item[@key=''16'']/Supply/Item[@key=''anode'']/Amperage', NULL, 3, 'float')
,
('Configuration/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE061.Runtime'']/Equipment/Slot/Item[@key=''16'']/Supply/Item[@key=''anode'']/Voltage', NULL, 3, 'integer')
,
('Configuration/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE061.Runtime'']/Equipment/Slot/Item[@key=''17'']/Supply/Item[@key=''photocathode'']/Amperage', NULL, 3, 'float')
,
('Configuration/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE061.Runtime'']/Equipment/Slot/Item[@key=''17'']/Supply/Item[@key=''photocathode'']/Voltage', NULL, 3, 'integer')
,
('Configuration/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE061.Runtime'']/Equipment/Slot/Item[@key=''17'']/Supply/Item[@key=''microchannelplate1'']/Amperage', NULL, 3, 'float')
,
('Configuration/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE061.Runtime'']/Equipment/Slot/Item[@key=''17'']/Supply/Item[@key=''microchannelplate1'']/Voltage', NULL, 3, 'integer')
,
('Configuration/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE061.Runtime'']/Equipment/Slot/Item[@key=''17'']/Supply/Item[@key=''microchannelplate12'']/Amperage', NULL, 3, 'float')
,
('Configuration/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE061.Runtime'']/Equipment/Slot/Item[@key=''17'']/Supply/Item[@key=''microchannelplate12'']/Voltage', NULL, 3, 'integer')
,
('Configuration/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE061.Runtime'']/Equipment/Slot/Item[@key=''17'']/Supply/Item[@key=''microchannelplate2'']/Amperage', NULL, 3, 'float')
,
('Configuration/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE061.Runtime'']/Equipment/Slot/Item[@key=''17'']/Supply/Item[@key=''microchannelplate2'']/Voltage', NULL, 3, 'integer')
,
('Configuration/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE061.Runtime'']/Equipment/Slot/Item[@key=''17'']/Supply/Item[@key=''anode'']/Amperage', NULL, 3, 'float')
,
('Configuration/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE061.Runtime'']/Equipment/Slot/Item[@key=''17'']/Supply/Item[@key=''anode'']/Voltage', NULL, 3, 'integer')
,
('Configuration/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE061.Runtime'']/Equipment/Slot/Item[@key=''18'']/Supply/Item[@key=''photocathode'']/Amperage', NULL, 3, 'float')
,
('Configuration/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE061.Runtime'']/Equipment/Slot/Item[@key=''18'']/Supply/Item[@key=''photocathode'']/Voltage', NULL, 3, 'integer')
,
('Configuration/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE061.Runtime'']/Equipment/Slot/Item[@key=''18'']/Supply/Item[@key=''microchannelplate1'']/Amperage', NULL, 3, 'float')
,
('Configuration/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE061.Runtime'']/Equipment/Slot/Item[@key=''18'']/Supply/Item[@key=''microchannelplate1'']/Voltage', NULL, 3, 'integer')
,
('Configuration/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE061.Runtime'']/Equipment/Slot/Item[@key=''18'']/Supply/Item[@key=''microchannelplate12'']/Amperage', NULL, 3, 'float')
,
('Configuration/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE061.Runtime'']/Equipment/Slot/Item[@key=''18'']/Supply/Item[@key=''microchannelplate12'']/Voltage', NULL, 3, 'integer')
,
('Configuration/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE061.Runtime'']/Equipment/Slot/Item[@key=''18'']/Supply/Item[@key=''microchannelplate2'']/Amperage', NULL, 3, 'float')
,
('Configuration/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE061.Runtime'']/Equipment/Slot/Item[@key=''18'']/Supply/Item[@key=''microchannelplate2'']/Voltage', NULL, 3, 'integer')
,
('Configuration/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE061.Runtime'']/Equipment/Slot/Item[@key=''18'']/Supply/Item[@key=''anode'']/Amperage', NULL, 3, 'float')
,
('Configuration/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE061.Runtime'']/Equipment/Slot/Item[@key=''18'']/Supply/Item[@key=''anode'']/Voltage', NULL, 3, 'integer')
,
('Configuration/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE061.Runtime'']/Equipment/Slot/Item[@key=''19'']/Supply/Item[@key=''photocathode'']/Amperage', NULL, 3, 'float')
,
('Configuration/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE061.Runtime'']/Equipment/Slot/Item[@key=''19'']/Supply/Item[@key=''photocathode'']/Voltage', NULL, 3, 'integer')
,
('Configuration/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE061.Runtime'']/Equipment/Slot/Item[@key=''19'']/Supply/Item[@key=''microchannelplate1'']/Amperage', NULL, 3, 'float')
,
('Configuration/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE061.Runtime'']/Equipment/Slot/Item[@key=''19'']/Supply/Item[@key=''microchannelplate1'']/Voltage', NULL, 3, 'integer')
,
('Configuration/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE061.Runtime'']/Equipment/Slot/Item[@key=''19'']/Supply/Item[@key=''microchannelplate12'']/Amperage', NULL, 3, 'float')
,
('Configuration/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE061.Runtime'']/Equipment/Slot/Item[@key=''19'']/Supply/Item[@key=''microchannelplate12'']/Voltage', NULL, 3, 'integer')
,
('Configuration/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE061.Runtime'']/Equipment/Slot/Item[@key=''19'']/Supply/Item[@key=''microchannelplate2'']/Amperage', NULL, 3, 'float')
,
('Configuration/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE061.Runtime'']/Equipment/Slot/Item[@key=''19'']/Supply/Item[@key=''microchannelplate2'']/Voltage', NULL, 3, 'integer')
,
('Configuration/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE061.Runtime'']/Equipment/Slot/Item[@key=''19'']/Supply/Item[@key=''anode'']/Amperage', NULL, 3, 'float')
,
('Configuration/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE061.Runtime'']/Equipment/Slot/Item[@key=''19'']/Supply/Item[@key=''anode'']/Voltage', NULL, 3, 'integer')
,
('Configuration/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE061.Runtime'']/Equipment/Slot/Item[@key=''20'']/Supply/Item[@key=''photocathode'']/Amperage', NULL, 3, 'float')
,
('Configuration/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE061.Runtime'']/Equipment/Slot/Item[@key=''20'']/Supply/Item[@key=''photocathode'']/Voltage', NULL, 3, 'integer')
,
('Configuration/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE061.Runtime'']/Equipment/Slot/Item[@key=''20'']/Supply/Item[@key=''microchannelplate1'']/Amperage', NULL, 3, 'float')
,
('Configuration/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE061.Runtime'']/Equipment/Slot/Item[@key=''20'']/Supply/Item[@key=''microchannelplate1'']/Voltage', NULL, 3, 'integer')
,
('Configuration/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE061.Runtime'']/Equipment/Slot/Item[@key=''20'']/Supply/Item[@key=''microchannelplate12'']/Amperage', NULL, 3, 'float')
,
('Configuration/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE061.Runtime'']/Equipment/Slot/Item[@key=''20'']/Supply/Item[@key=''microchannelplate12'']/Voltage', NULL, 3, 'integer')
,
('Configuration/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE061.Runtime'']/Equipment/Slot/Item[@key=''20'']/Supply/Item[@key=''microchannelplate2'']/Amperage', NULL, 3, 'float')
,
('Configuration/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE061.Runtime'']/Equipment/Slot/Item[@key=''20'']/Supply/Item[@key=''microchannelplate2'']/Voltage', NULL, 3, 'integer')
,
('Configuration/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE061.Runtime'']/Equipment/Slot/Item[@key=''20'']/Supply/Item[@key=''anode'']/Amperage', NULL, 3, 'float')
,
('Configuration/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE061.Runtime'']/Equipment/Slot/Item[@key=''20'']/Supply/Item[@key=''anode'']/Voltage', NULL, 3, 'integer')
,
('Configuration/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE061.Runtime'']/Equipment/Slot/Item[@key=''21'']/Supply/Item[@key=''photocathode'']/Amperage', NULL, 3, 'float')
,
('Configuration/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE061.Runtime'']/Equipment/Slot/Item[@key=''21'']/Supply/Item[@key=''photocathode'']/Voltage', NULL, 3, 'integer')
,
('Configuration/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE061.Runtime'']/Equipment/Slot/Item[@key=''21'']/Supply/Item[@key=''microchannelplate1'']/Amperage', NULL, 3, 'float')
,
('Configuration/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE061.Runtime'']/Equipment/Slot/Item[@key=''21'']/Supply/Item[@key=''microchannelplate1'']/Voltage', NULL, 3, 'integer')
,
('Configuration/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE061.Runtime'']/Equipment/Slot/Item[@key=''21'']/Supply/Item[@key=''microchannelplate12'']/Amperage', NULL, 3, 'float')
,
('Configuration/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE061.Runtime'']/Equipment/Slot/Item[@key=''21'']/Supply/Item[@key=''microchannelplate12'']/Voltage', NULL, 3, 'integer')
,
('Configuration/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE061.Runtime'']/Equipment/Slot/Item[@key=''21'']/Supply/Item[@key=''microchannelplate2'']/Amperage', NULL, 3, 'float')
,
('Configuration/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE061.Runtime'']/Equipment/Slot/Item[@key=''21'']/Supply/Item[@key=''microchannelplate2'']/Voltage', NULL, 3, 'integer')
,
('Configuration/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE061.Runtime'']/Equipment/Slot/Item[@key=''21'']/Supply/Item[@key=''anode'']/Amperage', NULL, 3, 'float')
,
('Configuration/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE061.Runtime'']/Equipment/Slot/Item[@key=''21'']/Supply/Item[@key=''anode'']/Voltage', NULL, 3, 'integer')
,
('Configuration/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE061.Runtime'']/Equipment/Slot/Item[@key=''22'']/Supply/Item[@key=''photocathode'']/Amperage', NULL, 3, 'float')
,
('Configuration/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE061.Runtime'']/Equipment/Slot/Item[@key=''22'']/Supply/Item[@key=''photocathode'']/Voltage', NULL, 3, 'integer')
,
('Configuration/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE061.Runtime'']/Equipment/Slot/Item[@key=''22'']/Supply/Item[@key=''microchannelplate1'']/Amperage', NULL, 3, 'float')
,
('Configuration/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE061.Runtime'']/Equipment/Slot/Item[@key=''22'']/Supply/Item[@key=''microchannelplate1'']/Voltage', NULL, 3, 'integer')
,
('Configuration/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE061.Runtime'']/Equipment/Slot/Item[@key=''22'']/Supply/Item[@key=''microchannelplate12'']/Amperage', NULL, 3, 'float')
,
('Configuration/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE061.Runtime'']/Equipment/Slot/Item[@key=''22'']/Supply/Item[@key=''microchannelplate12'']/Voltage', NULL, 3, 'integer')
,
('Configuration/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE061.Runtime'']/Equipment/Slot/Item[@key=''22'']/Supply/Item[@key=''microchannelplate2'']/Amperage', NULL, 3, 'float')
,
('Configuration/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE061.Runtime'']/Equipment/Slot/Item[@key=''22'']/Supply/Item[@key=''microchannelplate2'']/Voltage', NULL, 3, 'integer')
,
('Configuration/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE061.Runtime'']/Equipment/Slot/Item[@key=''22'']/Supply/Item[@key=''anode'']/Amperage', NULL, 3, 'float')
,
('Configuration/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE061.Runtime'']/Equipment/Slot/Item[@key=''22'']/Supply/Item[@key=''anode'']/Voltage', NULL, 3, 'integer')
,
('Configuration/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE061.Runtime'']/Equipment/Slot/Item[@key=''23'']/Supply/Item[@key=''photocathode'']/Amperage', NULL, 3, 'float')
,
('Configuration/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE061.Runtime'']/Equipment/Slot/Item[@key=''23'']/Supply/Item[@key=''photocathode'']/Voltage', NULL, 3, 'integer')
,
('Configuration/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE061.Runtime'']/Equipment/Slot/Item[@key=''23'']/Supply/Item[@key=''microchannelplate1'']/Amperage', NULL, 3, 'float')
,
('Configuration/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE061.Runtime'']/Equipment/Slot/Item[@key=''23'']/Supply/Item[@key=''microchannelplate1'']/Voltage', NULL, 3, 'integer')
,
('Configuration/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE061.Runtime'']/Equipment/Slot/Item[@key=''23'']/Supply/Item[@key=''microchannelplate12'']/Amperage', NULL, 3, 'float')
,
('Configuration/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE061.Runtime'']/Equipment/Slot/Item[@key=''23'']/Supply/Item[@key=''microchannelplate12'']/Voltage', NULL, 3, 'integer')
,
('Configuration/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE061.Runtime'']/Equipment/Slot/Item[@key=''23'']/Supply/Item[@key=''microchannelplate2'']/Amperage', NULL, 3, 'float')
,
('Configuration/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE061.Runtime'']/Equipment/Slot/Item[@key=''23'']/Supply/Item[@key=''microchannelplate2'']/Voltage', NULL, 3, 'integer')
,
('Configuration/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE061.Runtime'']/Equipment/Slot/Item[@key=''23'']/Supply/Item[@key=''anode'']/Amperage', NULL, 3, 'float')
,
('Configuration/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE061.Runtime'']/Equipment/Slot/Item[@key=''23'']/Supply/Item[@key=''anode'']/Voltage', NULL, 3, 'integer')
,
('Configuration/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE061.Runtime'']/Equipment/Slot/Item[@key=''24'']/Supply/Item[@key=''photocathode'']/Amperage', NULL, 3, 'float')
,
('Configuration/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE061.Runtime'']/Equipment/Slot/Item[@key=''24'']/Supply/Item[@key=''photocathode'']/Voltage', NULL, 3, 'integer')
,
('Configuration/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE061.Runtime'']/Equipment/Slot/Item[@key=''24'']/Supply/Item[@key=''microchannelplate1'']/Amperage', NULL, 3, 'float')
,
('Configuration/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE061.Runtime'']/Equipment/Slot/Item[@key=''24'']/Supply/Item[@key=''microchannelplate1'']/Voltage', NULL, 3, 'integer')
,
('Configuration/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE061.Runtime'']/Equipment/Slot/Item[@key=''24'']/Supply/Item[@key=''microchannelplate12'']/Amperage', NULL, 3, 'float')
,
('Configuration/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE061.Runtime'']/Equipment/Slot/Item[@key=''24'']/Supply/Item[@key=''microchannelplate12'']/Voltage', NULL, 3, 'integer')
,
('Configuration/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE061.Runtime'']/Equipment/Slot/Item[@key=''24'']/Supply/Item[@key=''microchannelplate2'']/Amperage', NULL, 3, 'float')
,
('Configuration/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE061.Runtime'']/Equipment/Slot/Item[@key=''24'']/Supply/Item[@key=''microchannelplate2'']/Voltage', NULL, 3, 'integer')
,
('Configuration/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE061.Runtime'']/Equipment/Slot/Item[@key=''24'']/Supply/Item[@key=''anode'']/Amperage', NULL, 3, 'float')
,
('Configuration/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE061.Runtime'']/Equipment/Slot/Item[@key=''24'']/Supply/Item[@key=''anode'']/Voltage', NULL, 3, 'integer')
,
('Configuration/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE061.Runtime'']/Equipment/Slot/Item[@key=''25'']/Supply/Item[@key=''photocathode'']/Amperage', NULL, 3, 'float')
,
('Configuration/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE061.Runtime'']/Equipment/Slot/Item[@key=''25'']/Supply/Item[@key=''photocathode'']/Voltage', NULL, 3, 'integer')
,
('Configuration/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE061.Runtime'']/Equipment/Slot/Item[@key=''25'']/Supply/Item[@key=''microchannelplate1'']/Amperage', NULL, 3, 'float')
,
('Configuration/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE061.Runtime'']/Equipment/Slot/Item[@key=''25'']/Supply/Item[@key=''microchannelplate1'']/Voltage', NULL, 3, 'integer')
,
('Configuration/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE061.Runtime'']/Equipment/Slot/Item[@key=''25'']/Supply/Item[@key=''microchannelplate12'']/Amperage', NULL, 3, 'float')
,
('Configuration/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE061.Runtime'']/Equipment/Slot/Item[@key=''25'']/Supply/Item[@key=''microchannelplate12'']/Voltage', NULL, 3, 'integer')
,
('Configuration/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE061.Runtime'']/Equipment/Slot/Item[@key=''25'']/Supply/Item[@key=''microchannelplate2'']/Amperage', NULL, 3, 'float')
,
('Configuration/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE061.Runtime'']/Equipment/Slot/Item[@key=''25'']/Supply/Item[@key=''microchannelplate2'']/Voltage', NULL, 3, 'integer')
,
('Configuration/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE061.Runtime'']/Equipment/Slot/Item[@key=''25'']/Supply/Item[@key=''anode'']/Amperage', NULL, 3, 'float')
,
('Configuration/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE061.Runtime'']/Equipment/Slot/Item[@key=''25'']/Supply/Item[@key=''anode'']/Voltage', NULL, 3, 'integer')
,
('Configuration/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE061.Runtime'']/Equipment/Slot/Item[@key=''26'']/Supply/Item[@key=''photocathode'']/Amperage', NULL, 3, 'float')
,
('Configuration/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE061.Runtime'']/Equipment/Slot/Item[@key=''26'']/Supply/Item[@key=''photocathode'']/Voltage', NULL, 3, 'integer')
,
('Configuration/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE061.Runtime'']/Equipment/Slot/Item[@key=''26'']/Supply/Item[@key=''microchannelplate1'']/Amperage', NULL, 3, 'float')
,
('Configuration/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE061.Runtime'']/Equipment/Slot/Item[@key=''26'']/Supply/Item[@key=''microchannelplate1'']/Voltage', NULL, 3, 'integer')
,
('Configuration/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE061.Runtime'']/Equipment/Slot/Item[@key=''26'']/Supply/Item[@key=''microchannelplate12'']/Amperage', NULL, 3, 'float')
,
('Configuration/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE061.Runtime'']/Equipment/Slot/Item[@key=''26'']/Supply/Item[@key=''microchannelplate12'']/Voltage', NULL, 3, 'integer')
,
('Configuration/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE061.Runtime'']/Equipment/Slot/Item[@key=''26'']/Supply/Item[@key=''microchannelplate2'']/Amperage', NULL, 3, 'float')
,
('Configuration/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE061.Runtime'']/Equipment/Slot/Item[@key=''26'']/Supply/Item[@key=''microchannelplate2'']/Voltage', NULL, 3, 'integer')
,
('Configuration/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE061.Runtime'']/Equipment/Slot/Item[@key=''26'']/Supply/Item[@key=''anode'']/Amperage', NULL, 3, 'float')
,
('Configuration/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE061.Runtime'']/Equipment/Slot/Item[@key=''26'']/Supply/Item[@key=''anode'']/Voltage', NULL, 3, 'integer')
,
('Configuration/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE061.Runtime'']/Equipment/Slot/Item[@key=''27'']/Supply/Item[@key=''photocathode'']/Amperage', NULL, 3, 'float')
,
('Configuration/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE061.Runtime'']/Equipment/Slot/Item[@key=''27'']/Supply/Item[@key=''photocathode'']/Voltage', NULL, 3, 'integer')
,
('Configuration/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE061.Runtime'']/Equipment/Slot/Item[@key=''27'']/Supply/Item[@key=''microchannelplate1'']/Amperage', NULL, 3, 'float')
,
('Configuration/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE061.Runtime'']/Equipment/Slot/Item[@key=''27'']/Supply/Item[@key=''microchannelplate1'']/Voltage', NULL, 3, 'integer')
,
('Configuration/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE061.Runtime'']/Equipment/Slot/Item[@key=''27'']/Supply/Item[@key=''microchannelplate12'']/Amperage', NULL, 3, 'float')
,
('Configuration/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE061.Runtime'']/Equipment/Slot/Item[@key=''27'']/Supply/Item[@key=''microchannelplate12'']/Voltage', NULL, 3, 'integer')
,
('Configuration/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE061.Runtime'']/Equipment/Slot/Item[@key=''27'']/Supply/Item[@key=''microchannelplate2'']/Amperage', NULL, 3, 'float')
,
('Configuration/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE061.Runtime'']/Equipment/Slot/Item[@key=''27'']/Supply/Item[@key=''microchannelplate2'']/Voltage', NULL, 3, 'integer')
,
('Configuration/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE061.Runtime'']/Equipment/Slot/Item[@key=''27'']/Supply/Item[@key=''anode'']/Amperage', NULL, 3, 'float')
,
('Configuration/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE061.Runtime'']/Equipment/Slot/Item[@key=''27'']/Supply/Item[@key=''anode'']/Voltage', NULL, 3, 'integer')
,
('Configuration/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE061.Runtime'']/Equipment/Slot/Item[@key=''28'']/Supply/Item[@key=''photocathode'']/Amperage', NULL, 3, 'float')
,
('Configuration/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE061.Runtime'']/Equipment/Slot/Item[@key=''28'']/Supply/Item[@key=''photocathode'']/Voltage', NULL, 3, 'integer')
,
('Configuration/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE061.Runtime'']/Equipment/Slot/Item[@key=''28'']/Supply/Item[@key=''microchannelplate1'']/Amperage', NULL, 3, 'float')
,
('Configuration/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE061.Runtime'']/Equipment/Slot/Item[@key=''28'']/Supply/Item[@key=''microchannelplate1'']/Voltage', NULL, 3, 'integer')
,
('Configuration/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE061.Runtime'']/Equipment/Slot/Item[@key=''28'']/Supply/Item[@key=''microchannelplate12'']/Amperage', NULL, 3, 'float')
,
('Configuration/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE061.Runtime'']/Equipment/Slot/Item[@key=''28'']/Supply/Item[@key=''microchannelplate12'']/Voltage', NULL, 3, 'integer')
,
('Configuration/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE061.Runtime'']/Equipment/Slot/Item[@key=''28'']/Supply/Item[@key=''microchannelplate2'']/Amperage', NULL, 3, 'float')
,
('Configuration/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE061.Runtime'']/Equipment/Slot/Item[@key=''28'']/Supply/Item[@key=''microchannelplate2'']/Voltage', NULL, 3, 'integer')
,
('Configuration/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE061.Runtime'']/Equipment/Slot/Item[@key=''28'']/Supply/Item[@key=''anode'']/Amperage', NULL, 3, 'float')
,
('Configuration/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE061.Runtime'']/Equipment/Slot/Item[@key=''28'']/Supply/Item[@key=''anode'']/Voltage', NULL, 3, 'integer')
,
('Configuration/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE061.Runtime'']/Equipment/Slot/Item[@key=''29'']/Supply/Item[@key=''photocathode'']/Amperage', NULL, 3, 'float')
,
('Configuration/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE061.Runtime'']/Equipment/Slot/Item[@key=''29'']/Supply/Item[@key=''photocathode'']/Voltage', NULL, 3, 'integer')
,
('Configuration/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE061.Runtime'']/Equipment/Slot/Item[@key=''29'']/Supply/Item[@key=''microchannelplate1'']/Amperage', NULL, 3, 'float')
,
('Configuration/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE061.Runtime'']/Equipment/Slot/Item[@key=''29'']/Supply/Item[@key=''microchannelplate1'']/Voltage', NULL, 3, 'integer')
,
('Configuration/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE061.Runtime'']/Equipment/Slot/Item[@key=''29'']/Supply/Item[@key=''microchannelplate12'']/Amperage', NULL, 3, 'float')
,
('Configuration/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE061.Runtime'']/Equipment/Slot/Item[@key=''29'']/Supply/Item[@key=''microchannelplate12'']/Voltage', NULL, 3, 'integer')
,
('Configuration/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE061.Runtime'']/Equipment/Slot/Item[@key=''29'']/Supply/Item[@key=''microchannelplate2'']/Amperage', NULL, 3, 'float')
,
('Configuration/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE061.Runtime'']/Equipment/Slot/Item[@key=''29'']/Supply/Item[@key=''microchannelplate2'']/Voltage', NULL, 3, 'integer')
,
('Configuration/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE061.Runtime'']/Equipment/Slot/Item[@key=''29'']/Supply/Item[@key=''anode'']/Amperage', NULL, 3, 'float')
,
('Configuration/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE061.Runtime'']/Equipment/Slot/Item[@key=''29'']/Supply/Item[@key=''anode'']/Voltage', NULL, 3, 'integer')
,
('Configuration/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE061.Runtime'']/Equipment/Slot/Item[@key=''30'']/Supply/Item[@key=''photocathode'']/Amperage', NULL, 3, 'float')
,
('Configuration/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE061.Runtime'']/Equipment/Slot/Item[@key=''30'']/Supply/Item[@key=''photocathode'']/Voltage', NULL, 3, 'integer')
,
('Configuration/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE061.Runtime'']/Equipment/Slot/Item[@key=''30'']/Supply/Item[@key=''microchannelplate1'']/Amperage', NULL, 3, 'float')
,
('Configuration/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE061.Runtime'']/Equipment/Slot/Item[@key=''30'']/Supply/Item[@key=''microchannelplate1'']/Voltage', NULL, 3, 'integer')
,
('Configuration/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE061.Runtime'']/Equipment/Slot/Item[@key=''30'']/Supply/Item[@key=''microchannelplate12'']/Amperage', NULL, 3, 'float')
,
('Configuration/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE061.Runtime'']/Equipment/Slot/Item[@key=''30'']/Supply/Item[@key=''microchannelplate12'']/Voltage', NULL, 3, 'integer')
,
('Configuration/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE061.Runtime'']/Equipment/Slot/Item[@key=''30'']/Supply/Item[@key=''microchannelplate2'']/Amperage', NULL, 3, 'float')
,
('Configuration/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE061.Runtime'']/Equipment/Slot/Item[@key=''30'']/Supply/Item[@key=''microchannelplate2'']/Voltage', NULL, 3, 'integer')
,
('Configuration/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE061.Runtime'']/Equipment/Slot/Item[@key=''30'']/Supply/Item[@key=''anode'']/Amperage', NULL, 3, 'float')
,
('Configuration/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE061.Runtime'']/Equipment/Slot/Item[@key=''30'']/Supply/Item[@key=''anode'']/Voltage', NULL, 3, 'integer')
;
-----------------------------------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION _communication(xpath VARCHAR, value anyelement) 
RETURNS VOID AS $$

--Сбор информации с оборудования в БД

--Использование функции:
--SELECT * FROM _communication(XPath,Value);

DECLARE 

	--переменные для:
	_TableName TEXT;		--значения 4-го поля таблицы glossary, формирующего _Table и _HyperTable    
	_Table TEXT;  			--имени актуальной таблицы  
	_HyperTable TEXT;		--имени соответствующей гипертаблицы
	_Allowance FLOAT;		--допуска, значения 3-его поле таблицы glossary
	_ValueOld FLOAT;		--последнего значения 3-го поля val из актуальной таблицы
	_Count INTEGER;			--числа строк в гипертаблице
	_Delta FLOAT;			--получения разницы в % между старым и новым значениями val актуальной таблицы  
	_Key INTEGER;			--значения ключа таблицы glossary  
	
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
	IF (SELECT EXISTS(SELECT 1 from glossary WHERE configuration = xpath)) THEN
		_Allowance := (SELECT allowance FROM glossary WHERE configuration = xpath);
	ELSE	
		_Allowance := NULL;
	END IF;  
	
	--Получение последнего значения value из актуальной таблицы
	EXECUTE FORMAT('SELECT value FROM %I ORDER BY key DESC LIMIT 1', _Table) INTO _ValueOld;
	
	--Получение разницы в % между старым и новым значениями
	_Delta := ABS(_ValueOld - value) * 100 / _ValueOld;
				
	--Число строк в гипертаблице
	EXECUTE FORMAT('SELECT COUNT(*) FROM %I', _HyperTable) INTO _Count;
	
	--Если в допуске
	IF(_Delta <= _Allowance) THEN
		--Если число записей в гипертаблице не превышает 2
		IF(_Count < 2) THEN
			EXECUTE FORMAT('INSERT INTO %I(key, fix, value) VALUES(%s, NOW(), %s);', _Table, _Key, value);
		ELSE
			EXECUTE FORMAT('UPDATE %I SET fix = NOW() WHERE key = (SELECT MAX(key) from %I);', _Table, _Table);
		END IF;
	ELSE
		EXECUTE FORMAT('INSERT INTO %I(key, fix, value) VALUES(%s, NOW(), %s);', _Table, _Key, value);
	END IF;
	
END;

$$ LANGUAGE plpgsql;
-----------------------------------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION _refresh(xpath VARCHAR)
RETURNS RECORD AS $$

--Обновление активной информации в ПО из БД, возврат одной записи из актуальной таблицы

--Использование функции:
--SELECT * FROM _refresh(XPath) AS (rkey INTEGER, rfix TIMESTAMPTZ, rvalue FLOAT); - возврат записи из float_actual
--SELECT * FROM _refresh(XPath) AS (rkey INTEGER, rfix TIMESTAMPTZ, rvalue INTEGER); - возврат записи из integer_actual

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

	--Получение одной записи из актуальной таблицы
	IF (_Table IS NOT NULL) THEN
		EXECUTE FORMAT('SELECT * FROM %I WHERE %I.key = %s;', _Table, _Table, _Key) INTO ret;
	END IF;  
	
	--Возврат записи
	RETURN ret;
	
END;

$$ LANGUAGE plpgsql;
-----------------------------------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION _refresh()
RETURNS TABLE (rconfig TEXT, rfix TIMESTAMPTZ, value_float FLOAT, value_integer INTEGER) AS $$

--Обновление активной информации в ПО из БД, возврат записей из всех активных таблиц

--Использование функции:
--SELECT * FROM _refresh();

DECLARE 
	
BEGIN
	
	RETURN QUERY EXECUTE FORMAT('
	SELECT g.configuration AS config, float_actual.fix AS fix, float_actual.value AS float_value, NULL AS integer_value
	FROM glossary AS g
	INNER JOIN float_actual ON g.key = float_actual.key 
	UNION
	SELECT g.configuration AS config, integer_actual.fix AS fix, NULL AS float_value, integer_actual.value AS integer_value
	FROM glossary AS g
	INNER JOIN integer_actual ON g.key = integer_actual.key;
	');			
	
END;

$$ LANGUAGE plpgsql;
-----------------------------------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION _refreshold(xpath VARCHAR, st TIMESTAMP, fin TIMESTAMP)
RETURNS TABLE (rkey INTEGER, rfix TIMESTAMPTZ, rvalue FLOAT) AS $$

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
	
	--возврат записей из гипертаблицы от st до fin
	RETURN QUERY EXECUTE FORMAT('
	SELECT *
	FROM %I 
	WHERE %I.fix BETWEEN ''%s'' AND ''%s'';
	', 
	_HyperTable,
	_HyperTable, st, fin);

END;

$$ LANGUAGE plpgsql;
-----------------------------------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION _refreshold(st TIMESTAMP, fin TIMESTAMP)
RETURNS TABLE (rkey INTEGER, rconfig TEXT, fix TIMESTAMPTZ, value_float FLOAT, value_integer INTEGER) AS $$

--Обновление архивной информации в ПО из БД, возврат записей из всех гипертаблиц от st до fin

DECLARE 
		
BEGIN

	--возврат записей из гипертаблицы от st до fin
	RETURN QUERY EXECUTE FORMAT('
	SELECT g.key AS key, g.configuration AS config, float_archive.fix AS fix, float_archive.value AS float_value, NULL AS integer_value
	FROM glossary AS g
	INNER JOIN float_archive ON g.key = float_archive.key 
	WHERE fix BETWEEN ''%s'' AND ''%s''
	UNION
	SELECT g.key AS key, configuration AS config, integer_archive.fix AS fix, NULL AS float_value, integer_archive.value AS integer_value
	FROM glossary AS g
	INNER JOIN integer_archive ON g.key = integer_archive.key 
	WHERE fix BETWEEN ''%s'' AND ''%s''
	ORDER BY key;
	', st, fin, st, fin);
	
END;

$$ LANGUAGE plpgsql;
	