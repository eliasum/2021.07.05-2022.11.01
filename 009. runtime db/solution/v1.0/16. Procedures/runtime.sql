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
	_Table 		 := NEW.tablename || '_actual';
	_HyperTable  := NEW.tablename || '_archive';
	
	_KEY_actual  := _Table 		  || '_key';
	_KEY_archive := _HyperTable   || '_key';
	
	_TS_actual 	 := _Table 		  || '_tstamp';
	_TS_archive	 := _HyperTable   || '_tstamp';
	
	_VAL_actual  := _Table 		  || '_val';
	_VAL_archive := _HyperTable   || '_val';
				
	--Создание актуальной и гипертаблицы, если они не существуют, 
	--исходя из значения поля tablename таблицы glossary	
	EXECUTE format('
	CREATE TABLE IF NOT EXISTS %I(
	%I INTEGER NOT NULL,
	%I TIMESTAMPTZ NOT NULL,
	%I FLOAT NOT NULL);

	SELECT create_hypertable(
	''%I'', ''%I'',
	chunk_time_interval => INTERVAL ''1 day'',
	if_not_exists => TRUE
	);

	CREATE TABLE IF NOT EXISTS %I( 
	%I integer NOT NULL GENERATED ALWAYS AS IDENTITY ( INCREMENT 1 START 1 MINVALUE 1 MAXVALUE 2147483647 CACHE 1 ),
	%I TIMESTAMPTZ NOT NULL,
	%I FLOAT NOT NULL,
	FOREIGN KEY (%I) REFERENCES glossary(key));',
	_HyperTable, 	
	_KEY_archive, 	
	_TS_archive, 	
	_VAL_archive,	
	
	_HyperTable,	
	_TS_archive, 	
	
	_Table,			
	_KEY_actual,	
	_TS_actual,		
	_VAL_actual,	
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
INSERT INTO glossary (configuration, communication, allowance, tablename) VALUES --,
('ControlWorkstation/Equipment/Slot/Item[@key=''1'']/Supply/Item[@key=''Photocathode'']/Amperage', NULL, 3, 'float')
,
('ControlWorkstation/Equipment/Slot/Item[@key=''1'']/Supply/Item[@key=''Photocathode'']/Voltage', NULL, 3, 'number')
,
('ControlWorkstation/Equipment/Slot/Item[@key=''1'']/Supply/Item[@key=''Microchannelplate1'']/Amperage', NULL, 3, 'float')
,
('ControlWorkstation/Equipment/Slot/Item[@key=''1'']/Supply/Item[@key=''Microchannelplate1'']/Voltage', NULL, 3, 'number')
,
('ControlWorkstation/Equipment/Slot/Item[@key=''1'']/Supply/Item[@key=''Microchannelplate12'']/Amperage', NULL, 3, 'float')
,
('ControlWorkstation/Equipment/Slot/Item[@key=''1'']/Supply/Item[@key=''Microchannelplate12'']/Voltage', NULL, 3, 'number')
,
('ControlWorkstation/Equipment/Slot/Item[@key=''1'']/Supply/Item[@key=''Microchannelplate2'']/Amperage', NULL, 3, 'float')
,
('ControlWorkstation/Equipment/Slot/Item[@key=''1'']/Supply/Item[@key=''Microchannelplate2'']/Voltage', NULL, 3, 'number')
,
('ControlWorkstation/Equipment/Slot/Item[@key=''1'']/Supply/Item[@key=''Anode'']/Amperage', NULL, 3, 'float')
,
('ControlWorkstation/Equipment/Slot/Item[@key=''1'']/Supply/Item[@key=''Anode'']/Voltage', NULL, 3, 'number')
,
('ControlWorkstation/Equipment/Slot/Item[@key=''2'']/Supply/Item[@key=''Photocathode'']/Amperage', NULL, 3, 'float')
,
('ControlWorkstation/Equipment/Slot/Item[@key=''2'']/Supply/Item[@key=''Photocathode'']/Voltage', NULL, 3, 'number')
,
('ControlWorkstation/Equipment/Slot/Item[@key=''2'']/Supply/Item[@key=''Microchannelplate1'']/Amperage', NULL, 3, 'float')
,
('ControlWorkstation/Equipment/Slot/Item[@key=''2'']/Supply/Item[@key=''Microchannelplate1'']/Voltage', NULL, 3, 'number')
,
('ControlWorkstation/Equipment/Slot/Item[@key=''2'']/Supply/Item[@key=''Microchannelplate12'']/Amperage', NULL, 3, 'float')
,
('ControlWorkstation/Equipment/Slot/Item[@key=''2'']/Supply/Item[@key=''Microchannelplate12'']/Voltage', NULL, 3, 'number')
,
('ControlWorkstation/Equipment/Slot/Item[@key=''2'']/Supply/Item[@key=''Microchannelplate2'']/Amperage', NULL, 3, 'float')
,
('ControlWorkstation/Equipment/Slot/Item[@key=''2'']/Supply/Item[@key=''Microchannelplate2'']/Voltage', NULL, 3, 'number')
,
('ControlWorkstation/Equipment/Slot/Item[@key=''2'']/Supply/Item[@key=''Anode'']/Amperage', NULL, 3, 'float')
,
('ControlWorkstation/Equipment/Slot/Item[@key=''2'']/Supply/Item[@key=''Anode'']/Voltage', NULL, 3, 'number')
,
('ControlWorkstation/Equipment/Slot/Item[@key=''3'']/Supply/Item[@key=''Photocathode'']/Amperage', NULL, 3, 'float')
,
('ControlWorkstation/Equipment/Slot/Item[@key=''3'']/Supply/Item[@key=''Photocathode'']/Voltage', NULL, 3, 'number')
,
('ControlWorkstation/Equipment/Slot/Item[@key=''3'']/Supply/Item[@key=''Microchannelplate1'']/Amperage', NULL, 3, 'float')
,
('ControlWorkstation/Equipment/Slot/Item[@key=''3'']/Supply/Item[@key=''Microchannelplate1'']/Voltage', NULL, 3, 'number')
,
('ControlWorkstation/Equipment/Slot/Item[@key=''3'']/Supply/Item[@key=''Microchannelplate12'']/Amperage', NULL, 3, 'float')
,
('ControlWorkstation/Equipment/Slot/Item[@key=''3'']/Supply/Item[@key=''Microchannelplate12'']/Voltage', NULL, 3, 'number')
,
('ControlWorkstation/Equipment/Slot/Item[@key=''3'']/Supply/Item[@key=''Microchannelplate2'']/Amperage', NULL, 3, 'float')
,
('ControlWorkstation/Equipment/Slot/Item[@key=''3'']/Supply/Item[@key=''Microchannelplate2'']/Voltage', NULL, 3, 'number')
,
('ControlWorkstation/Equipment/Slot/Item[@key=''3'']/Supply/Item[@key=''Anode'']/Amperage', NULL, 3, 'float')
,
('ControlWorkstation/Equipment/Slot/Item[@key=''3'']/Supply/Item[@key=''Anode'']/Voltage', NULL, 3, 'number')
,
('ControlWorkstation/Equipment/Slot/Item[@key=''4'']/Supply/Item[@key=''Photocathode'']/Amperage', NULL, 3, 'float')
,
('ControlWorkstation/Equipment/Slot/Item[@key=''4'']/Supply/Item[@key=''Photocathode'']/Voltage', NULL, 3, 'number')
,
('ControlWorkstation/Equipment/Slot/Item[@key=''4'']/Supply/Item[@key=''Microchannelplate1'']/Amperage', NULL, 3, 'float')
,
('ControlWorkstation/Equipment/Slot/Item[@key=''4'']/Supply/Item[@key=''Microchannelplate1'']/Voltage', NULL, 3, 'number')
,
('ControlWorkstation/Equipment/Slot/Item[@key=''4'']/Supply/Item[@key=''Microchannelplate12'']/Amperage', NULL, 3, 'float')
,
('ControlWorkstation/Equipment/Slot/Item[@key=''4'']/Supply/Item[@key=''Microchannelplate12'']/Voltage', NULL, 3, 'number')
,
('ControlWorkstation/Equipment/Slot/Item[@key=''4'']/Supply/Item[@key=''Microchannelplate2'']/Amperage', NULL, 3, 'float')
,
('ControlWorkstation/Equipment/Slot/Item[@key=''4'']/Supply/Item[@key=''Microchannelplate2'']/Voltage', NULL, 3, 'number')
,
('ControlWorkstation/Equipment/Slot/Item[@key=''4'']/Supply/Item[@key=''Anode'']/Amperage', NULL, 3, 'float')
,
('ControlWorkstation/Equipment/Slot/Item[@key=''4'']/Supply/Item[@key=''Anode'']/Voltage', NULL, 3, 'number')
,
('ControlWorkstation/Equipment/Slot/Item[@key=''5'']/Supply/Item[@key=''Photocathode'']/Amperage', NULL, 3, 'float')
,
('ControlWorkstation/Equipment/Slot/Item[@key=''5'']/Supply/Item[@key=''Photocathode'']/Voltage', NULL, 3, 'number')
,
('ControlWorkstation/Equipment/Slot/Item[@key=''5'']/Supply/Item[@key=''Microchannelplate1'']/Amperage', NULL, 3, 'float')
,
('ControlWorkstation/Equipment/Slot/Item[@key=''5'']/Supply/Item[@key=''Microchannelplate1'']/Voltage', NULL, 3, 'number')
,
('ControlWorkstation/Equipment/Slot/Item[@key=''5'']/Supply/Item[@key=''Microchannelplate12'']/Amperage', NULL, 3, 'float')
,
('ControlWorkstation/Equipment/Slot/Item[@key=''5'']/Supply/Item[@key=''Microchannelplate12'']/Voltage', NULL, 3, 'number')
,
('ControlWorkstation/Equipment/Slot/Item[@key=''5'']/Supply/Item[@key=''Microchannelplate2'']/Amperage', NULL, 3, 'float')
,
('ControlWorkstation/Equipment/Slot/Item[@key=''5'']/Supply/Item[@key=''Microchannelplate2'']/Voltage', NULL, 3, 'number')
,
('ControlWorkstation/Equipment/Slot/Item[@key=''5'']/Supply/Item[@key=''Anode'']/Amperage', NULL, 3, 'float')
,
('ControlWorkstation/Equipment/Slot/Item[@key=''5'']/Supply/Item[@key=''Anode'']/Voltage', NULL, 3, 'number')
,
('ControlWorkstation/Equipment/Slot/Item[@key=''6'']/Supply/Item[@key=''Photocathode'']/Amperage', NULL, 3, 'float')
,
('ControlWorkstation/Equipment/Slot/Item[@key=''6'']/Supply/Item[@key=''Photocathode'']/Voltage', NULL, 3, 'number')
,
('ControlWorkstation/Equipment/Slot/Item[@key=''6'']/Supply/Item[@key=''Microchannelplate1'']/Amperage', NULL, 3, 'float')
,
('ControlWorkstation/Equipment/Slot/Item[@key=''6'']/Supply/Item[@key=''Microchannelplate1'']/Voltage', NULL, 3, 'number')
,
('ControlWorkstation/Equipment/Slot/Item[@key=''6'']/Supply/Item[@key=''Microchannelplate12'']/Amperage', NULL, 3, 'float')
,
('ControlWorkstation/Equipment/Slot/Item[@key=''6'']/Supply/Item[@key=''Microchannelplate12'']/Voltage', NULL, 3, 'number')
,
('ControlWorkstation/Equipment/Slot/Item[@key=''6'']/Supply/Item[@key=''Microchannelplate2'']/Amperage', NULL, 3, 'float')
,
('ControlWorkstation/Equipment/Slot/Item[@key=''6'']/Supply/Item[@key=''Microchannelplate2'']/Voltage', NULL, 3, 'number')
,
('ControlWorkstation/Equipment/Slot/Item[@key=''6'']/Supply/Item[@key=''Anode'']/Amperage', NULL, 3, 'float')
,
('ControlWorkstation/Equipment/Slot/Item[@key=''6'']/Supply/Item[@key=''Anode'']/Voltage', NULL, 3, 'number')
,
('ControlWorkstation/Equipment/Slot/Item[@key=''7'']/Supply/Item[@key=''Photocathode'']/Amperage', NULL, 3, 'float')
,
('ControlWorkstation/Equipment/Slot/Item[@key=''7'']/Supply/Item[@key=''Photocathode'']/Voltage', NULL, 3, 'number')
,
('ControlWorkstation/Equipment/Slot/Item[@key=''7'']/Supply/Item[@key=''Microchannelplate1'']/Amperage', NULL, 3, 'float')
,
('ControlWorkstation/Equipment/Slot/Item[@key=''7'']/Supply/Item[@key=''Microchannelplate1'']/Voltage', NULL, 3, 'number')
,
('ControlWorkstation/Equipment/Slot/Item[@key=''7'']/Supply/Item[@key=''Microchannelplate12'']/Amperage', NULL, 3, 'float')
,
('ControlWorkstation/Equipment/Slot/Item[@key=''7'']/Supply/Item[@key=''Microchannelplate12'']/Voltage', NULL, 3, 'number')
,
('ControlWorkstation/Equipment/Slot/Item[@key=''7'']/Supply/Item[@key=''Microchannelplate2'']/Amperage', NULL, 3, 'float')
,
('ControlWorkstation/Equipment/Slot/Item[@key=''7'']/Supply/Item[@key=''Microchannelplate2'']/Voltage', NULL, 3, 'number')
,
('ControlWorkstation/Equipment/Slot/Item[@key=''7'']/Supply/Item[@key=''Anode'']/Amperage', NULL, 3, 'float')
,
('ControlWorkstation/Equipment/Slot/Item[@key=''7'']/Supply/Item[@key=''Anode'']/Voltage', NULL, 3, 'number')
,
('ControlWorkstation/Equipment/Slot/Item[@key=''8'']/Supply/Item[@key=''Photocathode'']/Amperage', NULL, 3, 'float')
,
('ControlWorkstation/Equipment/Slot/Item[@key=''8'']/Supply/Item[@key=''Photocathode'']/Voltage', NULL, 3, 'number')
,
('ControlWorkstation/Equipment/Slot/Item[@key=''8'']/Supply/Item[@key=''Microchannelplate1'']/Amperage', NULL, 3, 'float')
,
('ControlWorkstation/Equipment/Slot/Item[@key=''8'']/Supply/Item[@key=''Microchannelplate1'']/Voltage', NULL, 3, 'number')
,
('ControlWorkstation/Equipment/Slot/Item[@key=''8'']/Supply/Item[@key=''Microchannelplate12'']/Amperage', NULL, 3, 'float')
,
('ControlWorkstation/Equipment/Slot/Item[@key=''8'']/Supply/Item[@key=''Microchannelplate12'']/Voltage', NULL, 3, 'number')
,
('ControlWorkstation/Equipment/Slot/Item[@key=''8'']/Supply/Item[@key=''Microchannelplate2'']/Amperage', NULL, 3, 'float')
,
('ControlWorkstation/Equipment/Slot/Item[@key=''8'']/Supply/Item[@key=''Microchannelplate2'']/Voltage', NULL, 3, 'number')
,
('ControlWorkstation/Equipment/Slot/Item[@key=''8'']/Supply/Item[@key=''Anode'']/Amperage', NULL, 3, 'float')
,
('ControlWorkstation/Equipment/Slot/Item[@key=''8'']/Supply/Item[@key=''Anode'']/Voltage', NULL, 3, 'number')
,
('ControlWorkstation/Equipment/Slot/Item[@key=''9'']/Supply/Item[@key=''Photocathode'']/Amperage', NULL, 3, 'float')
,
('ControlWorkstation/Equipment/Slot/Item[@key=''9'']/Supply/Item[@key=''Photocathode'']/Voltage', NULL, 3, 'number')
,
('ControlWorkstation/Equipment/Slot/Item[@key=''9'']/Supply/Item[@key=''Microchannelplate1'']/Amperage', NULL, 3, 'float')
,
('ControlWorkstation/Equipment/Slot/Item[@key=''9'']/Supply/Item[@key=''Microchannelplate1'']/Voltage', NULL, 3, 'number')
,
('ControlWorkstation/Equipment/Slot/Item[@key=''9'']/Supply/Item[@key=''Microchannelplate12'']/Amperage', NULL, 3, 'float')
,
('ControlWorkstation/Equipment/Slot/Item[@key=''9'']/Supply/Item[@key=''Microchannelplate12'']/Voltage', NULL, 3, 'number')
,
('ControlWorkstation/Equipment/Slot/Item[@key=''9'']/Supply/Item[@key=''Microchannelplate2'']/Amperage', NULL, 3, 'float')
,
('ControlWorkstation/Equipment/Slot/Item[@key=''9'']/Supply/Item[@key=''Microchannelplate2'']/Voltage', NULL, 3, 'number')
,
('ControlWorkstation/Equipment/Slot/Item[@key=''9'']/Supply/Item[@key=''Anode'']/Amperage', NULL, 3, 'float')
,
('ControlWorkstation/Equipment/Slot/Item[@key=''9'']/Supply/Item[@key=''Anode'']/Voltage', NULL, 3, 'number')
,
('ControlWorkstation/Equipment/Slot/Item[@key=''10'']/Supply/Item[@key=''Photocathode'']/Amperage', NULL, 3, 'float')
,
('ControlWorkstation/Equipment/Slot/Item[@key=''10'']/Supply/Item[@key=''Photocathode'']/Voltage', NULL, 3, 'number')
,
('ControlWorkstation/Equipment/Slot/Item[@key=''10'']/Supply/Item[@key=''Microchannelplate1'']/Amperage', NULL, 3, 'float')
,
('ControlWorkstation/Equipment/Slot/Item[@key=''10'']/Supply/Item[@key=''Microchannelplate1'']/Voltage', NULL, 3, 'number')
,
('ControlWorkstation/Equipment/Slot/Item[@key=''10'']/Supply/Item[@key=''Microchannelplate12'']/Amperage', NULL, 3, 'float')
,
('ControlWorkstation/Equipment/Slot/Item[@key=''10'']/Supply/Item[@key=''Microchannelplate12'']/Voltage', NULL, 3, 'number')
,
('ControlWorkstation/Equipment/Slot/Item[@key=''10'']/Supply/Item[@key=''Microchannelplate2'']/Amperage', NULL, 3, 'float')
,
('ControlWorkstation/Equipment/Slot/Item[@key=''10'']/Supply/Item[@key=''Microchannelplate2'']/Voltage', NULL, 3, 'number')
,
('ControlWorkstation/Equipment/Slot/Item[@key=''10'']/Supply/Item[@key=''Anode'']/Amperage', NULL, 3, 'float')
,
('ControlWorkstation/Equipment/Slot/Item[@key=''10'']/Supply/Item[@key=''Anode'']/Voltage', NULL, 3, 'number')
,
('ControlWorkstation/Equipment/Slot/Item[@key=''11'']/Supply/Item[@key=''Photocathode'']/Amperage', NULL, 3, 'float')
,
('ControlWorkstation/Equipment/Slot/Item[@key=''11'']/Supply/Item[@key=''Photocathode'']/Voltage', NULL, 3, 'number')
,
('ControlWorkstation/Equipment/Slot/Item[@key=''11'']/Supply/Item[@key=''Microchannelplate1'']/Amperage', NULL, 3, 'float')
,
('ControlWorkstation/Equipment/Slot/Item[@key=''11'']/Supply/Item[@key=''Microchannelplate1'']/Voltage', NULL, 3, 'number')
,
('ControlWorkstation/Equipment/Slot/Item[@key=''11'']/Supply/Item[@key=''Microchannelplate12'']/Amperage', NULL, 3, 'float')
,
('ControlWorkstation/Equipment/Slot/Item[@key=''11'']/Supply/Item[@key=''Microchannelplate12'']/Voltage', NULL, 3, 'number')
,
('ControlWorkstation/Equipment/Slot/Item[@key=''11'']/Supply/Item[@key=''Microchannelplate2'']/Amperage', NULL, 3, 'float')
,
('ControlWorkstation/Equipment/Slot/Item[@key=''11'']/Supply/Item[@key=''Microchannelplate2'']/Voltage', NULL, 3, 'number')
,
('ControlWorkstation/Equipment/Slot/Item[@key=''11'']/Supply/Item[@key=''Anode'']/Amperage', NULL, 3, 'float')
,
('ControlWorkstation/Equipment/Slot/Item[@key=''11'']/Supply/Item[@key=''Anode'']/Voltage', NULL, 3, 'number')
,
('ControlWorkstation/Equipment/Slot/Item[@key=''12'']/Supply/Item[@key=''Photocathode'']/Amperage', NULL, 3, 'float')
,
('ControlWorkstation/Equipment/Slot/Item[@key=''12'']/Supply/Item[@key=''Photocathode'']/Voltage', NULL, 3, 'number')
,
('ControlWorkstation/Equipment/Slot/Item[@key=''12'']/Supply/Item[@key=''Microchannelplate1'']/Amperage', NULL, 3, 'float')
,
('ControlWorkstation/Equipment/Slot/Item[@key=''12'']/Supply/Item[@key=''Microchannelplate1'']/Voltage', NULL, 3, 'number')
,
('ControlWorkstation/Equipment/Slot/Item[@key=''12'']/Supply/Item[@key=''Microchannelplate12'']/Amperage', NULL, 3, 'float')
,
('ControlWorkstation/Equipment/Slot/Item[@key=''12'']/Supply/Item[@key=''Microchannelplate12'']/Voltage', NULL, 3, 'number')
,
('ControlWorkstation/Equipment/Slot/Item[@key=''12'']/Supply/Item[@key=''Microchannelplate2'']/Amperage', NULL, 3, 'float')
,
('ControlWorkstation/Equipment/Slot/Item[@key=''12'']/Supply/Item[@key=''Microchannelplate2'']/Voltage', NULL, 3, 'number')
,
('ControlWorkstation/Equipment/Slot/Item[@key=''12'']/Supply/Item[@key=''Anode'']/Amperage', NULL, 3, 'float')
,
('ControlWorkstation/Equipment/Slot/Item[@key=''12'']/Supply/Item[@key=''Anode'']/Voltage', NULL, 3, 'number')
,
('ControlWorkstation/Equipment/Slot/Item[@key=''13'']/Supply/Item[@key=''Photocathode'']/Amperage', NULL, 3, 'float')
,
('ControlWorkstation/Equipment/Slot/Item[@key=''13'']/Supply/Item[@key=''Photocathode'']/Voltage', NULL, 3, 'number')
,
('ControlWorkstation/Equipment/Slot/Item[@key=''13'']/Supply/Item[@key=''Microchannelplate1'']/Amperage', NULL, 3, 'float')
,
('ControlWorkstation/Equipment/Slot/Item[@key=''13'']/Supply/Item[@key=''Microchannelplate1'']/Voltage', NULL, 3, 'number')
,
('ControlWorkstation/Equipment/Slot/Item[@key=''13'']/Supply/Item[@key=''Microchannelplate12'']/Amperage', NULL, 3, 'float')
,
('ControlWorkstation/Equipment/Slot/Item[@key=''13'']/Supply/Item[@key=''Microchannelplate12'']/Voltage', NULL, 3, 'number')
,
('ControlWorkstation/Equipment/Slot/Item[@key=''13'']/Supply/Item[@key=''Microchannelplate2'']/Amperage', NULL, 3, 'float')
,
('ControlWorkstation/Equipment/Slot/Item[@key=''13'']/Supply/Item[@key=''Microchannelplate2'']/Voltage', NULL, 3, 'number')
,
('ControlWorkstation/Equipment/Slot/Item[@key=''13'']/Supply/Item[@key=''Anode'']/Amperage', NULL, 3, 'float')
,
('ControlWorkstation/Equipment/Slot/Item[@key=''13'']/Supply/Item[@key=''Anode'']/Voltage', NULL, 3, 'number')
,
('ControlWorkstation/Equipment/Slot/Item[@key=''14'']/Supply/Item[@key=''Photocathode'']/Amperage', NULL, 3, 'float')
,
('ControlWorkstation/Equipment/Slot/Item[@key=''14'']/Supply/Item[@key=''Photocathode'']/Voltage', NULL, 3, 'number')
,
('ControlWorkstation/Equipment/Slot/Item[@key=''14'']/Supply/Item[@key=''Microchannelplate1'']/Amperage', NULL, 3, 'float')
,
('ControlWorkstation/Equipment/Slot/Item[@key=''14'']/Supply/Item[@key=''Microchannelplate1'']/Voltage', NULL, 3, 'number')
,
('ControlWorkstation/Equipment/Slot/Item[@key=''14'']/Supply/Item[@key=''Microchannelplate12'']/Amperage', NULL, 3, 'float')
,
('ControlWorkstation/Equipment/Slot/Item[@key=''14'']/Supply/Item[@key=''Microchannelplate12'']/Voltage', NULL, 3, 'number')
,
('ControlWorkstation/Equipment/Slot/Item[@key=''14'']/Supply/Item[@key=''Microchannelplate2'']/Amperage', NULL, 3, 'float')
,
('ControlWorkstation/Equipment/Slot/Item[@key=''14'']/Supply/Item[@key=''Microchannelplate2'']/Voltage', NULL, 3, 'number')
,
('ControlWorkstation/Equipment/Slot/Item[@key=''14'']/Supply/Item[@key=''Anode'']/Amperage', NULL, 3, 'float')
,
('ControlWorkstation/Equipment/Slot/Item[@key=''14'']/Supply/Item[@key=''Anode'']/Voltage', NULL, 3, 'number')
,
('ControlWorkstation/Equipment/Slot/Item[@key=''15'']/Supply/Item[@key=''Photocathode'']/Amperage', NULL, 3, 'float')
,
('ControlWorkstation/Equipment/Slot/Item[@key=''15'']/Supply/Item[@key=''Photocathode'']/Voltage', NULL, 3, 'number')
,
('ControlWorkstation/Equipment/Slot/Item[@key=''15'']/Supply/Item[@key=''Microchannelplate1'']/Amperage', NULL, 3, 'float')
,
('ControlWorkstation/Equipment/Slot/Item[@key=''15'']/Supply/Item[@key=''Microchannelplate1'']/Voltage', NULL, 3, 'number')
,
('ControlWorkstation/Equipment/Slot/Item[@key=''15'']/Supply/Item[@key=''Microchannelplate12'']/Amperage', NULL, 3, 'float')
,
('ControlWorkstation/Equipment/Slot/Item[@key=''15'']/Supply/Item[@key=''Microchannelplate12'']/Voltage', NULL, 3, 'number')
,
('ControlWorkstation/Equipment/Slot/Item[@key=''15'']/Supply/Item[@key=''Microchannelplate2'']/Amperage', NULL, 3, 'float')
,
('ControlWorkstation/Equipment/Slot/Item[@key=''15'']/Supply/Item[@key=''Microchannelplate2'']/Voltage', NULL, 3, 'number')
,
('ControlWorkstation/Equipment/Slot/Item[@key=''15'']/Supply/Item[@key=''Anode'']/Amperage', NULL, 3, 'float')
,
('ControlWorkstation/Equipment/Slot/Item[@key=''15'']/Supply/Item[@key=''Anode'']/Voltage', NULL, 3, 'number')
,
('ControlWorkstation/Equipment/Slot/Item[@key=''16'']/Supply/Item[@key=''Photocathode'']/Amperage', NULL, 3, 'float')
,
('ControlWorkstation/Equipment/Slot/Item[@key=''16'']/Supply/Item[@key=''Photocathode'']/Voltage', NULL, 3, 'number')
,
('ControlWorkstation/Equipment/Slot/Item[@key=''16'']/Supply/Item[@key=''Microchannelplate1'']/Amperage', NULL, 3, 'float')
,
('ControlWorkstation/Equipment/Slot/Item[@key=''16'']/Supply/Item[@key=''Microchannelplate1'']/Voltage', NULL, 3, 'number')
,
('ControlWorkstation/Equipment/Slot/Item[@key=''16'']/Supply/Item[@key=''Microchannelplate12'']/Amperage', NULL, 3, 'float')
,
('ControlWorkstation/Equipment/Slot/Item[@key=''16'']/Supply/Item[@key=''Microchannelplate12'']/Voltage', NULL, 3, 'number')
,
('ControlWorkstation/Equipment/Slot/Item[@key=''16'']/Supply/Item[@key=''Microchannelplate2'']/Amperage', NULL, 3, 'float')
,
('ControlWorkstation/Equipment/Slot/Item[@key=''16'']/Supply/Item[@key=''Microchannelplate2'']/Voltage', NULL, 3, 'number')
,
('ControlWorkstation/Equipment/Slot/Item[@key=''16'']/Supply/Item[@key=''Anode'']/Amperage', NULL, 3, 'float')
,
('ControlWorkstation/Equipment/Slot/Item[@key=''16'']/Supply/Item[@key=''Anode'']/Voltage', NULL, 3, 'number')
,
('ControlWorkstation/Equipment/Slot/Item[@key=''17'']/Supply/Item[@key=''Photocathode'']/Amperage', NULL, 3, 'float')
,
('ControlWorkstation/Equipment/Slot/Item[@key=''17'']/Supply/Item[@key=''Photocathode'']/Voltage', NULL, 3, 'number')
,
('ControlWorkstation/Equipment/Slot/Item[@key=''17'']/Supply/Item[@key=''Microchannelplate1'']/Amperage', NULL, 3, 'float')
,
('ControlWorkstation/Equipment/Slot/Item[@key=''17'']/Supply/Item[@key=''Microchannelplate1'']/Voltage', NULL, 3, 'number')
,
('ControlWorkstation/Equipment/Slot/Item[@key=''17'']/Supply/Item[@key=''Microchannelplate12'']/Amperage', NULL, 3, 'float')
,
('ControlWorkstation/Equipment/Slot/Item[@key=''17'']/Supply/Item[@key=''Microchannelplate12'']/Voltage', NULL, 3, 'number')
,
('ControlWorkstation/Equipment/Slot/Item[@key=''17'']/Supply/Item[@key=''Microchannelplate2'']/Amperage', NULL, 3, 'float')
,
('ControlWorkstation/Equipment/Slot/Item[@key=''17'']/Supply/Item[@key=''Microchannelplate2'']/Voltage', NULL, 3, 'number')
,
('ControlWorkstation/Equipment/Slot/Item[@key=''17'']/Supply/Item[@key=''Anode'']/Amperage', NULL, 3, 'float')
,
('ControlWorkstation/Equipment/Slot/Item[@key=''17'']/Supply/Item[@key=''Anode'']/Voltage', NULL, 3, 'number')
,
('ControlWorkstation/Equipment/Slot/Item[@key=''18'']/Supply/Item[@key=''Photocathode'']/Amperage', NULL, 3, 'float')
,
('ControlWorkstation/Equipment/Slot/Item[@key=''18'']/Supply/Item[@key=''Photocathode'']/Voltage', NULL, 3, 'number')
,
('ControlWorkstation/Equipment/Slot/Item[@key=''18'']/Supply/Item[@key=''Microchannelplate1'']/Amperage', NULL, 3, 'float')
,
('ControlWorkstation/Equipment/Slot/Item[@key=''18'']/Supply/Item[@key=''Microchannelplate1'']/Voltage', NULL, 3, 'number')
,
('ControlWorkstation/Equipment/Slot/Item[@key=''18'']/Supply/Item[@key=''Microchannelplate12'']/Amperage', NULL, 3, 'float')
,
('ControlWorkstation/Equipment/Slot/Item[@key=''18'']/Supply/Item[@key=''Microchannelplate12'']/Voltage', NULL, 3, 'number')
,
('ControlWorkstation/Equipment/Slot/Item[@key=''18'']/Supply/Item[@key=''Microchannelplate2'']/Amperage', NULL, 3, 'float')
,
('ControlWorkstation/Equipment/Slot/Item[@key=''18'']/Supply/Item[@key=''Microchannelplate2'']/Voltage', NULL, 3, 'number')
,
('ControlWorkstation/Equipment/Slot/Item[@key=''18'']/Supply/Item[@key=''Anode'']/Amperage', NULL, 3, 'float')
,
('ControlWorkstation/Equipment/Slot/Item[@key=''18'']/Supply/Item[@key=''Anode'']/Voltage', NULL, 3, 'number')
,
('ControlWorkstation/Equipment/Slot/Item[@key=''19'']/Supply/Item[@key=''Photocathode'']/Amperage', NULL, 3, 'float')
,
('ControlWorkstation/Equipment/Slot/Item[@key=''19'']/Supply/Item[@key=''Photocathode'']/Voltage', NULL, 3, 'number')
,
('ControlWorkstation/Equipment/Slot/Item[@key=''19'']/Supply/Item[@key=''Microchannelplate1'']/Amperage', NULL, 3, 'float')
,
('ControlWorkstation/Equipment/Slot/Item[@key=''19'']/Supply/Item[@key=''Microchannelplate1'']/Voltage', NULL, 3, 'number')
,
('ControlWorkstation/Equipment/Slot/Item[@key=''19'']/Supply/Item[@key=''Microchannelplate12'']/Amperage', NULL, 3, 'float')
,
('ControlWorkstation/Equipment/Slot/Item[@key=''19'']/Supply/Item[@key=''Microchannelplate12'']/Voltage', NULL, 3, 'number')
,
('ControlWorkstation/Equipment/Slot/Item[@key=''19'']/Supply/Item[@key=''Microchannelplate2'']/Amperage', NULL, 3, 'float')
,
('ControlWorkstation/Equipment/Slot/Item[@key=''19'']/Supply/Item[@key=''Microchannelplate2'']/Voltage', NULL, 3, 'number')
,
('ControlWorkstation/Equipment/Slot/Item[@key=''19'']/Supply/Item[@key=''Anode'']/Amperage', NULL, 3, 'float')
,
('ControlWorkstation/Equipment/Slot/Item[@key=''19'']/Supply/Item[@key=''Anode'']/Voltage', NULL, 3, 'number')
,
('ControlWorkstation/Equipment/Slot/Item[@key=''20'']/Supply/Item[@key=''Photocathode'']/Amperage', NULL, 3, 'float')
,
('ControlWorkstation/Equipment/Slot/Item[@key=''20'']/Supply/Item[@key=''Photocathode'']/Voltage', NULL, 3, 'number')
,
('ControlWorkstation/Equipment/Slot/Item[@key=''20'']/Supply/Item[@key=''Microchannelplate1'']/Amperage', NULL, 3, 'float')
,
('ControlWorkstation/Equipment/Slot/Item[@key=''20'']/Supply/Item[@key=''Microchannelplate1'']/Voltage', NULL, 3, 'number')
,
('ControlWorkstation/Equipment/Slot/Item[@key=''20'']/Supply/Item[@key=''Microchannelplate12'']/Amperage', NULL, 3, 'float')
,
('ControlWorkstation/Equipment/Slot/Item[@key=''20'']/Supply/Item[@key=''Microchannelplate12'']/Voltage', NULL, 3, 'number')
,
('ControlWorkstation/Equipment/Slot/Item[@key=''20'']/Supply/Item[@key=''Microchannelplate2'']/Amperage', NULL, 3, 'float')
,
('ControlWorkstation/Equipment/Slot/Item[@key=''20'']/Supply/Item[@key=''Microchannelplate2'']/Voltage', NULL, 3, 'number')
,
('ControlWorkstation/Equipment/Slot/Item[@key=''20'']/Supply/Item[@key=''Anode'']/Amperage', NULL, 3, 'float')
,
('ControlWorkstation/Equipment/Slot/Item[@key=''20'']/Supply/Item[@key=''Anode'']/Voltage', NULL, 3, 'number')
,
('ControlWorkstation/Equipment/Slot/Item[@key=''21'']/Supply/Item[@key=''Photocathode'']/Amperage', NULL, 3, 'float')
,
('ControlWorkstation/Equipment/Slot/Item[@key=''21'']/Supply/Item[@key=''Photocathode'']/Voltage', NULL, 3, 'number')
,
('ControlWorkstation/Equipment/Slot/Item[@key=''21'']/Supply/Item[@key=''Microchannelplate1'']/Amperage', NULL, 3, 'float')
,
('ControlWorkstation/Equipment/Slot/Item[@key=''21'']/Supply/Item[@key=''Microchannelplate1'']/Voltage', NULL, 3, 'number')
,
('ControlWorkstation/Equipment/Slot/Item[@key=''21'']/Supply/Item[@key=''Microchannelplate12'']/Amperage', NULL, 3, 'float')
,
('ControlWorkstation/Equipment/Slot/Item[@key=''21'']/Supply/Item[@key=''Microchannelplate12'']/Voltage', NULL, 3, 'number')
,
('ControlWorkstation/Equipment/Slot/Item[@key=''21'']/Supply/Item[@key=''Microchannelplate2'']/Amperage', NULL, 3, 'float')
,
('ControlWorkstation/Equipment/Slot/Item[@key=''21'']/Supply/Item[@key=''Microchannelplate2'']/Voltage', NULL, 3, 'number')
,
('ControlWorkstation/Equipment/Slot/Item[@key=''21'']/Supply/Item[@key=''Anode'']/Amperage', NULL, 3, 'float')
,
('ControlWorkstation/Equipment/Slot/Item[@key=''21'']/Supply/Item[@key=''Anode'']/Voltage', NULL, 3, 'number')
,
('ControlWorkstation/Equipment/Slot/Item[@key=''22'']/Supply/Item[@key=''Photocathode'']/Amperage', NULL, 3, 'float')
,
('ControlWorkstation/Equipment/Slot/Item[@key=''22'']/Supply/Item[@key=''Photocathode'']/Voltage', NULL, 3, 'number')
,
('ControlWorkstation/Equipment/Slot/Item[@key=''22'']/Supply/Item[@key=''Microchannelplate1'']/Amperage', NULL, 3, 'float')
,
('ControlWorkstation/Equipment/Slot/Item[@key=''22'']/Supply/Item[@key=''Microchannelplate1'']/Voltage', NULL, 3, 'number')
,
('ControlWorkstation/Equipment/Slot/Item[@key=''22'']/Supply/Item[@key=''Microchannelplate12'']/Amperage', NULL, 3, 'float')
,
('ControlWorkstation/Equipment/Slot/Item[@key=''22'']/Supply/Item[@key=''Microchannelplate12'']/Voltage', NULL, 3, 'number')
,
('ControlWorkstation/Equipment/Slot/Item[@key=''22'']/Supply/Item[@key=''Microchannelplate2'']/Amperage', NULL, 3, 'float')
,
('ControlWorkstation/Equipment/Slot/Item[@key=''22'']/Supply/Item[@key=''Microchannelplate2'']/Voltage', NULL, 3, 'number')
,
('ControlWorkstation/Equipment/Slot/Item[@key=''22'']/Supply/Item[@key=''Anode'']/Amperage', NULL, 3, 'float')
,
('ControlWorkstation/Equipment/Slot/Item[@key=''22'']/Supply/Item[@key=''Anode'']/Voltage', NULL, 3, 'number')
,
('ControlWorkstation/Equipment/Slot/Item[@key=''23'']/Supply/Item[@key=''Photocathode'']/Amperage', NULL, 3, 'float')
,
('ControlWorkstation/Equipment/Slot/Item[@key=''23'']/Supply/Item[@key=''Photocathode'']/Voltage', NULL, 3, 'number')
,
('ControlWorkstation/Equipment/Slot/Item[@key=''23'']/Supply/Item[@key=''Microchannelplate1'']/Amperage', NULL, 3, 'float')
,
('ControlWorkstation/Equipment/Slot/Item[@key=''23'']/Supply/Item[@key=''Microchannelplate1'']/Voltage', NULL, 3, 'number')
,
('ControlWorkstation/Equipment/Slot/Item[@key=''23'']/Supply/Item[@key=''Microchannelplate12'']/Amperage', NULL, 3, 'float')
,
('ControlWorkstation/Equipment/Slot/Item[@key=''23'']/Supply/Item[@key=''Microchannelplate12'']/Voltage', NULL, 3, 'number')
,
('ControlWorkstation/Equipment/Slot/Item[@key=''23'']/Supply/Item[@key=''Microchannelplate2'']/Amperage', NULL, 3, 'float')
,
('ControlWorkstation/Equipment/Slot/Item[@key=''23'']/Supply/Item[@key=''Microchannelplate2'']/Voltage', NULL, 3, 'number')
,
('ControlWorkstation/Equipment/Slot/Item[@key=''23'']/Supply/Item[@key=''Anode'']/Amperage', NULL, 3, 'float')
,
('ControlWorkstation/Equipment/Slot/Item[@key=''23'']/Supply/Item[@key=''Anode'']/Voltage', NULL, 3, 'number')
,
('ControlWorkstation/Equipment/Slot/Item[@key=''24'']/Supply/Item[@key=''Photocathode'']/Amperage', NULL, 3, 'float')
,
('ControlWorkstation/Equipment/Slot/Item[@key=''24'']/Supply/Item[@key=''Photocathode'']/Voltage', NULL, 3, 'number')
,
('ControlWorkstation/Equipment/Slot/Item[@key=''24'']/Supply/Item[@key=''Microchannelplate1'']/Amperage', NULL, 3, 'float')
,
('ControlWorkstation/Equipment/Slot/Item[@key=''24'']/Supply/Item[@key=''Microchannelplate1'']/Voltage', NULL, 3, 'number')
,
('ControlWorkstation/Equipment/Slot/Item[@key=''24'']/Supply/Item[@key=''Microchannelplate12'']/Amperage', NULL, 3, 'float')
,
('ControlWorkstation/Equipment/Slot/Item[@key=''24'']/Supply/Item[@key=''Microchannelplate12'']/Voltage', NULL, 3, 'number')
,
('ControlWorkstation/Equipment/Slot/Item[@key=''24'']/Supply/Item[@key=''Microchannelplate2'']/Amperage', NULL, 3, 'float')
,
('ControlWorkstation/Equipment/Slot/Item[@key=''24'']/Supply/Item[@key=''Microchannelplate2'']/Voltage', NULL, 3, 'number')
,
('ControlWorkstation/Equipment/Slot/Item[@key=''24'']/Supply/Item[@key=''Anode'']/Amperage', NULL, 3, 'float')
,
('ControlWorkstation/Equipment/Slot/Item[@key=''24'']/Supply/Item[@key=''Anode'']/Voltage', NULL, 3, 'number')
,
('ControlWorkstation/Equipment/Slot/Item[@key=''25'']/Supply/Item[@key=''Photocathode'']/Amperage', NULL, 3, 'float')
,
('ControlWorkstation/Equipment/Slot/Item[@key=''25'']/Supply/Item[@key=''Photocathode'']/Voltage', NULL, 3, 'number')
,
('ControlWorkstation/Equipment/Slot/Item[@key=''25'']/Supply/Item[@key=''Microchannelplate1'']/Amperage', NULL, 3, 'float')
,
('ControlWorkstation/Equipment/Slot/Item[@key=''25'']/Supply/Item[@key=''Microchannelplate1'']/Voltage', NULL, 3, 'number')
,
('ControlWorkstation/Equipment/Slot/Item[@key=''25'']/Supply/Item[@key=''Microchannelplate12'']/Amperage', NULL, 3, 'float')
,
('ControlWorkstation/Equipment/Slot/Item[@key=''25'']/Supply/Item[@key=''Microchannelplate12'']/Voltage', NULL, 3, 'number')
,
('ControlWorkstation/Equipment/Slot/Item[@key=''25'']/Supply/Item[@key=''Microchannelplate2'']/Amperage', NULL, 3, 'float')
,
('ControlWorkstation/Equipment/Slot/Item[@key=''25'']/Supply/Item[@key=''Microchannelplate2'']/Voltage', NULL, 3, 'number')
,
('ControlWorkstation/Equipment/Slot/Item[@key=''25'']/Supply/Item[@key=''Anode'']/Amperage', NULL, 3, 'float')
,
('ControlWorkstation/Equipment/Slot/Item[@key=''25'']/Supply/Item[@key=''Anode'']/Voltage', NULL, 3, 'number')
,
('ControlWorkstation/Equipment/Slot/Item[@key=''26'']/Supply/Item[@key=''Photocathode'']/Amperage', NULL, 3, 'float')
,
('ControlWorkstation/Equipment/Slot/Item[@key=''26'']/Supply/Item[@key=''Photocathode'']/Voltage', NULL, 3, 'number')
,
('ControlWorkstation/Equipment/Slot/Item[@key=''26'']/Supply/Item[@key=''Microchannelplate1'']/Amperage', NULL, 3, 'float')
,
('ControlWorkstation/Equipment/Slot/Item[@key=''26'']/Supply/Item[@key=''Microchannelplate1'']/Voltage', NULL, 3, 'number')
,
('ControlWorkstation/Equipment/Slot/Item[@key=''26'']/Supply/Item[@key=''Microchannelplate12'']/Amperage', NULL, 3, 'float')
,
('ControlWorkstation/Equipment/Slot/Item[@key=''26'']/Supply/Item[@key=''Microchannelplate12'']/Voltage', NULL, 3, 'number')
,
('ControlWorkstation/Equipment/Slot/Item[@key=''26'']/Supply/Item[@key=''Microchannelplate2'']/Amperage', NULL, 3, 'float')
,
('ControlWorkstation/Equipment/Slot/Item[@key=''26'']/Supply/Item[@key=''Microchannelplate2'']/Voltage', NULL, 3, 'number')
,
('ControlWorkstation/Equipment/Slot/Item[@key=''26'']/Supply/Item[@key=''Anode'']/Amperage', NULL, 3, 'float')
,
('ControlWorkstation/Equipment/Slot/Item[@key=''26'']/Supply/Item[@key=''Anode'']/Voltage', NULL, 3, 'number')
,
('ControlWorkstation/Equipment/Slot/Item[@key=''27'']/Supply/Item[@key=''Photocathode'']/Amperage', NULL, 3, 'float')
,
('ControlWorkstation/Equipment/Slot/Item[@key=''27'']/Supply/Item[@key=''Photocathode'']/Voltage', NULL, 3, 'number')
,
('ControlWorkstation/Equipment/Slot/Item[@key=''27'']/Supply/Item[@key=''Microchannelplate1'']/Amperage', NULL, 3, 'float')
,
('ControlWorkstation/Equipment/Slot/Item[@key=''27'']/Supply/Item[@key=''Microchannelplate1'']/Voltage', NULL, 3, 'number')
,
('ControlWorkstation/Equipment/Slot/Item[@key=''27'']/Supply/Item[@key=''Microchannelplate12'']/Amperage', NULL, 3, 'float')
,
('ControlWorkstation/Equipment/Slot/Item[@key=''27'']/Supply/Item[@key=''Microchannelplate12'']/Voltage', NULL, 3, 'number')
,
('ControlWorkstation/Equipment/Slot/Item[@key=''27'']/Supply/Item[@key=''Microchannelplate2'']/Amperage', NULL, 3, 'float')
,
('ControlWorkstation/Equipment/Slot/Item[@key=''27'']/Supply/Item[@key=''Microchannelplate2'']/Voltage', NULL, 3, 'number')
,
('ControlWorkstation/Equipment/Slot/Item[@key=''27'']/Supply/Item[@key=''Anode'']/Amperage', NULL, 3, 'float')
,
('ControlWorkstation/Equipment/Slot/Item[@key=''27'']/Supply/Item[@key=''Anode'']/Voltage', NULL, 3, 'number')
,
('ControlWorkstation/Equipment/Slot/Item[@key=''28'']/Supply/Item[@key=''Photocathode'']/Amperage', NULL, 3, 'float')
,
('ControlWorkstation/Equipment/Slot/Item[@key=''28'']/Supply/Item[@key=''Photocathode'']/Voltage', NULL, 3, 'number')
,
('ControlWorkstation/Equipment/Slot/Item[@key=''28'']/Supply/Item[@key=''Microchannelplate1'']/Amperage', NULL, 3, 'float')
,
('ControlWorkstation/Equipment/Slot/Item[@key=''28'']/Supply/Item[@key=''Microchannelplate1'']/Voltage', NULL, 3, 'number')
,
('ControlWorkstation/Equipment/Slot/Item[@key=''28'']/Supply/Item[@key=''Microchannelplate12'']/Amperage', NULL, 3, 'float')
,
('ControlWorkstation/Equipment/Slot/Item[@key=''28'']/Supply/Item[@key=''Microchannelplate12'']/Voltage', NULL, 3, 'number')
,
('ControlWorkstation/Equipment/Slot/Item[@key=''28'']/Supply/Item[@key=''Microchannelplate2'']/Amperage', NULL, 3, 'float')
,
('ControlWorkstation/Equipment/Slot/Item[@key=''28'']/Supply/Item[@key=''Microchannelplate2'']/Voltage', NULL, 3, 'number')
,
('ControlWorkstation/Equipment/Slot/Item[@key=''28'']/Supply/Item[@key=''Anode'']/Amperage', NULL, 3, 'float')
,
('ControlWorkstation/Equipment/Slot/Item[@key=''28'']/Supply/Item[@key=''Anode'']/Voltage', NULL, 3, 'number')
,
('ControlWorkstation/Equipment/Slot/Item[@key=''29'']/Supply/Item[@key=''Photocathode'']/Amperage', NULL, 3, 'float')
,
('ControlWorkstation/Equipment/Slot/Item[@key=''29'']/Supply/Item[@key=''Photocathode'']/Voltage', NULL, 3, 'number')
,
('ControlWorkstation/Equipment/Slot/Item[@key=''29'']/Supply/Item[@key=''Microchannelplate1'']/Amperage', NULL, 3, 'float')
,
('ControlWorkstation/Equipment/Slot/Item[@key=''29'']/Supply/Item[@key=''Microchannelplate1'']/Voltage', NULL, 3, 'number')
,
('ControlWorkstation/Equipment/Slot/Item[@key=''29'']/Supply/Item[@key=''Microchannelplate12'']/Amperage', NULL, 3, 'float')
,
('ControlWorkstation/Equipment/Slot/Item[@key=''29'']/Supply/Item[@key=''Microchannelplate12'']/Voltage', NULL, 3, 'number')
,
('ControlWorkstation/Equipment/Slot/Item[@key=''29'']/Supply/Item[@key=''Microchannelplate2'']/Amperage', NULL, 3, 'float')
,
('ControlWorkstation/Equipment/Slot/Item[@key=''29'']/Supply/Item[@key=''Microchannelplate2'']/Voltage', NULL, 3, 'number')
,
('ControlWorkstation/Equipment/Slot/Item[@key=''29'']/Supply/Item[@key=''Anode'']/Amperage', NULL, 3, 'float')
,
('ControlWorkstation/Equipment/Slot/Item[@key=''29'']/Supply/Item[@key=''Anode'']/Voltage', NULL, 3, 'number')
,
('ControlWorkstation/Equipment/Slot/Item[@key=''30'']/Supply/Item[@key=''Photocathode'']/Amperage', NULL, 3, 'float')
,
('ControlWorkstation/Equipment/Slot/Item[@key=''30'']/Supply/Item[@key=''Photocathode'']/Voltage', NULL, 3, 'number')
,
('ControlWorkstation/Equipment/Slot/Item[@key=''30'']/Supply/Item[@key=''Microchannelplate1'']/Amperage', NULL, 3, 'float')
,
('ControlWorkstation/Equipment/Slot/Item[@key=''30'']/Supply/Item[@key=''Microchannelplate1'']/Voltage', NULL, 3, 'number')
,
('ControlWorkstation/Equipment/Slot/Item[@key=''30'']/Supply/Item[@key=''Microchannelplate12'']/Amperage', NULL, 3, 'float')
,
('ControlWorkstation/Equipment/Slot/Item[@key=''30'']/Supply/Item[@key=''Microchannelplate12'']/Voltage', NULL, 3, 'number')
,
('ControlWorkstation/Equipment/Slot/Item[@key=''30'']/Supply/Item[@key=''Microchannelplate2'']/Amperage', NULL, 3, 'float')
,
('ControlWorkstation/Equipment/Slot/Item[@key=''30'']/Supply/Item[@key=''Microchannelplate2'']/Voltage', NULL, 3, 'number')
,
('ControlWorkstation/Equipment/Slot/Item[@key=''30'']/Supply/Item[@key=''Anode'']/Amperage', NULL, 3, 'float')
,
('ControlWorkstation/Equipment/Slot/Item[@key=''30'']/Supply/Item[@key=''Anode'']/Voltage', NULL, 3, 'number')
;
-----------------------------------------------------------------------------------------------------
CREATE OR REPLACE PROCEDURE _communication(xpath VARCHAR, valnew FLOAT) AS $$

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
	IF(_DeltaP <= _Allowance) THEN
		--Если число записей в гипертаблице не превышает 2
		IF(_Count < 2) THEN
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
RETURNS FLOAT AS $$

--Обновление активной информации в ПО из БД

DECLARE 

	--переменные для:
	_Key INTEGER;			--значения ключа актуальной таблицы
	_TableName TEXT;		--значения 4-го поля таблицы glossary, формирующего _Table    
	_Table TEXT;  			--имени актуальной таблицы  
	_Value FLOAT;			--значения 3-го поля val из актуальной таблицы
	_KEY_actual TEXT;		--имени ключа актуальной таблицы 
	_TS_actual TEXT;		--фиксированного момента актуальной таблицы 
	_VAL_actual TEXT;		--фиксированного значения актуальной таблицы 
	
	_reс T_REC;
	
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
			
	--Получение значения val из актуальной таблицы
	IF (_Table IS NOT NULL) THEN 
		EXECUTE FORMAT('SELECT %I FROM %I WHERE %I = %s;', _VAL_actual, _Table, _KEY_actual, _Key) INTO _Value;
	ELSE
		_Value := NULL;
	END IF;  
	
	RETURN _Value;
						
END;

$$ LANGUAGE plpgsql;
-----------------------------------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION _refreshold(xpath VARCHAR, st TIMESTAMP, fin TIMESTAMP)
RETURNS TABLE (rkey INTEGER, rtstamp TIMESTAMPTZ, rval FLOAT) AS $$

--Обновление архивной информации в ПО из БД

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