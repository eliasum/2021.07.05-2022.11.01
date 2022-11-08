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