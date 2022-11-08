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

--тестирование _communication

	DROP TABLE IF EXISTS float_archive, float_actual, integer_archive, integer_actual;

	CREATE TABLE IF NOT EXISTS float_archive( 
	key INTEGER NOT NULL,
	fix TIMESTAMPTZ NOT NULL,
	value FLOAT NOT NULL,
	FOREIGN KEY (key) REFERENCES glossary(key));
	
	SELECT create_hypertable(
	'float_archive', 'fix',
	chunk_time_interval => INTERVAL '1 day',
	if_not_exists => TRUE
	);

	CREATE TABLE IF NOT EXISTS float_actual( 
	key INTEGER NOT NULL,
	fix TIMESTAMPTZ NOT NULL,
	value FLOAT NOT NULL,
	FOREIGN KEY (key) REFERENCES glossary(key));
	
	--------------------------------------------
	
	CREATE TABLE IF NOT EXISTS integer_archive( 
	key INTEGER NOT NULL,
	fix TIMESTAMPTZ NOT NULL,
	value INTEGER NOT NULL,
	FOREIGN KEY (key) REFERENCES glossary(key));
	
	SELECT create_hypertable(
	'integer_archive', 'fix',
	chunk_time_interval => INTERVAL '1 day',
	if_not_exists => TRUE
	);
	
	CREATE TABLE IF NOT EXISTS integer_actual( 
	key INTEGER NOT NULL,
	fix TIMESTAMPTZ NOT NULL,
	value INTEGER NOT NULL,
	FOREIGN KEY (key) REFERENCES glossary(key));
	
	--------------------------------------------
	
	INSERT INTO float_archive(key, fix, value) VALUES(1, NOW(), 1);	
	INSERT INTO float_archive(key, fix, value) VALUES(2, NOW(), 2);
	SELECT * FROM float_archive ORDER BY fix;

SELECT EXISTS(SELECT 1 from glossary WHERE configuration = 
'Configuration/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE061.Runtime'']/Equipment/Slot/Item[@key=''1'']/Supply/Item[@key=''photocathode'']/Amperage');

INSERT INTO float_actual(key, fix, value) VALUES(1, NOW(), 1);	
select * from float_actual order by key;

--float
--#1 from UPDATE
select * from _communication('Configuration[@key=''_036CE061.Communicator'']/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE061.Runtime'']/Communication/Item[@key=''serialport'']/Modbus/Item[@key=''COM2'']/Board/Item[@key=''_045СЕ108'']/Adress/Item[@key=''01'']/Channel/Item[@key=''1'']/Amperage/@value',18.0);
select * from float_actual order by key;

--#1 from UPDATE
select * from _communication('Configuration[@key=''_036CE061.Communicator'']/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE061.Runtime'']/Communication/Item[@key=''serialport'']/Modbus/Item[@key=''COM2'']/Board/Item[@key=''_045СЕ108'']/Adress/Item[@key=''01'']/Channel/Item[@key=''1'']/Amperage/@value',18.0);
select * from float_archive order by key;

UPDATE float_actual SET fix = NOW(), value = 2 WHERE key = 1;
select * from float_actual order by key;

--#3 from UPDATE
select * from _communication('Configuration[@key=''_036CE061.Communicator'']/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE061.Runtime'']/Communication/Item[@key=''serialport'']/Modbus/Item[@key=''COM2'']/Board/Item[@key=''_045СЕ108'']/Adress/Item[@key=''01'']/Channel/Item[@key=''2'']/Amperage/@value',28.0);
select * from float_actual order by key;

--#3 from UPDATE
select * from _communication('Configuration[@key=''_036CE061.Communicator'']/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE061.Runtime'']/Communication/Item[@key=''serialport'']/Modbus/Item[@key=''COM2'']/Board/Item[@key=''_045СЕ108'']/Adress/Item[@key=''01'']/Channel/Item[@key=''2'']/Amperage/@value',28.0);
select * from float_archive order by key;

SELECT MAX(fix) from float_archive;
UPDATE float_archive SET fix = NOW() WHERE fix = (SELECT MAX(fix) from float_archive);

select * from _communication('Configuration[@key=''_036CE061.Communicator'']/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE061.Runtime'']/Communication/Item[@key=''serialport'']/Modbus/Item[@key=''COM2'']/Board/Item[@key=''_045СЕ108'']/Adress/Item[@key=''01'']/Channel/Item[@key=''1'']/Amperage/@value',18.0);
select * from _communication('Configuration[@key=''_036CE061.Communicator'']/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE061.Runtime'']/Communication/Item[@key=''serialport'']/Modbus/Item[@key=''COM2'']/Board/Item[@key=''_045СЕ108'']/Adress/Item[@key=''01'']/Channel/Item[@key=''2'']/Amperage/@value',28.0);
select * from _communication('Configuration[@key=''_036CE061.Communicator'']/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE061.Runtime'']/Communication/Item[@key=''serialport'']/Modbus/Item[@key=''COM2'']/Board/Item[@key=''_045СЕ108'']/Adress/Item[@key=''01'']/Channel/Item[@key=''3'']/Amperage/@value',38.0);
select * from _communication('Configuration[@key=''_036CE061.Communicator'']/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE061.Runtime'']/Communication/Item[@key=''serialport'']/Modbus/Item[@key=''COM2'']/Board/Item[@key=''_045СЕ108'']/Adress/Item[@key=''01'']/Channel/Item[@key=''4'']/Amperage/@value',48.0);
select * from _communication('Configuration[@key=''_036CE061.Communicator'']/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE061.Runtime'']/Communication/Item[@key=''serialport'']/Modbus/Item[@key=''COM2'']/Board/Item[@key=''_045СЕ108'']/Adress/Item[@key=''01'']/Channel/Item[@key=''5'']/Amperage/@value',58.0);
select * from _communication('Configuration[@key=''_036CE061.Communicator'']/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE061.Runtime'']/Communication/Item[@key=''serialport'']/Modbus/Item[@key=''COM2'']/Board/Item[@key=''_045СЕ108'']/Adress/Item[@key=''02'']/Channel/Item[@key=''1'']/Amperage/@value',68.0);
select * from float_actual order by value;

select * from _communication('Configuration[@key=''_036CE061.Communicator'']/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE061.Runtime'']/Communication/Item[@key=''serialport'']/Modbus/Item[@key=''COM2'']/Board/Item[@key=''_045СЕ108'']/Adress/Item[@key=''01'']/Channel/Item[@key=''1'']/Amperage/@value',78.0);
select * from _communication('Configuration[@key=''_036CE061.Communicator'']/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE061.Runtime'']/Communication/Item[@key=''serialport'']/Modbus/Item[@key=''COM2'']/Board/Item[@key=''_045СЕ108'']/Adress/Item[@key=''01'']/Channel/Item[@key=''2'']/Amperage/@value',88.0);
select * from _communication('Configuration[@key=''_036CE061.Communicator'']/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE061.Runtime'']/Communication/Item[@key=''serialport'']/Modbus/Item[@key=''COM2'']/Board/Item[@key=''_045СЕ108'']/Adress/Item[@key=''01'']/Channel/Item[@key=''3'']/Amperage/@value',98.0);
select * from _communication('Configuration[@key=''_036CE061.Communicator'']/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE061.Runtime'']/Communication/Item[@key=''serialport'']/Modbus/Item[@key=''COM2'']/Board/Item[@key=''_045СЕ108'']/Adress/Item[@key=''01'']/Channel/Item[@key=''4'']/Amperage/@value',108.0);
select * from _communication('Configuration[@key=''_036CE061.Communicator'']/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE061.Runtime'']/Communication/Item[@key=''serialport'']/Modbus/Item[@key=''COM2'']/Board/Item[@key=''_045СЕ108'']/Adress/Item[@key=''01'']/Channel/Item[@key=''5'']/Amperage/@value',118.0);
select * from _communication('Configuration[@key=''_036CE061.Communicator'']/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE061.Runtime'']/Communication/Item[@key=''serialport'']/Modbus/Item[@key=''COM2'']/Board/Item[@key=''_045СЕ108'']/Adress/Item[@key=''02'']/Channel/Item[@key=''1'']/Amperage/@value',128.0);
select * from float_actual order by value;

select * from _communication('Configuration[@key=''_036CE061.Communicator'']/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE061.Runtime'']/Communication/Item[@key=''serialport'']/Modbus/Item[@key=''COM2'']/Board/Item[@key=''_045СЕ108'']/Adress/Item[@key=''01'']/Channel/Item[@key=''1'']/Amperage/@value',18.0);
select * from _communication('Configuration[@key=''_036CE061.Communicator'']/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE061.Runtime'']/Communication/Item[@key=''serialport'']/Modbus/Item[@key=''COM2'']/Board/Item[@key=''_045СЕ108'']/Adress/Item[@key=''01'']/Channel/Item[@key=''2'']/Amperage/@value',28.0);
select * from _communication('Configuration[@key=''_036CE061.Communicator'']/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE061.Runtime'']/Communication/Item[@key=''serialport'']/Modbus/Item[@key=''COM2'']/Board/Item[@key=''_045СЕ108'']/Adress/Item[@key=''01'']/Channel/Item[@key=''3'']/Amperage/@value',38.0);
select * from _communication('Configuration[@key=''_036CE061.Communicator'']/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE061.Runtime'']/Communication/Item[@key=''serialport'']/Modbus/Item[@key=''COM2'']/Board/Item[@key=''_045СЕ108'']/Adress/Item[@key=''01'']/Channel/Item[@key=''4'']/Amperage/@value',48.0);
select * from _communication('Configuration[@key=''_036CE061.Communicator'']/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE061.Runtime'']/Communication/Item[@key=''serialport'']/Modbus/Item[@key=''COM2'']/Board/Item[@key=''_045СЕ108'']/Adress/Item[@key=''01'']/Channel/Item[@key=''5'']/Amperage/@value',58.0);
select * from _communication('Configuration[@key=''_036CE061.Communicator'']/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE061.Runtime'']/Communication/Item[@key=''serialport'']/Modbus/Item[@key=''COM2'']/Board/Item[@key=''_045СЕ108'']/Adress/Item[@key=''02'']/Channel/Item[@key=''1'']/Amperage/@value',68.0);
select * from float_archive order by value desc;

select * from _communication('Configuration[@key=''_036CE061.Communicator'']/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE061.Runtime'']/Communication/Item[@key=''serialport'']/Modbus/Item[@key=''COM2'']/Board/Item[@key=''_045СЕ108'']/Adress/Item[@key=''01'']/Channel/Item[@key=''1'']/Amperage/@value',78.0);
select * from _communication('Configuration[@key=''_036CE061.Communicator'']/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE061.Runtime'']/Communication/Item[@key=''serialport'']/Modbus/Item[@key=''COM2'']/Board/Item[@key=''_045СЕ108'']/Adress/Item[@key=''01'']/Channel/Item[@key=''2'']/Amperage/@value',88.0);
select * from _communication('Configuration[@key=''_036CE061.Communicator'']/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE061.Runtime'']/Communication/Item[@key=''serialport'']/Modbus/Item[@key=''COM2'']/Board/Item[@key=''_045СЕ108'']/Adress/Item[@key=''01'']/Channel/Item[@key=''3'']/Amperage/@value',98.0);
select * from _communication('Configuration[@key=''_036CE061.Communicator'']/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE061.Runtime'']/Communication/Item[@key=''serialport'']/Modbus/Item[@key=''COM2'']/Board/Item[@key=''_045СЕ108'']/Adress/Item[@key=''01'']/Channel/Item[@key=''4'']/Amperage/@value',108.0);
select * from _communication('Configuration[@key=''_036CE061.Communicator'']/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE061.Runtime'']/Communication/Item[@key=''serialport'']/Modbus/Item[@key=''COM2'']/Board/Item[@key=''_045СЕ108'']/Adress/Item[@key=''01'']/Channel/Item[@key=''5'']/Amperage/@value',118.0);
select * from _communication('Configuration[@key=''_036CE061.Communicator'']/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE061.Runtime'']/Communication/Item[@key=''serialport'']/Modbus/Item[@key=''COM2'']/Board/Item[@key=''_045СЕ108'']/Adress/Item[@key=''02'']/Channel/Item[@key=''1'']/Amperage/@value',128.0);
select * from float_archive order by value desc;

--integer
--#2 from UPDATE
select * from _communication('Configuration[@key=''_036CE061.Communicator'']/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE061.Runtime'']/Communication/Item[@key=''serialport'']/Modbus/Item[@key=''COM2'']/Board/Item[@key=''_045СЕ108'']/Adress/Item[@key=''01'']/Channel/Item[@key=''1'']/Voltage/@value',18);
select * from integer_actual order by key;

--#2 from UPDATE
select * from _communication('Configuration[@key=''_036CE061.Communicator'']/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE061.Runtime'']/Communication/Item[@key=''serialport'']/Modbus/Item[@key=''COM2'']/Board/Item[@key=''_045СЕ108'']/Adress/Item[@key=''01'']/Channel/Item[@key=''1'']/Voltage/@value',18);
select * from integer_archive order by key;

--#4 from UPDATE
select * from _communication('Configuration[@key=''_036CE061.Communicator'']/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE061.Runtime'']/Communication/Item[@key=''serialport'']/Modbus/Item[@key=''COM2'']/Board/Item[@key=''_045СЕ108'']/Adress/Item[@key=''01'']/Channel/Item[@key=''2'']/Voltage/@value',28);
select * from integer_actual order by key;

--#4 from UPDATE
select * from _communication('Configuration[@key=''_036CE061.Communicator'']/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE061.Runtime'']/Communication/Item[@key=''serialport'']/Modbus/Item[@key=''COM2'']/Board/Item[@key=''_045СЕ108'']/Adress/Item[@key=''01'']/Channel/Item[@key=''2'']/Voltage/@value',28);
select * from integer_archive order by key;

select * from _communication('Configuration[@key=''_036CE061.Communicator'']/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE061.Runtime'']/Communication/Item[@key=''serialport'']/Modbus/Item[@key=''COM2'']/Board/Item[@key=''_045СЕ108'']/Adress/Item[@key=''01'']/Channel/Item[@key=''1'']/Voltage/@value',18);
select * from _communication('Configuration[@key=''_036CE061.Communicator'']/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE061.Runtime'']/Communication/Item[@key=''serialport'']/Modbus/Item[@key=''COM2'']/Board/Item[@key=''_045СЕ108'']/Adress/Item[@key=''01'']/Channel/Item[@key=''2'']/Voltage/@value',28);
select * from _communication('Configuration[@key=''_036CE061.Communicator'']/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE061.Runtime'']/Communication/Item[@key=''serialport'']/Modbus/Item[@key=''COM2'']/Board/Item[@key=''_045СЕ108'']/Adress/Item[@key=''01'']/Channel/Item[@key=''3'']/Voltage/@value',38);
select * from _communication('Configuration[@key=''_036CE061.Communicator'']/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE061.Runtime'']/Communication/Item[@key=''serialport'']/Modbus/Item[@key=''COM2'']/Board/Item[@key=''_045СЕ108'']/Adress/Item[@key=''01'']/Channel/Item[@key=''4'']/Voltage/@value',48);
select * from _communication('Configuration[@key=''_036CE061.Communicator'']/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE061.Runtime'']/Communication/Item[@key=''serialport'']/Modbus/Item[@key=''COM2'']/Board/Item[@key=''_045СЕ108'']/Adress/Item[@key=''01'']/Channel/Item[@key=''5'']/Voltage/@value',58);
select * from _communication('Configuration[@key=''_036CE061.Communicator'']/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE061.Runtime'']/Communication/Item[@key=''serialport'']/Modbus/Item[@key=''COM2'']/Board/Item[@key=''_045СЕ108'']/Adress/Item[@key=''02'']/Channel/Item[@key=''1'']/Voltage/@value',68);
select * from integer_actual order by value;

select * from _communication('Configuration[@key=''_036CE061.Communicator'']/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE061.Runtime'']/Communication/Item[@key=''serialport'']/Modbus/Item[@key=''COM2'']/Board/Item[@key=''_045СЕ108'']/Adress/Item[@key=''01'']/Channel/Item[@key=''1'']/Voltage/@value',181);
select * from _communication('Configuration[@key=''_036CE061.Communicator'']/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE061.Runtime'']/Communication/Item[@key=''serialport'']/Modbus/Item[@key=''COM2'']/Board/Item[@key=''_045СЕ108'']/Adress/Item[@key=''01'']/Channel/Item[@key=''2'']/Voltage/@value',281);
select * from _communication('Configuration[@key=''_036CE061.Communicator'']/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE061.Runtime'']/Communication/Item[@key=''serialport'']/Modbus/Item[@key=''COM2'']/Board/Item[@key=''_045СЕ108'']/Adress/Item[@key=''01'']/Channel/Item[@key=''3'']/Voltage/@value',381);
select * from _communication('Configuration[@key=''_036CE061.Communicator'']/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE061.Runtime'']/Communication/Item[@key=''serialport'']/Modbus/Item[@key=''COM2'']/Board/Item[@key=''_045СЕ108'']/Adress/Item[@key=''01'']/Channel/Item[@key=''4'']/Voltage/@value',481);
select * from _communication('Configuration[@key=''_036CE061.Communicator'']/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE061.Runtime'']/Communication/Item[@key=''serialport'']/Modbus/Item[@key=''COM2'']/Board/Item[@key=''_045СЕ108'']/Adress/Item[@key=''01'']/Channel/Item[@key=''5'']/Voltage/@value',581);
select * from _communication('Configuration[@key=''_036CE061.Communicator'']/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE061.Runtime'']/Communication/Item[@key=''serialport'']/Modbus/Item[@key=''COM2'']/Board/Item[@key=''_045СЕ108'']/Adress/Item[@key=''02'']/Channel/Item[@key=''1'']/Voltage/@value',681);
select * from integer_actual order by value;

select * from _communication('Configuration[@key=''_036CE061.Communicator'']/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE061.Runtime'']/Communication/Item[@key=''serialport'']/Modbus/Item[@key=''COM2'']/Board/Item[@key=''_045СЕ108'']/Adress/Item[@key=''01'']/Channel/Item[@key=''1'']/Voltage/@value',18);
select * from _communication('Configuration[@key=''_036CE061.Communicator'']/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE061.Runtime'']/Communication/Item[@key=''serialport'']/Modbus/Item[@key=''COM2'']/Board/Item[@key=''_045СЕ108'']/Adress/Item[@key=''01'']/Channel/Item[@key=''2'']/Voltage/@value',28);
select * from _communication('Configuration[@key=''_036CE061.Communicator'']/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE061.Runtime'']/Communication/Item[@key=''serialport'']/Modbus/Item[@key=''COM2'']/Board/Item[@key=''_045СЕ108'']/Adress/Item[@key=''01'']/Channel/Item[@key=''3'']/Voltage/@value',38);
select * from _communication('Configuration[@key=''_036CE061.Communicator'']/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE061.Runtime'']/Communication/Item[@key=''serialport'']/Modbus/Item[@key=''COM2'']/Board/Item[@key=''_045СЕ108'']/Adress/Item[@key=''01'']/Channel/Item[@key=''4'']/Voltage/@value',48);
select * from _communication('Configuration[@key=''_036CE061.Communicator'']/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE061.Runtime'']/Communication/Item[@key=''serialport'']/Modbus/Item[@key=''COM2'']/Board/Item[@key=''_045СЕ108'']/Adress/Item[@key=''01'']/Channel/Item[@key=''5'']/Voltage/@value',58);
select * from _communication('Configuration[@key=''_036CE061.Communicator'']/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE061.Runtime'']/Communication/Item[@key=''serialport'']/Modbus/Item[@key=''COM2'']/Board/Item[@key=''_045СЕ108'']/Adress/Item[@key=''02'']/Channel/Item[@key=''1'']/Voltage/@value',68);
select * from integer_archive order by value;

select * from _communication('Configuration[@key=''_036CE061.Communicator'']/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE061.Runtime'']/Communication/Item[@key=''serialport'']/Modbus/Item[@key=''COM2'']/Board/Item[@key=''_045СЕ108'']/Adress/Item[@key=''01'']/Channel/Item[@key=''1'']/Voltage/@value',181);
select * from _communication('Configuration[@key=''_036CE061.Communicator'']/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE061.Runtime'']/Communication/Item[@key=''serialport'']/Modbus/Item[@key=''COM2'']/Board/Item[@key=''_045СЕ108'']/Adress/Item[@key=''01'']/Channel/Item[@key=''2'']/Voltage/@value',281);
select * from _communication('Configuration[@key=''_036CE061.Communicator'']/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE061.Runtime'']/Communication/Item[@key=''serialport'']/Modbus/Item[@key=''COM2'']/Board/Item[@key=''_045СЕ108'']/Adress/Item[@key=''01'']/Channel/Item[@key=''3'']/Voltage/@value',381);
select * from _communication('Configuration[@key=''_036CE061.Communicator'']/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE061.Runtime'']/Communication/Item[@key=''serialport'']/Modbus/Item[@key=''COM2'']/Board/Item[@key=''_045СЕ108'']/Adress/Item[@key=''01'']/Channel/Item[@key=''4'']/Voltage/@value',481);
select * from _communication('Configuration[@key=''_036CE061.Communicator'']/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE061.Runtime'']/Communication/Item[@key=''serialport'']/Modbus/Item[@key=''COM2'']/Board/Item[@key=''_045СЕ108'']/Adress/Item[@key=''01'']/Channel/Item[@key=''5'']/Voltage/@value',581);
select * from _communication('Configuration[@key=''_036CE061.Communicator'']/Communication/Item[@key=''database'']/Postgres/Item[@key=''localhost:5432:_036CE061.Runtime'']/Communication/Item[@key=''serialport'']/Modbus/Item[@key=''COM2'']/Board/Item[@key=''_045СЕ108'']/Adress/Item[@key=''02'']/Channel/Item[@key=''1'']/Voltage/@value',681);
select * from integer_archive order by value;

select * from float_archive order by key desc;
SELECT value FROM float_archive ORDER BY fix DESC LIMIT 1;

SELECT value FROM float_archive WHERE key = 1 ORDER BY fix DESC LIMIT 1;

SELECT * FROM float_archive WHERE key = 5 ORDER BY value;

--UPDATE hyper

UPDATE float_archive SET fix = NOW() WHERE value = 128;
SELECT * FROM float_archive

SELECT fix FROM float_archive WHERE key = 11;
SELECT MAX(fix) FROM float_archive WHERE key = 11;

UPDATE float_archive SET fix = NOW() WHERE fix = (SELECT MAX(fix) FROM float_archive WHERE key = 11);
SELECT * FROM float_archive









