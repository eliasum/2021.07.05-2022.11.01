/*2022.01.21 11:56 IMM*/

--тестирование заполнения 300 строк
CREATE TABLE IF NOT EXISTS num( 
number_actual_key integer NOT NULL GENERATED ALWAYS AS IDENTITY ( INCREMENT 1 START 1 MINVALUE 1 MAXVALUE 2147483647 CACHE 1 ),
number_actual_tstamp TIMESTAMPTZ NOT NULL,
number_actual_val FLOAT NOT NULL);
	
INSERT INTO num (number_actual_tstamp, number_actual_val) 
  SELECT
    tstamp, random()*80 - 40
  FROM
    generate_series(
      NOW() - INTERVAL '299 days',
      NOW(),
      '1 day'
    ) AS tstamp;
	
select * from num;
-----------------------------------------------------------------------------------------------------

--тестирование заполнения 300 строк в number_actual
CREATE TABLE IF NOT EXISTS number_actual( 
number_actual_key integer NOT NULL GENERATED ALWAYS AS IDENTITY ( INCREMENT 1 START 1 MINVALUE 1 MAXVALUE 2147483647 CACHE 1 ),
number_actual_tstamp TIMESTAMPTZ NOT NULL,
number_actual_val FLOAT NOT NULL,
FOREIGN KEY (number_actual_key) REFERENCES glossary(key));

INSERT INTO number_actual (number_actual_tstamp, number_actual_val) 
  SELECT
    tstamp, random()*80 - 40
  FROM
    generate_series(
      NOW() - INTERVAL '299 days',
      NOW(),
      '1 day'
    ) AS tstamp;
	
select * from number_actual;
-----------------------------------------------------------------------------------------------------

--заполнение таблиц (200 строк в actual)
INSERT INTO number_actual (number_actual_tstamp, number_actual_val) 
  SELECT
    tstamp, random()*80 - 40
  FROM
    generate_series(
      NOW() - INTERVAL '199 days',
      NOW(),
      '1 day'
    ) AS tstamp;

INSERT INTO float_actual (float_actual_tstamp, float_actual_val) 
  SELECT
    tstamp, random()*80 - 40
  FROM
    generate_series(
      NOW() - INTERVAL '199 days',
      NOW(),
      '1 day'
    ) AS tstamp;

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

--тестирование _Refresh(xpath VARCHAR)
select * from float_actual;

select * from _Refresh(
'ControlWorkstation/Equipment/Slot/Item[@key=''1'']/Supply/Item[@key=''Photocathode'']/Amperage');

select * from number_actual;

select * from _Refresh(
'ControlWorkstation/Equipment/Slot/Item[@key=''1'']/Supply/Item[@key=''Photocathode'']/Voltage');
-----------------------------------------------------------------------------------------------------

--тестирование _сommunication(xpath VARCHAR, valnew FLOAT)
select * from number_archive;	-- -10.913192256428772

SELECT number_actual_key, number_actual_val FROM number_actual ORDER BY number_actual_key DESC LIMIT 1;	-- -9.436145585167424   	

select * from _communication('ControlWorkstation/Equipment/Slot/Item[@key=''1'']/Supply/Item[@key=''Photocathode'']/Voltage',-11);

select * from number_actual;
select * from number_archive;

TRUNCATE TABLE number_archive;

INSERT INTO glossary (configuration, communication, allowance, tablename) VALUES 
('ControlWorkstation/Equipment/Slot/Item[@key=''1'']/Supply/Item[@key=''Photocathode'']/Voltage', NULL, 3, 'float');

SELECT * FROM glossary ORDER BY key DESC LIMIT 1;




