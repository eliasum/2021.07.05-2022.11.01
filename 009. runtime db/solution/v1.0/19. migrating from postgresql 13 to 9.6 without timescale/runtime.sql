
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
	key SERIAL NOT NULL,
	fix TIMESTAMPTZ NOT NULL,
	value %s NOT NULL,
	FOREIGN KEY (key) REFERENCES glossary(key));',
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
('ControlWorkstation/Equipment/Slot/Item[@key=''1'']/Supply/Item[@key=''Photocathode'']/Amperage', NULL, 3, 'float')
,
('ControlWorkstation/Equipment/Slot/Item[@key=''1'']/Supply/Item[@key=''Photocathode'']/Voltage', NULL, 3, 'integer')
,
('ControlWorkstation/Equipment/Slot/Item[@key=''1'']/Supply/Item[@key=''Microchannelplate1'']/Amperage', NULL, 3, 'float')
,
('ControlWorkstation/Equipment/Slot/Item[@key=''1'']/Supply/Item[@key=''Microchannelplate1'']/Voltage', NULL, 3, 'integer')
,
('ControlWorkstation/Equipment/Slot/Item[@key=''1'']/Supply/Item[@key=''Microchannelplate12'']/Amperage', NULL, 3, 'float')
,
('ControlWorkstation/Equipment/Slot/Item[@key=''1'']/Supply/Item[@key=''Microchannelplate12'']/Voltage', NULL, 3, 'integer')
,
('ControlWorkstation/Equipment/Slot/Item[@key=''1'']/Supply/Item[@key=''Microchannelplate2'']/Amperage', NULL, 3, 'float')
,
('ControlWorkstation/Equipment/Slot/Item[@key=''1'']/Supply/Item[@key=''Microchannelplate2'']/Voltage', NULL, 3, 'integer')
,
('ControlWorkstation/Equipment/Slot/Item[@key=''1'']/Supply/Item[@key=''Anode'']/Amperage', NULL, 3, 'float')
,
('ControlWorkstation/Equipment/Slot/Item[@key=''1'']/Supply/Item[@key=''Anode'']/Voltage', NULL, 3, 'integer')
,
('ControlWorkstation/Equipment/Slot/Item[@key=''2'']/Supply/Item[@key=''Photocathode'']/Amperage', NULL, 3, 'float')
,
('ControlWorkstation/Equipment/Slot/Item[@key=''2'']/Supply/Item[@key=''Photocathode'']/Voltage', NULL, 3, 'integer')
,
('ControlWorkstation/Equipment/Slot/Item[@key=''2'']/Supply/Item[@key=''Microchannelplate1'']/Amperage', NULL, 3, 'float')
,
('ControlWorkstation/Equipment/Slot/Item[@key=''2'']/Supply/Item[@key=''Microchannelplate1'']/Voltage', NULL, 3, 'integer')
,
('ControlWorkstation/Equipment/Slot/Item[@key=''2'']/Supply/Item[@key=''Microchannelplate12'']/Amperage', NULL, 3, 'float')
,
('ControlWorkstation/Equipment/Slot/Item[@key=''2'']/Supply/Item[@key=''Microchannelplate12'']/Voltage', NULL, 3, 'integer')
,
('ControlWorkstation/Equipment/Slot/Item[@key=''2'']/Supply/Item[@key=''Microchannelplate2'']/Amperage', NULL, 3, 'float')
,
('ControlWorkstation/Equipment/Slot/Item[@key=''2'']/Supply/Item[@key=''Microchannelplate2'']/Voltage', NULL, 3, 'integer')
,
('ControlWorkstation/Equipment/Slot/Item[@key=''2'']/Supply/Item[@key=''Anode'']/Amperage', NULL, 3, 'float')
,
('ControlWorkstation/Equipment/Slot/Item[@key=''2'']/Supply/Item[@key=''Anode'']/Voltage', NULL, 3, 'integer')
,
('ControlWorkstation/Equipment/Slot/Item[@key=''3'']/Supply/Item[@key=''Photocathode'']/Amperage', NULL, 3, 'float')
,
('ControlWorkstation/Equipment/Slot/Item[@key=''3'']/Supply/Item[@key=''Photocathode'']/Voltage', NULL, 3, 'integer')
,
('ControlWorkstation/Equipment/Slot/Item[@key=''3'']/Supply/Item[@key=''Microchannelplate1'']/Amperage', NULL, 3, 'float')
,
('ControlWorkstation/Equipment/Slot/Item[@key=''3'']/Supply/Item[@key=''Microchannelplate1'']/Voltage', NULL, 3, 'integer')
,
('ControlWorkstation/Equipment/Slot/Item[@key=''3'']/Supply/Item[@key=''Microchannelplate12'']/Amperage', NULL, 3, 'float')
,
('ControlWorkstation/Equipment/Slot/Item[@key=''3'']/Supply/Item[@key=''Microchannelplate12'']/Voltage', NULL, 3, 'integer')
,
('ControlWorkstation/Equipment/Slot/Item[@key=''3'']/Supply/Item[@key=''Microchannelplate2'']/Amperage', NULL, 3, 'float')
,
('ControlWorkstation/Equipment/Slot/Item[@key=''3'']/Supply/Item[@key=''Microchannelplate2'']/Voltage', NULL, 3, 'integer')
,
('ControlWorkstation/Equipment/Slot/Item[@key=''3'']/Supply/Item[@key=''Anode'']/Amperage', NULL, 3, 'float')
,
('ControlWorkstation/Equipment/Slot/Item[@key=''3'']/Supply/Item[@key=''Anode'']/Voltage', NULL, 3, 'integer')
,
('ControlWorkstation/Equipment/Slot/Item[@key=''4'']/Supply/Item[@key=''Photocathode'']/Amperage', NULL, 3, 'float')
,
('ControlWorkstation/Equipment/Slot/Item[@key=''4'']/Supply/Item[@key=''Photocathode'']/Voltage', NULL, 3, 'integer')
,
('ControlWorkstation/Equipment/Slot/Item[@key=''4'']/Supply/Item[@key=''Microchannelplate1'']/Amperage', NULL, 3, 'float')
,
('ControlWorkstation/Equipment/Slot/Item[@key=''4'']/Supply/Item[@key=''Microchannelplate1'']/Voltage', NULL, 3, 'integer')
,
('ControlWorkstation/Equipment/Slot/Item[@key=''4'']/Supply/Item[@key=''Microchannelplate12'']/Amperage', NULL, 3, 'float')
,
('ControlWorkstation/Equipment/Slot/Item[@key=''4'']/Supply/Item[@key=''Microchannelplate12'']/Voltage', NULL, 3, 'integer')
,
('ControlWorkstation/Equipment/Slot/Item[@key=''4'']/Supply/Item[@key=''Microchannelplate2'']/Amperage', NULL, 3, 'float')
,
('ControlWorkstation/Equipment/Slot/Item[@key=''4'']/Supply/Item[@key=''Microchannelplate2'']/Voltage', NULL, 3, 'integer')
,
('ControlWorkstation/Equipment/Slot/Item[@key=''4'']/Supply/Item[@key=''Anode'']/Amperage', NULL, 3, 'float')
,
('ControlWorkstation/Equipment/Slot/Item[@key=''4'']/Supply/Item[@key=''Anode'']/Voltage', NULL, 3, 'integer')
,
('ControlWorkstation/Equipment/Slot/Item[@key=''5'']/Supply/Item[@key=''Photocathode'']/Amperage', NULL, 3, 'float')
,
('ControlWorkstation/Equipment/Slot/Item[@key=''5'']/Supply/Item[@key=''Photocathode'']/Voltage', NULL, 3, 'integer')
,
('ControlWorkstation/Equipment/Slot/Item[@key=''5'']/Supply/Item[@key=''Microchannelplate1'']/Amperage', NULL, 3, 'float')
,
('ControlWorkstation/Equipment/Slot/Item[@key=''5'']/Supply/Item[@key=''Microchannelplate1'']/Voltage', NULL, 3, 'integer')
,
('ControlWorkstation/Equipment/Slot/Item[@key=''5'']/Supply/Item[@key=''Microchannelplate12'']/Amperage', NULL, 3, 'float')
,
('ControlWorkstation/Equipment/Slot/Item[@key=''5'']/Supply/Item[@key=''Microchannelplate12'']/Voltage', NULL, 3, 'integer')
,
('ControlWorkstation/Equipment/Slot/Item[@key=''5'']/Supply/Item[@key=''Microchannelplate2'']/Amperage', NULL, 3, 'float')
,
('ControlWorkstation/Equipment/Slot/Item[@key=''5'']/Supply/Item[@key=''Microchannelplate2'']/Voltage', NULL, 3, 'integer')
,
('ControlWorkstation/Equipment/Slot/Item[@key=''5'']/Supply/Item[@key=''Anode'']/Amperage', NULL, 3, 'float')
,
('ControlWorkstation/Equipment/Slot/Item[@key=''5'']/Supply/Item[@key=''Anode'']/Voltage', NULL, 3, 'integer')
,
('ControlWorkstation/Equipment/Slot/Item[@key=''6'']/Supply/Item[@key=''Photocathode'']/Amperage', NULL, 3, 'float')
,
('ControlWorkstation/Equipment/Slot/Item[@key=''6'']/Supply/Item[@key=''Photocathode'']/Voltage', NULL, 3, 'integer')
,
('ControlWorkstation/Equipment/Slot/Item[@key=''6'']/Supply/Item[@key=''Microchannelplate1'']/Amperage', NULL, 3, 'float')
,
('ControlWorkstation/Equipment/Slot/Item[@key=''6'']/Supply/Item[@key=''Microchannelplate1'']/Voltage', NULL, 3, 'integer')
,
('ControlWorkstation/Equipment/Slot/Item[@key=''6'']/Supply/Item[@key=''Microchannelplate12'']/Amperage', NULL, 3, 'float')
,
('ControlWorkstation/Equipment/Slot/Item[@key=''6'']/Supply/Item[@key=''Microchannelplate12'']/Voltage', NULL, 3, 'integer')
,
('ControlWorkstation/Equipment/Slot/Item[@key=''6'']/Supply/Item[@key=''Microchannelplate2'']/Amperage', NULL, 3, 'float')
,
('ControlWorkstation/Equipment/Slot/Item[@key=''6'']/Supply/Item[@key=''Microchannelplate2'']/Voltage', NULL, 3, 'integer')
,
('ControlWorkstation/Equipment/Slot/Item[@key=''6'']/Supply/Item[@key=''Anode'']/Amperage', NULL, 3, 'float')
,
('ControlWorkstation/Equipment/Slot/Item[@key=''6'']/Supply/Item[@key=''Anode'']/Voltage', NULL, 3, 'integer')
,
('ControlWorkstation/Equipment/Slot/Item[@key=''7'']/Supply/Item[@key=''Photocathode'']/Amperage', NULL, 3, 'float')
,
('ControlWorkstation/Equipment/Slot/Item[@key=''7'']/Supply/Item[@key=''Photocathode'']/Voltage', NULL, 3, 'integer')
,
('ControlWorkstation/Equipment/Slot/Item[@key=''7'']/Supply/Item[@key=''Microchannelplate1'']/Amperage', NULL, 3, 'float')
,
('ControlWorkstation/Equipment/Slot/Item[@key=''7'']/Supply/Item[@key=''Microchannelplate1'']/Voltage', NULL, 3, 'integer')
,
('ControlWorkstation/Equipment/Slot/Item[@key=''7'']/Supply/Item[@key=''Microchannelplate12'']/Amperage', NULL, 3, 'float')
,
('ControlWorkstation/Equipment/Slot/Item[@key=''7'']/Supply/Item[@key=''Microchannelplate12'']/Voltage', NULL, 3, 'integer')
,
('ControlWorkstation/Equipment/Slot/Item[@key=''7'']/Supply/Item[@key=''Microchannelplate2'']/Amperage', NULL, 3, 'float')
,
('ControlWorkstation/Equipment/Slot/Item[@key=''7'']/Supply/Item[@key=''Microchannelplate2'']/Voltage', NULL, 3, 'integer')
,
('ControlWorkstation/Equipment/Slot/Item[@key=''7'']/Supply/Item[@key=''Anode'']/Amperage', NULL, 3, 'float')
,
('ControlWorkstation/Equipment/Slot/Item[@key=''7'']/Supply/Item[@key=''Anode'']/Voltage', NULL, 3, 'integer')
,
('ControlWorkstation/Equipment/Slot/Item[@key=''8'']/Supply/Item[@key=''Photocathode'']/Amperage', NULL, 3, 'float')
,
('ControlWorkstation/Equipment/Slot/Item[@key=''8'']/Supply/Item[@key=''Photocathode'']/Voltage', NULL, 3, 'integer')
,
('ControlWorkstation/Equipment/Slot/Item[@key=''8'']/Supply/Item[@key=''Microchannelplate1'']/Amperage', NULL, 3, 'float')
,
('ControlWorkstation/Equipment/Slot/Item[@key=''8'']/Supply/Item[@key=''Microchannelplate1'']/Voltage', NULL, 3, 'integer')
,
('ControlWorkstation/Equipment/Slot/Item[@key=''8'']/Supply/Item[@key=''Microchannelplate12'']/Amperage', NULL, 3, 'float')
,
('ControlWorkstation/Equipment/Slot/Item[@key=''8'']/Supply/Item[@key=''Microchannelplate12'']/Voltage', NULL, 3, 'integer')
,
('ControlWorkstation/Equipment/Slot/Item[@key=''8'']/Supply/Item[@key=''Microchannelplate2'']/Amperage', NULL, 3, 'float')
,
('ControlWorkstation/Equipment/Slot/Item[@key=''8'']/Supply/Item[@key=''Microchannelplate2'']/Voltage', NULL, 3, 'integer')
,
('ControlWorkstation/Equipment/Slot/Item[@key=''8'']/Supply/Item[@key=''Anode'']/Amperage', NULL, 3, 'float')
,
('ControlWorkstation/Equipment/Slot/Item[@key=''8'']/Supply/Item[@key=''Anode'']/Voltage', NULL, 3, 'integer')
,
('ControlWorkstation/Equipment/Slot/Item[@key=''9'']/Supply/Item[@key=''Photocathode'']/Amperage', NULL, 3, 'float')
,
('ControlWorkstation/Equipment/Slot/Item[@key=''9'']/Supply/Item[@key=''Photocathode'']/Voltage', NULL, 3, 'integer')
,
('ControlWorkstation/Equipment/Slot/Item[@key=''9'']/Supply/Item[@key=''Microchannelplate1'']/Amperage', NULL, 3, 'float')
,
('ControlWorkstation/Equipment/Slot/Item[@key=''9'']/Supply/Item[@key=''Microchannelplate1'']/Voltage', NULL, 3, 'integer')
,
('ControlWorkstation/Equipment/Slot/Item[@key=''9'']/Supply/Item[@key=''Microchannelplate12'']/Amperage', NULL, 3, 'float')
,
('ControlWorkstation/Equipment/Slot/Item[@key=''9'']/Supply/Item[@key=''Microchannelplate12'']/Voltage', NULL, 3, 'integer')
,
('ControlWorkstation/Equipment/Slot/Item[@key=''9'']/Supply/Item[@key=''Microchannelplate2'']/Amperage', NULL, 3, 'float')
,
('ControlWorkstation/Equipment/Slot/Item[@key=''9'']/Supply/Item[@key=''Microchannelplate2'']/Voltage', NULL, 3, 'integer')
,
('ControlWorkstation/Equipment/Slot/Item[@key=''9'']/Supply/Item[@key=''Anode'']/Amperage', NULL, 3, 'float')
,
('ControlWorkstation/Equipment/Slot/Item[@key=''9'']/Supply/Item[@key=''Anode'']/Voltage', NULL, 3, 'integer')
,
('ControlWorkstation/Equipment/Slot/Item[@key=''10'']/Supply/Item[@key=''Photocathode'']/Amperage', NULL, 3, 'float')
,
('ControlWorkstation/Equipment/Slot/Item[@key=''10'']/Supply/Item[@key=''Photocathode'']/Voltage', NULL, 3, 'integer')
,
('ControlWorkstation/Equipment/Slot/Item[@key=''10'']/Supply/Item[@key=''Microchannelplate1'']/Amperage', NULL, 3, 'float')
,
('ControlWorkstation/Equipment/Slot/Item[@key=''10'']/Supply/Item[@key=''Microchannelplate1'']/Voltage', NULL, 3, 'integer')
,
('ControlWorkstation/Equipment/Slot/Item[@key=''10'']/Supply/Item[@key=''Microchannelplate12'']/Amperage', NULL, 3, 'float')
,
('ControlWorkstation/Equipment/Slot/Item[@key=''10'']/Supply/Item[@key=''Microchannelplate12'']/Voltage', NULL, 3, 'integer')
,
('ControlWorkstation/Equipment/Slot/Item[@key=''10'']/Supply/Item[@key=''Microchannelplate2'']/Amperage', NULL, 3, 'float')
,
('ControlWorkstation/Equipment/Slot/Item[@key=''10'']/Supply/Item[@key=''Microchannelplate2'']/Voltage', NULL, 3, 'integer')
,
('ControlWorkstation/Equipment/Slot/Item[@key=''10'']/Supply/Item[@key=''Anode'']/Amperage', NULL, 3, 'float')
,
('ControlWorkstation/Equipment/Slot/Item[@key=''10'']/Supply/Item[@key=''Anode'']/Voltage', NULL, 3, 'integer')
,
('ControlWorkstation/Equipment/Slot/Item[@key=''11'']/Supply/Item[@key=''Photocathode'']/Amperage', NULL, 3, 'float')
,
('ControlWorkstation/Equipment/Slot/Item[@key=''11'']/Supply/Item[@key=''Photocathode'']/Voltage', NULL, 3, 'integer')
,
('ControlWorkstation/Equipment/Slot/Item[@key=''11'']/Supply/Item[@key=''Microchannelplate1'']/Amperage', NULL, 3, 'float')
,
('ControlWorkstation/Equipment/Slot/Item[@key=''11'']/Supply/Item[@key=''Microchannelplate1'']/Voltage', NULL, 3, 'integer')
,
('ControlWorkstation/Equipment/Slot/Item[@key=''11'']/Supply/Item[@key=''Microchannelplate12'']/Amperage', NULL, 3, 'float')
,
('ControlWorkstation/Equipment/Slot/Item[@key=''11'']/Supply/Item[@key=''Microchannelplate12'']/Voltage', NULL, 3, 'integer')
,
('ControlWorkstation/Equipment/Slot/Item[@key=''11'']/Supply/Item[@key=''Microchannelplate2'']/Amperage', NULL, 3, 'float')
,
('ControlWorkstation/Equipment/Slot/Item[@key=''11'']/Supply/Item[@key=''Microchannelplate2'']/Voltage', NULL, 3, 'integer')
,
('ControlWorkstation/Equipment/Slot/Item[@key=''11'']/Supply/Item[@key=''Anode'']/Amperage', NULL, 3, 'float')
,
('ControlWorkstation/Equipment/Slot/Item[@key=''11'']/Supply/Item[@key=''Anode'']/Voltage', NULL, 3, 'integer')
,
('ControlWorkstation/Equipment/Slot/Item[@key=''12'']/Supply/Item[@key=''Photocathode'']/Amperage', NULL, 3, 'float')
,
('ControlWorkstation/Equipment/Slot/Item[@key=''12'']/Supply/Item[@key=''Photocathode'']/Voltage', NULL, 3, 'integer')
,
('ControlWorkstation/Equipment/Slot/Item[@key=''12'']/Supply/Item[@key=''Microchannelplate1'']/Amperage', NULL, 3, 'float')
,
('ControlWorkstation/Equipment/Slot/Item[@key=''12'']/Supply/Item[@key=''Microchannelplate1'']/Voltage', NULL, 3, 'integer')
,
('ControlWorkstation/Equipment/Slot/Item[@key=''12'']/Supply/Item[@key=''Microchannelplate12'']/Amperage', NULL, 3, 'float')
,
('ControlWorkstation/Equipment/Slot/Item[@key=''12'']/Supply/Item[@key=''Microchannelplate12'']/Voltage', NULL, 3, 'integer')
,
('ControlWorkstation/Equipment/Slot/Item[@key=''12'']/Supply/Item[@key=''Microchannelplate2'']/Amperage', NULL, 3, 'float')
,
('ControlWorkstation/Equipment/Slot/Item[@key=''12'']/Supply/Item[@key=''Microchannelplate2'']/Voltage', NULL, 3, 'integer')
,
('ControlWorkstation/Equipment/Slot/Item[@key=''12'']/Supply/Item[@key=''Anode'']/Amperage', NULL, 3, 'float')
,
('ControlWorkstation/Equipment/Slot/Item[@key=''12'']/Supply/Item[@key=''Anode'']/Voltage', NULL, 3, 'integer')
,
('ControlWorkstation/Equipment/Slot/Item[@key=''13'']/Supply/Item[@key=''Photocathode'']/Amperage', NULL, 3, 'float')
,
('ControlWorkstation/Equipment/Slot/Item[@key=''13'']/Supply/Item[@key=''Photocathode'']/Voltage', NULL, 3, 'integer')
,
('ControlWorkstation/Equipment/Slot/Item[@key=''13'']/Supply/Item[@key=''Microchannelplate1'']/Amperage', NULL, 3, 'float')
,
('ControlWorkstation/Equipment/Slot/Item[@key=''13'']/Supply/Item[@key=''Microchannelplate1'']/Voltage', NULL, 3, 'integer')
,
('ControlWorkstation/Equipment/Slot/Item[@key=''13'']/Supply/Item[@key=''Microchannelplate12'']/Amperage', NULL, 3, 'float')
,
('ControlWorkstation/Equipment/Slot/Item[@key=''13'']/Supply/Item[@key=''Microchannelplate12'']/Voltage', NULL, 3, 'integer')
,
('ControlWorkstation/Equipment/Slot/Item[@key=''13'']/Supply/Item[@key=''Microchannelplate2'']/Amperage', NULL, 3, 'float')
,
('ControlWorkstation/Equipment/Slot/Item[@key=''13'']/Supply/Item[@key=''Microchannelplate2'']/Voltage', NULL, 3, 'integer')
,
('ControlWorkstation/Equipment/Slot/Item[@key=''13'']/Supply/Item[@key=''Anode'']/Amperage', NULL, 3, 'float')
,
('ControlWorkstation/Equipment/Slot/Item[@key=''13'']/Supply/Item[@key=''Anode'']/Voltage', NULL, 3, 'integer')
,
('ControlWorkstation/Equipment/Slot/Item[@key=''14'']/Supply/Item[@key=''Photocathode'']/Amperage', NULL, 3, 'float')
,
('ControlWorkstation/Equipment/Slot/Item[@key=''14'']/Supply/Item[@key=''Photocathode'']/Voltage', NULL, 3, 'integer')
,
('ControlWorkstation/Equipment/Slot/Item[@key=''14'']/Supply/Item[@key=''Microchannelplate1'']/Amperage', NULL, 3, 'float')
,
('ControlWorkstation/Equipment/Slot/Item[@key=''14'']/Supply/Item[@key=''Microchannelplate1'']/Voltage', NULL, 3, 'integer')
,
('ControlWorkstation/Equipment/Slot/Item[@key=''14'']/Supply/Item[@key=''Microchannelplate12'']/Amperage', NULL, 3, 'float')
,
('ControlWorkstation/Equipment/Slot/Item[@key=''14'']/Supply/Item[@key=''Microchannelplate12'']/Voltage', NULL, 3, 'integer')
,
('ControlWorkstation/Equipment/Slot/Item[@key=''14'']/Supply/Item[@key=''Microchannelplate2'']/Amperage', NULL, 3, 'float')
,
('ControlWorkstation/Equipment/Slot/Item[@key=''14'']/Supply/Item[@key=''Microchannelplate2'']/Voltage', NULL, 3, 'integer')
,
('ControlWorkstation/Equipment/Slot/Item[@key=''14'']/Supply/Item[@key=''Anode'']/Amperage', NULL, 3, 'float')
,
('ControlWorkstation/Equipment/Slot/Item[@key=''14'']/Supply/Item[@key=''Anode'']/Voltage', NULL, 3, 'integer')
,
('ControlWorkstation/Equipment/Slot/Item[@key=''15'']/Supply/Item[@key=''Photocathode'']/Amperage', NULL, 3, 'float')
,
('ControlWorkstation/Equipment/Slot/Item[@key=''15'']/Supply/Item[@key=''Photocathode'']/Voltage', NULL, 3, 'integer')
,
('ControlWorkstation/Equipment/Slot/Item[@key=''15'']/Supply/Item[@key=''Microchannelplate1'']/Amperage', NULL, 3, 'float')
,
('ControlWorkstation/Equipment/Slot/Item[@key=''15'']/Supply/Item[@key=''Microchannelplate1'']/Voltage', NULL, 3, 'integer')
,
('ControlWorkstation/Equipment/Slot/Item[@key=''15'']/Supply/Item[@key=''Microchannelplate12'']/Amperage', NULL, 3, 'float')
,
('ControlWorkstation/Equipment/Slot/Item[@key=''15'']/Supply/Item[@key=''Microchannelplate12'']/Voltage', NULL, 3, 'integer')
,
('ControlWorkstation/Equipment/Slot/Item[@key=''15'']/Supply/Item[@key=''Microchannelplate2'']/Amperage', NULL, 3, 'float')
,
('ControlWorkstation/Equipment/Slot/Item[@key=''15'']/Supply/Item[@key=''Microchannelplate2'']/Voltage', NULL, 3, 'integer')
,
('ControlWorkstation/Equipment/Slot/Item[@key=''15'']/Supply/Item[@key=''Anode'']/Amperage', NULL, 3, 'float')
,
('ControlWorkstation/Equipment/Slot/Item[@key=''15'']/Supply/Item[@key=''Anode'']/Voltage', NULL, 3, 'integer')
,
('ControlWorkstation/Equipment/Slot/Item[@key=''16'']/Supply/Item[@key=''Photocathode'']/Amperage', NULL, 3, 'float')
,
('ControlWorkstation/Equipment/Slot/Item[@key=''16'']/Supply/Item[@key=''Photocathode'']/Voltage', NULL, 3, 'integer')
,
('ControlWorkstation/Equipment/Slot/Item[@key=''16'']/Supply/Item[@key=''Microchannelplate1'']/Amperage', NULL, 3, 'float')
,
('ControlWorkstation/Equipment/Slot/Item[@key=''16'']/Supply/Item[@key=''Microchannelplate1'']/Voltage', NULL, 3, 'integer')
,
('ControlWorkstation/Equipment/Slot/Item[@key=''16'']/Supply/Item[@key=''Microchannelplate12'']/Amperage', NULL, 3, 'float')
,
('ControlWorkstation/Equipment/Slot/Item[@key=''16'']/Supply/Item[@key=''Microchannelplate12'']/Voltage', NULL, 3, 'integer')
,
('ControlWorkstation/Equipment/Slot/Item[@key=''16'']/Supply/Item[@key=''Microchannelplate2'']/Amperage', NULL, 3, 'float')
,
('ControlWorkstation/Equipment/Slot/Item[@key=''16'']/Supply/Item[@key=''Microchannelplate2'']/Voltage', NULL, 3, 'integer')
,
('ControlWorkstation/Equipment/Slot/Item[@key=''16'']/Supply/Item[@key=''Anode'']/Amperage', NULL, 3, 'float')
,
('ControlWorkstation/Equipment/Slot/Item[@key=''16'']/Supply/Item[@key=''Anode'']/Voltage', NULL, 3, 'integer')
,
('ControlWorkstation/Equipment/Slot/Item[@key=''17'']/Supply/Item[@key=''Photocathode'']/Amperage', NULL, 3, 'float')
,
('ControlWorkstation/Equipment/Slot/Item[@key=''17'']/Supply/Item[@key=''Photocathode'']/Voltage', NULL, 3, 'integer')
,
('ControlWorkstation/Equipment/Slot/Item[@key=''17'']/Supply/Item[@key=''Microchannelplate1'']/Amperage', NULL, 3, 'float')
,
('ControlWorkstation/Equipment/Slot/Item[@key=''17'']/Supply/Item[@key=''Microchannelplate1'']/Voltage', NULL, 3, 'integer')
,
('ControlWorkstation/Equipment/Slot/Item[@key=''17'']/Supply/Item[@key=''Microchannelplate12'']/Amperage', NULL, 3, 'float')
,
('ControlWorkstation/Equipment/Slot/Item[@key=''17'']/Supply/Item[@key=''Microchannelplate12'']/Voltage', NULL, 3, 'integer')
,
('ControlWorkstation/Equipment/Slot/Item[@key=''17'']/Supply/Item[@key=''Microchannelplate2'']/Amperage', NULL, 3, 'float')
,
('ControlWorkstation/Equipment/Slot/Item[@key=''17'']/Supply/Item[@key=''Microchannelplate2'']/Voltage', NULL, 3, 'integer')
,
('ControlWorkstation/Equipment/Slot/Item[@key=''17'']/Supply/Item[@key=''Anode'']/Amperage', NULL, 3, 'float')
,
('ControlWorkstation/Equipment/Slot/Item[@key=''17'']/Supply/Item[@key=''Anode'']/Voltage', NULL, 3, 'integer')
,
('ControlWorkstation/Equipment/Slot/Item[@key=''18'']/Supply/Item[@key=''Photocathode'']/Amperage', NULL, 3, 'float')
,
('ControlWorkstation/Equipment/Slot/Item[@key=''18'']/Supply/Item[@key=''Photocathode'']/Voltage', NULL, 3, 'integer')
,
('ControlWorkstation/Equipment/Slot/Item[@key=''18'']/Supply/Item[@key=''Microchannelplate1'']/Amperage', NULL, 3, 'float')
,
('ControlWorkstation/Equipment/Slot/Item[@key=''18'']/Supply/Item[@key=''Microchannelplate1'']/Voltage', NULL, 3, 'integer')
,
('ControlWorkstation/Equipment/Slot/Item[@key=''18'']/Supply/Item[@key=''Microchannelplate12'']/Amperage', NULL, 3, 'float')
,
('ControlWorkstation/Equipment/Slot/Item[@key=''18'']/Supply/Item[@key=''Microchannelplate12'']/Voltage', NULL, 3, 'integer')
,
('ControlWorkstation/Equipment/Slot/Item[@key=''18'']/Supply/Item[@key=''Microchannelplate2'']/Amperage', NULL, 3, 'float')
,
('ControlWorkstation/Equipment/Slot/Item[@key=''18'']/Supply/Item[@key=''Microchannelplate2'']/Voltage', NULL, 3, 'integer')
,
('ControlWorkstation/Equipment/Slot/Item[@key=''18'']/Supply/Item[@key=''Anode'']/Amperage', NULL, 3, 'float')
,
('ControlWorkstation/Equipment/Slot/Item[@key=''18'']/Supply/Item[@key=''Anode'']/Voltage', NULL, 3, 'integer')
,
('ControlWorkstation/Equipment/Slot/Item[@key=''19'']/Supply/Item[@key=''Photocathode'']/Amperage', NULL, 3, 'float')
,
('ControlWorkstation/Equipment/Slot/Item[@key=''19'']/Supply/Item[@key=''Photocathode'']/Voltage', NULL, 3, 'integer')
,
('ControlWorkstation/Equipment/Slot/Item[@key=''19'']/Supply/Item[@key=''Microchannelplate1'']/Amperage', NULL, 3, 'float')
,
('ControlWorkstation/Equipment/Slot/Item[@key=''19'']/Supply/Item[@key=''Microchannelplate1'']/Voltage', NULL, 3, 'integer')
,
('ControlWorkstation/Equipment/Slot/Item[@key=''19'']/Supply/Item[@key=''Microchannelplate12'']/Amperage', NULL, 3, 'float')
,
('ControlWorkstation/Equipment/Slot/Item[@key=''19'']/Supply/Item[@key=''Microchannelplate12'']/Voltage', NULL, 3, 'integer')
,
('ControlWorkstation/Equipment/Slot/Item[@key=''19'']/Supply/Item[@key=''Microchannelplate2'']/Amperage', NULL, 3, 'float')
,
('ControlWorkstation/Equipment/Slot/Item[@key=''19'']/Supply/Item[@key=''Microchannelplate2'']/Voltage', NULL, 3, 'integer')
,
('ControlWorkstation/Equipment/Slot/Item[@key=''19'']/Supply/Item[@key=''Anode'']/Amperage', NULL, 3, 'float')
,
('ControlWorkstation/Equipment/Slot/Item[@key=''19'']/Supply/Item[@key=''Anode'']/Voltage', NULL, 3, 'integer')
,
('ControlWorkstation/Equipment/Slot/Item[@key=''20'']/Supply/Item[@key=''Photocathode'']/Amperage', NULL, 3, 'float')
,
('ControlWorkstation/Equipment/Slot/Item[@key=''20'']/Supply/Item[@key=''Photocathode'']/Voltage', NULL, 3, 'integer')
,
('ControlWorkstation/Equipment/Slot/Item[@key=''20'']/Supply/Item[@key=''Microchannelplate1'']/Amperage', NULL, 3, 'float')
,
('ControlWorkstation/Equipment/Slot/Item[@key=''20'']/Supply/Item[@key=''Microchannelplate1'']/Voltage', NULL, 3, 'integer')
,
('ControlWorkstation/Equipment/Slot/Item[@key=''20'']/Supply/Item[@key=''Microchannelplate12'']/Amperage', NULL, 3, 'float')
,
('ControlWorkstation/Equipment/Slot/Item[@key=''20'']/Supply/Item[@key=''Microchannelplate12'']/Voltage', NULL, 3, 'integer')
,
('ControlWorkstation/Equipment/Slot/Item[@key=''20'']/Supply/Item[@key=''Microchannelplate2'']/Amperage', NULL, 3, 'float')
,
('ControlWorkstation/Equipment/Slot/Item[@key=''20'']/Supply/Item[@key=''Microchannelplate2'']/Voltage', NULL, 3, 'integer')
,
('ControlWorkstation/Equipment/Slot/Item[@key=''20'']/Supply/Item[@key=''Anode'']/Amperage', NULL, 3, 'float')
,
('ControlWorkstation/Equipment/Slot/Item[@key=''20'']/Supply/Item[@key=''Anode'']/Voltage', NULL, 3, 'integer')
,
('ControlWorkstation/Equipment/Slot/Item[@key=''21'']/Supply/Item[@key=''Photocathode'']/Amperage', NULL, 3, 'float')
,
('ControlWorkstation/Equipment/Slot/Item[@key=''21'']/Supply/Item[@key=''Photocathode'']/Voltage', NULL, 3, 'integer')
,
('ControlWorkstation/Equipment/Slot/Item[@key=''21'']/Supply/Item[@key=''Microchannelplate1'']/Amperage', NULL, 3, 'float')
,
('ControlWorkstation/Equipment/Slot/Item[@key=''21'']/Supply/Item[@key=''Microchannelplate1'']/Voltage', NULL, 3, 'integer')
,
('ControlWorkstation/Equipment/Slot/Item[@key=''21'']/Supply/Item[@key=''Microchannelplate12'']/Amperage', NULL, 3, 'float')
,
('ControlWorkstation/Equipment/Slot/Item[@key=''21'']/Supply/Item[@key=''Microchannelplate12'']/Voltage', NULL, 3, 'integer')
,
('ControlWorkstation/Equipment/Slot/Item[@key=''21'']/Supply/Item[@key=''Microchannelplate2'']/Amperage', NULL, 3, 'float')
,
('ControlWorkstation/Equipment/Slot/Item[@key=''21'']/Supply/Item[@key=''Microchannelplate2'']/Voltage', NULL, 3, 'integer')
,
('ControlWorkstation/Equipment/Slot/Item[@key=''21'']/Supply/Item[@key=''Anode'']/Amperage', NULL, 3, 'float')
,
('ControlWorkstation/Equipment/Slot/Item[@key=''21'']/Supply/Item[@key=''Anode'']/Voltage', NULL, 3, 'integer')
,
('ControlWorkstation/Equipment/Slot/Item[@key=''22'']/Supply/Item[@key=''Photocathode'']/Amperage', NULL, 3, 'float')
,
('ControlWorkstation/Equipment/Slot/Item[@key=''22'']/Supply/Item[@key=''Photocathode'']/Voltage', NULL, 3, 'integer')
,
('ControlWorkstation/Equipment/Slot/Item[@key=''22'']/Supply/Item[@key=''Microchannelplate1'']/Amperage', NULL, 3, 'float')
,
('ControlWorkstation/Equipment/Slot/Item[@key=''22'']/Supply/Item[@key=''Microchannelplate1'']/Voltage', NULL, 3, 'integer')
,
('ControlWorkstation/Equipment/Slot/Item[@key=''22'']/Supply/Item[@key=''Microchannelplate12'']/Amperage', NULL, 3, 'float')
,
('ControlWorkstation/Equipment/Slot/Item[@key=''22'']/Supply/Item[@key=''Microchannelplate12'']/Voltage', NULL, 3, 'integer')
,
('ControlWorkstation/Equipment/Slot/Item[@key=''22'']/Supply/Item[@key=''Microchannelplate2'']/Amperage', NULL, 3, 'float')
,
('ControlWorkstation/Equipment/Slot/Item[@key=''22'']/Supply/Item[@key=''Microchannelplate2'']/Voltage', NULL, 3, 'integer')
,
('ControlWorkstation/Equipment/Slot/Item[@key=''22'']/Supply/Item[@key=''Anode'']/Amperage', NULL, 3, 'float')
,
('ControlWorkstation/Equipment/Slot/Item[@key=''22'']/Supply/Item[@key=''Anode'']/Voltage', NULL, 3, 'integer')
,
('ControlWorkstation/Equipment/Slot/Item[@key=''23'']/Supply/Item[@key=''Photocathode'']/Amperage', NULL, 3, 'float')
,
('ControlWorkstation/Equipment/Slot/Item[@key=''23'']/Supply/Item[@key=''Photocathode'']/Voltage', NULL, 3, 'integer')
,
('ControlWorkstation/Equipment/Slot/Item[@key=''23'']/Supply/Item[@key=''Microchannelplate1'']/Amperage', NULL, 3, 'float')
,
('ControlWorkstation/Equipment/Slot/Item[@key=''23'']/Supply/Item[@key=''Microchannelplate1'']/Voltage', NULL, 3, 'integer')
,
('ControlWorkstation/Equipment/Slot/Item[@key=''23'']/Supply/Item[@key=''Microchannelplate12'']/Amperage', NULL, 3, 'float')
,
('ControlWorkstation/Equipment/Slot/Item[@key=''23'']/Supply/Item[@key=''Microchannelplate12'']/Voltage', NULL, 3, 'integer')
,
('ControlWorkstation/Equipment/Slot/Item[@key=''23'']/Supply/Item[@key=''Microchannelplate2'']/Amperage', NULL, 3, 'float')
,
('ControlWorkstation/Equipment/Slot/Item[@key=''23'']/Supply/Item[@key=''Microchannelplate2'']/Voltage', NULL, 3, 'integer')
,
('ControlWorkstation/Equipment/Slot/Item[@key=''23'']/Supply/Item[@key=''Anode'']/Amperage', NULL, 3, 'float')
,
('ControlWorkstation/Equipment/Slot/Item[@key=''23'']/Supply/Item[@key=''Anode'']/Voltage', NULL, 3, 'integer')
,
('ControlWorkstation/Equipment/Slot/Item[@key=''24'']/Supply/Item[@key=''Photocathode'']/Amperage', NULL, 3, 'float')
,
('ControlWorkstation/Equipment/Slot/Item[@key=''24'']/Supply/Item[@key=''Photocathode'']/Voltage', NULL, 3, 'integer')
,
('ControlWorkstation/Equipment/Slot/Item[@key=''24'']/Supply/Item[@key=''Microchannelplate1'']/Amperage', NULL, 3, 'float')
,
('ControlWorkstation/Equipment/Slot/Item[@key=''24'']/Supply/Item[@key=''Microchannelplate1'']/Voltage', NULL, 3, 'integer')
,
('ControlWorkstation/Equipment/Slot/Item[@key=''24'']/Supply/Item[@key=''Microchannelplate12'']/Amperage', NULL, 3, 'float')
,
('ControlWorkstation/Equipment/Slot/Item[@key=''24'']/Supply/Item[@key=''Microchannelplate12'']/Voltage', NULL, 3, 'integer')
,
('ControlWorkstation/Equipment/Slot/Item[@key=''24'']/Supply/Item[@key=''Microchannelplate2'']/Amperage', NULL, 3, 'float')
,
('ControlWorkstation/Equipment/Slot/Item[@key=''24'']/Supply/Item[@key=''Microchannelplate2'']/Voltage', NULL, 3, 'integer')
,
('ControlWorkstation/Equipment/Slot/Item[@key=''24'']/Supply/Item[@key=''Anode'']/Amperage', NULL, 3, 'float')
,
('ControlWorkstation/Equipment/Slot/Item[@key=''24'']/Supply/Item[@key=''Anode'']/Voltage', NULL, 3, 'integer')
,
('ControlWorkstation/Equipment/Slot/Item[@key=''25'']/Supply/Item[@key=''Photocathode'']/Amperage', NULL, 3, 'float')
,
('ControlWorkstation/Equipment/Slot/Item[@key=''25'']/Supply/Item[@key=''Photocathode'']/Voltage', NULL, 3, 'integer')
,
('ControlWorkstation/Equipment/Slot/Item[@key=''25'']/Supply/Item[@key=''Microchannelplate1'']/Amperage', NULL, 3, 'float')
,
('ControlWorkstation/Equipment/Slot/Item[@key=''25'']/Supply/Item[@key=''Microchannelplate1'']/Voltage', NULL, 3, 'integer')
,
('ControlWorkstation/Equipment/Slot/Item[@key=''25'']/Supply/Item[@key=''Microchannelplate12'']/Amperage', NULL, 3, 'float')
,
('ControlWorkstation/Equipment/Slot/Item[@key=''25'']/Supply/Item[@key=''Microchannelplate12'']/Voltage', NULL, 3, 'integer')
,
('ControlWorkstation/Equipment/Slot/Item[@key=''25'']/Supply/Item[@key=''Microchannelplate2'']/Amperage', NULL, 3, 'float')
,
('ControlWorkstation/Equipment/Slot/Item[@key=''25'']/Supply/Item[@key=''Microchannelplate2'']/Voltage', NULL, 3, 'integer')
,
('ControlWorkstation/Equipment/Slot/Item[@key=''25'']/Supply/Item[@key=''Anode'']/Amperage', NULL, 3, 'float')
,
('ControlWorkstation/Equipment/Slot/Item[@key=''25'']/Supply/Item[@key=''Anode'']/Voltage', NULL, 3, 'integer')
,
('ControlWorkstation/Equipment/Slot/Item[@key=''26'']/Supply/Item[@key=''Photocathode'']/Amperage', NULL, 3, 'float')
,
('ControlWorkstation/Equipment/Slot/Item[@key=''26'']/Supply/Item[@key=''Photocathode'']/Voltage', NULL, 3, 'integer')
,
('ControlWorkstation/Equipment/Slot/Item[@key=''26'']/Supply/Item[@key=''Microchannelplate1'']/Amperage', NULL, 3, 'float')
,
('ControlWorkstation/Equipment/Slot/Item[@key=''26'']/Supply/Item[@key=''Microchannelplate1'']/Voltage', NULL, 3, 'integer')
,
('ControlWorkstation/Equipment/Slot/Item[@key=''26'']/Supply/Item[@key=''Microchannelplate12'']/Amperage', NULL, 3, 'float')
,
('ControlWorkstation/Equipment/Slot/Item[@key=''26'']/Supply/Item[@key=''Microchannelplate12'']/Voltage', NULL, 3, 'integer')
,
('ControlWorkstation/Equipment/Slot/Item[@key=''26'']/Supply/Item[@key=''Microchannelplate2'']/Amperage', NULL, 3, 'float')
,
('ControlWorkstation/Equipment/Slot/Item[@key=''26'']/Supply/Item[@key=''Microchannelplate2'']/Voltage', NULL, 3, 'integer')
,
('ControlWorkstation/Equipment/Slot/Item[@key=''26'']/Supply/Item[@key=''Anode'']/Amperage', NULL, 3, 'float')
,
('ControlWorkstation/Equipment/Slot/Item[@key=''26'']/Supply/Item[@key=''Anode'']/Voltage', NULL, 3, 'integer')
,
('ControlWorkstation/Equipment/Slot/Item[@key=''27'']/Supply/Item[@key=''Photocathode'']/Amperage', NULL, 3, 'float')
,
('ControlWorkstation/Equipment/Slot/Item[@key=''27'']/Supply/Item[@key=''Photocathode'']/Voltage', NULL, 3, 'integer')
,
('ControlWorkstation/Equipment/Slot/Item[@key=''27'']/Supply/Item[@key=''Microchannelplate1'']/Amperage', NULL, 3, 'float')
,
('ControlWorkstation/Equipment/Slot/Item[@key=''27'']/Supply/Item[@key=''Microchannelplate1'']/Voltage', NULL, 3, 'integer')
,
('ControlWorkstation/Equipment/Slot/Item[@key=''27'']/Supply/Item[@key=''Microchannelplate12'']/Amperage', NULL, 3, 'float')
,
('ControlWorkstation/Equipment/Slot/Item[@key=''27'']/Supply/Item[@key=''Microchannelplate12'']/Voltage', NULL, 3, 'integer')
,
('ControlWorkstation/Equipment/Slot/Item[@key=''27'']/Supply/Item[@key=''Microchannelplate2'']/Amperage', NULL, 3, 'float')
,
('ControlWorkstation/Equipment/Slot/Item[@key=''27'']/Supply/Item[@key=''Microchannelplate2'']/Voltage', NULL, 3, 'integer')
,
('ControlWorkstation/Equipment/Slot/Item[@key=''27'']/Supply/Item[@key=''Anode'']/Amperage', NULL, 3, 'float')
,
('ControlWorkstation/Equipment/Slot/Item[@key=''27'']/Supply/Item[@key=''Anode'']/Voltage', NULL, 3, 'integer')
,
('ControlWorkstation/Equipment/Slot/Item[@key=''28'']/Supply/Item[@key=''Photocathode'']/Amperage', NULL, 3, 'float')
,
('ControlWorkstation/Equipment/Slot/Item[@key=''28'']/Supply/Item[@key=''Photocathode'']/Voltage', NULL, 3, 'integer')
,
('ControlWorkstation/Equipment/Slot/Item[@key=''28'']/Supply/Item[@key=''Microchannelplate1'']/Amperage', NULL, 3, 'float')
,
('ControlWorkstation/Equipment/Slot/Item[@key=''28'']/Supply/Item[@key=''Microchannelplate1'']/Voltage', NULL, 3, 'integer')
,
('ControlWorkstation/Equipment/Slot/Item[@key=''28'']/Supply/Item[@key=''Microchannelplate12'']/Amperage', NULL, 3, 'float')
,
('ControlWorkstation/Equipment/Slot/Item[@key=''28'']/Supply/Item[@key=''Microchannelplate12'']/Voltage', NULL, 3, 'integer')
,
('ControlWorkstation/Equipment/Slot/Item[@key=''28'']/Supply/Item[@key=''Microchannelplate2'']/Amperage', NULL, 3, 'float')
,
('ControlWorkstation/Equipment/Slot/Item[@key=''28'']/Supply/Item[@key=''Microchannelplate2'']/Voltage', NULL, 3, 'integer')
,
('ControlWorkstation/Equipment/Slot/Item[@key=''28'']/Supply/Item[@key=''Anode'']/Amperage', NULL, 3, 'float')
,
('ControlWorkstation/Equipment/Slot/Item[@key=''28'']/Supply/Item[@key=''Anode'']/Voltage', NULL, 3, 'integer')
,
('ControlWorkstation/Equipment/Slot/Item[@key=''29'']/Supply/Item[@key=''Photocathode'']/Amperage', NULL, 3, 'float')
,
('ControlWorkstation/Equipment/Slot/Item[@key=''29'']/Supply/Item[@key=''Photocathode'']/Voltage', NULL, 3, 'integer')
,
('ControlWorkstation/Equipment/Slot/Item[@key=''29'']/Supply/Item[@key=''Microchannelplate1'']/Amperage', NULL, 3, 'float')
,
('ControlWorkstation/Equipment/Slot/Item[@key=''29'']/Supply/Item[@key=''Microchannelplate1'']/Voltage', NULL, 3, 'integer')
,
('ControlWorkstation/Equipment/Slot/Item[@key=''29'']/Supply/Item[@key=''Microchannelplate12'']/Amperage', NULL, 3, 'float')
,
('ControlWorkstation/Equipment/Slot/Item[@key=''29'']/Supply/Item[@key=''Microchannelplate12'']/Voltage', NULL, 3, 'integer')
,
('ControlWorkstation/Equipment/Slot/Item[@key=''29'']/Supply/Item[@key=''Microchannelplate2'']/Amperage', NULL, 3, 'float')
,
('ControlWorkstation/Equipment/Slot/Item[@key=''29'']/Supply/Item[@key=''Microchannelplate2'']/Voltage', NULL, 3, 'integer')
,
('ControlWorkstation/Equipment/Slot/Item[@key=''29'']/Supply/Item[@key=''Anode'']/Amperage', NULL, 3, 'float')
,
('ControlWorkstation/Equipment/Slot/Item[@key=''29'']/Supply/Item[@key=''Anode'']/Voltage', NULL, 3, 'integer')
,
('ControlWorkstation/Equipment/Slot/Item[@key=''30'']/Supply/Item[@key=''Photocathode'']/Amperage', NULL, 3, 'float')
,
('ControlWorkstation/Equipment/Slot/Item[@key=''30'']/Supply/Item[@key=''Photocathode'']/Voltage', NULL, 3, 'integer')
,
('ControlWorkstation/Equipment/Slot/Item[@key=''30'']/Supply/Item[@key=''Microchannelplate1'']/Amperage', NULL, 3, 'float')
,
('ControlWorkstation/Equipment/Slot/Item[@key=''30'']/Supply/Item[@key=''Microchannelplate1'']/Voltage', NULL, 3, 'integer')
,
('ControlWorkstation/Equipment/Slot/Item[@key=''30'']/Supply/Item[@key=''Microchannelplate12'']/Amperage', NULL, 3, 'float')
,
('ControlWorkstation/Equipment/Slot/Item[@key=''30'']/Supply/Item[@key=''Microchannelplate12'']/Voltage', NULL, 3, 'integer')
,
('ControlWorkstation/Equipment/Slot/Item[@key=''30'']/Supply/Item[@key=''Microchannelplate2'']/Amperage', NULL, 3, 'float')
,
('ControlWorkstation/Equipment/Slot/Item[@key=''30'']/Supply/Item[@key=''Microchannelplate2'']/Voltage', NULL, 3, 'integer')
,
('ControlWorkstation/Equipment/Slot/Item[@key=''30'']/Supply/Item[@key=''Anode'']/Amperage', NULL, 3, 'float')
,
('ControlWorkstation/Equipment/Slot/Item[@key=''30'']/Supply/Item[@key=''Anode'']/Voltage', NULL, 3, 'integer')
;
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