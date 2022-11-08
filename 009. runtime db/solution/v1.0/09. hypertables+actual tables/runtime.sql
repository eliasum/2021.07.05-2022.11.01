
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
CREATE TABLE table_Number(
  key_Number integer NOT NULL,
  tstamp timestamptz NOT NULL);

SELECT create_hypertable(
  'table_Number', 'tstamp',
  chunk_time_interval => INTERVAL '1 day'
);

CREATE TABLE NumberActual(
  NumberActKey integer NOT NULL,
  tstamp timestamptz NOT NULL,
  CONSTRAINT "NumberActualKey" PRIMARY KEY (NumberActKey),
  FOREIGN KEY (NumberActKey) REFERENCES table_Glossary(key));
/*-------------------------------------------------------------------------------------------------*/
CREATE TABLE table_Float(
  key_Float integer NOT NULL,
  tstamp timestamptz NOT NULL);

SELECT create_hypertable(
  'table_Float', 'tstamp',
  chunk_time_interval => INTERVAL '1 day'
);
	
CREATE TABLE FloatActual(
  FloatActKey integer NOT NULL,
  tstamp timestamptz NOT NULL,
  CONSTRAINT "FloatActualKey" PRIMARY KEY (FloatActKey),
  FOREIGN KEY (FloatActKey) REFERENCES table_Glossary(key));
 /*-------------------------------------------------------------------------------------------------*/
 CREATE TABLE table_Decimal(
  key_Decimal integer NOT NULL,
  tstamp timestamptz NOT NULL);

SELECT create_hypertable(
  'table_Decimal', 'tstamp',
  chunk_time_interval => INTERVAL '1 day'
);
	
CREATE TABLE DecimalActual(
  DecimalActKey integer NOT NULL,
  tstamp timestamptz NOT NULL,
  CONSTRAINT "DecimalActualKey" PRIMARY KEY (DecimalActKey),
  FOREIGN KEY (DecimalActKey) REFERENCES table_Glossary(key));
 /*-------------------------------------------------------------------------------------------------*/
  CREATE TABLE table_String(
  key_String integer NOT NULL,
  tstamp timestamptz NOT NULL);

SELECT create_hypertable(
  'table_String', 'tstamp',
  chunk_time_interval => INTERVAL '1 day'
);
	
CREATE TABLE StringActual(
  StringActKey integer NOT NULL,
  tstamp timestamptz NOT NULL,
  CONSTRAINT "StringActualKey" PRIMARY KEY (StringActKey),
  FOREIGN KEY (StringActKey) REFERENCES table_Glossary(key));
 /*-------------------------------------------------------------------------------------------------*/
INSERT INTO table_Glossary (configuration, communication, allowance, tablename) VALUES 
('ControlWorkstation/Equipment/Slot/Item[@key=''1'']/Supply/Item[@key=''Photocathode'']/Amperage', NULL, 3, 'table_Float'),
('ControlWorkstation/Equipment/Slot/Item[@key=''1'']/Supply/Item[@key=''Photocathode'']/Voltage', NULL, 3, 'table_Number'),
('ControlWorkstation/Equipment/Slot/Item[@key=''1'']/Supply/Item[@key=''Microchannelplate1'']/Amperage', NULL, 3, 'table_Float'),
('ControlWorkstation/Equipment/Slot/Item[@key=''1'']/Supply/Item[@key=''Microchannelplate1'']/Voltage', NULL, 3, 'table_Number'),
('ControlWorkstation/Equipment/Slot/Item[@key=''1'']/Supply/Item[@key=''Microchannelplate12'']/Amperage', NULL, 3, 'table_Float'),
('ControlWorkstation/Equipment/Slot/Item[@key=''1'']/Supply/Item[@key=''Microchannelplate12'']/Voltage', NULL, 3, 'table_Number'),
('ControlWorkstation/Equipment/Slot/Item[@key=''1'']/Supply/Item[@key=''Microchannelplate2'']/Amperage', NULL, 3, 'table_Float'),
('ControlWorkstation/Equipment/Slot/Item[@key=''1'']/Supply/Item[@key=''Microchannelplate2'']/Voltage', NULL, 3, 'table_Number'),
('ControlWorkstation/Equipment/Slot/Item[@key=''1'']/Supply/Item[@key=''Anode'']/Amperage', NULL, 3, 'table_Float'),
('ControlWorkstation/Equipment/Slot/Item[@key=''1'']/Supply/Item[@key=''Anode'']/Voltage', NULL, 3, 'table_Number'),
('ControlWorkstation/Equipment/Slot/Item[@key=''2'']/Supply/Item[@key=''Photocathode'']/Amperage', NULL, 3, 'table_Float'),
('ControlWorkstation/Equipment/Slot/Item[@key=''2'']/Supply/Item[@key=''Photocathode'']/Voltage', NULL, 3, 'table_Number'),
('ControlWorkstation/Equipment/Slot/Item[@key=''2'']/Supply/Item[@key=''Microchannelplate1'']/Amperage', NULL, 3, 'table_Float'),
('ControlWorkstation/Equipment/Slot/Item[@key=''2'']/Supply/Item[@key=''Microchannelplate1'']/Voltage', NULL, 3, 'table_Number'),
('ControlWorkstation/Equipment/Slot/Item[@key=''2'']/Supply/Item[@key=''Microchannelplate12'']/Amperage', NULL, 3, 'table_Float'),
('ControlWorkstation/Equipment/Slot/Item[@key=''2'']/Supply/Item[@key=''Microchannelplate12'']/Voltage', NULL, 3, 'table_Number'),
('ControlWorkstation/Equipment/Slot/Item[@key=''2'']/Supply/Item[@key=''Microchannelplate2'']/Amperage', NULL, 3, 'table_Float'),
('ControlWorkstation/Equipment/Slot/Item[@key=''2'']/Supply/Item[@key=''Microchannelplate2'']/Voltage', NULL, 3, 'table_Number'),
('ControlWorkstation/Equipment/Slot/Item[@key=''2'']/Supply/Item[@key=''Anode'']/Amperage', NULL, 3, 'table_Float'),
('ControlWorkstation/Equipment/Slot/Item[@key=''2'']/Supply/Item[@key=''Anode'']/Voltage', NULL, 3, 'table_Number'),
('ControlWorkstation/Equipment/Slot/Item[@key=''3'']/Supply/Item[@key=''Photocathode'']/Amperage', NULL, 3, 'table_Float'),
('ControlWorkstation/Equipment/Slot/Item[@key=''3'']/Supply/Item[@key=''Photocathode'']/Voltage', NULL, 3, 'table_Number'),
('ControlWorkstation/Equipment/Slot/Item[@key=''3'']/Supply/Item[@key=''Microchannelplate1'']/Amperage', NULL, 3, 'table_Float'),
('ControlWorkstation/Equipment/Slot/Item[@key=''3'']/Supply/Item[@key=''Microchannelplate1'']/Voltage', NULL, 3, 'table_Number'),
('ControlWorkstation/Equipment/Slot/Item[@key=''3'']/Supply/Item[@key=''Microchannelplate12'']/Amperage', NULL, 3, 'table_Float'),
('ControlWorkstation/Equipment/Slot/Item[@key=''3'']/Supply/Item[@key=''Microchannelplate12'']/Voltage', NULL, 3, 'table_Number'),
('ControlWorkstation/Equipment/Slot/Item[@key=''3'']/Supply/Item[@key=''Microchannelplate2'']/Amperage', NULL, 3, 'table_Float'),
('ControlWorkstation/Equipment/Slot/Item[@key=''3'']/Supply/Item[@key=''Microchannelplate2'']/Voltage', NULL, 3, 'table_Number'),
('ControlWorkstation/Equipment/Slot/Item[@key=''3'']/Supply/Item[@key=''Anode'']/Amperage', NULL, 3, 'table_Float'),
('ControlWorkstation/Equipment/Slot/Item[@key=''3'']/Supply/Item[@key=''Anode'']/Voltage', NULL, 3, 'table_Number'),
('ControlWorkstation/Equipment/Slot/Item[@key=''4'']/Supply/Item[@key=''Photocathode'']/Amperage', NULL, 3, 'table_Float'),
('ControlWorkstation/Equipment/Slot/Item[@key=''4'']/Supply/Item[@key=''Photocathode'']/Voltage', NULL, 3, 'table_Number'),
('ControlWorkstation/Equipment/Slot/Item[@key=''4'']/Supply/Item[@key=''Microchannelplate1'']/Amperage', NULL, 3, 'table_Float'),
('ControlWorkstation/Equipment/Slot/Item[@key=''4'']/Supply/Item[@key=''Microchannelplate1'']/Voltage', NULL, 3, 'table_Number'),
('ControlWorkstation/Equipment/Slot/Item[@key=''4'']/Supply/Item[@key=''Microchannelplate12'']/Amperage', NULL, 3, 'table_Float'),
('ControlWorkstation/Equipment/Slot/Item[@key=''4'']/Supply/Item[@key=''Microchannelplate12'']/Voltage', NULL, 3, 'table_Number'),
('ControlWorkstation/Equipment/Slot/Item[@key=''4'']/Supply/Item[@key=''Microchannelplate2'']/Amperage', NULL, 3, 'table_Float'),
('ControlWorkstation/Equipment/Slot/Item[@key=''4'']/Supply/Item[@key=''Microchannelplate2'']/Voltage', NULL, 3, 'table_Number'),
('ControlWorkstation/Equipment/Slot/Item[@key=''4'']/Supply/Item[@key=''Anode'']/Amperage', NULL, 3, 'table_Float'),
('ControlWorkstation/Equipment/Slot/Item[@key=''4'']/Supply/Item[@key=''Anode'']/Voltage', NULL, 3, 'table_Number'),
('ControlWorkstation/Equipment/Slot/Item[@key=''5'']/Supply/Item[@key=''Photocathode'']/Amperage', NULL, 3, 'table_Float'),
('ControlWorkstation/Equipment/Slot/Item[@key=''5'']/Supply/Item[@key=''Photocathode'']/Voltage', NULL, 3, 'table_Number'),
('ControlWorkstation/Equipment/Slot/Item[@key=''5'']/Supply/Item[@key=''Microchannelplate1'']/Amperage', NULL, 3, 'table_Float'),
('ControlWorkstation/Equipment/Slot/Item[@key=''5'']/Supply/Item[@key=''Microchannelplate1'']/Voltage', NULL, 3, 'table_Number'),
('ControlWorkstation/Equipment/Slot/Item[@key=''5'']/Supply/Item[@key=''Microchannelplate12'']/Amperage', NULL, 3, 'table_Float'),
('ControlWorkstation/Equipment/Slot/Item[@key=''5'']/Supply/Item[@key=''Microchannelplate12'']/Voltage', NULL, 3, 'table_Number'),
('ControlWorkstation/Equipment/Slot/Item[@key=''5'']/Supply/Item[@key=''Microchannelplate2'']/Amperage', NULL, 3, 'table_Float'),
('ControlWorkstation/Equipment/Slot/Item[@key=''5'']/Supply/Item[@key=''Microchannelplate2'']/Voltage', NULL, 3, 'table_Number'),
('ControlWorkstation/Equipment/Slot/Item[@key=''5'']/Supply/Item[@key=''Anode'']/Amperage', NULL, 3, 'table_Float'),
('ControlWorkstation/Equipment/Slot/Item[@key=''5'']/Supply/Item[@key=''Anode'']/Voltage', NULL, 3, 'table_Number'),
('ControlWorkstation/Equipment/Slot/Item[@key=''6'']/Supply/Item[@key=''Photocathode'']/Amperage', NULL, 3, 'table_Float'),
('ControlWorkstation/Equipment/Slot/Item[@key=''6'']/Supply/Item[@key=''Photocathode'']/Voltage', NULL, 3, 'table_Number'),
('ControlWorkstation/Equipment/Slot/Item[@key=''6'']/Supply/Item[@key=''Microchannelplate1'']/Amperage', NULL, 3, 'table_Float'),
('ControlWorkstation/Equipment/Slot/Item[@key=''6'']/Supply/Item[@key=''Microchannelplate1'']/Voltage', NULL, 3, 'table_Number'),
('ControlWorkstation/Equipment/Slot/Item[@key=''6'']/Supply/Item[@key=''Microchannelplate12'']/Amperage', NULL, 3, 'table_Float'),
('ControlWorkstation/Equipment/Slot/Item[@key=''6'']/Supply/Item[@key=''Microchannelplate12'']/Voltage', NULL, 3, 'table_Number'),
('ControlWorkstation/Equipment/Slot/Item[@key=''6'']/Supply/Item[@key=''Microchannelplate2'']/Amperage', NULL, 3, 'table_Float'),
('ControlWorkstation/Equipment/Slot/Item[@key=''6'']/Supply/Item[@key=''Microchannelplate2'']/Voltage', NULL, 3, 'table_Number'),
('ControlWorkstation/Equipment/Slot/Item[@key=''6'']/Supply/Item[@key=''Anode'']/Amperage', NULL, 3, 'table_Float'),
('ControlWorkstation/Equipment/Slot/Item[@key=''6'']/Supply/Item[@key=''Anode'']/Voltage', NULL, 3, 'table_Number'),
('ControlWorkstation/Equipment/Slot/Item[@key=''7'']/Supply/Item[@key=''Photocathode'']/Amperage', NULL, 3, 'table_Float'),
('ControlWorkstation/Equipment/Slot/Item[@key=''7'']/Supply/Item[@key=''Photocathode'']/Voltage', NULL, 3, 'table_Number'),
('ControlWorkstation/Equipment/Slot/Item[@key=''7'']/Supply/Item[@key=''Microchannelplate1'']/Amperage', NULL, 3, 'table_Float'),
('ControlWorkstation/Equipment/Slot/Item[@key=''7'']/Supply/Item[@key=''Microchannelplate1'']/Voltage', NULL, 3, 'table_Number'),
('ControlWorkstation/Equipment/Slot/Item[@key=''7'']/Supply/Item[@key=''Microchannelplate12'']/Amperage', NULL, 3, 'table_Float'),
('ControlWorkstation/Equipment/Slot/Item[@key=''7'']/Supply/Item[@key=''Microchannelplate12'']/Voltage', NULL, 3, 'table_Number'),
('ControlWorkstation/Equipment/Slot/Item[@key=''7'']/Supply/Item[@key=''Microchannelplate2'']/Amperage', NULL, 3, 'table_Float'),
('ControlWorkstation/Equipment/Slot/Item[@key=''7'']/Supply/Item[@key=''Microchannelplate2'']/Voltage', NULL, 3, 'table_Number'),
('ControlWorkstation/Equipment/Slot/Item[@key=''7'']/Supply/Item[@key=''Anode'']/Amperage', NULL, 3, 'table_Float'),
('ControlWorkstation/Equipment/Slot/Item[@key=''7'']/Supply/Item[@key=''Anode'']/Voltage', NULL, 3, 'table_Number'),
('ControlWorkstation/Equipment/Slot/Item[@key=''8'']/Supply/Item[@key=''Photocathode'']/Amperage', NULL, 3, 'table_Float'),
('ControlWorkstation/Equipment/Slot/Item[@key=''8'']/Supply/Item[@key=''Photocathode'']/Voltage', NULL, 3, 'table_Number'),
('ControlWorkstation/Equipment/Slot/Item[@key=''8'']/Supply/Item[@key=''Microchannelplate1'']/Amperage', NULL, 3, 'table_Float'),
('ControlWorkstation/Equipment/Slot/Item[@key=''8'']/Supply/Item[@key=''Microchannelplate1'']/Voltage', NULL, 3, 'table_Number'),
('ControlWorkstation/Equipment/Slot/Item[@key=''8'']/Supply/Item[@key=''Microchannelplate12'']/Amperage', NULL, 3, 'table_Float'),
('ControlWorkstation/Equipment/Slot/Item[@key=''8'']/Supply/Item[@key=''Microchannelplate12'']/Voltage', NULL, 3, 'table_Number'),
('ControlWorkstation/Equipment/Slot/Item[@key=''8'']/Supply/Item[@key=''Microchannelplate2'']/Amperage', NULL, 3, 'table_Float'),
('ControlWorkstation/Equipment/Slot/Item[@key=''8'']/Supply/Item[@key=''Microchannelplate2'']/Voltage', NULL, 3, 'table_Number'),
('ControlWorkstation/Equipment/Slot/Item[@key=''8'']/Supply/Item[@key=''Anode'']/Amperage', NULL, 3, 'table_Float'),
('ControlWorkstation/Equipment/Slot/Item[@key=''8'']/Supply/Item[@key=''Anode'']/Voltage', NULL, 3, 'table_Number'),
('ControlWorkstation/Equipment/Slot/Item[@key=''9'']/Supply/Item[@key=''Photocathode'']/Amperage', NULL, 3, 'table_Float'),
('ControlWorkstation/Equipment/Slot/Item[@key=''9'']/Supply/Item[@key=''Photocathode'']/Voltage', NULL, 3, 'table_Number'),
('ControlWorkstation/Equipment/Slot/Item[@key=''9'']/Supply/Item[@key=''Microchannelplate1'']/Amperage', NULL, 3, 'table_Float'),
('ControlWorkstation/Equipment/Slot/Item[@key=''9'']/Supply/Item[@key=''Microchannelplate1'']/Voltage', NULL, 3, 'table_Number'),
('ControlWorkstation/Equipment/Slot/Item[@key=''9'']/Supply/Item[@key=''Microchannelplate12'']/Amperage', NULL, 3, 'table_Float'),
('ControlWorkstation/Equipment/Slot/Item[@key=''9'']/Supply/Item[@key=''Microchannelplate12'']/Voltage', NULL, 3, 'table_Number'),
('ControlWorkstation/Equipment/Slot/Item[@key=''9'']/Supply/Item[@key=''Microchannelplate2'']/Amperage', NULL, 3, 'table_Float'),
('ControlWorkstation/Equipment/Slot/Item[@key=''9'']/Supply/Item[@key=''Microchannelplate2'']/Voltage', NULL, 3, 'table_Number'),
('ControlWorkstation/Equipment/Slot/Item[@key=''9'']/Supply/Item[@key=''Anode'']/Amperage', NULL, 3, 'table_Float'),
('ControlWorkstation/Equipment/Slot/Item[@key=''9'']/Supply/Item[@key=''Anode'']/Voltage', NULL, 3, 'table_Number'),
('ControlWorkstation/Equipment/Slot/Item[@key=''10'']/Supply/Item[@key=''Photocathode'']/Amperage', NULL, 3, 'table_Float'),
('ControlWorkstation/Equipment/Slot/Item[@key=''10'']/Supply/Item[@key=''Photocathode'']/Voltage', NULL, 3, 'table_Number'),
('ControlWorkstation/Equipment/Slot/Item[@key=''10'']/Supply/Item[@key=''Microchannelplate1'']/Amperage', NULL, 3, 'table_Float'),
('ControlWorkstation/Equipment/Slot/Item[@key=''10'']/Supply/Item[@key=''Microchannelplate1'']/Voltage', NULL, 3, 'table_Number'),
('ControlWorkstation/Equipment/Slot/Item[@key=''10'']/Supply/Item[@key=''Microchannelplate12'']/Amperage', NULL, 3, 'table_Float'),
('ControlWorkstation/Equipment/Slot/Item[@key=''10'']/Supply/Item[@key=''Microchannelplate12'']/Voltage', NULL, 3, 'table_Number'),
('ControlWorkstation/Equipment/Slot/Item[@key=''10'']/Supply/Item[@key=''Microchannelplate2'']/Amperage', NULL, 3, 'table_Float'),
('ControlWorkstation/Equipment/Slot/Item[@key=''10'']/Supply/Item[@key=''Microchannelplate2'']/Voltage', NULL, 3, 'table_Number'),
('ControlWorkstation/Equipment/Slot/Item[@key=''10'']/Supply/Item[@key=''Anode'']/Amperage', NULL, 3, 'table_Float'),
('ControlWorkstation/Equipment/Slot/Item[@key=''10'']/Supply/Item[@key=''Anode'']/Voltage', NULL, 3, 'table_Number'),
('ControlWorkstation/Equipment/Slot/Item[@key=''11'']/Supply/Item[@key=''Photocathode'']/Amperage', NULL, 3, 'table_Float'),
('ControlWorkstation/Equipment/Slot/Item[@key=''11'']/Supply/Item[@key=''Photocathode'']/Voltage', NULL, 3, 'table_Number'),
('ControlWorkstation/Equipment/Slot/Item[@key=''11'']/Supply/Item[@key=''Microchannelplate1'']/Amperage', NULL, 3, 'table_Float'),
('ControlWorkstation/Equipment/Slot/Item[@key=''11'']/Supply/Item[@key=''Microchannelplate1'']/Voltage', NULL, 3, 'table_Number'),
('ControlWorkstation/Equipment/Slot/Item[@key=''11'']/Supply/Item[@key=''Microchannelplate12'']/Amperage', NULL, 3, 'table_Float'),
('ControlWorkstation/Equipment/Slot/Item[@key=''11'']/Supply/Item[@key=''Microchannelplate12'']/Voltage', NULL, 3, 'table_Number'),
('ControlWorkstation/Equipment/Slot/Item[@key=''11'']/Supply/Item[@key=''Microchannelplate2'']/Amperage', NULL, 3, 'table_Float'),
('ControlWorkstation/Equipment/Slot/Item[@key=''11'']/Supply/Item[@key=''Microchannelplate2'']/Voltage', NULL, 3, 'table_Number'),
('ControlWorkstation/Equipment/Slot/Item[@key=''11'']/Supply/Item[@key=''Anode'']/Amperage', NULL, 3, 'table_Float'),
('ControlWorkstation/Equipment/Slot/Item[@key=''11'']/Supply/Item[@key=''Anode'']/Voltage', NULL, 3, 'table_Number'),
('ControlWorkstation/Equipment/Slot/Item[@key=''12'']/Supply/Item[@key=''Photocathode'']/Amperage', NULL, 3, 'table_Float'),
('ControlWorkstation/Equipment/Slot/Item[@key=''12'']/Supply/Item[@key=''Photocathode'']/Voltage', NULL, 3, 'table_Number'),
('ControlWorkstation/Equipment/Slot/Item[@key=''12'']/Supply/Item[@key=''Microchannelplate1'']/Amperage', NULL, 3, 'table_Float'),
('ControlWorkstation/Equipment/Slot/Item[@key=''12'']/Supply/Item[@key=''Microchannelplate1'']/Voltage', NULL, 3, 'table_Number'),
('ControlWorkstation/Equipment/Slot/Item[@key=''12'']/Supply/Item[@key=''Microchannelplate12'']/Amperage', NULL, 3, 'table_Float'),
('ControlWorkstation/Equipment/Slot/Item[@key=''12'']/Supply/Item[@key=''Microchannelplate12'']/Voltage', NULL, 3, 'table_Number'),
('ControlWorkstation/Equipment/Slot/Item[@key=''12'']/Supply/Item[@key=''Microchannelplate2'']/Amperage', NULL, 3, 'table_Float'),
('ControlWorkstation/Equipment/Slot/Item[@key=''12'']/Supply/Item[@key=''Microchannelplate2'']/Voltage', NULL, 3, 'table_Number'),
('ControlWorkstation/Equipment/Slot/Item[@key=''12'']/Supply/Item[@key=''Anode'']/Amperage', NULL, 3, 'table_Float'),
('ControlWorkstation/Equipment/Slot/Item[@key=''12'']/Supply/Item[@key=''Anode'']/Voltage', NULL, 3, 'table_Number'),
('ControlWorkstation/Equipment/Slot/Item[@key=''13'']/Supply/Item[@key=''Photocathode'']/Amperage', NULL, 3, 'table_Float'),
('ControlWorkstation/Equipment/Slot/Item[@key=''13'']/Supply/Item[@key=''Photocathode'']/Voltage', NULL, 3, 'table_Number'),
('ControlWorkstation/Equipment/Slot/Item[@key=''13'']/Supply/Item[@key=''Microchannelplate1'']/Amperage', NULL, 3, 'table_Float'),
('ControlWorkstation/Equipment/Slot/Item[@key=''13'']/Supply/Item[@key=''Microchannelplate1'']/Voltage', NULL, 3, 'table_Number'),
('ControlWorkstation/Equipment/Slot/Item[@key=''13'']/Supply/Item[@key=''Microchannelplate12'']/Amperage', NULL, 3, 'table_Float'),
('ControlWorkstation/Equipment/Slot/Item[@key=''13'']/Supply/Item[@key=''Microchannelplate12'']/Voltage', NULL, 3, 'table_Number'),
('ControlWorkstation/Equipment/Slot/Item[@key=''13'']/Supply/Item[@key=''Microchannelplate2'']/Amperage', NULL, 3, 'table_Float'),
('ControlWorkstation/Equipment/Slot/Item[@key=''13'']/Supply/Item[@key=''Microchannelplate2'']/Voltage', NULL, 3, 'table_Number'),
('ControlWorkstation/Equipment/Slot/Item[@key=''13'']/Supply/Item[@key=''Anode'']/Amperage', NULL, 3, 'table_Float'),
('ControlWorkstation/Equipment/Slot/Item[@key=''13'']/Supply/Item[@key=''Anode'']/Voltage', NULL, 3, 'table_Number'),
('ControlWorkstation/Equipment/Slot/Item[@key=''14'']/Supply/Item[@key=''Photocathode'']/Amperage', NULL, 3, 'table_Float'),
('ControlWorkstation/Equipment/Slot/Item[@key=''14'']/Supply/Item[@key=''Photocathode'']/Voltage', NULL, 3, 'table_Number'),
('ControlWorkstation/Equipment/Slot/Item[@key=''14'']/Supply/Item[@key=''Microchannelplate1'']/Amperage', NULL, 3, 'table_Float'),
('ControlWorkstation/Equipment/Slot/Item[@key=''14'']/Supply/Item[@key=''Microchannelplate1'']/Voltage', NULL, 3, 'table_Number'),
('ControlWorkstation/Equipment/Slot/Item[@key=''14'']/Supply/Item[@key=''Microchannelplate12'']/Amperage', NULL, 3, 'table_Float'),
('ControlWorkstation/Equipment/Slot/Item[@key=''14'']/Supply/Item[@key=''Microchannelplate12'']/Voltage', NULL, 3, 'table_Number'),
('ControlWorkstation/Equipment/Slot/Item[@key=''14'']/Supply/Item[@key=''Microchannelplate2'']/Amperage', NULL, 3, 'table_Float'),
('ControlWorkstation/Equipment/Slot/Item[@key=''14'']/Supply/Item[@key=''Microchannelplate2'']/Voltage', NULL, 3, 'table_Number'),
('ControlWorkstation/Equipment/Slot/Item[@key=''14'']/Supply/Item[@key=''Anode'']/Amperage', NULL, 3, 'table_Float'),
('ControlWorkstation/Equipment/Slot/Item[@key=''14'']/Supply/Item[@key=''Anode'']/Voltage', NULL, 3, 'table_Number'),
('ControlWorkstation/Equipment/Slot/Item[@key=''15'']/Supply/Item[@key=''Photocathode'']/Amperage', NULL, 3, 'table_Float'),
('ControlWorkstation/Equipment/Slot/Item[@key=''15'']/Supply/Item[@key=''Photocathode'']/Voltage', NULL, 3, 'table_Number'),
('ControlWorkstation/Equipment/Slot/Item[@key=''15'']/Supply/Item[@key=''Microchannelplate1'']/Amperage', NULL, 3, 'table_Float'),
('ControlWorkstation/Equipment/Slot/Item[@key=''15'']/Supply/Item[@key=''Microchannelplate1'']/Voltage', NULL, 3, 'table_Number'),
('ControlWorkstation/Equipment/Slot/Item[@key=''15'']/Supply/Item[@key=''Microchannelplate12'']/Amperage', NULL, 3, 'table_Float'),
('ControlWorkstation/Equipment/Slot/Item[@key=''15'']/Supply/Item[@key=''Microchannelplate12'']/Voltage', NULL, 3, 'table_Number'),
('ControlWorkstation/Equipment/Slot/Item[@key=''15'']/Supply/Item[@key=''Microchannelplate2'']/Amperage', NULL, 3, 'table_Float'),
('ControlWorkstation/Equipment/Slot/Item[@key=''15'']/Supply/Item[@key=''Microchannelplate2'']/Voltage', NULL, 3, 'table_Number'),
('ControlWorkstation/Equipment/Slot/Item[@key=''15'']/Supply/Item[@key=''Anode'']/Amperage', NULL, 3, 'table_Float'),
('ControlWorkstation/Equipment/Slot/Item[@key=''15'']/Supply/Item[@key=''Anode'']/Voltage', NULL, 3, 'table_Number'),
('ControlWorkstation/Equipment/Slot/Item[@key=''16'']/Supply/Item[@key=''Photocathode'']/Amperage', NULL, 3, 'table_Float'),
('ControlWorkstation/Equipment/Slot/Item[@key=''16'']/Supply/Item[@key=''Photocathode'']/Voltage', NULL, 3, 'table_Number'),
('ControlWorkstation/Equipment/Slot/Item[@key=''16'']/Supply/Item[@key=''Microchannelplate1'']/Amperage', NULL, 3, 'table_Float'),
('ControlWorkstation/Equipment/Slot/Item[@key=''16'']/Supply/Item[@key=''Microchannelplate1'']/Voltage', NULL, 3, 'table_Number'),
('ControlWorkstation/Equipment/Slot/Item[@key=''16'']/Supply/Item[@key=''Microchannelplate12'']/Amperage', NULL, 3, 'table_Float'),
('ControlWorkstation/Equipment/Slot/Item[@key=''16'']/Supply/Item[@key=''Microchannelplate12'']/Voltage', NULL, 3, 'table_Number'),
('ControlWorkstation/Equipment/Slot/Item[@key=''16'']/Supply/Item[@key=''Microchannelplate2'']/Amperage', NULL, 3, 'table_Float'),
('ControlWorkstation/Equipment/Slot/Item[@key=''16'']/Supply/Item[@key=''Microchannelplate2'']/Voltage', NULL, 3, 'table_Number'),
('ControlWorkstation/Equipment/Slot/Item[@key=''16'']/Supply/Item[@key=''Anode'']/Amperage', NULL, 3, 'table_Float'),
('ControlWorkstation/Equipment/Slot/Item[@key=''16'']/Supply/Item[@key=''Anode'']/Voltage', NULL, 3, 'table_Number'),
('ControlWorkstation/Equipment/Slot/Item[@key=''17'']/Supply/Item[@key=''Photocathode'']/Amperage', NULL, 3, 'table_Float'),
('ControlWorkstation/Equipment/Slot/Item[@key=''17'']/Supply/Item[@key=''Photocathode'']/Voltage', NULL, 3, 'table_Number'),
('ControlWorkstation/Equipment/Slot/Item[@key=''17'']/Supply/Item[@key=''Microchannelplate1'']/Amperage', NULL, 3, 'table_Float'),
('ControlWorkstation/Equipment/Slot/Item[@key=''17'']/Supply/Item[@key=''Microchannelplate1'']/Voltage', NULL, 3, 'table_Number'),
('ControlWorkstation/Equipment/Slot/Item[@key=''17'']/Supply/Item[@key=''Microchannelplate12'']/Amperage', NULL, 3, 'table_Float'),
('ControlWorkstation/Equipment/Slot/Item[@key=''17'']/Supply/Item[@key=''Microchannelplate12'']/Voltage', NULL, 3, 'table_Number'),
('ControlWorkstation/Equipment/Slot/Item[@key=''17'']/Supply/Item[@key=''Microchannelplate2'']/Amperage', NULL, 3, 'table_Float'),
('ControlWorkstation/Equipment/Slot/Item[@key=''17'']/Supply/Item[@key=''Microchannelplate2'']/Voltage', NULL, 3, 'table_Number'),
('ControlWorkstation/Equipment/Slot/Item[@key=''17'']/Supply/Item[@key=''Anode'']/Amperage', NULL, 3, 'table_Float'),
('ControlWorkstation/Equipment/Slot/Item[@key=''17'']/Supply/Item[@key=''Anode'']/Voltage', NULL, 3, 'table_Number'),
('ControlWorkstation/Equipment/Slot/Item[@key=''18'']/Supply/Item[@key=''Photocathode'']/Amperage', NULL, 3, 'table_Float'),
('ControlWorkstation/Equipment/Slot/Item[@key=''18'']/Supply/Item[@key=''Photocathode'']/Voltage', NULL, 3, 'table_Number'),
('ControlWorkstation/Equipment/Slot/Item[@key=''18'']/Supply/Item[@key=''Microchannelplate1'']/Amperage', NULL, 3, 'table_Float'),
('ControlWorkstation/Equipment/Slot/Item[@key=''18'']/Supply/Item[@key=''Microchannelplate1'']/Voltage', NULL, 3, 'table_Number'),
('ControlWorkstation/Equipment/Slot/Item[@key=''18'']/Supply/Item[@key=''Microchannelplate12'']/Amperage', NULL, 3, 'table_Float'),
('ControlWorkstation/Equipment/Slot/Item[@key=''18'']/Supply/Item[@key=''Microchannelplate12'']/Voltage', NULL, 3, 'table_Number'),
('ControlWorkstation/Equipment/Slot/Item[@key=''18'']/Supply/Item[@key=''Microchannelplate2'']/Amperage', NULL, 3, 'table_Float'),
('ControlWorkstation/Equipment/Slot/Item[@key=''18'']/Supply/Item[@key=''Microchannelplate2'']/Voltage', NULL, 3, 'table_Number'),
('ControlWorkstation/Equipment/Slot/Item[@key=''18'']/Supply/Item[@key=''Anode'']/Amperage', NULL, 3, 'table_Float'),
('ControlWorkstation/Equipment/Slot/Item[@key=''18'']/Supply/Item[@key=''Anode'']/Voltage', NULL, 3, 'table_Number'),
('ControlWorkstation/Equipment/Slot/Item[@key=''19'']/Supply/Item[@key=''Photocathode'']/Amperage', NULL, 3, 'table_Float'),
('ControlWorkstation/Equipment/Slot/Item[@key=''19'']/Supply/Item[@key=''Photocathode'']/Voltage', NULL, 3, 'table_Number'),
('ControlWorkstation/Equipment/Slot/Item[@key=''19'']/Supply/Item[@key=''Microchannelplate1'']/Amperage', NULL, 3, 'table_Float'),
('ControlWorkstation/Equipment/Slot/Item[@key=''19'']/Supply/Item[@key=''Microchannelplate1'']/Voltage', NULL, 3, 'table_Number'),
('ControlWorkstation/Equipment/Slot/Item[@key=''19'']/Supply/Item[@key=''Microchannelplate12'']/Amperage', NULL, 3, 'table_Float'),
('ControlWorkstation/Equipment/Slot/Item[@key=''19'']/Supply/Item[@key=''Microchannelplate12'']/Voltage', NULL, 3, 'table_Number'),
('ControlWorkstation/Equipment/Slot/Item[@key=''19'']/Supply/Item[@key=''Microchannelplate2'']/Amperage', NULL, 3, 'table_Float'),
('ControlWorkstation/Equipment/Slot/Item[@key=''19'']/Supply/Item[@key=''Microchannelplate2'']/Voltage', NULL, 3, 'table_Number'),
('ControlWorkstation/Equipment/Slot/Item[@key=''19'']/Supply/Item[@key=''Anode'']/Amperage', NULL, 3, 'table_Float'),
('ControlWorkstation/Equipment/Slot/Item[@key=''19'']/Supply/Item[@key=''Anode'']/Voltage', NULL, 3, 'table_Number'),
('ControlWorkstation/Equipment/Slot/Item[@key=''20'']/Supply/Item[@key=''Photocathode'']/Amperage', NULL, 3, 'table_Float'),
('ControlWorkstation/Equipment/Slot/Item[@key=''20'']/Supply/Item[@key=''Photocathode'']/Voltage', NULL, 3, 'table_Number'),
('ControlWorkstation/Equipment/Slot/Item[@key=''20'']/Supply/Item[@key=''Microchannelplate1'']/Amperage', NULL, 3, 'table_Float'),
('ControlWorkstation/Equipment/Slot/Item[@key=''20'']/Supply/Item[@key=''Microchannelplate1'']/Voltage', NULL, 3, 'table_Number'),
('ControlWorkstation/Equipment/Slot/Item[@key=''20'']/Supply/Item[@key=''Microchannelplate12'']/Amperage', NULL, 3, 'table_Float'),
('ControlWorkstation/Equipment/Slot/Item[@key=''20'']/Supply/Item[@key=''Microchannelplate12'']/Voltage', NULL, 3, 'table_Number'),
('ControlWorkstation/Equipment/Slot/Item[@key=''20'']/Supply/Item[@key=''Microchannelplate2'']/Amperage', NULL, 3, 'table_Float'),
('ControlWorkstation/Equipment/Slot/Item[@key=''20'']/Supply/Item[@key=''Microchannelplate2'']/Voltage', NULL, 3, 'table_Number'),
('ControlWorkstation/Equipment/Slot/Item[@key=''20'']/Supply/Item[@key=''Anode'']/Amperage', NULL, 3, 'table_Float'),
('ControlWorkstation/Equipment/Slot/Item[@key=''20'']/Supply/Item[@key=''Anode'']/Voltage', NULL, 3, 'table_Number'),
('ControlWorkstation/Equipment/Slot/Item[@key=''21'']/Supply/Item[@key=''Photocathode'']/Amperage', NULL, 3, 'table_Float'),
('ControlWorkstation/Equipment/Slot/Item[@key=''21'']/Supply/Item[@key=''Photocathode'']/Voltage', NULL, 3, 'table_Number'),
('ControlWorkstation/Equipment/Slot/Item[@key=''21'']/Supply/Item[@key=''Microchannelplate1'']/Amperage', NULL, 3, 'table_Float'),
('ControlWorkstation/Equipment/Slot/Item[@key=''21'']/Supply/Item[@key=''Microchannelplate1'']/Voltage', NULL, 3, 'table_Number'),
('ControlWorkstation/Equipment/Slot/Item[@key=''21'']/Supply/Item[@key=''Microchannelplate12'']/Amperage', NULL, 3, 'table_Float'),
('ControlWorkstation/Equipment/Slot/Item[@key=''21'']/Supply/Item[@key=''Microchannelplate12'']/Voltage', NULL, 3, 'table_Number'),
('ControlWorkstation/Equipment/Slot/Item[@key=''21'']/Supply/Item[@key=''Microchannelplate2'']/Amperage', NULL, 3, 'table_Float'),
('ControlWorkstation/Equipment/Slot/Item[@key=''21'']/Supply/Item[@key=''Microchannelplate2'']/Voltage', NULL, 3, 'table_Number'),
('ControlWorkstation/Equipment/Slot/Item[@key=''21'']/Supply/Item[@key=''Anode'']/Amperage', NULL, 3, 'table_Float'),
('ControlWorkstation/Equipment/Slot/Item[@key=''21'']/Supply/Item[@key=''Anode'']/Voltage', NULL, 3, 'table_Number'),
('ControlWorkstation/Equipment/Slot/Item[@key=''22'']/Supply/Item[@key=''Photocathode'']/Amperage', NULL, 3, 'table_Float'),
('ControlWorkstation/Equipment/Slot/Item[@key=''22'']/Supply/Item[@key=''Photocathode'']/Voltage', NULL, 3, 'table_Number'),
('ControlWorkstation/Equipment/Slot/Item[@key=''22'']/Supply/Item[@key=''Microchannelplate1'']/Amperage', NULL, 3, 'table_Float'),
('ControlWorkstation/Equipment/Slot/Item[@key=''22'']/Supply/Item[@key=''Microchannelplate1'']/Voltage', NULL, 3, 'table_Number'),
('ControlWorkstation/Equipment/Slot/Item[@key=''22'']/Supply/Item[@key=''Microchannelplate12'']/Amperage', NULL, 3, 'table_Float'),
('ControlWorkstation/Equipment/Slot/Item[@key=''22'']/Supply/Item[@key=''Microchannelplate12'']/Voltage', NULL, 3, 'table_Number'),
('ControlWorkstation/Equipment/Slot/Item[@key=''22'']/Supply/Item[@key=''Microchannelplate2'']/Amperage', NULL, 3, 'table_Float'),
('ControlWorkstation/Equipment/Slot/Item[@key=''22'']/Supply/Item[@key=''Microchannelplate2'']/Voltage', NULL, 3, 'table_Number'),
('ControlWorkstation/Equipment/Slot/Item[@key=''22'']/Supply/Item[@key=''Anode'']/Amperage', NULL, 3, 'table_Float'),
('ControlWorkstation/Equipment/Slot/Item[@key=''22'']/Supply/Item[@key=''Anode'']/Voltage', NULL, 3, 'table_Number'),
('ControlWorkstation/Equipment/Slot/Item[@key=''23'']/Supply/Item[@key=''Photocathode'']/Amperage', NULL, 3, 'table_Float'),
('ControlWorkstation/Equipment/Slot/Item[@key=''23'']/Supply/Item[@key=''Photocathode'']/Voltage', NULL, 3, 'table_Number'),
('ControlWorkstation/Equipment/Slot/Item[@key=''23'']/Supply/Item[@key=''Microchannelplate1'']/Amperage', NULL, 3, 'table_Float'),
('ControlWorkstation/Equipment/Slot/Item[@key=''23'']/Supply/Item[@key=''Microchannelplate1'']/Voltage', NULL, 3, 'table_Number'),
('ControlWorkstation/Equipment/Slot/Item[@key=''23'']/Supply/Item[@key=''Microchannelplate12'']/Amperage', NULL, 3, 'table_Float'),
('ControlWorkstation/Equipment/Slot/Item[@key=''23'']/Supply/Item[@key=''Microchannelplate12'']/Voltage', NULL, 3, 'table_Number'),
('ControlWorkstation/Equipment/Slot/Item[@key=''23'']/Supply/Item[@key=''Microchannelplate2'']/Amperage', NULL, 3, 'table_Float'),
('ControlWorkstation/Equipment/Slot/Item[@key=''23'']/Supply/Item[@key=''Microchannelplate2'']/Voltage', NULL, 3, 'table_Number'),
('ControlWorkstation/Equipment/Slot/Item[@key=''23'']/Supply/Item[@key=''Anode'']/Amperage', NULL, 3, 'table_Float'),
('ControlWorkstation/Equipment/Slot/Item[@key=''23'']/Supply/Item[@key=''Anode'']/Voltage', NULL, 3, 'table_Number'),
('ControlWorkstation/Equipment/Slot/Item[@key=''24'']/Supply/Item[@key=''Photocathode'']/Amperage', NULL, 3, 'table_Float'),
('ControlWorkstation/Equipment/Slot/Item[@key=''24'']/Supply/Item[@key=''Photocathode'']/Voltage', NULL, 3, 'table_Number'),
('ControlWorkstation/Equipment/Slot/Item[@key=''24'']/Supply/Item[@key=''Microchannelplate1'']/Amperage', NULL, 3, 'table_Float'),
('ControlWorkstation/Equipment/Slot/Item[@key=''24'']/Supply/Item[@key=''Microchannelplate1'']/Voltage', NULL, 3, 'table_Number'),
('ControlWorkstation/Equipment/Slot/Item[@key=''24'']/Supply/Item[@key=''Microchannelplate12'']/Amperage', NULL, 3, 'table_Float'),
('ControlWorkstation/Equipment/Slot/Item[@key=''24'']/Supply/Item[@key=''Microchannelplate12'']/Voltage', NULL, 3, 'table_Number'),
('ControlWorkstation/Equipment/Slot/Item[@key=''24'']/Supply/Item[@key=''Microchannelplate2'']/Amperage', NULL, 3, 'table_Float'),
('ControlWorkstation/Equipment/Slot/Item[@key=''24'']/Supply/Item[@key=''Microchannelplate2'']/Voltage', NULL, 3, 'table_Number'),
('ControlWorkstation/Equipment/Slot/Item[@key=''24'']/Supply/Item[@key=''Anode'']/Amperage', NULL, 3, 'table_Float'),
('ControlWorkstation/Equipment/Slot/Item[@key=''24'']/Supply/Item[@key=''Anode'']/Voltage', NULL, 3, 'table_Number'),
('ControlWorkstation/Equipment/Slot/Item[@key=''25'']/Supply/Item[@key=''Photocathode'']/Amperage', NULL, 3, 'table_Float'),
('ControlWorkstation/Equipment/Slot/Item[@key=''25'']/Supply/Item[@key=''Photocathode'']/Voltage', NULL, 3, 'table_Number'),
('ControlWorkstation/Equipment/Slot/Item[@key=''25'']/Supply/Item[@key=''Microchannelplate1'']/Amperage', NULL, 3, 'table_Float'),
('ControlWorkstation/Equipment/Slot/Item[@key=''25'']/Supply/Item[@key=''Microchannelplate1'']/Voltage', NULL, 3, 'table_Number'),
('ControlWorkstation/Equipment/Slot/Item[@key=''25'']/Supply/Item[@key=''Microchannelplate12'']/Amperage', NULL, 3, 'table_Float'),
('ControlWorkstation/Equipment/Slot/Item[@key=''25'']/Supply/Item[@key=''Microchannelplate12'']/Voltage', NULL, 3, 'table_Number'),
('ControlWorkstation/Equipment/Slot/Item[@key=''25'']/Supply/Item[@key=''Microchannelplate2'']/Amperage', NULL, 3, 'table_Float'),
('ControlWorkstation/Equipment/Slot/Item[@key=''25'']/Supply/Item[@key=''Microchannelplate2'']/Voltage', NULL, 3, 'table_Number'),
('ControlWorkstation/Equipment/Slot/Item[@key=''25'']/Supply/Item[@key=''Anode'']/Amperage', NULL, 3, 'table_Float'),
('ControlWorkstation/Equipment/Slot/Item[@key=''25'']/Supply/Item[@key=''Anode'']/Voltage', NULL, 3, 'table_Number'),
('ControlWorkstation/Equipment/Slot/Item[@key=''26'']/Supply/Item[@key=''Photocathode'']/Amperage', NULL, 3, 'table_Float'),
('ControlWorkstation/Equipment/Slot/Item[@key=''26'']/Supply/Item[@key=''Photocathode'']/Voltage', NULL, 3, 'table_Number'),
('ControlWorkstation/Equipment/Slot/Item[@key=''26'']/Supply/Item[@key=''Microchannelplate1'']/Amperage', NULL, 3, 'table_Float'),
('ControlWorkstation/Equipment/Slot/Item[@key=''26'']/Supply/Item[@key=''Microchannelplate1'']/Voltage', NULL, 3, 'table_Number'),
('ControlWorkstation/Equipment/Slot/Item[@key=''26'']/Supply/Item[@key=''Microchannelplate12'']/Amperage', NULL, 3, 'table_Float'),
('ControlWorkstation/Equipment/Slot/Item[@key=''26'']/Supply/Item[@key=''Microchannelplate12'']/Voltage', NULL, 3, 'table_Number'),
('ControlWorkstation/Equipment/Slot/Item[@key=''26'']/Supply/Item[@key=''Microchannelplate2'']/Amperage', NULL, 3, 'table_Float'),
('ControlWorkstation/Equipment/Slot/Item[@key=''26'']/Supply/Item[@key=''Microchannelplate2'']/Voltage', NULL, 3, 'table_Number'),
('ControlWorkstation/Equipment/Slot/Item[@key=''26'']/Supply/Item[@key=''Anode'']/Amperage', NULL, 3, 'table_Float'),
('ControlWorkstation/Equipment/Slot/Item[@key=''26'']/Supply/Item[@key=''Anode'']/Voltage', NULL, 3, 'table_Number'),
('ControlWorkstation/Equipment/Slot/Item[@key=''27'']/Supply/Item[@key=''Photocathode'']/Amperage', NULL, 3, 'table_Float'),
('ControlWorkstation/Equipment/Slot/Item[@key=''27'']/Supply/Item[@key=''Photocathode'']/Voltage', NULL, 3, 'table_Number'),
('ControlWorkstation/Equipment/Slot/Item[@key=''27'']/Supply/Item[@key=''Microchannelplate1'']/Amperage', NULL, 3, 'table_Float'),
('ControlWorkstation/Equipment/Slot/Item[@key=''27'']/Supply/Item[@key=''Microchannelplate1'']/Voltage', NULL, 3, 'table_Number'),
('ControlWorkstation/Equipment/Slot/Item[@key=''27'']/Supply/Item[@key=''Microchannelplate12'']/Amperage', NULL, 3, 'table_Float'),
('ControlWorkstation/Equipment/Slot/Item[@key=''27'']/Supply/Item[@key=''Microchannelplate12'']/Voltage', NULL, 3, 'table_Number'),
('ControlWorkstation/Equipment/Slot/Item[@key=''27'']/Supply/Item[@key=''Microchannelplate2'']/Amperage', NULL, 3, 'table_Float'),
('ControlWorkstation/Equipment/Slot/Item[@key=''27'']/Supply/Item[@key=''Microchannelplate2'']/Voltage', NULL, 3, 'table_Number'),
('ControlWorkstation/Equipment/Slot/Item[@key=''27'']/Supply/Item[@key=''Anode'']/Amperage', NULL, 3, 'table_Float'),
('ControlWorkstation/Equipment/Slot/Item[@key=''27'']/Supply/Item[@key=''Anode'']/Voltage', NULL, 3, 'table_Number'),
('ControlWorkstation/Equipment/Slot/Item[@key=''28'']/Supply/Item[@key=''Photocathode'']/Amperage', NULL, 3, 'table_Float'),
('ControlWorkstation/Equipment/Slot/Item[@key=''28'']/Supply/Item[@key=''Photocathode'']/Voltage', NULL, 3, 'table_Number'),
('ControlWorkstation/Equipment/Slot/Item[@key=''28'']/Supply/Item[@key=''Microchannelplate1'']/Amperage', NULL, 3, 'table_Float'),
('ControlWorkstation/Equipment/Slot/Item[@key=''28'']/Supply/Item[@key=''Microchannelplate1'']/Voltage', NULL, 3, 'table_Number'),
('ControlWorkstation/Equipment/Slot/Item[@key=''28'']/Supply/Item[@key=''Microchannelplate12'']/Amperage', NULL, 3, 'table_Float'),
('ControlWorkstation/Equipment/Slot/Item[@key=''28'']/Supply/Item[@key=''Microchannelplate12'']/Voltage', NULL, 3, 'table_Number'),
('ControlWorkstation/Equipment/Slot/Item[@key=''28'']/Supply/Item[@key=''Microchannelplate2'']/Amperage', NULL, 3, 'table_Float'),
('ControlWorkstation/Equipment/Slot/Item[@key=''28'']/Supply/Item[@key=''Microchannelplate2'']/Voltage', NULL, 3, 'table_Number'),
('ControlWorkstation/Equipment/Slot/Item[@key=''28'']/Supply/Item[@key=''Anode'']/Amperage', NULL, 3, 'table_Float'),
('ControlWorkstation/Equipment/Slot/Item[@key=''28'']/Supply/Item[@key=''Anode'']/Voltage', NULL, 3, 'table_Number'),
('ControlWorkstation/Equipment/Slot/Item[@key=''29'']/Supply/Item[@key=''Photocathode'']/Amperage', NULL, 3, 'table_Float'),
('ControlWorkstation/Equipment/Slot/Item[@key=''29'']/Supply/Item[@key=''Photocathode'']/Voltage', NULL, 3, 'table_Number'),
('ControlWorkstation/Equipment/Slot/Item[@key=''29'']/Supply/Item[@key=''Microchannelplate1'']/Amperage', NULL, 3, 'table_Float'),
('ControlWorkstation/Equipment/Slot/Item[@key=''29'']/Supply/Item[@key=''Microchannelplate1'']/Voltage', NULL, 3, 'table_Number'),
('ControlWorkstation/Equipment/Slot/Item[@key=''29'']/Supply/Item[@key=''Microchannelplate12'']/Amperage', NULL, 3, 'table_Float'),
('ControlWorkstation/Equipment/Slot/Item[@key=''29'']/Supply/Item[@key=''Microchannelplate12'']/Voltage', NULL, 3, 'table_Number'),
('ControlWorkstation/Equipment/Slot/Item[@key=''29'']/Supply/Item[@key=''Microchannelplate2'']/Amperage', NULL, 3, 'table_Float'),
('ControlWorkstation/Equipment/Slot/Item[@key=''29'']/Supply/Item[@key=''Microchannelplate2'']/Voltage', NULL, 3, 'table_Number'),
('ControlWorkstation/Equipment/Slot/Item[@key=''29'']/Supply/Item[@key=''Anode'']/Amperage', NULL, 3, 'table_Float'),
('ControlWorkstation/Equipment/Slot/Item[@key=''29'']/Supply/Item[@key=''Anode'']/Voltage', NULL, 3, 'table_Number'),
('ControlWorkstation/Equipment/Slot/Item[@key=''30'']/Supply/Item[@key=''Photocathode'']/Amperage', NULL, 3, 'table_Float'),
('ControlWorkstation/Equipment/Slot/Item[@key=''30'']/Supply/Item[@key=''Photocathode'']/Voltage', NULL, 3, 'table_Number'),
('ControlWorkstation/Equipment/Slot/Item[@key=''30'']/Supply/Item[@key=''Microchannelplate1'']/Amperage', NULL, 3, 'table_Float'),
('ControlWorkstation/Equipment/Slot/Item[@key=''30'']/Supply/Item[@key=''Microchannelplate1'']/Voltage', NULL, 3, 'table_Number'),
('ControlWorkstation/Equipment/Slot/Item[@key=''30'']/Supply/Item[@key=''Microchannelplate12'']/Amperage', NULL, 3, 'table_Float'),
('ControlWorkstation/Equipment/Slot/Item[@key=''30'']/Supply/Item[@key=''Microchannelplate12'']/Voltage', NULL, 3, 'table_Number'),
('ControlWorkstation/Equipment/Slot/Item[@key=''30'']/Supply/Item[@key=''Microchannelplate2'']/Amperage', NULL, 3, 'table_Float'),
('ControlWorkstation/Equipment/Slot/Item[@key=''30'']/Supply/Item[@key=''Microchannelplate2'']/Voltage', NULL, 3, 'table_Number'),
('ControlWorkstation/Equipment/Slot/Item[@key=''30'']/Supply/Item[@key=''Anode'']/Amperage', NULL, 3, 'table_Float'),
('ControlWorkstation/Equipment/Slot/Item[@key=''30'']/Supply/Item[@key=''Anode'']/Voltage', NULL, 3, 'table_Number');
 /*-------------------------------------------------------------------------------------------------*/
INSERT INTO NumberActual (NumberActKey, tstamp)
SELECT * FROM (
  SELECT ROW_NUMBER() OVER () n, t
  	  FROM generate_series(NOW() - INTERVAL '90 days', NOW(),'1 min') t
  ) sq
 WHERE n <= 300;
 
INSERT INTO FloatActual (FloatActKey, tstamp)
SELECT * FROM (
  SELECT ROW_NUMBER() OVER () n, t
  	  FROM generate_series(NOW() - INTERVAL '90 days', NOW(),'1 min') t
  ) sq
 WHERE n <= 300;
 
INSERT INTO DecimalActual (DecimalActKey, tstamp)
SELECT * FROM (
  SELECT ROW_NUMBER() OVER () n, t
  	  FROM generate_series(NOW() - INTERVAL '90 days', NOW(),'1 min') t
  ) sq
 WHERE n <= 300;
 
INSERT INTO StringActual (StringActKey, tstamp)
SELECT * FROM (
  SELECT ROW_NUMBER() OVER () n, t
  	  FROM generate_series(NOW() - INTERVAL '90 days', NOW(),'1 min') t
  ) sq
 WHERE n <= 300;
  /*-------------------------------------------------------------------------------------------------*/
CREATE FUNCTION Refresh_ (xpath character, value_ anyelement) returns void
as
$$
	/**/
$$
language 'sql';