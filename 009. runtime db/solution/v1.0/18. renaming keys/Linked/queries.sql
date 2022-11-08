/*2022.01.27 17:45 IMM*/

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

INSERT INTO integer_archive (key, fix, value) 
  SELECT
    (random()*30+1)::INT,tstamp, random()*80 - 40
  FROM
    generate_series(
      NOW() - INTERVAL '90 days',
      NOW(),
      '1 min'
    ) AS tstamp;

INSERT INTO float_archive (key, fix, value) 
  SELECT
    (random()*30+1)::INT,tstamp, random()*80 - 40
  FROM
    generate_series(
      NOW() - INTERVAL '90 days',
      NOW(),
      '1 min'
    ) AS tstamp;
	
select * from integer_actual;
select * from float_actual;
select * from integer_archive;
select * from float_archive;
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

select * from _Refresh(
'ControlWorkstation/Equipment/Slot/Item[@key=''1'']/Supply/Item[@key=''Microchannelplate1'']/Amperage');

select * from integer_actual;

select * from _Refresh(
'ControlWorkstation/Equipment/Slot/Item[@key=''1'']/Supply/Item[@key=''Microchannelplate1'']/Voltage');
-----------------------------------------------------------------------------------------------------

--тестирование _refreshold(xpath VARCHAR, st TIMESTAMP, fin TIMESTAMP)

select * from float_archive;

select * from _refreshold('ControlWorkstation/Equipment/Slot/Item[@key=''1'']/Supply/Item[@key=''Microchannelplate1'']/Amperage',
'2021-10-28 19:54:43.120367+07', '2021-10-28 20:00:43.120367+07');

-----------------------------------------------------------------------------------------------------

--тестирование _refreshold(st TIMESTAMP, fin TIMESTAMP)

select * from integer_archive;
select * from float_archive;

SELECT g.key AS key, g.configuration AS config, float_archive.fix AS fix, float_archive.value AS float_value, NULL AS integer_value
FROM glossary AS g
INNER JOIN float_archive ON g.key = float_archive.key 
WHERE fix BETWEEN ('2021-10-28 19:54:43.120367+07') AND ('2021-10-28 20:00:43.120367+07')
UNION
SELECT g.key AS key, configuration AS config, integer_archive.fix AS fix, NULL AS float_value, integer_archive.value AS integer_value
FROM glossary AS g
INNER JOIN integer_archive ON g.key = integer_archive.key 
WHERE fix BETWEEN ('2021-10-28 19:54:43.120367+07') AND ('2021-10-28 20:00:43.120367+07')
ORDER BY key;

select * from _refreshold('2021-10-28 19:54:43.120367+07','2021-10-28 20:00:43.120367+07');

--тестирование графиков stimulsoft
CREATE TABLE IF NOT EXISTS foo_test( 
key integer NOT NULL GENERATED ALWAYS AS IDENTITY ( INCREMENT 1 START 1 MINVALUE 1 MAXVALUE 2147483647 CACHE 1 ),
val FLOAT NOT NULL);

INSERT INTO foo_test (val) VALUES
(15.16),
(42.32),
(73.39),
(144.488),
(555.5),
(836.698),
(1007.007),
(1508.528),
(3009.9);

select * from foo_test;
-----------------------------------------------------------------------------------------------------

--тестирование VIEW

CREATE OR REPLACE VIEW glossary_join_actual AS
SELECT configuration AS config, f.fix AS float_fix, f.value AS float_value, i.fix AS integer_fix, i.value AS integer_value
FROM glossary AS g
LEFT JOIN float_actual AS f ON g.key = f.key
LEFT JOIN integer_actual AS i ON g.key = i.key;

SELECT * FROM glossary_join_actual;

--тестирование хранимой функции, возвращающей разные типы

CREATE OR REPLACE FUNCTION public.foo(str character varying)
 RETURNS SETOF record
 LANGUAGE plpgsql
AS $$
BEGIN
  IF str = 'i' THEN
   RETURN QUERY SELECT i, i*i FROM generate_series(1, 10) i;
  ELSE
    RETURN QUERY SELECT i, SQRT(i::float) FROM generate_series(1, 10) i;
  END IF;
END;
$$

select * from foo('i') as (key int, value int);

select * from foo('x') as (key int, value float);