
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
-----------------------------------------------------------------------------------------------------
CREATE TABLE glossary (
    key INTEGER NOT NULL GENERATED ALWAYS AS IDENTITY ( INCREMENT 1 START 1 MINVALUE 1 MAXVALUE 2147483647 CACHE 1 ),
    configuration TEXT NOT NULL,
    communication TEXT,
    allowance FLOAT NOT NULL,
    tablename character(15) NOT NULL,
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
	%I INTEGER NOT NULL,
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
INSERT INTO number_actual (number_actual_tstamp, number_actual_val) 
SELECT NOW(), number FROM generate_series(0,149) number;

INSERT INTO float_actual (float_actual_tstamp, float_actual_val) 
SELECT NOW(), number FROM generate_series(0,149) number;

INSERT INTO number_archive (number_archive_key, number_archive_tstamp, number_archive_val) 
  SELECT
    (random()*30)::INT, tstamp, random()*80 - 40
  FROM
    generate_series(
      NOW() - INTERVAL '90 days',
      NOW(),
      '1 min'
    ) AS tstamp;

INSERT INTO float_archive (float_archive_key, float_archive_tstamp, float_archive_val) 
  SELECT
    (random()*30)::INT, tstamp, random()*80 - 40
  FROM
    generate_series(
      NOW() - INTERVAL '90 days',
      NOW(),
      '1 min'
    ) AS tstamp;
-----------------------------------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION _Refresh(xpath VARCHAR, valnew FLOAT)
RETURNS VOID AS $$
DECLARE 

	--переменные для:
	_TableName TEXT;		--значения 4-го поля таблицы glossary, формирующего _Table и _HyperTable    
	_Table TEXT;  			--имени актуальной таблицы  
	_HyperTable TEXT;		--имени соответствующей гипертаблицы
	_Allowance FLOAT;		--допуска, значения 3-его поле таблицы glossary
	_ValueOld FLOAT;		--последнего значения 3-го поля val из актуальной таблицы
	_Count INTEGER;			--числа строк в гипертаблице
	_1P FLOAT;
	_Delta FLOAT;
	_DeltaP FLOAT;
	
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
	
	--Получение allowance (допуска) из XPath таблицы glossary
	IF (SELECT EXISTS(SELECT 1 from glossary WHERE configuration = xpath)) THEN
		_Allowance := (SELECT allowance FROM glossary WHERE configuration = xpath);
	ELSE
		_Allowance := NULL;
	END IF;  
	
	--Получение последнего значения val из актуальной таблицы
	EXECUTE FORMAT('SELECT val FROM %I ORDER BY key DESC LIMIT 1', _Table) INTO _ValueOld;
	
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
			EXECUTE FORMAT('INSERT INTO %I(tstamp, val) VALUES(NOW(), %s);', _Table, valnew);
		ELSE
			EXECUTE FORMAT('UPDATE %I SET tstamp = NOW() WHERE key = (SELECT MAX(key) from %I);', _Table, _Table);
		END IF;
	ELSE
		EXECUTE FORMAT('INSERT INTO %I(tstamp, val) VALUES(NOW(), %s);', _Table, valnew);
	END IF;
		
END;

$$ LANGUAGE plpgsql;
-----------------------------------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION _Refresh(xpath VARCHAR)
RETURNS FLOAT AS $$
DECLARE 

	--переменные для:
	_Key INTEGER;			--значения ключа актуальной таблицы
	_TableName TEXT;		--значения 4-го поля таблицы glossary, формирующего _Table    
	_Table TEXT;  			--имени актуальной таблицы  
	_Value FLOAT;			--значения 3-го поля val из актуальной таблицы
	
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
			
	--Получение значения val из актуальной таблицы
	IF (_Table IS NOT NULL) THEN 
		EXECUTE FORMAT('SELECT val FROM %I WHERE key = %s;', _Table, _Key) INTO _Value;
	ELSE
		_Value := NULL;
	END IF;  
	
	RETURN _Value
						
END;

$$ LANGUAGE plpgsql;
-----------------------------------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION _Refresh(xpath VARCHAR, st TIMESTAMP, fin TIMESTAMP)
RETURNS TABLE (keya INTEGER, tstampa timestamptz, vala FLOAT) AS $$
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
	
	EXECUTE FORMAT('
	RETURN QUERY SELECT %I, %I, %I 
				   FROM %I 
				  WHERE %I BETWEEN st AND fin;
	',_KEY_archive, _TS_archive, _VAL_archive,
	  _HyperTable,
	  _TS_archive);
	/*
	RETURN QUERY SELECT float_archive_key, float_archive_tstamp, float_archive_val 
				   FROM float_archive 
				  WHERE float_archive_tstamp BETWEEN st AND fin;
	*/		
END;

$$ LANGUAGE plpgsql;
	