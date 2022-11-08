
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

INSERT INTO table_Glossary (configuration, communication, allowance, tablename) VALUES 
('ControlWorkstation/Equipment/Slot/Item[@key=''1'']/Supply/Item[@key=''Photocathode'']/Amperage', NULL, 3.0, 'table_Float'),
('ControlWorkstation/Equipment/Slot/Item[@key=''1'']/Supply/Item[@key=''Photocathode'']/Voltage', NULL, 3, 'table_Number');
