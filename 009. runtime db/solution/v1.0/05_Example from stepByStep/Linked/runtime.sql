
-- PostgreSQL database dump
--"%PROGRAM_PATH%\PostgresPro\13\bin\psql" --username=postgres -d postgres -f D:\TEMP\runtime.sql
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

SET search_path = public, pg_catalog;
SET default_tablespace = '';
SET default_with_oids = false;

CREATE TABLE table_Glossary (
    key integer NOT NULL GENERATED ALWAYS AS IDENTITY ( INCREMENT 1 START 1 MINVALUE 1 MAXVALUE 2147483647 CACHE 1 ),
    configuration text NOT NULL,
    communication text,
    allowance float NOT NULL,
    tablename character(15) NOT NULL,
    CONSTRAINT "glossary_key" PRIMARY KEY (key)
);
COMMENT ON TABLE table_Glossary IS '������� ��� ����������� ����������';
COMMENT ON COLUMN table_Glossary.key IS '���������� ���� ���������� ��� ����� � ������� ���������';
COMMENT ON COLUMN table_Glossary.configuration IS 'XPath - ���� � ���������� � XML-���������������� ����� ��� ��';
COMMENT ON COLUMN table_Glossary.communication IS 'XPath - ���� � ���������� � XML-���������������� ����� ��� ������������';
COMMENT ON COLUMN table_Glossary.allowance IS '������ �� ��������� ����������';
COMMENT ON COLUMN table_Glossary.tablename IS '��� ������� � ������� �������� �������� ����������';

COPY table_Glossary (configuration, communication, allowance, tablename) FROM stdin;
ControlWorkstation/Equipment/Slot/Item[@key='1']/Supply/Item[@key='Photocathode']/Amperage 3 table_Float
ControlWorkstation/Equipment/Slot/Item[@key='1']/Supply/Item[@key='Photocathode']/Voltage 3 table_Number
ControlWorkstation/Equipment/Slot/Item[@key='1']/Supply/Item[@key='Microchannelplate1']/Amperage 3 table_Float
ControlWorkstation/Equipment/Slot/Item[@key='1']/Supply/Item[@key='Microchannelplate1']/Voltage 3 table_Number
ControlWorkstation/Equipment/Slot/Item[@key='1']/Supply/Item[@key='Microchannelplate12']/Amperage 3 table_Float
ControlWorkstation/Equipment/Slot/Item[@key='1']/Supply/Item[@key='Microchannelplate12']/Voltage 3 table_Number
ControlWorkstation/Equipment/Slot/Item[@key='1']/Supply/Item[@key='Microchannelplate2']/Amperage 3 table_Float
ControlWorkstation/Equipment/Slot/Item[@key='1']/Supply/Item[@key='Microchannelplate2']/Voltage 3 table_Number
ControlWorkstation/Equipment/Slot/Item[@key='1']/Supply/Item[@key='Anode']/Amperage 3 table_Float
ControlWorkstation/Equipment/Slot/Item[@key='1']/Supply/Item[@key='Anode']/Voltage 3 table_Number
ControlWorkstation/Equipment/Slot/Item[@key='2']/Supply/Item[@key='Photocathode']/Amperage 3 table_Float
ControlWorkstation/Equipment/Slot/Item[@key='2']/Supply/Item[@key='Photocathode']/Voltage 3 table_Number
ControlWorkstation/Equipment/Slot/Item[@key='2']/Supply/Item[@key='Microchannelplate1']/Amperage 3 table_Float
ControlWorkstation/Equipment/Slot/Item[@key='2']/Supply/Item[@key='Microchannelplate1']/Voltage 3 table_Number
ControlWorkstation/Equipment/Slot/Item[@key='2']/Supply/Item[@key='Microchannelplate12']/Amperage 3 table_Float
ControlWorkstation/Equipment/Slot/Item[@key='2']/Supply/Item[@key='Microchannelplate12']/Voltage 3 table_Number
ControlWorkstation/Equipment/Slot/Item[@key='2']/Supply/Item[@key='Microchannelplate2']/Amperage 3 table_Float
ControlWorkstation/Equipment/Slot/Item[@key='2']/Supply/Item[@key='Microchannelplate2']/Voltage 3 table_Number
ControlWorkstation/Equipment/Slot/Item[@key='2']/Supply/Item[@key='Anode']/Amperage 3 table_Float
ControlWorkstation/Equipment/Slot/Item[@key='2']/Supply/Item[@key='Anode']/Voltage 3 table_Number
ControlWorkstation/Equipment/Slot/Item[@key='3']/Supply/Item[@key='Photocathode']/Amperage 3 table_Float
ControlWorkstation/Equipment/Slot/Item[@key='3']/Supply/Item[@key='Photocathode']/Voltage 3 table_Number
ControlWorkstation/Equipment/Slot/Item[@key='3']/Supply/Item[@key='Microchannelplate1']/Amperage 3 table_Float
ControlWorkstation/Equipment/Slot/Item[@key='3']/Supply/Item[@key='Microchannelplate1']/Voltage 3 table_Number
ControlWorkstation/Equipment/Slot/Item[@key='3']/Supply/Item[@key='Microchannelplate12']/Amperage 3 table_Float
ControlWorkstation/Equipment/Slot/Item[@key='3']/Supply/Item[@key='Microchannelplate12']/Voltage 3 table_Number
ControlWorkstation/Equipment/Slot/Item[@key='3']/Supply/Item[@key='Microchannelplate2']/Amperage 3 table_Float
ControlWorkstation/Equipment/Slot/Item[@key='3']/Supply/Item[@key='Microchannelplate2']/Voltage 3 table_Number
ControlWorkstation/Equipment/Slot/Item[@key='3']/Supply/Item[@key='Anode']/Amperage 3 table_Float
ControlWorkstation/Equipment/Slot/Item[@key='3']/Supply/Item[@key='Anode']/Voltage 3 table_Number
ControlWorkstation/Equipment/Slot/Item[@key='4']/Supply/Item[@key='Photocathode']/Amperage 3 table_Float
ControlWorkstation/Equipment/Slot/Item[@key='4']/Supply/Item[@key='Photocathode']/Voltage 3 table_Number
ControlWorkstation/Equipment/Slot/Item[@key='4']/Supply/Item[@key='Microchannelplate1']/Amperage 3 table_Float
ControlWorkstation/Equipment/Slot/Item[@key='4']/Supply/Item[@key='Microchannelplate1']/Voltage 3 table_Number
ControlWorkstation/Equipment/Slot/Item[@key='4']/Supply/Item[@key='Microchannelplate12']/Amperage 3 table_Float
ControlWorkstation/Equipment/Slot/Item[@key='4']/Supply/Item[@key='Microchannelplate12']/Voltage 3 table_Number
ControlWorkstation/Equipment/Slot/Item[@key='4']/Supply/Item[@key='Microchannelplate2']/Amperage 3 table_Float
ControlWorkstation/Equipment/Slot/Item[@key='4']/Supply/Item[@key='Microchannelplate2']/Voltage 3 table_Number
ControlWorkstation/Equipment/Slot/Item[@key='4']/Supply/Item[@key='Anode']/Amperage 3 table_Float
ControlWorkstation/Equipment/Slot/Item[@key='4']/Supply/Item[@key='Anode']/Voltage 3 table_Number
ControlWorkstation/Equipment/Slot/Item[@key='5']/Supply/Item[@key='Photocathode']/Amperage 3 table_Float
ControlWorkstation/Equipment/Slot/Item[@key='5']/Supply/Item[@key='Photocathode']/Voltage 3 table_Number
ControlWorkstation/Equipment/Slot/Item[@key='5']/Supply/Item[@key='Microchannelplate1']/Amperage 3 table_Float
ControlWorkstation/Equipment/Slot/Item[@key='5']/Supply/Item[@key='Microchannelplate1']/Voltage 3 table_Number
ControlWorkstation/Equipment/Slot/Item[@key='5']/Supply/Item[@key='Microchannelplate12']/Amperage 3 table_Float
ControlWorkstation/Equipment/Slot/Item[@key='5']/Supply/Item[@key='Microchannelplate12']/Voltage 3 table_Number
ControlWorkstation/Equipment/Slot/Item[@key='5']/Supply/Item[@key='Microchannelplate2']/Amperage 3 table_Float
ControlWorkstation/Equipment/Slot/Item[@key='5']/Supply/Item[@key='Microchannelplate2']/Voltage 3 table_Number
ControlWorkstation/Equipment/Slot/Item[@key='5']/Supply/Item[@key='Anode']/Amperage 3 table_Float
ControlWorkstation/Equipment/Slot/Item[@key='5']/Supply/Item[@key='Anode']/Voltage 3 table_Number
ControlWorkstation/Equipment/Slot/Item[@key='6']/Supply/Item[@key='Photocathode']/Amperage 3 table_Float
ControlWorkstation/Equipment/Slot/Item[@key='6']/Supply/Item[@key='Photocathode']/Voltage 3 table_Number
ControlWorkstation/Equipment/Slot/Item[@key='6']/Supply/Item[@key='Microchannelplate1']/Amperage 3 table_Float
ControlWorkstation/Equipment/Slot/Item[@key='6']/Supply/Item[@key='Microchannelplate1']/Voltage 3 table_Number
ControlWorkstation/Equipment/Slot/Item[@key='6']/Supply/Item[@key='Microchannelplate12']/Amperage 3 table_Float
ControlWorkstation/Equipment/Slot/Item[@key='6']/Supply/Item[@key='Microchannelplate12']/Voltage 3 table_Number
ControlWorkstation/Equipment/Slot/Item[@key='6']/Supply/Item[@key='Microchannelplate2']/Amperage 3 table_Float
ControlWorkstation/Equipment/Slot/Item[@key='6']/Supply/Item[@key='Microchannelplate2']/Voltage 3 table_Number
ControlWorkstation/Equipment/Slot/Item[@key='6']/Supply/Item[@key='Anode']/Amperage 3 table_Float
ControlWorkstation/Equipment/Slot/Item[@key='6']/Supply/Item[@key='Anode']/Voltage 3 table_Number
ControlWorkstation/Equipment/Slot/Item[@key='7']/Supply/Item[@key='Photocathode']/Amperage 3 table_Float
ControlWorkstation/Equipment/Slot/Item[@key='7']/Supply/Item[@key='Photocathode']/Voltage 3 table_Number
ControlWorkstation/Equipment/Slot/Item[@key='7']/Supply/Item[@key='Microchannelplate1']/Amperage 3 table_Float
ControlWorkstation/Equipment/Slot/Item[@key='7']/Supply/Item[@key='Microchannelplate1']/Voltage 3 table_Number
ControlWorkstation/Equipment/Slot/Item[@key='7']/Supply/Item[@key='Microchannelplate12']/Amperage 3 table_Float
ControlWorkstation/Equipment/Slot/Item[@key='7']/Supply/Item[@key='Microchannelplate12']/Voltage 3 table_Number
ControlWorkstation/Equipment/Slot/Item[@key='7']/Supply/Item[@key='Microchannelplate2']/Amperage 3 table_Float
ControlWorkstation/Equipment/Slot/Item[@key='7']/Supply/Item[@key='Microchannelplate2']/Voltage 3 table_Number
ControlWorkstation/Equipment/Slot/Item[@key='7']/Supply/Item[@key='Anode']/Amperage 3 table_Float
ControlWorkstation/Equipment/Slot/Item[@key='7']/Supply/Item[@key='Anode']/Voltage 3 table_Number
ControlWorkstation/Equipment/Slot/Item[@key='8']/Supply/Item[@key='Photocathode']/Amperage 3 table_Float
ControlWorkstation/Equipment/Slot/Item[@key='8']/Supply/Item[@key='Photocathode']/Voltage 3 table_Number
ControlWorkstation/Equipment/Slot/Item[@key='8']/Supply/Item[@key='Microchannelplate1']/Amperage 3 table_Float
ControlWorkstation/Equipment/Slot/Item[@key='8']/Supply/Item[@key='Microchannelplate1']/Voltage 3 table_Number
ControlWorkstation/Equipment/Slot/Item[@key='8']/Supply/Item[@key='Microchannelplate12']/Amperage 3 table_Float
ControlWorkstation/Equipment/Slot/Item[@key='8']/Supply/Item[@key='Microchannelplate12']/Voltage 3 table_Number
ControlWorkstation/Equipment/Slot/Item[@key='8']/Supply/Item[@key='Microchannelplate2']/Amperage 3 table_Float
ControlWorkstation/Equipment/Slot/Item[@key='8']/Supply/Item[@key='Microchannelplate2']/Voltage 3 table_Number
ControlWorkstation/Equipment/Slot/Item[@key='8']/Supply/Item[@key='Anode']/Amperage 3 table_Float
ControlWorkstation/Equipment/Slot/Item[@key='8']/Supply/Item[@key='Anode']/Voltage 3 table_Number
ControlWorkstation/Equipment/Slot/Item[@key='9']/Supply/Item[@key='Photocathode']/Amperage 3 table_Float
ControlWorkstation/Equipment/Slot/Item[@key='9']/Supply/Item[@key='Photocathode']/Voltage 3 table_Number
ControlWorkstation/Equipment/Slot/Item[@key='9']/Supply/Item[@key='Microchannelplate1']/Amperage 3 table_Float
ControlWorkstation/Equipment/Slot/Item[@key='9']/Supply/Item[@key='Microchannelplate1']/Voltage 3 table_Number
ControlWorkstation/Equipment/Slot/Item[@key='9']/Supply/Item[@key='Microchannelplate12']/Amperage 3 table_Float
ControlWorkstation/Equipment/Slot/Item[@key='9']/Supply/Item[@key='Microchannelplate12']/Voltage 3 table_Number
ControlWorkstation/Equipment/Slot/Item[@key='9']/Supply/Item[@key='Microchannelplate2']/Amperage 3 table_Float
ControlWorkstation/Equipment/Slot/Item[@key='9']/Supply/Item[@key='Microchannelplate2']/Voltage 3 table_Number
ControlWorkstation/Equipment/Slot/Item[@key='9']/Supply/Item[@key='Anode']/Amperage 3 table_Float
ControlWorkstation/Equipment/Slot/Item[@key='9']/Supply/Item[@key='Anode']/Voltage 3 table_Number
ControlWorkstation/Equipment/Slot/Item[@key='10']/Supply/Item[@key='Photocathode']/Amperage 3 table_Float
ControlWorkstation/Equipment/Slot/Item[@key='10']/Supply/Item[@key='Photocathode']/Voltage 3 table_Number
ControlWorkstation/Equipment/Slot/Item[@key='10']/Supply/Item[@key='Microchannelplate1']/Amperage 3 table_Float
ControlWorkstation/Equipment/Slot/Item[@key='10']/Supply/Item[@key='Microchannelplate1']/Voltage 3 table_Number
ControlWorkstation/Equipment/Slot/Item[@key='10']/Supply/Item[@key='Microchannelplate12']/Amperage 3 table_Float
ControlWorkstation/Equipment/Slot/Item[@key='10']/Supply/Item[@key='Microchannelplate12']/Voltage 3 table_Number
ControlWorkstation/Equipment/Slot/Item[@key='10']/Supply/Item[@key='Microchannelplate2']/Amperage 3 table_Float
ControlWorkstation/Equipment/Slot/Item[@key='10']/Supply/Item[@key='Microchannelplate2']/Voltage 3 table_Number
ControlWorkstation/Equipment/Slot/Item[@key='10']/Supply/Item[@key='Anode']/Amperage 3 table_Float
ControlWorkstation/Equipment/Slot/Item[@key='10']/Supply/Item[@key='Anode']/Voltage 3 table_Number
ControlWorkstation/Equipment/Slot/Item[@key='11']/Supply/Item[@key='Photocathode']/Amperage 3 table_Float
ControlWorkstation/Equipment/Slot/Item[@key='11']/Supply/Item[@key='Photocathode']/Voltage 3 table_Number
ControlWorkstation/Equipment/Slot/Item[@key='11']/Supply/Item[@key='Microchannelplate1']/Amperage 3 table_Float
ControlWorkstation/Equipment/Slot/Item[@key='11']/Supply/Item[@key='Microchannelplate1']/Voltage 3 table_Number
ControlWorkstation/Equipment/Slot/Item[@key='11']/Supply/Item[@key='Microchannelplate12']/Amperage 3 table_Float
ControlWorkstation/Equipment/Slot/Item[@key='11']/Supply/Item[@key='Microchannelplate12']/Voltage 3 table_Number
ControlWorkstation/Equipment/Slot/Item[@key='11']/Supply/Item[@key='Microchannelplate2']/Amperage 3 table_Float
ControlWorkstation/Equipment/Slot/Item[@key='11']/Supply/Item[@key='Microchannelplate2']/Voltage 3 table_Number
ControlWorkstation/Equipment/Slot/Item[@key='11']/Supply/Item[@key='Anode']/Amperage 3 table_Float
ControlWorkstation/Equipment/Slot/Item[@key='11']/Supply/Item[@key='Anode']/Voltage 3 table_Number
ControlWorkstation/Equipment/Slot/Item[@key='12']/Supply/Item[@key='Photocathode']/Amperage 3 table_Float
ControlWorkstation/Equipment/Slot/Item[@key='12']/Supply/Item[@key='Photocathode']/Voltage 3 table_Number
ControlWorkstation/Equipment/Slot/Item[@key='12']/Supply/Item[@key='Microchannelplate1']/Amperage 3 table_Float
ControlWorkstation/Equipment/Slot/Item[@key='12']/Supply/Item[@key='Microchannelplate1']/Voltage 3 table_Number
ControlWorkstation/Equipment/Slot/Item[@key='12']/Supply/Item[@key='Microchannelplate12']/Amperage 3 table_Float
ControlWorkstation/Equipment/Slot/Item[@key='12']/Supply/Item[@key='Microchannelplate12']/Voltage 3 table_Number
ControlWorkstation/Equipment/Slot/Item[@key='12']/Supply/Item[@key='Microchannelplate2']/Amperage 3 table_Float
ControlWorkstation/Equipment/Slot/Item[@key='12']/Supply/Item[@key='Microchannelplate2']/Voltage 3 table_Number
ControlWorkstation/Equipment/Slot/Item[@key='12']/Supply/Item[@key='Anode']/Amperage 3 table_Float
ControlWorkstation/Equipment/Slot/Item[@key='12']/Supply/Item[@key='Anode']/Voltage 3 table_Number
ControlWorkstation/Equipment/Slot/Item[@key='13']/Supply/Item[@key='Photocathode']/Amperage 3 table_Float
ControlWorkstation/Equipment/Slot/Item[@key='13']/Supply/Item[@key='Photocathode']/Voltage 3 table_Number
ControlWorkstation/Equipment/Slot/Item[@key='13']/Supply/Item[@key='Microchannelplate1']/Amperage 3 table_Float
ControlWorkstation/Equipment/Slot/Item[@key='13']/Supply/Item[@key='Microchannelplate1']/Voltage 3 table_Number
ControlWorkstation/Equipment/Slot/Item[@key='13']/Supply/Item[@key='Microchannelplate12']/Amperage 3 table_Float
ControlWorkstation/Equipment/Slot/Item[@key='13']/Supply/Item[@key='Microchannelplate12']/Voltage 3 table_Number
ControlWorkstation/Equipment/Slot/Item[@key='13']/Supply/Item[@key='Microchannelplate2']/Amperage 3 table_Float
ControlWorkstation/Equipment/Slot/Item[@key='13']/Supply/Item[@key='Microchannelplate2']/Voltage 3 table_Number
ControlWorkstation/Equipment/Slot/Item[@key='13']/Supply/Item[@key='Anode']/Amperage 3 table_Float
ControlWorkstation/Equipment/Slot/Item[@key='13']/Supply/Item[@key='Anode']/Voltage 3 table_Number
ControlWorkstation/Equipment/Slot/Item[@key='14']/Supply/Item[@key='Photocathode']/Amperage 3 table_Float
ControlWorkstation/Equipment/Slot/Item[@key='14']/Supply/Item[@key='Photocathode']/Voltage 3 table_Number
ControlWorkstation/Equipment/Slot/Item[@key='14']/Supply/Item[@key='Microchannelplate1']/Amperage 3 table_Float
ControlWorkstation/Equipment/Slot/Item[@key='14']/Supply/Item[@key='Microchannelplate1']/Voltage 3 table_Number
ControlWorkstation/Equipment/Slot/Item[@key='14']/Supply/Item[@key='Microchannelplate12']/Amperage 3 table_Float
ControlWorkstation/Equipment/Slot/Item[@key='14']/Supply/Item[@key='Microchannelplate12']/Voltage 3 table_Number
ControlWorkstation/Equipment/Slot/Item[@key='14']/Supply/Item[@key='Microchannelplate2']/Amperage 3 table_Float
ControlWorkstation/Equipment/Slot/Item[@key='14']/Supply/Item[@key='Microchannelplate2']/Voltage 3 table_Number
ControlWorkstation/Equipment/Slot/Item[@key='14']/Supply/Item[@key='Anode']/Amperage 3 table_Float
ControlWorkstation/Equipment/Slot/Item[@key='14']/Supply/Item[@key='Anode']/Voltage 3 table_Number
ControlWorkstation/Equipment/Slot/Item[@key='15']/Supply/Item[@key='Photocathode']/Amperage 3 table_Float
ControlWorkstation/Equipment/Slot/Item[@key='15']/Supply/Item[@key='Photocathode']/Voltage 3 table_Number
ControlWorkstation/Equipment/Slot/Item[@key='15']/Supply/Item[@key='Microchannelplate1']/Amperage 3 table_Float
ControlWorkstation/Equipment/Slot/Item[@key='15']/Supply/Item[@key='Microchannelplate1']/Voltage 3 table_Number
ControlWorkstation/Equipment/Slot/Item[@key='15']/Supply/Item[@key='Microchannelplate12']/Amperage 3 table_Float
ControlWorkstation/Equipment/Slot/Item[@key='15']/Supply/Item[@key='Microchannelplate12']/Voltage 3 table_Number
ControlWorkstation/Equipment/Slot/Item[@key='15']/Supply/Item[@key='Microchannelplate2']/Amperage 3 table_Float
ControlWorkstation/Equipment/Slot/Item[@key='15']/Supply/Item[@key='Microchannelplate2']/Voltage 3 table_Number
ControlWorkstation/Equipment/Slot/Item[@key='15']/Supply/Item[@key='Anode']/Amperage 3 table_Float
ControlWorkstation/Equipment/Slot/Item[@key='15']/Supply/Item[@key='Anode']/Voltage 3 table_Number
ControlWorkstation/Equipment/Slot/Item[@key='16']/Supply/Item[@key='Photocathode']/Amperage 3 table_Float
ControlWorkstation/Equipment/Slot/Item[@key='16']/Supply/Item[@key='Photocathode']/Voltage 3 table_Number
ControlWorkstation/Equipment/Slot/Item[@key='16']/Supply/Item[@key='Microchannelplate1']/Amperage 3 table_Float
ControlWorkstation/Equipment/Slot/Item[@key='16']/Supply/Item[@key='Microchannelplate1']/Voltage 3 table_Number
ControlWorkstation/Equipment/Slot/Item[@key='16']/Supply/Item[@key='Microchannelplate12']/Amperage 3 table_Float
ControlWorkstation/Equipment/Slot/Item[@key='16']/Supply/Item[@key='Microchannelplate12']/Voltage 3 table_Number
ControlWorkstation/Equipment/Slot/Item[@key='16']/Supply/Item[@key='Microchannelplate2']/Amperage 3 table_Float
ControlWorkstation/Equipment/Slot/Item[@key='16']/Supply/Item[@key='Microchannelplate2']/Voltage 3 table_Number
ControlWorkstation/Equipment/Slot/Item[@key='16']/Supply/Item[@key='Anode']/Amperage 3 table_Float
ControlWorkstation/Equipment/Slot/Item[@key='16']/Supply/Item[@key='Anode']/Voltage 3 table_Number
ControlWorkstation/Equipment/Slot/Item[@key='17']/Supply/Item[@key='Photocathode']/Amperage 3 table_Float
ControlWorkstation/Equipment/Slot/Item[@key='17']/Supply/Item[@key='Photocathode']/Voltage 3 table_Number
ControlWorkstation/Equipment/Slot/Item[@key='17']/Supply/Item[@key='Microchannelplate1']/Amperage 3 table_Float
ControlWorkstation/Equipment/Slot/Item[@key='17']/Supply/Item[@key='Microchannelplate1']/Voltage 3 table_Number
ControlWorkstation/Equipment/Slot/Item[@key='17']/Supply/Item[@key='Microchannelplate12']/Amperage 3 table_Float
ControlWorkstation/Equipment/Slot/Item[@key='17']/Supply/Item[@key='Microchannelplate12']/Voltage 3 table_Number
ControlWorkstation/Equipment/Slot/Item[@key='17']/Supply/Item[@key='Microchannelplate2']/Amperage 3 table_Float
ControlWorkstation/Equipment/Slot/Item[@key='17']/Supply/Item[@key='Microchannelplate2']/Voltage 3 table_Number
ControlWorkstation/Equipment/Slot/Item[@key='17']/Supply/Item[@key='Anode']/Amperage 3 table_Float
ControlWorkstation/Equipment/Slot/Item[@key='17']/Supply/Item[@key='Anode']/Voltage 3 table_Number
ControlWorkstation/Equipment/Slot/Item[@key='18']/Supply/Item[@key='Photocathode']/Amperage 3 table_Float
ControlWorkstation/Equipment/Slot/Item[@key='18']/Supply/Item[@key='Photocathode']/Voltage 3 table_Number
ControlWorkstation/Equipment/Slot/Item[@key='18']/Supply/Item[@key='Microchannelplate1']/Amperage 3 table_Float
ControlWorkstation/Equipment/Slot/Item[@key='18']/Supply/Item[@key='Microchannelplate1']/Voltage 3 table_Number
ControlWorkstation/Equipment/Slot/Item[@key='18']/Supply/Item[@key='Microchannelplate12']/Amperage 3 table_Float
ControlWorkstation/Equipment/Slot/Item[@key='18']/Supply/Item[@key='Microchannelplate12']/Voltage 3 table_Number
ControlWorkstation/Equipment/Slot/Item[@key='18']/Supply/Item[@key='Microchannelplate2']/Amperage 3 table_Float
ControlWorkstation/Equipment/Slot/Item[@key='18']/Supply/Item[@key='Microchannelplate2']/Voltage 3 table_Number
ControlWorkstation/Equipment/Slot/Item[@key='18']/Supply/Item[@key='Anode']/Amperage 3 table_Float
ControlWorkstation/Equipment/Slot/Item[@key='18']/Supply/Item[@key='Anode']/Voltage 3 table_Number
ControlWorkstation/Equipment/Slot/Item[@key='19']/Supply/Item[@key='Photocathode']/Amperage 3 table_Float
ControlWorkstation/Equipment/Slot/Item[@key='19']/Supply/Item[@key='Photocathode']/Voltage 3 table_Number
ControlWorkstation/Equipment/Slot/Item[@key='19']/Supply/Item[@key='Microchannelplate1']/Amperage 3 table_Float
ControlWorkstation/Equipment/Slot/Item[@key='19']/Supply/Item[@key='Microchannelplate1']/Voltage 3 table_Number
ControlWorkstation/Equipment/Slot/Item[@key='19']/Supply/Item[@key='Microchannelplate12']/Amperage 3 table_Float
ControlWorkstation/Equipment/Slot/Item[@key='19']/Supply/Item[@key='Microchannelplate12']/Voltage 3 table_Number
ControlWorkstation/Equipment/Slot/Item[@key='19']/Supply/Item[@key='Microchannelplate2']/Amperage 3 table_Float
ControlWorkstation/Equipment/Slot/Item[@key='19']/Supply/Item[@key='Microchannelplate2']/Voltage 3 table_Number
ControlWorkstation/Equipment/Slot/Item[@key='19']/Supply/Item[@key='Anode']/Amperage 3 table_Float
ControlWorkstation/Equipment/Slot/Item[@key='19']/Supply/Item[@key='Anode']/Voltage 3 table_Number
ControlWorkstation/Equipment/Slot/Item[@key='20']/Supply/Item[@key='Photocathode']/Amperage 3 table_Float
ControlWorkstation/Equipment/Slot/Item[@key='20']/Supply/Item[@key='Photocathode']/Voltage 3 table_Number
ControlWorkstation/Equipment/Slot/Item[@key='20']/Supply/Item[@key='Microchannelplate1']/Amperage 3 table_Float
ControlWorkstation/Equipment/Slot/Item[@key='20']/Supply/Item[@key='Microchannelplate1']/Voltage 3 table_Number
ControlWorkstation/Equipment/Slot/Item[@key='20']/Supply/Item[@key='Microchannelplate12']/Amperage 3 table_Float
ControlWorkstation/Equipment/Slot/Item[@key='20']/Supply/Item[@key='Microchannelplate12']/Voltage 3 table_Number
ControlWorkstation/Equipment/Slot/Item[@key='20']/Supply/Item[@key='Microchannelplate2']/Amperage 3 table_Float
ControlWorkstation/Equipment/Slot/Item[@key='20']/Supply/Item[@key='Microchannelplate2']/Voltage 3 table_Number
ControlWorkstation/Equipment/Slot/Item[@key='20']/Supply/Item[@key='Anode']/Amperage 3 table_Float
ControlWorkstation/Equipment/Slot/Item[@key='20']/Supply/Item[@key='Anode']/Voltage 3 table_Number
ControlWorkstation/Equipment/Slot/Item[@key='21']/Supply/Item[@key='Photocathode']/Amperage 3 table_Float
ControlWorkstation/Equipment/Slot/Item[@key='21']/Supply/Item[@key='Photocathode']/Voltage 3 table_Number
ControlWorkstation/Equipment/Slot/Item[@key='21']/Supply/Item[@key='Microchannelplate1']/Amperage 3 table_Float
ControlWorkstation/Equipment/Slot/Item[@key='21']/Supply/Item[@key='Microchannelplate1']/Voltage 3 table_Number
ControlWorkstation/Equipment/Slot/Item[@key='21']/Supply/Item[@key='Microchannelplate12']/Amperage 3 table_Float
ControlWorkstation/Equipment/Slot/Item[@key='21']/Supply/Item[@key='Microchannelplate12']/Voltage 3 table_Number
ControlWorkstation/Equipment/Slot/Item[@key='21']/Supply/Item[@key='Microchannelplate2']/Amperage 3 table_Float
ControlWorkstation/Equipment/Slot/Item[@key='21']/Supply/Item[@key='Microchannelplate2']/Voltage 3 table_Number
ControlWorkstation/Equipment/Slot/Item[@key='21']/Supply/Item[@key='Anode']/Amperage 3 table_Float
ControlWorkstation/Equipment/Slot/Item[@key='21']/Supply/Item[@key='Anode']/Voltage 3 table_Number
ControlWorkstation/Equipment/Slot/Item[@key='22']/Supply/Item[@key='Photocathode']/Amperage 3 table_Float
ControlWorkstation/Equipment/Slot/Item[@key='22']/Supply/Item[@key='Photocathode']/Voltage 3 table_Number
ControlWorkstation/Equipment/Slot/Item[@key='22']/Supply/Item[@key='Microchannelplate1']/Amperage 3 table_Float
ControlWorkstation/Equipment/Slot/Item[@key='22']/Supply/Item[@key='Microchannelplate1']/Voltage 3 table_Number
ControlWorkstation/Equipment/Slot/Item[@key='22']/Supply/Item[@key='Microchannelplate12']/Amperage 3 table_Float
ControlWorkstation/Equipment/Slot/Item[@key='22']/Supply/Item[@key='Microchannelplate12']/Voltage 3 table_Number
ControlWorkstation/Equipment/Slot/Item[@key='22']/Supply/Item[@key='Microchannelplate2']/Amperage 3 table_Float
ControlWorkstation/Equipment/Slot/Item[@key='22']/Supply/Item[@key='Microchannelplate2']/Voltage 3 table_Number
ControlWorkstation/Equipment/Slot/Item[@key='22']/Supply/Item[@key='Anode']/Amperage 3 table_Float
ControlWorkstation/Equipment/Slot/Item[@key='22']/Supply/Item[@key='Anode']/Voltage 3 table_Number
ControlWorkstation/Equipment/Slot/Item[@key='23']/Supply/Item[@key='Photocathode']/Amperage 3 table_Float
ControlWorkstation/Equipment/Slot/Item[@key='23']/Supply/Item[@key='Photocathode']/Voltage 3 table_Number
ControlWorkstation/Equipment/Slot/Item[@key='23']/Supply/Item[@key='Microchannelplate1']/Amperage 3 table_Float
ControlWorkstation/Equipment/Slot/Item[@key='23']/Supply/Item[@key='Microchannelplate1']/Voltage 3 table_Number
ControlWorkstation/Equipment/Slot/Item[@key='23']/Supply/Item[@key='Microchannelplate12']/Amperage 3 table_Float
ControlWorkstation/Equipment/Slot/Item[@key='23']/Supply/Item[@key='Microchannelplate12']/Voltage 3 table_Number
ControlWorkstation/Equipment/Slot/Item[@key='23']/Supply/Item[@key='Microchannelplate2']/Amperage 3 table_Float
ControlWorkstation/Equipment/Slot/Item[@key='23']/Supply/Item[@key='Microchannelplate2']/Voltage 3 table_Number
ControlWorkstation/Equipment/Slot/Item[@key='23']/Supply/Item[@key='Anode']/Amperage 3 table_Float
ControlWorkstation/Equipment/Slot/Item[@key='23']/Supply/Item[@key='Anode']/Voltage 3 table_Number
ControlWorkstation/Equipment/Slot/Item[@key='24']/Supply/Item[@key='Photocathode']/Amperage 3 table_Float
ControlWorkstation/Equipment/Slot/Item[@key='24']/Supply/Item[@key='Photocathode']/Voltage 3 table_Number
ControlWorkstation/Equipment/Slot/Item[@key='24']/Supply/Item[@key='Microchannelplate1']/Amperage 3 table_Float
ControlWorkstation/Equipment/Slot/Item[@key='24']/Supply/Item[@key='Microchannelplate1']/Voltage 3 table_Number
ControlWorkstation/Equipment/Slot/Item[@key='24']/Supply/Item[@key='Microchannelplate12']/Amperage 3 table_Float
ControlWorkstation/Equipment/Slot/Item[@key='24']/Supply/Item[@key='Microchannelplate12']/Voltage 3 table_Number
ControlWorkstation/Equipment/Slot/Item[@key='24']/Supply/Item[@key='Microchannelplate2']/Amperage 3 table_Float
ControlWorkstation/Equipment/Slot/Item[@key='24']/Supply/Item[@key='Microchannelplate2']/Voltage 3 table_Number
ControlWorkstation/Equipment/Slot/Item[@key='24']/Supply/Item[@key='Anode']/Amperage 3 table_Float
ControlWorkstation/Equipment/Slot/Item[@key='24']/Supply/Item[@key='Anode']/Voltage 3 table_Number
ControlWorkstation/Equipment/Slot/Item[@key='25']/Supply/Item[@key='Photocathode']/Amperage 3 table_Float
ControlWorkstation/Equipment/Slot/Item[@key='25']/Supply/Item[@key='Photocathode']/Voltage 3 table_Number
ControlWorkstation/Equipment/Slot/Item[@key='25']/Supply/Item[@key='Microchannelplate1']/Amperage 3 table_Float
ControlWorkstation/Equipment/Slot/Item[@key='25']/Supply/Item[@key='Microchannelplate1']/Voltage 3 table_Number
ControlWorkstation/Equipment/Slot/Item[@key='25']/Supply/Item[@key='Microchannelplate12']/Amperage 3 table_Float
ControlWorkstation/Equipment/Slot/Item[@key='25']/Supply/Item[@key='Microchannelplate12']/Voltage 3 table_Number
ControlWorkstation/Equipment/Slot/Item[@key='25']/Supply/Item[@key='Microchannelplate2']/Amperage 3 table_Float
ControlWorkstation/Equipment/Slot/Item[@key='25']/Supply/Item[@key='Microchannelplate2']/Voltage 3 table_Number
ControlWorkstation/Equipment/Slot/Item[@key='25']/Supply/Item[@key='Anode']/Amperage 3 table_Float
ControlWorkstation/Equipment/Slot/Item[@key='25']/Supply/Item[@key='Anode']/Voltage 3 table_Number
ControlWorkstation/Equipment/Slot/Item[@key='26']/Supply/Item[@key='Photocathode']/Amperage 3 table_Float
ControlWorkstation/Equipment/Slot/Item[@key='26']/Supply/Item[@key='Photocathode']/Voltage 3 table_Number
ControlWorkstation/Equipment/Slot/Item[@key='26']/Supply/Item[@key='Microchannelplate1']/Amperage 3 table_Float
ControlWorkstation/Equipment/Slot/Item[@key='26']/Supply/Item[@key='Microchannelplate1']/Voltage 3 table_Number
ControlWorkstation/Equipment/Slot/Item[@key='26']/Supply/Item[@key='Microchannelplate12']/Amperage 3 table_Float
ControlWorkstation/Equipment/Slot/Item[@key='26']/Supply/Item[@key='Microchannelplate12']/Voltage 3 table_Number
ControlWorkstation/Equipment/Slot/Item[@key='26']/Supply/Item[@key='Microchannelplate2']/Amperage 3 table_Float
ControlWorkstation/Equipment/Slot/Item[@key='26']/Supply/Item[@key='Microchannelplate2']/Voltage 3 table_Number
ControlWorkstation/Equipment/Slot/Item[@key='26']/Supply/Item[@key='Anode']/Amperage 3 table_Float
ControlWorkstation/Equipment/Slot/Item[@key='26']/Supply/Item[@key='Anode']/Voltage 3 table_Number
ControlWorkstation/Equipment/Slot/Item[@key='27']/Supply/Item[@key='Photocathode']/Amperage 3 table_Float
ControlWorkstation/Equipment/Slot/Item[@key='27']/Supply/Item[@key='Photocathode']/Voltage 3 table_Number
ControlWorkstation/Equipment/Slot/Item[@key='27']/Supply/Item[@key='Microchannelplate1']/Amperage 3 table_Float
ControlWorkstation/Equipment/Slot/Item[@key='27']/Supply/Item[@key='Microchannelplate1']/Voltage 3 table_Number
ControlWorkstation/Equipment/Slot/Item[@key='27']/Supply/Item[@key='Microchannelplate12']/Amperage 3 table_Float
ControlWorkstation/Equipment/Slot/Item[@key='27']/Supply/Item[@key='Microchannelplate12']/Voltage 3 table_Number
ControlWorkstation/Equipment/Slot/Item[@key='27']/Supply/Item[@key='Microchannelplate2']/Amperage 3 table_Float
ControlWorkstation/Equipment/Slot/Item[@key='27']/Supply/Item[@key='Microchannelplate2']/Voltage 3 table_Number
ControlWorkstation/Equipment/Slot/Item[@key='27']/Supply/Item[@key='Anode']/Amperage 3 table_Float
ControlWorkstation/Equipment/Slot/Item[@key='27']/Supply/Item[@key='Anode']/Voltage 3 table_Number
ControlWorkstation/Equipment/Slot/Item[@key='28']/Supply/Item[@key='Photocathode']/Amperage 3 table_Float
ControlWorkstation/Equipment/Slot/Item[@key='28']/Supply/Item[@key='Photocathode']/Voltage 3 table_Number
ControlWorkstation/Equipment/Slot/Item[@key='28']/Supply/Item[@key='Microchannelplate1']/Amperage 3 table_Float
ControlWorkstation/Equipment/Slot/Item[@key='28']/Supply/Item[@key='Microchannelplate1']/Voltage 3 table_Number
ControlWorkstation/Equipment/Slot/Item[@key='28']/Supply/Item[@key='Microchannelplate12']/Amperage 3 table_Float
ControlWorkstation/Equipment/Slot/Item[@key='28']/Supply/Item[@key='Microchannelplate12']/Voltage 3 table_Number
ControlWorkstation/Equipment/Slot/Item[@key='28']/Supply/Item[@key='Microchannelplate2']/Amperage 3 table_Float
ControlWorkstation/Equipment/Slot/Item[@key='28']/Supply/Item[@key='Microchannelplate2']/Voltage 3 table_Number
ControlWorkstation/Equipment/Slot/Item[@key='28']/Supply/Item[@key='Anode']/Amperage 3 table_Float
ControlWorkstation/Equipment/Slot/Item[@key='28']/Supply/Item[@key='Anode']/Voltage 3 table_Number
ControlWorkstation/Equipment/Slot/Item[@key='29']/Supply/Item[@key='Photocathode']/Amperage 3 table_Float
ControlWorkstation/Equipment/Slot/Item[@key='29']/Supply/Item[@key='Photocathode']/Voltage 3 table_Number
ControlWorkstation/Equipment/Slot/Item[@key='29']/Supply/Item[@key='Microchannelplate1']/Amperage 3 table_Float
ControlWorkstation/Equipment/Slot/Item[@key='29']/Supply/Item[@key='Microchannelplate1']/Voltage 3 table_Number
ControlWorkstation/Equipment/Slot/Item[@key='29']/Supply/Item[@key='Microchannelplate12']/Amperage 3 table_Float
ControlWorkstation/Equipment/Slot/Item[@key='29']/Supply/Item[@key='Microchannelplate12']/Voltage 3 table_Number
ControlWorkstation/Equipment/Slot/Item[@key='29']/Supply/Item[@key='Microchannelplate2']/Amperage 3 table_Float
ControlWorkstation/Equipment/Slot/Item[@key='29']/Supply/Item[@key='Microchannelplate2']/Voltage 3 table_Number
ControlWorkstation/Equipment/Slot/Item[@key='29']/Supply/Item[@key='Anode']/Amperage 3 table_Float
ControlWorkstation/Equipment/Slot/Item[@key='29']/Supply/Item[@key='Anode']/Voltage 3 table_Number
ControlWorkstation/Equipment/Slot/Item[@key='30']/Supply/Item[@key='Photocathode']/Amperage 3 table_Float
ControlWorkstation/Equipment/Slot/Item[@key='30']/Supply/Item[@key='Photocathode']/Voltage 3 table_Number
ControlWorkstation/Equipment/Slot/Item[@key='30']/Supply/Item[@key='Microchannelplate1']/Amperage 3 table_Float
ControlWorkstation/Equipment/Slot/Item[@key='30']/Supply/Item[@key='Microchannelplate1']/Voltage 3 table_Number
ControlWorkstation/Equipment/Slot/Item[@key='30']/Supply/Item[@key='Microchannelplate12']/Amperage 3 table_Float
ControlWorkstation/Equipment/Slot/Item[@key='30']/Supply/Item[@key='Microchannelplate12']/Voltage 3 table_Number
ControlWorkstation/Equipment/Slot/Item[@key='30']/Supply/Item[@key='Microchannelplate2']/Amperage 3 table_Float
ControlWorkstation/Equipment/Slot/Item[@key='30']/Supply/Item[@key='Microchannelplate2']/Voltage 3 table_Number
ControlWorkstation/Equipment/Slot/Item[@key='30']/Supply/Item[@key='Anode']/Amperage 3 table_Float
ControlWorkstation/Equipment/Slot/Item[@key='30']/Supply/Item[@key='Anode']/Voltage 3 table_Number
\.