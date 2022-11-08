/*2022.02.15 17:21 IMM*/

--заполнение таблиц (200 строк в actual)
INSERT INTO integer_actual (fix, value) 
  SELECT
    tstamp, random()*80 - 40
  FROM
    generate_series(
      NOW() - INTERVAL '199 days',
      NOW(),
      '1 day'
    ) AS tstamp;

INSERT INTO float_actual (fix, value) 
  SELECT
    tstamp, random()*80 - 40
  FROM
    generate_series(
      NOW() - INTERVAL '199 days',
      NOW(),
      '1 day'
    ) AS tstamp;
	
select * from integer_actual;
select * from float_actual;
-----------------------------------------------------------------------------------------------------

--тестирование _communication()

--замена процедуры
CREATE OR REPLACE PROCEDURE _communication(xpath VARCHAR, value anyelement) AS $$
-- на функцию
CREATE OR REPLACE FUNCTION _communication(xpath VARCHAR, value anyelement) 
RETURNS FLOAT AS $$

--float_actual:

--последняя запись в float_actual
SELECT * FROM float_actual ORDER BY key DESC LIMIT 1;	

--вызов функции
select * from _communication('ControlWorkstation/Equipment/Slot/Item[@key=''1'']/Supply/Item[@key=''Photocathode'']/Amperage',-11.99);
SELECT * FROM float_actual ORDER BY key DESC LIMIT 1;	

--вызов процедуры
CALL _communication('ControlWorkstation/Equipment/Slot/Item[@key=''1'']/Supply/Item[@key=''Photocathode'']/Amperage',-12.88);

--integer_actual:

--последняя запись в integer_actual
SELECT * FROM integer_actual ORDER BY key DESC LIMIT 1;	

--вызов функции
select * from _communication('ControlWorkstation/Equipment/Slot/Item[@key=''1'']/Supply/Item[@key=''Photocathode'']/Voltage',18);
SELECT * FROM integer_actual ORDER BY key DESC LIMIT 1;	

--вызов процедуры
CALL _communication('ControlWorkstation/Equipment/Slot/Item[@key=''1'']/Supply/Item[@key=''Photocathode'']/Voltage',19);
-----------------------------------------------------------------------------------------------------

--тестирование _Refresh(xpath VARCHAR)
select * from float_actual;

select key from glossary where configuration = 
'ControlWorkstation/Equipment/Slot/Item[@key=''1'']/Supply/Item[@key=''Photocathode'']/Amperage';

SELECT * FROM _refresh(
'ControlWorkstation/Equipment/Slot/Item[@key=''1'']/Supply/Item[@key=''Microchannelplate1'']/Amperage')
 AS (rkey INTEGER, rfix TIMESTAMPTZ, rvalue FLOAT);

select * from integer_actual;

select * from _Refresh(
'ControlWorkstation/Equipment/Slot/Item[@key=''1'']/Supply/Item[@key=''Microchannelplate1'']/Voltage');

SELECT * FROM _refresh(
'ControlWorkstation/Equipment/Slot/Item[@key=''1'']/Supply/Item[@key=''Microchannelplate1'']/Voltage')
 AS (rkey INTEGER, rfix TIMESTAMPTZ, rvalue INTEGER);
-----------------------------------------------------------------------------------------------------

select * from glossary