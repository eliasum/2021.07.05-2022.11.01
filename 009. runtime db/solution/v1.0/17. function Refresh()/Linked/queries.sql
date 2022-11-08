/*2022.01.24 08:48 IMM*/

--заполнение таблиц (200 строк в actual)
INSERT INTO integer_actual (integer_actual_tstamp, integer_actual_val) 
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

INSERT INTO integer_archive (integer_archive_key, integer_archive_tstamp, integer_archive_val) 
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

select * from integer_actual;

select * from _Refresh(
'ControlWorkstation/Equipment/Slot/Item[@key=''1'']/Supply/Item[@key=''Photocathode'']/Voltage');
-----------------------------------------------------------------------------------------------------

--тестирование _refresh()
select * from integer_actual;
select * from integer_archive;

select * from float_actual;
select * from float_archive;

DROP TABLE integer_actual;
DROP TABLE float_actual;
DROP TABLE glossary;

CREATE TABLE glossary (
    key INTEGER NOT NULL GENERATED ALWAYS AS IDENTITY ( INCREMENT 1 START 1 MINVALUE 1 MAXVALUE 2147483647 CACHE 1 ),
    configuration TEXT NOT NULL,
    communication TEXT,
    allowance FLOAT NOT NULL,
    tablename CHARACTER(15) NOT NULL,
    CONSTRAINT "glossary_key" PRIMARY KEY (key)
);

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
('ControlWorkstation/Equipment/Slot/Item[@key=''1'']/Supply/Item[@key=''Microchannelplate12'']/Voltage', NULL, 3, 'integer');

select * from glossary;

CREATE TABLE IF NOT EXISTS float_actual( 
float_actual_key integer NOT NULL GENERATED ALWAYS AS IDENTITY ( INCREMENT 2 START 1 MINVALUE 1 MAXVALUE 5 CACHE 1 ),
float_actual_tstamp TIMESTAMPTZ NOT NULL,
float_actual_val FLOAT NOT NULL,
FOREIGN KEY (float_actual_key) REFERENCES glossary(key));

CREATE TABLE IF NOT EXISTS integer_actual( 
integer_actual_key INTEGER NOT NULL GENERATED ALWAYS AS IDENTITY ( INCREMENT 2 START 2 MINVALUE 2 MAXVALUE 6 CACHE 1 ),
integer_actual_tstamp TIMESTAMPTZ NOT NULL,
integer_actual_val INTEGER NOT NULL,
FOREIGN KEY (integer_actual_key) REFERENCES glossary(key));

INSERT INTO float_actual (float_actual_tstamp, float_actual_val) VALUES 
(NOW(), 1.1),
(NOW(), 3.3),
(NOW(), 5.5);

INSERT INTO integer_actual (integer_actual_tstamp, integer_actual_val) VALUES 
(NOW(), 2),
(NOW(), 4),
(NOW(), 6);

select * from float_actual;
select * from integer_actual; 

--значения val в одном столбце
SELECT gl.key AS key, configuration AS config, float_actual_tstamp AS fix, float_actual_val AS val
FROM glossary AS gl 
INNER JOIN float_actual ON key = float_actual_key 
UNION
SELECT gl.key AS key, configuration AS conf, integer_actual_tstamp AS fix, integer_actual_val AS val
FROM glossary AS gl 
INNER JOIN integer_actual ON key = integer_actual_key 
ORDER BY key;

--значения val в разных столбцах (в файл runtime.sql)
SELECT gl.key AS key, configuration AS config, float_actual_tstamp AS fix, float_actual_val AS float_val, NULL AS integer_val
FROM glossary AS gl 
INNER JOIN float_actual ON key = float_actual_key 
UNION
SELECT gl.key AS key, configuration AS conf, integer_actual_tstamp AS fix, NULL AS float_val, integer_actual_val AS val
FROM glossary AS gl 
INNER JOIN integer_actual ON key = integer_actual_key 
ORDER BY key;

select * from _refresh();

-----------------------------------------------------------------------------------------------------

--тестирование _refresh()

select * from integer_archive;
select * from float_archive;

SELECT gl.key AS key, configuration AS config, float_archive_tstamp AS fix, float_archive_val AS float_val, NULL AS integer_val
FROM glossary AS gl 
INNER JOIN float_archive ON key = float_archive_key 
WHERE float_archive_tstamp BETWEEN ('2021-10-26 08:57:56.072739+07') AND ('2021-10-26 09:23:56.072739+07')
UNION
SELECT gl.key AS key, configuration AS conf, integer_archive_tstamp AS fix, NULL AS float_val, integer_archive_val AS val
FROM glossary AS gl 
INNER JOIN integer_archive ON key = integer_archive_key 
WHERE integer_archive_tstamp BETWEEN ('2021-10-26 08:57:56.072739+07') AND ('2021-10-26 09:23:56.072739+07')
ORDER BY key;

select * from _refreshold('2021-10-27 11:57:05.844831+07','2021-10-27 12:02:05.844831+07');
-----------------------------------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION _foo()
  RETURNS BOOLEAN AS
$$
DECLARE 

	--переменные для:
	_Table TEXT;  			--имени актуальной таблицы  
	flag BOOLEAN;

BEGIN

	_Table := 'float' || '_actual';
	
	IF (_Table LIKE '%float%') THEN
		flag := TRUE;
	ELSE
		flag := FALSE;
	END IF; 

	RETURN flag; 
	
END;

$$ LANGUAGE plpgsql;
-----------------------------------------------------------------------------------------------------

--тестирование _communication()

--float_actual:
--вызов функции
select * from _communication('ControlWorkstation/Equipment/Slot/Item[@key=''1'']/Supply/Item[@key=''Photocathode'']/Amperage',-11.88);

--вызов процедуры
CALL _communication('ControlWorkstation/Equipment/Slot/Item[@key=''1'']/Supply/Item[@key=''Photocathode'']/Amperage',-12.88);

--последняя запись в float_actual
SELECT float_actual_key, float_actual_val FROM float_actual ORDER BY float_actual_key DESC LIMIT 1;	

--integer_actual:
--вызов функции
select * from _communication('ControlWorkstation/Equipment/Slot/Item[@key=''1'']/Supply/Item[@key=''Photocathode'']/Voltage',18);

--вызов процедуры
CALL _communication('ControlWorkstation/Equipment/Slot/Item[@key=''1'']/Supply/Item[@key=''Photocathode'']/Voltage',19);

--последняя запись в integer_actual
SELECT integer_actual_key, integer_actual_val FROM integer_actual ORDER BY integer_actual_key DESC LIMIT 1;	