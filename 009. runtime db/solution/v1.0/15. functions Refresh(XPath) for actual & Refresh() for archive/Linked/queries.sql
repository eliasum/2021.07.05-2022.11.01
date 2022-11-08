/*2022.01.20 17:46 IMM*/

DROP TABLE table_glossary;

DROP TABLE table_number;
DROP TABLE table_float;
DROP TABLE table_decimal;
DROP TABLE table_string;

DROP TABLE number_actual;
DROP TABLE float_actual;
DROP TABLE decimal_actual;
DROP TABLE string_actual;
/*-------------------------------------------------------------------------------------------------*/
CREATE TABLE table_glossary (
    key integer NOT NULL GENERATED ALWAYS AS IDENTITY ( INCREMENT 1 START 1 MINVALUE 1 MAXVALUE 2147483647 CACHE 1 ),
    configuration text NOT NULL,
    communication text,
    allowance float NOT NULL,
    tablename character(15) NOT NULL,
    CONSTRAINT "glossary_key" PRIMARY KEY (key)
);
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
INSERT INTO table_glossary (configuration, communication, allowance, tablename) VALUES 
('ControlWorkstation/Equipment/Slot/Item[@key=''1'']/Supply/Item[@key=''Photocathode'']/Amperage', NULL, 3, 'float_actual');
select * from table_glossary;

select * from number_actual;
select * from float_actual;

select * from _Refresh('ControlWorkstation/Equipment/Slot/Item[@key=''1'']/Supply/Item[@key=''Photocathode'']/Amperage');
select * from _Refresh('ControlWorkstation/Equipment/Slot/Item[@key=''1'']/Supply/Item[@key=''Photocathode'']/Voltage');

select * from number_archive;
select * from float_archive;

TRUNCATE TABLE number_archive;
TRUNCATE TABLE float_archive;

select * from _Refresh(
'ControlWorkstation/Equipment/Slot/Item[@key=''1'']/Supply/Item[@key=''Photocathode'']/Amperage', 
'2021-10-22 11:34:13.000004+07', '2021-10-22 11:40:13.000004+07');

SELECT * FROM _Refresh(
'ControlWorkstation/Equipment/Slot/Item[@key=''1'']/Supply/Item[@key=''Photocathode'']/Amperage', 
'2022-01-12'::TIMESTAMP, '2022-01-13'::TIMESTAMP);